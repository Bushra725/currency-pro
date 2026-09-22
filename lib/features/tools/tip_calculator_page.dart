import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../currency/currency_picker.dart';

/// Tip and bill splitting, with the total also shown in the home currency.
class TipCalculatorPage extends StatefulWidget {
  const TipCalculatorPage({super.key});

  @override
  State<TipCalculatorPage> createState() => _TipCalculatorPageState();
}

class _TipCalculatorPageState extends State<TipCalculatorPage> {
  final TextEditingController _bill = TextEditingController();
  int _people = 1;
  bool _roundUp = false;
  String _localCode = 'USD';

  @override
  void initState() {
    super.initState();
    _localCode = context.read<SettingsProvider>().toCode;
  }

  @override
  void dispose() {
    _bill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final double bill = Fmt.parse(_bill.text) ?? 0;
    final double tipPct = settings.tipPercent;
    double tip = bill * tipPct / 100;
    double total = bill + tip;
    if (_roundUp) {
      total = total.ceilToDouble();
      tip = total - bill;
    }
    final double perPerson = _people <= 0 ? total : total / _people;

    final Currency local = CurrencyLookup.of(_localCode);
    final Currency home = CurrencyLookup.of(settings.fromCode);
    final double? totalHome =
        rates.convert(total, local.code, home.code);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.tip),
      appBar: RateAppBar(title: 'Tip Calculator'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FieldLabel('Billing amount', width: 116),
                    Expanded(
                      child: TextField(
                        controller: _bill,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.right,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: 'Amount'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final Currency? picked = await CurrencyPicker.show(
                          context,
                          title: 'Bill currency',
                        );
                        if (picked != null) {
                          setState(() => _localCode = picked.code);
                        }
                      },
                      child: Row(
                        children: <Widget>[
                          Text(
                            local.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.primary,
                            ),
                          ),
                          Icon(Icons.expand_more,
                              size: 16, color: p.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const FieldLabel('Tip rate', width: 116),
                    Expanded(
                      child: Text(
                        '${tipPct.toStringAsFixed(0)} %',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: p.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tipPct.clamp(0.0, 30.0),
                  max: 30,
                  divisions: 60,
                  onChanged: (double v) => settings.setTipPercent(v),
                ),
                Wrap(
                  spacing: 8,
                  children: <double>[0, 5, 10, 12.5, 15, 18, 20, 25]
                      .map((double v) => ChoiceChip(
                            label: Text('${v % 1 == 0 ? v.toInt() : v}%'),
                            selected: tipPct == v,
                            showCheckmark: false,
                            onSelected: (_) => settings.setTipPercent(v),
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              color: tipPct == v
                                  ? p.onPrimary
                                  : p.textPrimary,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const FieldLabel('Split between', width: 116),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                      onPressed: _people > 1
                          ? () => setState(() => _people--)
                          : null,
                    ),
                    Text(
                      '$_people',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      onPressed: () => setState(() => _people++),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _roundUp,
                  onChanged: (bool v) => setState(() => _roundUp = v),
                  title: Text(
                    'Round the total up',
                    style: TextStyle(fontSize: 13, color: p.textPrimary),
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
                _row(p, 'Tip amount',
                    '${settings.format(tip)} ${local.code}'),
                const SizedBox(height: 8),
                _row(p, 'Total amount',
                    '${settings.format(total)} ${local.code}',
                    highlight: true),
                const SizedBox(height: 8),
                _row(p, 'Each person pays',
                    '${settings.format(perPerson)} ${local.code}'),
                if (totalHome != null && home.code != local.code) ...<Widget>[
                  Divider(height: 22, color: p.outline),
                  _row(
                    p,
                    'Total in ${home.code}',
                    '${settings.format(totalHome)} ${home.code}',
                    color: p.up,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    AppPalette p,
    String label,
    String value, {
    bool highlight = false,
    Color? color,
  }) {
    return Row(
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: highlight ? 20 : 14,
              fontWeight: FontWeight.w800,
              color: color ?? (highlight ? p.primary : p.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
