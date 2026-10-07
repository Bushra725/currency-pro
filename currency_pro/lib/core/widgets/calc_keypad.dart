import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../l10n/l10n.dart';

/// A single key face.
///
/// Keys are soft, shadowed tiles rather than flat rectangles, which gives the
/// keypad depth without drawing a single outline.
class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.child,
    required this.onTap,
    required this.color,
    required this.shadow,
    this.onLongPress,
    this.flex = 1,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color color;
  final List<BoxShadow> shadow;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: shadow,
          ),
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Center(child: child),
            ),
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
    this.multiLabel,
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
  final String? multiLabel;
  final bool showUtilityRow;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final List<BoxShadow> shadow = p.keyShadow;
    final String multiText = multiLabel ?? l10n.multiCurrencyConverter;

    TextStyle digitStyle() => TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: p.keyText,
        );

    TextStyle smallStyle(Color c) => TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: c,
        );

    Widget digit(String value, {int flex = 1, double fontSize = 23}) =>
        _KeyButton(
          flex: flex,
          color: p.keyFace,
          shadow: shadow,
          onTap: () => onDigit(value),
          child: Text(
            value,
            style: digitStyle().copyWith(fontSize: fontSize),
          ),
        );

    Widget op(String symbol) => _KeyButton(
          color: p.keyFaceAlt,
          shadow: shadow,
          onTap: () => onOperator(symbol),
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: p.primary,
            ),
          ),
        );

    Widget clrKey() => _KeyButton(
          color: p.keyFaceAlt,
          shadow: shadow,
          onTap: onClear,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.close_rounded, size: 14, color: p.down),
              const SizedBox(width: 5),
              Text(l10n.clr, style: smallStyle(p.keyText)),
            ],
          ),
        );

    Widget delKey() => _KeyButton(
          color: p.keyFaceAlt,
          shadow: shadow,
          onTap: onDelete,
          onLongPress: onClear,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.backspace_outlined, size: 14, color: p.primary),
              const SizedBox(width: 5),
              Text(l10n.del, style: smallStyle(p.keyText)),
            ],
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
                  shadow: shadow,
                  onTap: onCopy ?? () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.copy_rounded,
                          size: 13, color: const Color(0xFF2F80ED)),
                      const SizedBox(width: 5),
                      Text(l10n.copy, style: smallStyle(p.keyText)),
                    ],
                  ),
                ),
                _KeyButton(
                  color: p.keyFaceAlt,
                  shadow: shadow,
                  onTap: onSend ?? () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.share_rounded,
                          size: 13, color: const Color(0xFF27AE60)),
                      const SizedBox(width: 5),
                      Text(l10n.send, style: smallStyle(p.keyText)),
                    ],
                  ),
                ),
                clrKey(),
                delKey(),
              ],
            ),
          )
        else
          Expanded(
            child: Row(
              children: <Widget>[
                clrKey(),
                delKey(),
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
                color: p.primaryWash,
                shadow: shadow,
                onTap: onMulti ?? onPercent ?? () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: onMulti != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.grid_view_rounded,
                                size: 15, color: p.primary),
                            const SizedBox(height: 3),
                            Text(
                              multiText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 8,
                                height: 1.12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: p.primary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: p.primary,
                          ),
                        ),
                ),
              ),
              _KeyButton(
                color: p.keyFace,
                shadow: shadow,
                onTap: onSign,
                child: Text('±', style: digitStyle()),
              ),
              _KeyButton(
                color: p.keyFace,
                shadow: shadow,
                onTap: onDecimal,
                child: Text('.', style: digitStyle()),
              ),
              _KeyButton(
                color: p.equalsKey,
                shadow: <BoxShadow>[
                  BoxShadow(
                    color: p.equalsKey.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
                onTap: onEquals,
                child: const Text(
                  '=',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
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
///
/// These used to be a strip with a rule above and below it — the two
/// hairlines that ran across the screen under the currency rows. It is now a
/// row of free-standing pills, so nothing is underlined.
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < actions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _ActionPill(palette: p, action: actions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.palette, required this.action});

  final AppPalette palette;
  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(action.icon, size: 17, color: action.color ?? palette.primary),
              const SizedBox(height: 4),
              // Scale only when a line is wider than the pill. The label is
              // not locked to a short box, so both lines stay fully on screen.
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
}

/// Small X on an amount field so the typed number can be wiped in one tap.
class AmountClearButton extends StatelessWidget {
  const AmountClearButton({
    super.key,
    required this.onClear,
    this.visible = true,
  });

  final VoidCallback onClear;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    return IconButton(
      tooltip: l10n.clr,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(Icons.cancel_rounded, size: 20, color: p.down),
      onPressed: onClear,
    );
  }
}
