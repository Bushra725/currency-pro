import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The standard rounded panel used everywhere in the app.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.onTap,
    this.borderColor,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    // Cards are borderless by default: depth comes from fill plus a wide,
    // low-opacity shadow. Screens that want a tinted emphasis border still
    // get one by passing [borderColor].
    final Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border:
            borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: borderColor == null ? p.cardShadow : null,
      ),
      child: child,
    );

    return Padding(
      padding: margin,
      child: onTap == null
          ? body
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: body,
              ),
            ),
    );
  }
}

/// Small uppercase label that introduces a group of rows.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: padding ??
          const EdgeInsets.only(left: 4, right: 4, top: 18, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: p.textSecondary,
        ),
      ),
    );
  }
}

/// A left-accented row title, mirroring the reference app's field labels.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.width = 110});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      width: width,
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: p.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state placeholder with an icon and a hint.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surfaceAlt,
              ),
              child: Icon(
                icon,
                size: 36,
                color: p.textSecondary.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
