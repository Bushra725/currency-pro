import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
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

/// Convert one amount into 2, 4 or 8 currencies at once.
class MultiCurrencyPage extends StatefulWidget {
  const MultiCurrencyPage({super.key});

  @override
  State<MultiCurrencyPage> createState() => _MultiCurrencyPageState();
}

class _MultiCurrencyPageState extends State<MultiCurrencyPage> {
  String _input = '1';
  int _activeIndex = 0;
  final ExpressionParser _parser = ExpressionParser();

  double get _typed => _parser.tryEvaluate(_input) ?? 0;

  void _feedback() {
    final SettingsProvider s = context.read<SettingsProvider>();
    Haptics.tap(vibrate: s.vibrate, sound: s.keySound);
  }

  void _digit(String value) {
    _feedback();
    setState(() {
      if (_input == '0') {
        _input = value == '00' || value == '000' ? '0' : value;
      } else {
        _input += value;
      }
    });
  }

  void _operator(String symbol) {
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

  void _equals() {
    _feedback();
    final double? value = _parser.tryEvaluate(_input);
    if (value != null) {
      setState(() => _input = Fmt.smart(value, maxDecimals: 8, grouping: false));
    }
  }

  Future<void> _copyAll() async {
    final SettingsProvider settings = context.read<SettingsProvider>();
    final RatesProvider rates = context.read<RatesProvider>();
    final List<String> codes = settings.activeMultiSet;
    final String source = codes[_activeIndex];

    final StringBuffer buffer = StringBuffer()
      ..writeln('${settings.format(_typed)} $source =');
    for (int i = 0; i < codes.length; i++) {
      if (i == _activeIndex) continue;
      final double? value = rates.convert(_typed, source, codes[i]);
      buffer.writeln(
        '  ${value == null ? '—' : settings.format(value)} ${codes[i]}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All conversions copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final List<String> codes = settings.activeMultiSet;

    if (_activeIndex >= codes.length) _activeIndex = 0;
    final String source = codes[_activeIndex];

    return Scaffold(
      drawer: const AppDrawer(current: Routes.multi),
      appBar: RateAppBar(
        title: 'Multi Currency Converter',
        actions: <Widget>[
          PopupMenuButton<int>(
            tooltip: 'Number of currencies',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.filter_none, size: 17, color: p.textSecondary),
                const SizedBox(width: 3),
                Text(
                  '${settings.multiCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.primary,
                  ),
                ),
              ],
            ),
            onSelected: (int value) {
              settings.setMultiCount(value);
              setState(() => _activeIndex = 0);
            },
            itemBuilder: (_) => const <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: 2, child: Text('2 currencies')),
              PopupMenuItem<int>(value: 4, child: Text('4 currencies')),
              PopupMenuItem<int>(value: 8, child: Text('8 currencies')),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Expanded(
            flex: settings.multiCount > 4 ? 5 : 3,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: codes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final Currency c = CurrencyLookup.of(codes[index]);
                final bool active = index == _activeIndex;
                final double? value = active
                    ? _typed
                    : rates.convert(_typed, source, c.code);

                return _row(
                  p,
                  settings,
                  currency: c,
                  active: active,
                  text: active
                      ? _input
                      : (value == null
                          ? '—'
                          : settings.format(value, decimals: c.decimals)),
                  onTapAmount: () => setState(() {
                    _activeIndex = index;
                    _input = '1';
                  }),
                  onClear: active
                      ? () {
                          _feedback();
                          setState(() => _input = '0');
                        }
                      : null,
                  onTapCurrency: () async {
                    final Currency? picked = await CurrencyPicker.show(
                      context,
                      title: 'Replace ${c.code}',
                    );
                    if (picked == null) return;
                    final int realIndex =
                        settings.multiSet.indexOf(codes[index]);
                    await settings.setMultiAt(
                      realIndex < 0 ? index : realIndex,
                      picked.code,
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: CalcKeypad(
                onDigit: _digit,
                onOperator: _operator,
                onEquals: _equals,
                onClear: () {
                  _feedback();
                  setState(() => _input = '0');
                },
                onDelete: () {
                  _feedback();
                  setState(() {
                    _input = _input.length <= 1
                        ? '0'
                        : _input.substring(0, _input.length - 1);
                  });
                },
                onDecimal: () {
                  _feedback();
                  setState(() {
                    if (!_input.split(RegExp(r'[+\-×÷−]')).last.contains('.')) {
                      _input += '.';
                    }
                  });
                },
                onSign: () {
                  _feedback();
                  setState(() {
                    _input = _input.startsWith('-')
                        ? _input.substring(1)
                        : '-$_input';
                  });
                },
                onCopy: _copyAll,
                onPercent: () {
                  _feedback();
                  setState(() => _input += '%');
                },
                multiLabel: '%',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    AppPalette p,
    SettingsProvider settings, {
    required Currency currency,
    required bool active,
    required String text,
    required VoidCallback onTapAmount,
    required VoidCallback onTapCurrency,
    VoidCallback? onClear,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? p.primaryWash : p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: p.primary.withOpacity(p.isDark ? 0.20 : 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : p.keyShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onTapCurrency,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FlagAvatar(currency, size: 22),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        currency.code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        currency.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 10, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more, size: 16, color: p.textSecondary),
              ],
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapAmount,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    text,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 20,
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
}
