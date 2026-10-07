import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../currency/currency_picker.dart';

/// Sale price, savings, stacked discounts and tax — with the final price
/// also shown in a second currency.
class DiscountCalculatorPage extends StatefulWidget {
  const DiscountCalculatorPage({super.key});

  @override
  State<DiscountCalculatorPage> createState() =>
      _DiscountCalculatorPageState();
}

class _DiscountCalculatorPageState extends State<DiscountCalculatorPage> {
  final TextEditingController _price = TextEditingController(text: '100');
  double _discount = 20;
  double _secondDiscount = 0;
  double _tax = 0;
  String _code = 'USD';

  @override
  void initState() {
    super.initState();
    _code = context.read<SettingsProvider>().toCode;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final double price = Fmt.parse(_price.text) ?? 0;
    final double afterFirst = price * (1 - _discount / 100);
    final double afterSecond = afterFirst * (1 - _secondDiscount / 100);
    final double tax = afterSecond * _tax / 100;
    final double finalPrice = afterSecond + tax;
    final double saved = price - afterSecond;
    final double effective = price == 0 ? 0 : saved / price * 100;

    final Currency local = CurrencyLookup.of(_code);
    final Currency home = CurrencyLookup.of(settings.fromCode);
    final double? homeValue =
        rates.convert(finalPrice, local.code, home.code);

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.discountCalculator)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Row(
              children: <Widget>[
                FieldLabel(l10n.originalPrice, width: 116),
                Expanded(
                  child: TextField(
                    controller: _price,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    final Currency? picked =
                        await CurrencyPicker.show(context);
                    if (picked != null) {
                      setState(() => _code = picked.code);
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
          ),
          const SizedBox(height: 12),
          _sliderCard(p, l10n.discount, _discount, 90,
              (double v) => setState(() => _discount = v),
              presets: const <double>[5, 10, 15, 20, 25, 30, 40, 50, 70]),
          const SizedBox(height: 12),
          _sliderCard(p, l10n.extraDiscount, _secondDiscount, 90,
              (double v) => setState(() => _secondDiscount = v),
              hint: l10n.stackedOnPrice),
          const SizedBox(height: 12),
          _sliderCard(p, l10n.taxVat, _tax, 30,
              (double v) => setState(() => _tax = v),
              presets: const <double>[0, 5, 7.5, 10, 15, 17, 20]),
          const SizedBox(height: 12),
          SectionCard(
            color: p.primary.withOpacity(0.12),
            borderColor: p.primary.withOpacity(0.5),
            child: Column(
              children: <Widget>[
                Text(
                  l10n.youPay,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settings.format(finalPrice)} ${local.code}',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
                if (homeValue != null && home.code != local.code)
                  Text(
                    '≈ ${settings.format(homeValue)} ${home.code}',
                    style:
                        TextStyle(fontSize: 12, color: p.textSecondary),
                  ),
                Divider(height: 22, color: p.outline),
                _row(p, l10n.priceAfterDiscount,
                    '${settings.format(afterSecond)} ${local.code}'),
                const SizedBox(height: 8),
                _row(p, l10n.youSave,
                    '${settings.format(saved)} ${local.code}',
                    color: p.up),
                const SizedBox(height: 8),
                _row(p, l10n.effectiveDiscount,
                    '${effective.toStringAsFixed(1)} %'),
                if (_tax > 0) ...<Widget>[
                  const SizedBox(height: 8),
                  _row(p, l10n.taxAdded,
                      '${settings.format(tax)} ${local.code}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionLabel(l10n.commonDiscounts),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <double>[10, 20, 25, 30, 40, 50, 60, 70, 75, 80]
                  .map((double pct) {
                final double value = price * (1 - pct / 100);
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
                        width: 56,
                        child: Text(
                          '-${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: p.down,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.saveAmount(settings.format(price - value)),
                          style: TextStyle(
                              fontSize: 11.5, color: p.textSecondary),
                        ),
                      ),
                      Text(
                        '${settings.format(value)} ${local.code}',
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

  Widget _sliderCard(
    AppPalette p,
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged, {
    List<double>? presets,
    String? hint,
  }) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              FieldLabel(label, width: 116),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} %',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: p.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0.0, max),
            max: max,
            divisions: (max * 2).round(),
            onChanged: onChanged,
          ),
          if (presets != null)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: presets
                  .map((double v) => ChoiceChip(
                        label: Text('${v % 1 == 0 ? v.toInt() : v}%'),
                        selected: value == v,
                        showCheckmark: false,
                        onSelected: (_) => onChanged(v),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color:
                              value == v ? p.onPrimary : p.textPrimary,
                        ),
                      ))
                  .toList(),
            ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hint,
                style: TextStyle(fontSize: 10.5, color: p.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(AppPalette p, String label, String value, {Color? color}) {
    return Row(
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color ?? p.textPrimary,
          ),
        ),
      ],
    );
  }
}
