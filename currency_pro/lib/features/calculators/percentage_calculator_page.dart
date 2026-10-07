import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';

/// The six percentage questions people actually ask.
class PercentageCalculatorPage extends StatefulWidget {
  const PercentageCalculatorPage({super.key});

  @override
  State<PercentageCalculatorPage> createState() =>
      _PercentageCalculatorPageState();
}

class _PercentageCalculatorPageState extends State<PercentageCalculatorPage> {
  final TextEditingController _a1 = TextEditingController(text: '15');
  final TextEditingController _b1 = TextEditingController(text: '200');

  final TextEditingController _a2 = TextEditingController(text: '30');
  final TextEditingController _b2 = TextEditingController(text: '150');

  final TextEditingController _a3 = TextEditingController(text: '40');
  final TextEditingController _b3 = TextEditingController(text: '60');

  final TextEditingController _a4 = TextEditingController(text: '250');
  final TextEditingController _b4 = TextEditingController(text: '20');

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _a1, _b1, _a2, _b2, _a3, _b3, _a4, _b4,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _v(TextEditingController c) => Fmt.parse(c.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    final double r1 = _v(_a1) / 100 * _v(_b1);
    final double r2 = _v(_b2) == 0 ? 0 : _v(_a2) / _v(_b2) * 100;
    final double r3 =
        _v(_a3) == 0 ? 0 : (_v(_b3) - _v(_a3)) / _v(_a3) * 100;
    final double r4inc = _v(_a4) * (1 + _v(_b4) / 100);
    final double r4dec = _v(_a4) * (1 - _v(_b4) / 100);

    final L10n l10n = L10n.of(context);

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.percentageCalculator)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          _card(
            p,
            question: l10n.pctOfQuestion,
            fields: <Widget>[
              _field(p, _a1, 'X', suffix: '%'),
              _field(p, _b1, 'Y'),
            ],
            result: l10n.pctOfResult(
              '${_v(_a1)}',
              Fmt.smart(_v(_b1)),
              Fmt.smart(r1),
            ),
          ),
          _card(
            p,
            question: l10n.pctWhatQuestion,
            fields: <Widget>[
              _field(p, _a2, 'X'),
              _field(p, _b2, 'Y'),
            ],
            result: l10n.pctIsResult(
              Fmt.smart(_v(_a2)),
              Fmt.smart(r2, maxDecimals: 2),
              Fmt.smart(_v(_b2)),
            ),
          ),
          _card(
            p,
            question: l10n.pctChangeQuestion,
            fields: <Widget>[
              _field(p, _a3, l10n.fromLabel),
              _field(p, _b3, l10n.toLabel),
            ],
            result: l10n.changeOf(
              r3 >= 0 ? l10n.increase : l10n.decrease,
              Fmt.smart(r3.abs(), maxDecimals: 2),
            ),
            resultColor: r3 >= 0 ? p.up : p.down,
          ),
          _card(
            p,
            question: l10n.pctAdjustQuestion,
            fields: <Widget>[
              _field(p, _a4, 'X'),
              _field(p, _b4, 'Y', suffix: '%'),
            ],
            result: '↑ ${Fmt.smart(r4inc)}     ↓ ${Fmt.smart(r4dec)}',
          ),
          const SizedBox(height: 6),
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.lightbulb_outline, size: 18, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.pctReversalTip,
                    style:
                        TextStyle(fontSize: 11.5, color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    AppPalette p, {
    required String question,
    required List<Widget> fields,
    required String result,
    Color? resultColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              question,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: fields[0]),
                const SizedBox(width: 12),
                Expanded(child: fields[1]),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                result,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: resultColor ?? p.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    AppPalette p,
    TextEditingController controller,
    String label, {
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
    );
  }
}
