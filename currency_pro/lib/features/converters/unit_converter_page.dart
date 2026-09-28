import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/expression_parser.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/calc_keypad.dart';
import '../../core/widgets/section_card.dart';
import '../../state/settings_provider.dart';
import 'unit_models.dart';

/// Generic converter used for every measurement category.
///
/// The same screen serves length, weight, temperature, area, volume, speed,
/// data, pressure, energy and the rest — the category object supplies the
/// units and the conversion maths.
class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key, required this.category});

  final UnitCategory category;

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  late Unit _from;
  late Unit _to;
  String _input = '1';
  final ExpressionParser _parser = ExpressionParser();

  @override
  void initState() {
    super.initState();
    final List<Unit> units = widget.category.units;
    _from = units.first;
    _to = units.length > 1 ? units[1] : units.first;
  }

  double get _value => _parser.tryEvaluate(_input) ?? 0;

  double get _result => widget.category.convert(_value, _from, _to);

  void _feedback() {
    final SettingsProvider s = context.read<SettingsProvider>();
    Haptics.tap(vibrate: s.vibrate, sound: s.keySound);
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(
        text: '${Fmt.smart(_value)} ${_from.symbol} = '
            '${Fmt.smart(_result)} ${_to.symbol}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final UnitCategory category = widget.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name.toUpperCase()),
        actions: <Widget>[
          IconButton(
            tooltip: 'Swap units',
            icon: const Icon(Icons.swap_vert, size: 20),
            onPressed: () {
              _feedback();
              setState(() {
                final Unit old = _from;
                _from = _to;
                _to = old;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: SectionCard(
              child: Column(
                children: <Widget>[
                  _unitRow(
                    p,
                    unit: _from,
                    text: _input,
                    active: true,
                    onUnitChanged: (Unit u) => setState(() => _from = u),
                    onClear: () {
                      _feedback();
                      setState(() => _input = '0');
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(child: Divider(color: p.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.south, size: 16, color: p.primary),
                      ),
                      Expanded(child: Divider(color: p.outline)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _unitRow(
                    p,
                    unit: _to,
                    text: _result.isFinite ? Fmt.smart(_result) : '—',
                    active: false,
                    onUnitChanged: (Unit u) => setState(() => _to = u),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 13, color: p.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Base unit: ${category.baseUnitLabel} · '
                    '${category.units.length} units',
                    style:
                        TextStyle(fontSize: 10.5, color: p.textSecondary),
                  ),
                ),
                TextButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('COPY', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: CalcKeypad(
                showUtilityRow: false,
                multiLabel: '%',
                onDigit: (String v) {
                  _feedback();
                  setState(() {
                    if (_input == '0') {
                      _input = v == '00' || v == '000' ? '0' : v;
                    } else {
                      _input += v;
                    }
                  });
                },
                onOperator: (String symbol) {
                  _feedback();
                  setState(() {
                    final String last =
                        _input.isEmpty ? '' : _input[_input.length - 1];
                    if ('+-×÷−'.contains(last)) {
                      _input =
                          _input.substring(0, _input.length - 1) + symbol;
                    } else {
                      _input += symbol;
                    }
                  });
                },
                onEquals: () {
                  _feedback();
                  final double? v = _parser.tryEvaluate(_input);
                  if (v != null) {
                    setState(() =>
                        _input = Fmt.smart(v, maxDecimals: 8, grouping: false));
                  }
                },
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
                    if (!_input
                        .split(RegExp(r'[+\-×÷−]'))
                        .last
                        .contains('.')) {
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
                onPercent: () {
                  _feedback();
                  setState(() => _input += '%');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitRow(
    AppPalette p, {
    required Unit unit,
    required String text,
    required bool active,
    required ValueChanged<Unit> onUnitChanged,
    VoidCallback? onClear,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 150,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: unit.symbol,
              borderRadius: BorderRadius.circular(12),
              items: widget.category.units
                  .map(
                    (Unit u) => DropdownMenuItem<String>(
                      value: u.symbol,
                      child: Text(
                        u.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? symbol) {
                if (symbol == null) return;
                onUnitChanged(widget.category.unitBySymbol(symbol));
              },
            ),
          ),
        ),
        Expanded(
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
        AmountClearButton(
          visible: active && onClear != null && text != '0' && text.isNotEmpty,
          onClear: onClear ?? () {},
        ),
      ],
    );
  }
}
