import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/notifications/notification_permission.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/brand_logo.dart';
import '../../state/settings_provider.dart';

/// First-launch walkthrough. The last page asks for notification permission.
///
/// Visually this continues straight on from the splash: the same full-bleed
/// hero gradient, the same brand mark, no strokes or dividers anywhere. Each
/// slide shows a small mock-up of the real screen it is describing rather
/// than a generic icon.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pages = PageController();
  int _index = 0;
  bool _busy = false;

  static const int _lastIndex = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool requestPermission}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final SettingsProvider settings = context.read<SettingsProvider>();
    bool allowed = false;
    if (requestPermission) {
      allowed = await NotificationPermission.request();
    }
    await settings.setNotificationsEnabled(allowed);
    await settings.completeOnboarding();
    if (!mounted) return;
    widget.onFinished();
  }

  void _next() {
    if (_index >= _lastIndex) return;
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipToEnd() {
    _pages.animateToPage(
      _lastIndex,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final bool isNotify = _index == _lastIndex;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.heroGradient,
          stops: const <double>[0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _TopBar(
              palette: p,
              showSkip: !isNotify,
              onSkip: _skipToEnd,
              skipLabel: l10n.skip,
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (int i) => setState(() => _index = i),
                children: <Widget>[
                  _Slide(
                    palette: p,
                    art: _ConverterArt(palette: p),
                    title: l10n.onboardConvertTitle,
                    body: l10n.onboardConvertBody,
                  ),
                  _Slide(
                    palette: p,
                    art: _MarketArt(palette: p),
                    title: l10n.onboardMarketTitle,
                    body: l10n.onboardMarketBody,
                  ),
                  _Slide(
                    palette: p,
                    art: _ToolsArt(palette: p),
                    title: l10n.onboardToolsTitle,
                    body: l10n.onboardToolsBody,
                  ),
                  _Slide(
                    palette: p,
                    art: _AlertArt(palette: p),
                    title: l10n.onboardNotifyTitle,
                    body: l10n.onboardNotifyBody,
                  ),
                ],
              ),
            ),
            _Dots(count: _lastIndex + 1, index: _index, palette: p),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: isNotify
                  ? Column(
                      children: <Widget>[
                        _PrimaryButton(
                          palette: p,
                          busy: _busy,
                          label: l10n.allowNotifications,
                          onPressed: _busy
                              ? null
                              : () => _finish(requestPermission: true),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _finish(requestPermission: false),
                          style: TextButton.styleFrom(
                            foregroundColor: p.textSecondary,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: Text(l10n.notNow),
                        ),
                      ],
                    )
                  : _PrimaryButton(
                      palette: p,
                      busy: false,
                      label: l10n.continueBtn,
                      onPressed: _next,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.palette,
    required this.showSkip,
    required this.onSkip,
    required this.skipLabel,
  });

  final AppPalette palette;
  final bool showSkip;
  final VoidCallback onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            const BrandLogo(size: 30, radius: 8),
            const SizedBox(width: 10),
            Text(
              'CurrencyPro',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const Spacer(),
            if (showSkip)
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textSecondary,
                  minimumSize: const Size(0, 36),
                ),
                child: Text(skipLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.palette,
    required this.art,
    required this.title,
    required this.body,
  });

  final AppPalette palette;
  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 8),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 12),
          art,
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              height: 1.22,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.palette,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final AppPalette palette;
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null && !busy ? 0.6 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: palette.brandGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.primary.withOpacity(0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: palette.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: palette.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    required this.palette,
  });

  final int count;
  final int index;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 7,
          width: active ? 26 : 7,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: palette.brandGradient)
                : null,
            color: active ? null : palette.textSecondary.withOpacity(0.28),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide artwork — small mock-ups built from fills only (no strokes).
// ---------------------------------------------------------------------------

/// Shared frame so every slide's artwork has the same footprint.
class _ArtFrame extends StatelessWidget {
  const _ArtFrame({required this.palette, required this.child});

