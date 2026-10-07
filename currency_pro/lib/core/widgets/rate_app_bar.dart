import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rates_provider.dart';
import '../l10n/l10n.dart';
import '../theme/app_palette.dart';
import '../utils/formatting.dart';
import 'brand_logo.dart';
import 'screen_title.dart';

/// App bar used on the rate-driven screens: a title plus the
/// "Updated: 22 Sept 2026 14:01" line from the reference app.
class RateAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RateAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showUpdated = true,
    this.showRefresh = true,
    this.showLogo = true,
    this.uppercase = true,
    this.titleMaxLines = 1,
    this.titleFontSize = 14.5,
    this.titleLetterSpacing = 0.9,
  });

  final String title;
  final List<Widget>? actions;
  final bool showUpdated;
  final bool showRefresh;

  /// The mark eats width the title needs. Long names pass false so the
  /// title can stay large enough to read.
  final bool showLogo;

  /// Long names stay larger in their normal capitalization. Short names
  /// stay in capitals, matching the rest of the rate screens.
  final bool uppercase;
  final int titleMaxLines;
  final double titleFontSize;
  final double titleLetterSpacing;

  @override
  Size get preferredSize => Size.fromHeight(titleMaxLines > 1 ? 72 : 58);

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();

    final String shown = uppercase ? title.toUpperCase() : title;
    final TextStyle titleStyle = TextStyle(
      fontSize: titleFontSize,
      height: titleMaxLines > 1 ? 1.05 : null,
      fontWeight: FontWeight.w800,
      letterSpacing: titleLetterSpacing,
      color: p.textPrimary,
    );

    return AppBar(
      toolbarHeight: titleMaxLines > 1 ? 72 : 58,
      titleSpacing: showLogo ? null : 4,
      title: Row(
        children: <Widget>[
          if (showLogo) ...<Widget>[
            const BrandLogo(size: 30),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Shrinks rather than truncates, so even a long translated
                // screen name stays fully readable next to the actions.
                titleMaxLines > 1
                    ? Text(
                        shown,
                        maxLines: titleMaxLines,
                        style: titleStyle,
                      )
                    : ScreenTitle(
                        shown,
                        style: titleStyle,
                      ),
                if (showUpdated)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rates.isOffline ? p.down : p.up,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              rates.hasData
                                  ? l10n.updated(Fmt.dateTime(rates.updatedAt))
                                  : l10n.waitingFirstUpdate,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color:
                                    rates.isOffline ? p.down : p.textSecondary,
                              ),
                            ),
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
      actions: <Widget>[
        if (showRefresh)
          IconButton(
            tooltip: l10n.updateRatesNow,
            visualDensity: showLogo
                ? VisualDensity.standard
                : const VisualDensity(horizontal: -4, vertical: -4),
            padding: showLogo ? null : EdgeInsets.zero,
            constraints: showLogo
                ? null
                : const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: rates.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 21),
            onPressed: rates.isLoading ? null : () => rates.refresh(),
          ),
        ...?actions,
        const SizedBox(width: 4),
      ],
    );
  }
}

/// Thin banner shown when the rates on screen came from the offline cache.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    if (!rates.isOffline || !rates.hasData) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      decoration: BoxDecoration(
        color: p.down.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, size: 14, color: p.down),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rates.snapshot.provider.contains('bundled')
                  ? l10n.offlineBundled
                  : l10n.offlineSaved(Fmt.ago(rates.snapshot.fetchedAt)),
              style: TextStyle(fontSize: 11.5, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => rates.refresh(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(l10n.retry, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
