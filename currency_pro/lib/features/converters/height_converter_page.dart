import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';

/// Feet + inches ↔ centimetres, the way people actually quote height.
class HeightConverterPage extends StatefulWidget {
  const HeightConverterPage({super.key});

  @override
  State<HeightConverterPage> createState() => _HeightConverterPageState();
}

class _HeightConverterPageState extends State<HeightConverterPage> {
  final TextEditingController _feet = TextEditingController(text: '5');
  final TextEditingController _inches = TextEditingController(text: '9');
  final TextEditingController _cm = TextEditingController(text: '175.3');

  bool _updating = false;

  @override
  void dispose() {
    _feet.dispose();
    _inches.dispose();
    _cm.dispose();
    super.dispose();
  }

  void _fromImperial() {
    if (_updating) return;
    _updating = true;
    final double feet = Fmt.parse(_feet.text) ?? 0;
    final double inches = Fmt.parse(_inches.text) ?? 0;
    final double cm = (feet * 12 + inches) * 2.54;
    _cm.text = cm.toStringAsFixed(1);
    _updating = false;
    setState(() {});
  }

  void _fromMetric() {
    if (_updating) return;
    _updating = true;
    final double cm = Fmt.parse(_cm.text) ?? 0;
    final double totalInches = cm / 2.54;
    final int feet = totalInches ~/ 12;
    final double inches = totalInches - feet * 12;
    _feet.text = '$feet';
    _inches.text = inches.toStringAsFixed(1);
    _updating = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final double cm = Fmt.parse(_cm.text) ?? 0;

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.heightConverter)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FieldLabel(l10n.feetInches, width: 160),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _feet,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _fromImperial(),
                        decoration: InputDecoration(
                          labelText: l10n.feet,
                          suffixText: 'ft',
                          suffixIcon: IconButton(
                            tooltip: l10n.clearTooltip,
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            onPressed: () {
                              _feet.text = '0';
                              _fromImperial();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _inches,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => _fromImperial(),
                        decoration: InputDecoration(
                          labelText: l10n.inchesLabel,
                          suffixText: 'in',
                          suffixIcon: IconButton(
                            tooltip: l10n.clearTooltip,
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            onPressed: () {
                              _inches.text = '0';
                              _fromImperial();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FieldLabel(l10n.metric, width: 160),
                const SizedBox(height: 10),
                TextField(
                  controller: _cm,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _fromMetric(),
                  decoration: InputDecoration(
                    labelText: l10n.centimetres,
                    suffixText: 'cm',
                    suffixIcon: IconButton(
                      tooltip: l10n.clearTooltip,
                      icon: const Icon(Icons.cancel_rounded, size: 18),
                      onPressed: () {
                        _cm.text = '0';
                        _fromMetric();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: p.primary.withOpacity(0.12),
            borderColor: p.primary.withOpacity(0.5),
            child: Column(
              children: <Widget>[
                _row(p, l10n.metres, '${Fmt.smart(cm / 100, maxDecimals: 3)} m'),
                const SizedBox(height: 8),
                _row(p, l10n.millimetres, '${Fmt.smart(cm * 10)} mm'),
                const SizedBox(height: 8),
                _row(p, l10n.totalInches,
                    '${Fmt.smart(cm / 2.54, maxDecimals: 2)} in'),
                const SizedBox(height: 8),
                _row(p, l10n.handsHorses,
                    '${Fmt.smart(cm / 10.16, maxDecimals: 2)} hh'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionLabel(l10n.quickReference),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <int>[150, 155, 160, 165, 170, 175, 180, 185, 190, 195]
                  .map((int value) {
                final double inches = value / 2.54;
                final int ft = inches ~/ 12;
                final double inch = inches - ft * 12;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: p.outline.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Text('$value cm',
                          style: TextStyle(
                              fontSize: 12.5, color: p.textSecondary)),
                      const Spacer(),
                      Text(
                        "$ft' ${inch.toStringAsFixed(1)}\"",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppPalette p, String label, String value) {
    return Row(
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
      ],
    );
  }
}