  final AppPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                palette.primary.withOpacity(0.16),
                palette.primary.withOpacity(0),
              ],
            ),
          ),
        ),
        Container(
          width: 268,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: palette.cardShadow,
          ),
          child: child,
        ),
      ],
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.palette,
    required this.flag,
    required this.code,
    required this.value,
    this.highlight = false,
  });

  final AppPalette palette;
  final String flag;
  final String code;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: highlight ? palette.primaryWash : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Text(flag, style: const TextStyle(fontSize: 17)),
          const SizedBox(width: 9),
          Text(
            code,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: highlight ? palette.primary : palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConverterArt extends StatelessWidget {
  const _ConverterArt({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      palette: palette,
      child: Column(
        children: <Widget>[
          _MiniRow(
            palette: palette,
            flag: '🇺🇸',
            code: 'USD',
            value: '100.00',
            highlight: true,
          ),
          const SizedBox(height: 8),
          Icon(Icons.swap_vert_rounded, size: 18, color: palette.primary),
          const SizedBox(height: 8),
          _MiniRow(
            palette: palette,
            flag: '🇪🇺',
            code: 'EUR',
            value: '92.40',
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.bolt, size: 12, color: palette.primary),
              const SizedBox(width: 4),
              Text(
                '1 USD = 0.9240 EUR',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketArt extends StatelessWidget {
  const _MarketArt({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      palette: palette,
      child: Column(
        children: <Widget>[
          _AssetLine(
            palette: palette,
            badge: '₿',
            badgeColor: const Color(0xFFF7931A),
            name: 'Bitcoin',
            value: '86,076',
            change: '+1.24%',
            up: true,
          ),
          const SizedBox(height: 9),
          _AssetLine(
            palette: palette,
            badge: 'Au',
            badgeColor: const Color(0xFFD4AF37),
            name: 'Gold / oz',
            value: '4,329',
            change: '+0.38%',
            up: true,
          ),
          const SizedBox(height: 9),
          _AssetLine(
            palette: palette,
            badge: 'Ag',
            badgeColor: const Color(0xFFB8BFC6),
            name: 'Silver / oz',
            value: '65.58',
            change: '−0.21%',
            up: false,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: CustomPaint(
              size: const Size(double.infinity, 34),
              painter: _SparkPainter(color: palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetLine extends StatelessWidget {
  const _AssetLine({
    required this.palette,
    required this.badge,
    required this.badgeColor,
    required this.name,
    required this.value,
    required this.change,
    required this.up,
  });

  final AppPalette palette;
  final String badge;
  final Color badgeColor;
  final String name;
  final String value;
  final String change;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor.withOpacity(0.18),
          ),
          alignment: Alignment.center,
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            Text(
              change,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: up ? palette.up : palette.down,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.color});

  final Color color;

  static const List<double> _points = <double>[
    0.42, 0.48, 0.38, 0.55, 0.50, 0.66, 0.60, 0.74, 0.69, 0.82, 0.78, 0.92,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Path line = Path();
    for (int i = 0; i < _points.length; i++) {
      final double x = size.width * (i / (_points.length - 1));
      final double y = size.height * (1 - _points[i]);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }

    final Path area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color.withOpacity(0.30), color.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.color != color;
}

class _ToolsArt extends StatelessWidget {
  const _ToolsArt({required this.palette});

  final AppPalette palette;

  static const List<List<dynamic>> _tiles = <List<dynamic>>[
    <dynamic>[Icons.calculate_outlined, 'Scientific'],
    <dynamic>[Icons.account_balance_outlined, 'Loan'],
    <dynamic>[Icons.straighten, 'Units'],
    <dynamic>[Icons.local_offer_outlined, 'Discount'],
    <dynamic>[Icons.monitor_heart_outlined, 'BMI'],
    <dynamic>[Icons.cake_outlined, 'Age'],
  ];

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      palette: palette,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _tiles.map((List<dynamic> tile) {
          return SizedBox(
            width: 72,
            child: Column(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.primaryWash,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    tile[0] as IconData,
                    size: 21,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tile[1] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _AlertArt extends StatelessWidget {
  const _AlertArt({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return _ArtFrame(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(colors: palette.brandGradient),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 16,
                  color: palette.onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CurrencyPro',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      'now',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'USD / EUR reached 0.9200',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your target was hit — tap to convert.',
            style: TextStyle(fontSize: 11, color: palette.textSecondary),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: <Widget>[
                  Container(color: palette.surfaceAlt),
                  FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient:
                            LinearGradient(colors: palette.brandGradient),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Target reached · 100%',
            style: TextStyle(fontSize: 9.5, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
