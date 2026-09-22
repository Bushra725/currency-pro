import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_card.dart';

/// Body mass index with metric and imperial entry.
class BmiCalculatorPage extends StatefulWidget {
  const BmiCalculatorPage({super.key});

  @override
  State<BmiCalculatorPage> createState() => _BmiCalculatorPageState();
}

class _BmiCalculatorPageState extends State<BmiCalculatorPage> {
  bool _metric = true;
  double _heightCm = 175;
  double _weightKg = 70;

  double get _bmi {
    final double m = _heightCm / 100;
    if (m <= 0) return 0;
    return _weightKg / (m * m);
  }

  ({String label, Color color}) _category(AppPalette p, double bmi) {
    if (bmi < 18.5) return (label: 'Underweight', color: p.accent);
    if (bmi < 25) return (label: 'Healthy weight', color: p.up);
    if (bmi < 30) return (label: 'Overweight', color: p.primary);
    if (bmi < 35) return (label: 'Obesity class I', color: p.down);
    if (bmi < 40) return (label: 'Obesity class II', color: p.down);
    return (label: 'Obesity class III', color: p.down);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final double bmi = _bmi;
    final ({String label, Color color}) category = _category(p, bmi);

    final double m = _heightCm / 100;
    final double healthyMin = 18.5 * m * m;
    final double healthyMax = 24.9 * m * m;

    return Scaffold(
      appBar: AppBar(title: const Text('BMI CALCULATOR')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Metric')),
              ButtonSegment<bool>(value: false, label: Text('Imperial')),
            ],
            selected: <bool>{_metric},
            onSelectionChanged: (Set<bool> value) =>
                setState(() => _metric = value.first),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FieldLabel('Height', width: 90),
                    const Spacer(),
                    Text(
                      _metric
                          ? '${_heightCm.toStringAsFixed(0)} cm'
                          : _feetInches(_heightCm),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _heightCm.clamp(100.0, 220.0),
                  min: 100,
                  max: 220,
                  divisions: 120,
                  onChanged: (double v) => setState(() => _heightCm = v),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const FieldLabel('Weight', width: 90),
                    const Spacer(),
                    Text(
                      _metric
                          ? '${_weightKg.toStringAsFixed(1)} kg'
                          : '${(_weightKg * 2.20462).toStringAsFixed(1)} lb',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _weightKg.clamp(25.0, 200.0),
                  min: 25,
                  max: 200,
                  divisions: 350,
                  onChanged: (double v) => setState(() => _weightKg = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: category.color.withOpacity(0.14),
            borderColor: category.color.withOpacity(0.6),
            child: Column(
              children: <Widget>[
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: category.color,
                  ),
                ),
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _scale(p, bmi),
                const SizedBox(height: 12),
                Text(
                  'Healthy range for your height: '
                  '${Fmt.smart(_metric ? healthyMin : healthyMin * 2.20462, maxDecimals: 1)}'
                  ' – '
                  '${Fmt.smart(_metric ? healthyMax : healthyMax * 2.20462, maxDecimals: 1)}'
                  ' ${_metric ? 'kg' : 'lb'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionLabel('Categories (WHO)'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <List<String>>[
                <String>['Under 18.5', 'Underweight'],
                <String>['18.5 – 24.9', 'Healthy weight'],
                <String>['25.0 – 29.9', 'Overweight'],
                <String>['30.0 – 34.9', 'Obesity class I'],
                <String>['35.0 – 39.9', 'Obesity class II'],
                <String>['40.0 and above', 'Obesity class III'],
              ].map((List<String> row) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: p.outline.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        child: Text(
                          row[0],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row[1],
                          style: TextStyle(
                              fontSize: 12, color: p.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 17, color: p.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'BMI is a rough screening tool. It does not distinguish '
                    'muscle from fat, and it reads differently for children, '
                    'athletes and older adults. Ask a clinician before acting '
                    'on it.',
                    style:
                        TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _feetInches(double cm) {
    final double inches = cm / 2.54;
    final int ft = inches ~/ 12;
    final double inch = inches - ft * 12;
    return "$ft' ${inch.toStringAsFixed(0)}\"";
  }

  Widget _scale(AppPalette p, double bmi) {
    final double ratio = ((bmi - 12) / (42 - 12)).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(
          height: 26,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: <Color>[
                        p.accent,
                        p.up,
                        p.primary,
                        p.down,
                      ],
                      stops: const <double>[0.0, 0.28, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (constraints.maxWidth - 12) * ratio,
                top: 2,
                child: Container(
                  width: 12,
                  height: 20,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: p.textPrimary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
