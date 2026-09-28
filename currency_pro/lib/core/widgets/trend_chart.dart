import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/rate_snapshot.dart';
import '../theme/app_palette.dart';
import '../utils/formatting.dart';

/// An interactive line chart drawn with a [CustomPainter].
///
/// Written by hand rather than pulled from a charting package so the app has
/// one fewer dependency to keep in sync — and so the styling follows the
/// active theme exactly.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.points,
    this.height = 220,
    this.showAxis = true,
    this.lineWidth = 2,
    this.color,
    this.labelBuilder,
  });

  final List<RatePoint> points;
  final double height;
  final bool showAxis;
  final double lineWidth;
  final Color? color;

  /// Builds the tooltip text for a touched point.
  final String Function(RatePoint point)? labelBuilder;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final List<RatePoint> points = widget.points;

    if (points.length < 2) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No history available for this pair',
            style: TextStyle(color: p.textSecondary, fontSize: 12.5),
          ),
        ),
      );
    }

    final bool rising = points.last.value >= points.first.value;
    final Color line =
        widget.color ?? (rising ? p.up : p.down);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          void select(Offset local) {
            const double padLeft = 8;
            final double usable =
                math.max(1, constraints.maxWidth - padLeft - 8);
            final double ratio =
                ((local.dx - padLeft) / usable).clamp(0.0, 1.0);
            final int index = (ratio * (points.length - 1)).round();
            if (index != _selected) setState(() => _selected = index);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails d) => select(d.localPosition),
            onHorizontalDragStart: (DragStartDetails d) =>
                select(d.localPosition),
            onHorizontalDragUpdate: (DragUpdateDetails d) =>
                select(d.localPosition),
            onHorizontalDragEnd: (_) => setState(() => _selected = null),
            onTapUp: (_) => Future<void>.delayed(
              const Duration(seconds: 3),
              () {
                if (mounted) setState(() => _selected = null);
              },
            ),
            child: CustomPaint(
              size: Size(constraints.maxWidth, widget.height),
              painter: _TrendPainter(
                points: points,
                palette: p,
                lineColor: line,
                lineWidth: widget.lineWidth,
                showAxis: widget.showAxis,
                selected: _selected,
                label: _selected == null
                    ? null
                    : (widget.labelBuilder?.call(points[_selected!]) ??
                        '${Fmt.dateShort(points[_selected!].date)}  '
                            '${Fmt.smart(points[_selected!].value)}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.palette,
    required this.lineColor,
    required this.lineWidth,
    required this.showAxis,
    required this.selected,
    required this.label,
  });

  final List<RatePoint> points;
  final AppPalette palette;
  final Color lineColor;
  final double lineWidth;
  final bool showAxis;
  final int? selected;
  final String? label;

  static const double padLeft = 8;
  static const double padRight = 8;
  static const double padTop = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final double padBottom = showAxis ? 22 : 8;

    double minValue = points.first.value;
    double maxValue = points.first.value;
    for (final RatePoint p in points) {
      minValue = math.min(minValue, p.value);
      maxValue = math.max(maxValue, p.value);
    }
    final double span = (maxValue - minValue).abs();
    final double pad = span == 0 ? math.max(maxValue.abs() * 0.01, 0.0001) : span * 0.12;
    minValue -= pad;
    maxValue += pad;

    final double chartW = size.width - padLeft - padRight;
    final double chartH = size.height - padTop - padBottom;

    Offset at(int i) {
      final double x = padLeft + chartW * (i / (points.length - 1));
      final double t =
          (points[i].value - minValue) / math.max(1e-12, maxValue - minValue);
      final double y = padTop + chartH * (1 - t);
      return Offset(x, y);
    }

    // Horizontal grid lines.
    final Paint grid = Paint()
      ..color = palette.outline.withOpacity(0.7)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = padTop + chartH * (i / 4);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), grid);
    }

    // Filled area under the curve.
    final Path area = Path()..moveTo(padLeft, padTop + chartH);
    for (int i = 0; i < points.length; i++) {
      final Offset o = at(i);
      if (i == 0) {
        area.lineTo(o.dx, o.dy);
      } else {
        area.lineTo(o.dx, o.dy);
      }
    }
    area
      ..lineTo(padLeft + chartW, padTop + chartH)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lineColor.withOpacity(0.28),
            lineColor.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // The line itself.
    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final Offset o = at(i);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Min / max value labels.
    if (showAxis) {
      _text(canvas, Fmt.smart(maxValue, maxDecimals: 5),
          Offset(padLeft + 2, padTop - 10), 9, palette.textSecondary);
      _text(canvas, Fmt.smart(minValue, maxDecimals: 5),
          Offset(padLeft + 2, padTop + chartH + 2), 9, palette.textSecondary);
      _text(canvas, Fmt.dateShort(points.first.date),
          Offset(padLeft, size.height - 12), 9, palette.textSecondary);
      _text(
        canvas,
        Fmt.dateShort(points.last.date),
        Offset(size.width - padRight - 42, size.height - 12),
        9,
        palette.textSecondary,
      );
    }

    // Touch marker and tooltip.
    if (selected != null && selected! >= 0 && selected! < points.length) {
      final Offset o = at(selected!);
      canvas.drawLine(
        Offset(o.dx, padTop),
        Offset(o.dx, padTop + chartH),
        Paint()
          ..color = palette.textSecondary.withOpacity(0.5)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(o, 4.5, Paint()..color = lineColor);
      canvas.drawCircle(
        o,
        4.5,
        Paint()
          ..color = palette.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      if (label != null) {
        final TextPainter tp = _painter(label!, 10.5, palette.textPrimary);
        final double boxW = tp.width + 16;
        final double boxH = tp.height + 10;
        double left = o.dx - boxW / 2;
        left = left.clamp(padLeft, math.max(padLeft, size.width - padRight - boxW));
        final double top = math.max(0, o.dy - boxH - 12);
        final RRect box = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, boxW, boxH),
          const Radius.circular(7),
        );
        canvas.drawRRect(box, Paint()..color = palette.surfaceAlt);
        canvas.drawRRect(
          box,
          Paint()
            ..color = palette.outline
            ..style = PaintingStyle.stroke,
        );
        tp.paint(canvas, Offset(left + 8, top + 5));
      }
    }
  }

  TextPainter _painter(String text, double size, Color color) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _text(Canvas canvas, String text, Offset at, double size, Color color) {
    _painter(text, size, color).paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.lineColor != lineColor;
}

/// A tiny line used inside list rows.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.width = 64,
    this.height = 24,
    this.color,
  });

  final List<double> values;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    if (values.length < 2) return SizedBox(width: width, height: height);
    final bool rising = values.last >= values.first;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparkPainter(
          values: values,
          color: color ?? (rising ? p.up : p.down),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    double min = values.first;
    double max = values.first;
    for (final double v in values) {
      min = math.min(min, v);
      max = math.max(max, v);
    }
    final double range = math.max(1e-12, max - min);

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final double x = size.width * (i / (values.length - 1));
      final double y = size.height * (1 - (values[i] - min) / range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color;
}
