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
import 'currency_picker.dart';

/// Applies a bank spread and a fixed transfer fee to the mid-market rate so
/// the number on screen matches what a bank or remittance app will actually
/// pay out.
class RateAdjustmentPage extends StatefulWidget {
  const RateAdjustmentPage({super.key});

  @override
  State<RateAdjustmentPage> createState() => _RateAdjustmentPageState();
}

class _RateAdjustmentPageState extends State<RateAdjustmentPage> {
  final TextEditingController _amount = TextEditingController(text: '1000');
  final TextEditingController _fixedFee = TextEditingController(text: '0');
  String _from = 'USD';
  String _to = 'PKR';

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
    _fixedFee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final double amount = Fmt.parse(_amount.text) ?? 0;
    final double fixedFee = Fmt.parse(_fixedFee.text) ?? 0;
    final double spread = settings.bankFeePercent;

    final double? mid = rates.pairRate(_from, _to);
    final double? effective = mid == null ? null : mid * (1 - spread / 100);
    final double netSource = (amount - fixedFee).clamp(0.0, double.infinity).toDouble();
    final double? payout = effective == null ? null : netSource * effective;
    final double? midPayout = mid == null ? null : amount * mid;
    final double? cost = (payout == null || midPayout == null)
        ? null
        : midPayout - payout;

    return Scaffold(
      drawer: const AppDrawer(current: Routes.adjustment),
      appBar: RateAppBar(title: 'Exchange Rate Adjustment'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              children: <Widget>[
                _pairRow(p),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const FieldLabel('Send amount', width: 108),
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.right,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_from,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: p.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const FieldLabel('Fixed fee', width: 108),
                    Expanded(
                      child: TextField(
                        controller: _fixedFee,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.right,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_from,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: p.textSecondary)),
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
                Row(
                  children: <Widget>[
                    const FieldLabel('Bank spread', width: 108),
                    const Spacer(),
                    Text(
                      '${spread.toStringAsFixed(2)} %',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: spread.clamp(0.0, 10.0),
                  max: 10,
                  divisions: 200,
                  onChanged: (double v) => settings.setBankFeePercent(v),
                ),
                Text(
                  'Most banks quote 1.5 – 4 % below the mid-market rate. '
                  'Money-transfer apps are usually 0.3 – 1 %.',
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
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
                _row(p, 'Mid-market rate',
                    mid == null ? '—' : Fmt.smart(mid, maxDecimals: 6)),
                const SizedBox(height: 8),
                _row(
                  p,
                  'Adjusted rate',
                  effective == null
                      ? '—'
                      : Fmt.smart(effective, maxDecimals: 6),
                  highlight: true,
                ),
                Divider(height: 22, color: p.outline),
                _row(p, 'Amount converted',
                    '${settings.format(netSource)} $_from'),
                const SizedBox(height: 8),
                _row(
                  p,
                  'Recipient gets',
                  payout == null ? '—' : '${settings.format(payout)} $_to',
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _row(
                  p,
                  'Total cost of transfer',
                  cost == null ? '—' : '${settings.format(cost)} $_to',
                  color: p.down,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionLabel('Compare providers'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <List<dynamic>>[
                <dynamic>['Mid-market (no fee)', 0.0, 0.0],
                <dynamic>['Transfer app', 0.6, 2.0],
                <dynamic>['Online bank', 2.0, 5.0],
                <dynamic>['Branch / counter', 3.5, 10.0],
                <dynamic>['Airport kiosk', 8.0, 0.0],
              ].map((List<dynamic> row) {
                final String label = row[0] as String;
                final double pct = row[1] as double;
                final double fee = row[2] as double;
                final double? rate = mid == null ? null : mid * (1 - pct / 100);
                final double net =
                    (amount - fee).clamp(0.0, double.infinity).toDouble();
                final double? out = rate == null ? null : net * rate;

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
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: p.textPrimary,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(1)}% spread'
                              '${fee > 0 ? ' + ${fee.toStringAsFixed(0)} $_from' : ''}',
                              style: TextStyle(
                                  fontSize: 10.5, color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          out == null ? '—' : settings.format(out),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: pct == 0 ? p.up : p.textPrimary,
                          ),
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

  Widget _pairRow(AppPalette p) {
    Widget button(String code, bool isFrom) {
      final Currency c = CurrencyLookup.of(code);
      return Expanded(
        child: InkWell(
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
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${c.flag} ${c.code}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        button(_from, true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.east, size: 18, color: p.primary),
        ),
        button(_to, false),
      ],
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
              fontSize: highlight ? 17 : 13.5,
              fontWeight: FontWeight.w800,
              color: color ?? (highlight ? p.primary : p.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
