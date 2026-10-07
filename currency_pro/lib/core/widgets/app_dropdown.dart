import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// One choice inside an [AppDropdown].
class AppDropdownEntry<T> {
  const AppDropdownEntry({
    required this.value,
    required this.label,
    this.buttonLabel,
    this.icon,
  });

  final T value;
  final String label;

  /// Shorter face for the closed button. The open menu still shows [label].
  final String? buttonLabel;
  final IconData? icon;
}

/// A dropdown that always opens directly beneath its button.
///
/// Material's own `DropdownButton` positions its menu so that the *selected*
/// item lands on top of the button, which makes the menu jump up or down
/// depending on what is currently selected — and it gives no way to dismiss
/// the menu except by picking something. This widget fixes both:
///
///  * the menu is anchored to the button's rectangle, so it opens from the
///    same place every time regardless of the selection, and
///  * it is a modal popup route, so tapping anywhere outside it — including
///    back on the button itself — closes it without changing the value.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.labelStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    this.background,
    this.maxMenuHeight = 320,
    this.expand = false,
  });

  final T value;
  final List<AppDropdownEntry<T>> entries;
  final ValueChanged<T> onChanged;

  final TextStyle? labelStyle;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final double maxMenuHeight;

  /// When true the button fills its parent's width instead of hugging the
  /// label. Useful inside a sized container such as a form row.
  final bool expand;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final GlobalKey _anchor = GlobalKey();
  bool _open = false;

  AppDropdownEntry<T>? get _current {
    for (final AppDropdownEntry<T> e in widget.entries) {
      if (e.value == widget.value) return e;
    }
    return widget.entries.isEmpty ? null : widget.entries.first;
  }

  Future<void> _handleTap() async {
    // While the menu is open its modal barrier swallows taps, so this only
    // runs when the menu is closed. The guard is belt and braces.
    if (_open) {
      Navigator.of(context).maybePop();
      return;
    }

    final BuildContext? anchorContext = _anchor.currentContext;
    final NavigatorState navigator = Navigator.of(context);
    final RenderObject? anchorBox = anchorContext?.findRenderObject();
    final RenderObject? overlayBox =
        navigator.overlay?.context.findRenderObject();
    if (anchorBox is! RenderBox || overlayBox is! RenderBox) return;

    final Offset topLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Offset bottomRight = anchorBox.localToGlobal(
      anchorBox.size.bottomRight(Offset.zero),
      ancestor: overlayBox,
    );

    // Anchored to the button, never to the selected row.
    final RelativeRect position = RelativeRect.fromLTRB(
      topLeft.dx,
      bottomRight.dy + 4,
      overlayBox.size.width - bottomRight.dx,
      overlayBox.size.height - bottomRight.dy,
    );

    final AppPalette p = context.palette;

    setState(() => _open = true);

    final T? picked = await showMenu<T>(
      context: context,
      position: position,
      color: p.surfaceHigh,
      elevation: 8,
      constraints: BoxConstraints(
        minWidth: anchorBox.size.width,
        maxHeight: widget.maxMenuHeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      items: widget.entries.map((AppDropdownEntry<T> e) {
        final bool selected = e.value == widget.value;
        return PopupMenuItem<T>(
          value: e.value,
          height: 44,
          child: Row(
            children: <Widget>[
              if (e.icon != null) ...<Widget>[
                Icon(
                  e.icon,
                  size: 17,
                  color: selected ? p.primary : p.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  e.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? p.primary : p.textPrimary,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 17, color: p.primary),
            ],
          ),
        );
      }).toList(growable: false),
    );

    if (!mounted) return;
    setState(() => _open = false);
    // A null result means the menu was dismissed — leave the value alone.
    if (picked != null && picked != widget.value) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final AppDropdownEntry<T>? current = _current;

    return Material(
      key: _anchor,
      color: widget.background ?? p.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _handleTap,
        child: Padding(
          padding: widget.padding,
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              if (current?.icon != null) ...<Widget>[
                Icon(current!.icon, size: 16, color: p.primary),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  current?.buttonLabel ?? current?.label ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.labelStyle ??
                      TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: p.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
