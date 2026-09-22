import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A single key face.
class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.child,
    required this.onTap,
    required this.color,
    this.onLongPress,
    this.flex = 1,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color color;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(10),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// The calculator keypad that sits under the currency fields, mirroring the
/// layout of the reference app (COPY / SEND / CLR / DEL, a 4×4 number grid
/// and a wide "multi currency" shortcut).
class CalcKeypad extends StatelessWidget {
  const CalcKeypad({
    super.key,
    required this.onDigit,
    required this.onOperator,
    required this.onEquals,
    required this.onClear,
    required this.onDelete,
    required this.onDecimal,
    required this.onSign,
    this.onCopy,
    this.onSend,
    this.onMulti,
    this.onPercent,
    this.multiLabel = 'MULTI\nCURRENCY\nCONVERTER',
    this.showUtilityRow = true,
  });

  final ValueChanged<String> onDigit;
  final ValueChanged<String> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback onDecimal;
  final VoidCallback onSign;
  final VoidCallback? onCopy;
  final VoidCallback? onSend;
  final VoidCallback? onMulti;
  final VoidCallback? onPercent;
  final String multiLabel;
  final bool showUtilityRow;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    TextStyle digitStyle() => TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: p.keyText,
        );

    TextStyle smallStyle(Color c) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: c,
        );

    Widget digit(String value, {int flex = 1, double fontSize = 22}) =>
        _KeyButton(
          flex: flex,
          color: p.keyFace,
          onTap: () => onDigit(value),
          child: Text(
            value,
            style: digitStyle().copyWith(fontSize: fontSize),
          ),
        );

    Widget op(String symbol) => _KeyButton(
          color: p.keyFaceAlt,
          onTap: () => onOperator(symbol),
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: p.primary,
            ),
          ),
        );

    return Column(
      children: <Widget>[
        if (showUtilityRow)
          Expanded(
            child: Row(
              children: <Widget>[
                _KeyButton(
                  color: p.keyFaceAlt,
                  onTap: onCopy ?? () {},
                  child: Text('COPY', style: smallStyle(p.keyText)),
                ),
                _KeyButton(
                  color: p.keyFaceAlt,
                  onTap: onSend ?? () {},
                  child: Text('SEND', style: smallStyle(p.keyText)),
                ),
                _KeyButton(
                  color: p.keyFaceAlt,
                  onTap: onClear,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.close, size: 14, color: p.down),
                      const SizedBox(width: 5),
                      Text('CLR', style: smallStyle(p.keyText)),
                    ],
                  ),
                ),
                _KeyButton(
                  color: p.keyFaceAlt,
                  onTap: onDelete,
                  onLongPress: onClear,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.backspace_outlined,
                          size: 14, color: p.primary),
                      const SizedBox(width: 5),
                      Text('DEL', style: smallStyle(p.keyText)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[digit('7'), digit('8'), digit('9'), op('÷')],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[digit('4'), digit('5'), digit('6'), op('×')],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[digit('1'), digit('2'), digit('3'), op('−')],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[
              digit('000', fontSize: 18),
              digit('00', fontSize: 18),
              digit('0'),
              op('+'),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Row(
            children: <Widget>[
              _KeyButton(
                color: p.keyFaceAlt,
                onTap: onMulti ?? onPercent ?? () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    onMulti != null ? multiLabel : '%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: onMulti != null ? 8.5 : 20,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: p.primary,
                    ),
                  ),
                ),
              ),
              _KeyButton(
                color: p.keyFace,
                onTap: onSign,
                child: Text('±', style: digitStyle()),
              ),
              _KeyButton(
                color: p.keyFace,
                onTap: onDecimal,
                child: Text('.', style: digitStyle()),
              ),
              _KeyButton(
                color: p.equalsKey,
                onTap: onEquals,
                child: const Text(
                  '=',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The four shortcut buttons above the keypad.
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        border: Border(
          top: BorderSide(color: p.outline),
          bottom: BorderSide(color: p.outline),
        ),
      ),
      child: Row(
        children: actions.map((QuickAction a) {
          return Expanded(
            child: InkWell(
              onTap: a.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(a.icon, size: 15, color: p.primary),
                  const SizedBox(height: 3),
                  Text(
                    a.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.5,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w700,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
