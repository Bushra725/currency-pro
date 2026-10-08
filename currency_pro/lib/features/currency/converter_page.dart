import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_palette.dart';
import '../../core/l10n/l10n.dart';
import '../../core/utils/expression_parser.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/calc_keypad.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import 'currency_picker.dart';

/// The home screen: two currencies, a live rate and the calculator keypad.
class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  /// Raw text of the field the user is typing into — may hold an expression
  /// such as `12+8*2` until `=` is pressed.
  String _input = '0';

  /// True when the top row is the one being edited.
  bool _editingTop = true;

  final ExpressionParser _parser = ExpressionParser(degrees: true);

  double get _typedValue => _parser.tryEvaluate(_input) ?? 0;

  SettingsProvider get _settings => context.read<SettingsProvider>();

  // -- key handling -------------------------------------------------------

  void _feedback() {
    final SettingsProvider s = _settings;
    Haptics.tap(vibrate: s.vibrate, sound: s.keySound);
  }

  void _appendDigit(String value) {
    _feedback();
    setState(() {
      if (_input == '0' && value != '.') {
        _input = value == '00' || value == '000' ? '0' : value;
      } else {
        _input += value;
      }
    });
  }

  void _appendOperator(String symbol) {
    _feedback();
    setState(() {
      final String last = _input.isEmpty ? '' : _input[_input.length - 1];
      if ('+-×÷−'.contains(last)) {
        _input = _input.substring(0, _input.length - 1) + symbol;
      } else {
        _input += symbol;
      }
    });
  }

  void _decimal() {
    _feedback();
    setState(() {
      final int lastOp = _input.lastIndexOf(RegExp(r'[+\-×÷−]'));
      final String tail = _input.substring(lastOp + 1);
      if (!tail.contains('.')) _input += tail.isEmpty ? '0.' : '.';
    });
  }

  void _sign() {
    _feedback();
    setState(() {
      if (_input.startsWith('-')) {
        _input = _input.substring(1);
      } else if (_input != '0') {
        _input = '-$_input';
      }
    });
  }

  void _delete() {
    _feedback();
    setState(() {
      _input = _input.length <= 1 ? '0' : _input.substring(0, _input.length - 1);
      if (_input.isEmpty) _input = '0';
    });
  }

  void _clear() {
    _feedback();
    setState(() => _input = '0');
  }

  void _equals() {
    _feedback();
    final double? value = _parser.tryEvaluate(_input);
    setState(() {
      _input = value == null
          ? _input
          : Fmt.smart(value, maxDecimals: 8, grouping: false);
    });
  }

  // -- actions ------------------------------------------------------------

  String _shareText() {
    final SettingsProvider s = _settings;
    final RatesProvider rates = context.read<RatesProvider>();
    final double value = _typedValue;
    final double? other = _editingTop
        ? rates.convert(value, s.fromCode, s.toCode)
        : rates.convert(value, s.toCode, s.fromCode);

    final String a =
        '${s.format(value)} ${_editingTop ? s.fromCode : s.toCode}';
    final String b = other == null
        ? '—'
        : '${s.format(other)} ${_editingTop ? s.toCode : s.fromCode}';
    final L10n l10n = L10n.read(context);
    return '$a = $b\n(${l10n.shareRateLine(rates.provider, Fmt.dateTime(rates.updatedAt))})';
  }

  Future<void> _copy() async {
    _feedback();
    await Clipboard.setData(ClipboardData(text: _shareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.read(context).conversionCopied)),
    );
  }

  Future<void> _send() async {
    _feedback();
    await Share.share(
      _shareText(),
      subject: L10n.read(context).currencyConversion,
    );
  }

  Future<void> _pick({required bool top}) async {
    final SettingsProvider s = _settings;
    final L10n l10n = L10n.of(context);
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: top ? l10n.convertFrom : l10n.convertTo,
    );
    if (picked == null) return;
    if (top) {
      await s.setPair(from: picked.code);
    } else {
      await s.setPair(to: picked.code);
    }
  }

  // -- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final Currency from = CurrencyLookup.of(settings.fromCode);
    final Currency to = CurrencyLookup.of(settings.toCode);

    final double typed = _typedValue;
    final String topText;
    final String bottomText;

    if (_editingTop) {
      topText = _input;
      final double? converted =
          rates.convert(typed, from.code, to.code);
      bottomText = converted == null
          ? '—'
          : settings.format(converted, decimals: to.decimals);
    } else {
      bottomText = _input;
      final double? converted = rates.convert(typed, to.code, from.code);
      topText = converted == null
          ? '—'
          : settings.format(converted, decimals: from.decimals);
    }

    final double? unitRate = rates.pairRate(from.code, to.code);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.home),
      appBar: RateAppBar(
        title: l10n.realTimeCurrency,
        actions: <Widget>[
          IconButton(
            tooltip: l10n.multiCurrency,
            icon: const Icon(Icons.grid_view_rounded, size: 20),
            onPressed: () => Navigator.of(context).pushNamed(Routes.multi),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (String value) =>
                Navigator.of(context).pushNamed(value),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: Routes.rateList,
                child: Text(l10n.rateList),
              ),
              PopupMenuItem<String>(
                value: Routes.charts,
                child: Text(l10n.trendCharts),
              ),
              PopupMenuItem<String>(
                value: Routes.assets,
                child: Text(l10n.metalCrypto),
              ),
              PopupMenuItem<String>(
                value: Routes.settings,
                child: Text(l10n.appSettings),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          _pairPanel(
            p,
            settings,
            from,
            to,
            topText,
            bottomText,
            unitRate,
            l10n,
          ),
          QuickActionBar(
            actions: <QuickAction>[
              QuickAction(
                icon: Icons.update,
                label: l10n.exchangeUpdate,
                color: const Color(0xFF2F80ED),
                onTap: () => rates.refresh(),
              ),
              QuickAction(
                icon: Icons.bar_chart,
                label: l10n.exchangeChart,
                color: const Color(0xFF9B51E0),
                onTap: () => Navigator.of(context).pushNamed(Routes.charts),
              ),
              QuickAction(
                icon: Icons.star_border,
                label: l10n.favorites,
                color: const Color(0xFFF2C94C),
                onTap: _openFavorites,
              ),
              QuickAction(
                icon: Icons.swap_vert,
                label: l10n.currencySwitch,
                color: const Color(0xFF27AE60),
                onTap: () {
                  _feedback();
                  settings.swapPair();
                },
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: CalcKeypad(
                onDigit: _appendDigit,
                onOperator: _appendOperator,
                onEquals: _equals,
                onClear: _clear,
                onDelete: _delete,
                onDecimal: _decimal,
                onSign: _sign,
                onCopy: _copy,
                onSend: _send,
                onMulti: () => Navigator.of(context).pushNamed(Routes.multi),
                multiLabel: l10n.multiCurrencyConverter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairPanel(
    AppPalette p,
    SettingsProvider settings,
    Currency from,
    Currency to,
    String topText,
    String bottomText,
    double? unitRate,
    L10n l10n,
  ) {
    // A borderless hero panel. The rule that used to close it off at the
    // bottom is gone — the gradient simply fades into the page.
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            p.primary.withOpacity(p.isDark ? 0.16 : 0.12),
            p.accent.withOpacity(p.isDark ? 0.07 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: p.surface.withOpacity(p.isDark ? 0.55 : 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.bolt, size: 12, color: p.primary),
                    const SizedBox(width: 5),
                    Text(
                      unitRate == null
                          ? l10n.rateUnavailable
                          : '1 ${from.code} = ${Fmt.smart(unitRate, maxDecimals: 6)} ${to.code}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                settings.palette.city,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: p.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _currencyRow(
            p,
            currency: from,
            text: topText,
            active: _editingTop,
            onTapAmount: () => setState(() {
              _editingTop = true;
              _input = '0';
            }),
            onTapCurrency: () => _pick(top: true),
            onClear: _editingTop ? _clear : null,
          ),
          const SizedBox(height: 8),
          _currencyRow(
            p,
            currency: to,
            text: bottomText,
            active: !_editingTop,
            onTapAmount: () => setState(() {
              _editingTop = false;
              _input = '0';
            }),
            onTapCurrency: () => _pick(top: false),
            onClear: !_editingTop ? _clear : null,
          ),
        ],
      ),
    );
  }

  Widget _currencyRow(
    AppPalette p, {
    required Currency currency,
    required String text,
    required bool active,
    required VoidCallback onTapAmount,
    required VoidCallback onTapCurrency,
    VoidCallback? onClear,
  }) {
    // Fill and a soft glow mark the active field — no outline required.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? p.surfaceHigh : p.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: p.primary.withOpacity(p.isDark ? 0.22 : 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const <BoxShadow>[],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onTapCurrency,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FlagAvatar(currency, size: 24),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          currency.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: p.textPrimary,
                          ),
                        ),
                        Text(
                          currency.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.expand_more, size: 18, color: p.textSecondary),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapAmount,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: active ? p.primary : p.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AmountClearButton(
            visible: active && onClear != null && text != '0' && text.isNotEmpty,
            onClear: onClear ?? () {},
          ),
        ],
      ),
    );
  }

  Future<void> _openFavorites() async {
    _feedback();
    final SettingsProvider settings = _settings;
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: L10n.of(context).favoritesTap,
      initialTab: CurrencyPickerTab.favorites,
    );
    if (picked != null) await settings.setPair(to: picked.code);
  }
}
