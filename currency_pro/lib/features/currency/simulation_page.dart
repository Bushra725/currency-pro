import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import 'currency_picker.dart';

/// "What if the rate moved by X%?" — a simulator for planning transfers.
class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  final TextEditingController _amount = TextEditingController(text: '1000');
  double _shiftPercent = 0;
  String _from = 'USD';
  String _to = 'EUR';

  @override
  void initState() {
    super.initState();
    final SettingsProvider s = context.read<SettingsProvider>();
    _from = s.fromCode;
    _to = s.toCode;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final double amount = Fmt.parse(_amount.text) ?? 0;
    final double? liveRate = rates.pairRate(_from, _to);
    final double? simulatedRate =
        liveRate == null ? null : liveRate * (1 + _shiftPercent / 100);

    final double? liveValue = liveRate == null ? null : amount * liveRate;
    final double? simulatedValue =
        simulatedRate == null ? null : amount * simulatedRate;
    final double? difference = (liveValue == null || simulatedValue == null)
        ? null
        : simulatedValue - liveValue;

    return Scaffold(
      drawer: const AppDrawer(current: Routes.simulation),
      appBar: RateAppBar(title: 'Currency Simulation'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _picker(p, _from, isFrom: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: Icon(Icons.swap_horiz, color: p.primary),
                  onPressed: () => setState(() {
                    final String old = _from;
                    _from = _to;
                    _to = old;
                  }),
                ),
              ),
              Expanded(child: _picker(p, _to, isFrom: false)),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: <Widget>[
                const FieldLabel('Amount', width: 84),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _from,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FieldLabel('Rate change', width: 104),
                    const Spacer(),
                    Text(
                      Fmt.percent(_shiftPercent, decimals: 2),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _shiftPercent >= 0 ? p.up : p.down,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _shiftPercent,
                  min: -25,
                  max: 25,
                  divisions: 200,
                  onChanged: (double v) => setState(() => _shiftPercent = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('-25%',
                        style: TextStyle(
                            fontSize: 11, color: p.textSecondary)),
                    TextButton(
                      onPressed: () => setState(() => _shiftPercent = 0),
                      child: const Text('RESET'),
                    ),
                    Text('+25%',
                        style: TextStyle(
                            fontSize: 11, color: p.textSecondary)),
                  ],
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
                _resultRow(p, 'Live rate',
                    liveRate == null ? '—' : Fmt.smart(liveRate, maxDecimals: 6)),
                const SizedBox(height: 8),
                _resultRow(
                  p,
                  'Simulated rate',
                  simulatedRate == null
                      ? '—'
                      : Fmt.smart(simulatedRate, maxDecimals: 6),
                  highlight: true,
                ),
                Divider(height: 22, color: p.outline),
                _resultRow(
                  p,
                  'You get now',
                  liveValue == null
                      ? '—'
                      : '${settings.format(liveValue)} $_to',
                ),
                const SizedBox(height: 8),
                _resultRow(
                  p,
                  'You would get',
                  simulatedValue == null
                      ? '—'
                      : '${settings.format(simulatedValue)} $_to',
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _resultRow(
                  p,
                  'Difference',
                  difference == null
                      ? '—'
                      : '${difference >= 0 ? '+' : ''}'
                          '${settings.format(difference)} $_to',
                  color: difference == null
                      ? null
                      : (difference >= 0 ? p.up : p.down),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionLabel('Scenario table'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <double>[-10, -5, -2, -1, 1, 2, 5, 10].map((double pct) {
                final double? rate =
                    liveRate == null ? null : liveRate * (1 + pct / 100);
                final double? value = rate == null ? null : amount * rate;
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
                        width: 58,
                        child: Text(
                          Fmt.percent(pct, decimals: 0),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: pct >= 0 ? p.up : p.down,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rate == null
                              ? '—'
                              : Fmt.smart(rate, maxDecimals: 6),
                          style: TextStyle(
                              fontSize: 12, color: p.textSecondary),
                        ),
                      ),
                      Text(
                        value == null
                            ? '—'
                            : '${settings.format(value)} $_to',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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

  Widget _resultRow(
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
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 17 : 14,
            fontWeight: FontWeight.w800,
            color: color ?? (highlight ? p.primary : p.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _picker(AppPalette p, String code, {required bool isFrom}) {
    final Currency c = CurrencyLookup.of(code);
    return InkWell(
      onTap: () async {
        final Currency? picked = await CurrencyPicker.show(context);
        if (picked == null) return;
        setState(() {
          if (isFrom) {
            _from = picked.code;
          } else {
            _to = picked.code;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            FlagAvatar(c, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
