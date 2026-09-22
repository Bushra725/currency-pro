import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rates_provider.dart';
import '../theme/app_palette.dart';
import '../utils/formatting.dart';

/// App bar used on the rate-driven screens: a title plus the
/// "Updated: 22 Sept 2026 14:01" line from the reference app.
class RateAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RateAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showUpdated = true,
    this.showRefresh = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showUpdated;
  final bool showRefresh;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final RatesProvider rates = context.watch<RatesProvider>();

    return AppBar(
      toolbarHeight: 58,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: p.textPrimary,
            ),
          ),
          if (showUpdated)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                rates.hasData
                    ? 'Updated: ${Fmt.dateTime(rates.updatedAt)}'
                    : 'Waiting for first update…',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: rates.isOffline ? p.down : p.textSecondary,
                ),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        if (showRefresh)
          IconButton(
            tooltip: 'Update rates now',
            icon: rates.isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.primary,
                    ),
                  )
                : const Icon(Icons.refresh, size: 21),
            onPressed: rates.isLoading ? null : () => rates.refresh(),
          ),
        ...?actions,
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
    final RatesProvider rates = context.watch<RatesProvider>();
    if (!rates.isOffline || !rates.hasData) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: p.down.withOpacity(0.14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off, size: 14, color: p.down),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rates.isOffline
                  ? (rates.snapshot.provider.contains('bundled')
                      ? 'Showing bundled rates — tap RETRY for live prices'
                      : 'Offline — showing saved rates from '
                          '${Fmt.ago(rates.snapshot.fetchedAt)}')
                  : 'Offline — showing saved rates from '
                      '${Fmt.ago(rates.snapshot.fetchedAt)}',
              style: TextStyle(fontSize: 11.5, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: () => rates.refresh(),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('RETRY', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
