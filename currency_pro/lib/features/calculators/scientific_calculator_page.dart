import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/expression_parser.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/haptics.dart';
import '../../state/settings_provider.dart';

/// A full scientific calculator with history and degree/radian switching.
class ScientificCalculatorPage extends StatefulWidget {
  const ScientificCalculatorPage({super.key});

  @override
  State<ScientificCalculatorPage> createState() =>
      _ScientificCalculatorPageState();
}

class _ScientificCalculatorPageState extends State<ScientificCalculatorPage> {
  String _expression = '';
  String _result = '';
  bool _degrees = true;
  bool _secondary = false;
  double _memory = 0;
  final List<String> _history = <String>[];

  ExpressionParser get _parser => ExpressionParser(degrees: _degrees);

  void _feedback() {
    final SettingsProvider s = context.read<SettingsProvider>();
    Haptics.tap(vibrate: s.vibrate, sound: s.keySound);
  }

  void _append(String token) {
    _feedback();
    setState(() {
      _expression += token;
      _preview();
    });
  }

  void _preview() {
    final double? value = _parser.tryEvaluate(_expression);
    _result = value == null ? '' : Fmt.smart(value, maxDecimals: 10);
  }

  void _equals() {
    _feedback();
    if (_expression.trim().isEmpty) return;
    try {
      final double value = _parser.evaluate(_expression);
      final String text = Fmt.smart(value, maxDecimals: 10);
      setState(() {
        _history.insert(0, '$_expression = $text');
        if (_history.length > 30) _history.removeLast();
        _expression = text.replaceAll(',', '');
        _result = '';
      });
    } on ExpressionError catch (e) {
      setState(() => _result = e.message);
    } catch (_) {
      setState(() => _result = 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCIENTIFIC CALCULATOR'),
        actions: <Widget>[
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history, size: 20),
            onPressed: _showHistory,
          ),
          IconButton(
            tooltip: 'Copy result',
            icon: const Icon(Icons.copy, size: 19),
            onPressed: () async {
              final String text =
                  _result.isNotEmpty ? _result : _expression;
              if (text.isEmpty) return;
              await Clipboard.setData(ClipboardData(text: text));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(bottom: BorderSide(color: p.outline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _badge(p, _degrees ? 'DEG' : 'RAD'),
                    if (_memory != 0) ...<Widget>[
                      const SizedBox(width: 6),
                      _badge(p, 'M'),
                    ],
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _expression.isEmpty ? '0' : _expression,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _result,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _key(p, _secondary ? 'asin' : 'sin',
                            () => _append('${_secondary ? 'asin' : 'sin'}('),
                            small: true),
                        _key(p, _secondary ? 'acos' : 'cos',
                            () => _append('${_secondary ? 'acos' : 'cos'}('),
                            small: true),
                        _key(p, _secondary ? 'atan' : 'tan',
                            () => _append('${_secondary ? 'atan' : 'tan'}('),
                            small: true),
                        _key(p, _secondary ? 'eˣ' : 'ln',
                            () => _append(_secondary ? 'exp(' : 'ln('),
                            small: true),
                        _key(p, _secondary ? '10ˣ' : 'log',
                            () => _append(_secondary ? '10^' : 'log('),
                            small: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _key(p, '2nd', () {
                          _feedback();
                          setState(() => _secondary = !_secondary);
                        }, small: true, active: _secondary),
                        _key(p, _degrees ? 'DEG' : 'RAD', () {
                          _feedback();
                          setState(() {
                            _degrees = !_degrees;
                            _preview();
                          });
                        }, small: true),
                        _key(p, _secondary ? 'x³' : 'x²',
                            () => _append(_secondary ? '^3' : '^2'),
                            small: true),
                        _key(p, _secondary ? '∛' : '√',
                            () => _append(_secondary ? 'cbrt(' : 'sqrt('),
                            small: true),
                        _key(p, 'xʸ', () => _append('^'), small: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _key(p, 'π', () => _append('pi'), small: true),
                        _key(p, 'e', () => _append('e'), small: true),
                        _key(p, 'n!', () => _append('!'), small: true),
                        _key(p, '(', () => _append('('), small: true),
                        _key(p, ')', () => _append(')'), small: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _key(p, 'MC', () {
                          _feedback();
                          setState(() => _memory = 0);
                        }, small: true),
                        _key(p, 'MR', () => _append(
                            Fmt.smart(_memory, grouping: false)),
                            small: true),
                        _key(p, 'M+', () {
                          _feedback();
                          final double? v =
                              _parser.tryEvaluate(_expression);
                          if (v != null) setState(() => _memory += v);
                        }, small: true),
                        _key(p, 'M-', () {
                          _feedback();
                          final double? v =
                              _parser.tryEvaluate(_expression);
                          if (v != null) setState(() => _memory -= v);
                        }, small: true),
                        _key(p, '%', () => _append('%'), small: true),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '7', () => _append('7')),
                                    _key(p, '8', () => _append('8')),
                                    _key(p, '9', () => _append('9')),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '4', () => _append('4')),
                                    _key(p, '5', () => _append('5')),
                                    _key(p, '6', () => _append('6')),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '1', () => _append('1')),
                                    _key(p, '2', () => _append('2')),
                                    _key(p, '3', () => _append('3')),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '0', () => _append('0')),
                                    _key(p, '.', () => _append('.')),
                                    _key(p, '±', () {
                                      _feedback();
                                      setState(() {
                                        if (_expression.startsWith('-')) {
                                          _expression =
                                              _expression.substring(1);
                                        } else {
                                          _expression = '-$_expression';
                                        }
                                        _preview();
                                      });
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, 'C', () {
                                      _feedback();
                                      setState(() {
                                        _expression = '';
                                        _result = '';
                                      });
                                    }, color: p.equalsKey, textColor: Colors.white),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '÷', () => _append('÷'),
                                        accent: true),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '×', () => _append('×'),
                                        accent: true),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '−', () => _append('−'),
                                        accent: true),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '⌫', () {
                                      _feedback();
                                      setState(() {
                                        if (_expression.isNotEmpty) {
                                          _expression = _expression.substring(
                                              0, _expression.length - 1);
                                        }
                                        _preview();
                                      });
                                    }),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '+', () => _append('+'),
                                        accent: true),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: <Widget>[
                                    _key(p, '=', _equals,
                                        color: p.primary,
                                        textColor: p.onPrimary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(AppPalette p, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: p.primary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: p.primary,
          ),
        ),
      );

  Widget _key(
    AppPalette p,
    String label,
    VoidCallback onTap, {
    bool small = false,
    bool accent = false,
    bool active = false,
    Color? color,
    Color? textColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Material(
          color: color ??
              (active
                  ? p.primary.withOpacity(0.25)
                  : (small ? p.keyFaceAlt : p.keyFace)),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: small ? 13 : 21,
                  fontWeight: FontWeight.w600,
                  color: textColor ??
                      (accent ? p.primary : p.keyText),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        final AppPalette p = context.palette;
        if (_history.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'No calculations yet',
                style: TextStyle(color: p.textSecondary),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shrinkWrap: true,
          itemCount: _history.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: p.outline.withOpacity(0.5)),
          itemBuilder: (BuildContext context, int index) => ListTile(
            dense: true,
            title: Text(
              _history[index],
              style: TextStyle(fontSize: 13, color: p.textPrimary),
            ),
            onTap: () {
              final String entry = _history[index];
              final int eq = entry.lastIndexOf(' = ');
              setState(() {
                _expression =
                    eq < 0 ? entry : entry.substring(eq + 3).replaceAll(',', '');
                _preview();
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
