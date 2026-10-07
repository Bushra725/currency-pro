import '../../core/widgets/screen_title.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../state/settings_provider.dart';
import '../currency/currency_picker.dart';

/// Loan / EMI calculator with an amortisation preview.
class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final TextEditingController _amount =
      TextEditingController(text: '250000');
  double _ratePercent = 8.5;
  int _months = 60;
  String _code = 'USD';

  @override
  void initState() {
    super.initState();
    _code = context.read<SettingsProvider>().fromCode;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Standard annuity formula: P·r·(1+r)^n / ((1+r)^n − 1).
  double get _emi {
    final double principal = Fmt.parse(_amount.text) ?? 0;
    final double r = _ratePercent / 100 / 12;
    if (principal <= 0 || _months <= 0) return 0;
    if (r == 0) return principal / _months;
    final double factor = math.pow(1 + r, _months).toDouble();
    return principal * r * factor / (factor - 1);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final Currency currency = CurrencyLookup.of(_code);

    final double principal = Fmt.parse(_amount.text) ?? 0;
    final double emi = _emi;
    final double totalPaid = emi * _months;
    final double interest = totalPaid - principal;
    final double interestShare =
        totalPaid <= 0 ? 0 : interest / totalPaid * 100;

    return Scaffold(
      appBar: AppBar(title: ScreenTitle(l10n.loanCalculator)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    FieldLabel(l10n.loanAmount, width: 112),
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                            currency.code,
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
                    FieldLabel(l10n.interestYear, width: 112),
                    const Spacer(),
                    Text(
                      '${_ratePercent.toStringAsFixed(2)} %',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _ratePercent.clamp(0.0, 36.0),
                  max: 36,
                  divisions: 360,
                  onChanged: (double v) => setState(() => _ratePercent = v),
                ),
                Row(
                  children: <Widget>[
                    FieldLabel(l10n.term, width: 112),
                    const Spacer(),
                    Text(
                      _months % 12 == 0
                          ? l10n.termYears('${_months ~/ 12}')
                          : l10n.termMonths('$_months'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _months.toDouble().clamp(6.0, 360.0),
                  min: 6,
                  max: 360,
                  divisions: 118,
                  onChanged: (double v) =>
                      setState(() => _months = v.round()),
                ),
                Wrap(
                  spacing: 6,
                  children: <int>[12, 24, 36, 60, 120, 180, 240, 360]
                      .map((int m) => ChoiceChip(
                            label: Text(l10n.termYearsChip('${m ~/ 12}')),
                            selected: _months == m,
                            showCheckmark: false,
                            onSelected: (_) =>
                                setState(() => _months = m),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: _months == m
                                  ? p.onPrimary
                                  : p.textPrimary,
                            ),
                          ))
                      .toList(),
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
                Text(l10n.monthlyPayment,
                    style:
                        TextStyle(fontSize: 12, color: p.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '${settings.format(emi)} ${currency.code}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
                Divider(height: 22, color: p.outline),
                _row(p, l10n.principal,
                    '${settings.format(principal)} ${currency.code}'),
                const SizedBox(height: 8),
                _row(p, l10n.totalInterest,
                    '${settings.format(interest)} ${currency.code}',
                    color: p.down),
                const SizedBox(height: 8),
                _row(p, l10n.totalRepayment,
                    '${settings.format(totalPaid)} ${currency.code}'),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (interestShare / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: p.up.withOpacity(0.35),
                    color: p.down,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.interestShareOf(interestShare.toStringAsFixed(1)),
                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionLabel(l10n.yearlyBreakdown),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _schedule(p, l10n, settings, principal, emi),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _schedule(
    AppPalette p,
    L10n l10n,
    SettingsProvider settings,
    double principal,
    double emi,
  ) {
    final double r = _ratePercent / 100 / 12;
    double balance = principal;
    final List<Widget> rows = <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: p.surfaceAlt,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 42,
              child: Text(l10n.yearCol, style: _head(p)),
            ),
            Expanded(
              child: Text(l10n.interestCol,
                  textAlign: TextAlign.right, style: _head(p)),
            ),
            Expanded(
              child: Text(l10n.principal,
                  textAlign: TextAlign.right, style: _head(p)),
            ),
            Expanded(
              child: Text(l10n.balanceCol,
                  textAlign: TextAlign.right, style: _head(p)),
            ),
          ],
        ),
      ),
    ];

    final int years = (_months / 12).ceil();
    for (int year = 1; year <= years; year++) {
      double yearInterest = 0;
      double yearPrincipal = 0;
      for (int m = 0; m < 12; m++) {
        final int monthIndex = (year - 1) * 12 + m;
        if (monthIndex >= _months || balance <= 0) break;
        final double interest = balance * r;
        final double principalPart = (emi - interest).clamp(0.0, balance).toDouble();
        yearInterest += interest;
        yearPrincipal += principalPart;
        balance -= principalPart;
      }

      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: p.outline.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 42,
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  settings.format(yearInterest, decimals: 0),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11.5, color: p.down),
                ),
              ),
              Expanded(
                child: Text(
                  settings.format(yearPrincipal, decimals: 0),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11.5, color: p.up),
                ),
              ),
              Expanded(
                child: Text(
                  settings.format(
                      balance < 0 ? 0 : balance, decimals: 0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  TextStyle _head(AppPalette p) => TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: p.textSecondary,
      );

  Widget _row(AppPalette p, String label, String value, {Color? color}) {
    return Row(
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12.5, color: p.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color ?? p.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
