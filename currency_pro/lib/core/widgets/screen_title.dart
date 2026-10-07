import 'package:flutter/material.dart';

/// An app bar title that shrinks to fit instead of being cut off.
///
/// Plain `Text` in an `AppBar` ellipsises as soon as the title is wider than
/// the toolbar's middle slot — which happens easily once a title is
/// translated, or when the bar carries two or three action buttons. Scaling
/// the laid-out text down keeps every screen's full name on screen.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.style, this.alignment});

  final String text;
  final TextStyle? style;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment ?? AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        style: style,
      ),
    );
  }
}
