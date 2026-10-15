import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';
import '../../routes.dart';
import '../../state/premium_controller.dart';

/// Paid-content screen: sandbox purchase, unlocks, and restore.
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final PremiumController premium = context.watch<PremiumController>();
    final List<String> perks = <String>[
      l10n.premiumPerkAds,
      l10n.premiumPerkAlerts,
      l10n.premiumPerkCharts,
      l10n.premiumPerkExport,
    ];

    return Scaffold(
      drawer: const AppDrawer(current: Routes.premium),
      appBar: AppBar(title: ScreenTitle(l10n.premiumTitle.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  premium.isPremium
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  color: p.primary,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  premium.isPremium ? l10n.premiumActive : l10n.premiumTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  premium.isPremium ? l10n.premiumUnlocked : l10n.premiumLead,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SectionLabel(
            premium.isPremium ? l10n.premiumUnlocked : l10n.premiumWhatUnlocks,
          ),
          SectionCard(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < perks.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 12),
                  _PerkRow(label: perks[i], unlocked: premium.isPremium),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.premiumSandbox,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: p.textSecondary,
            ),
          ),
          if (premium.storePrice != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              premium.storePrice!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (!premium.isPremium)
            FilledButton(
              key: const Key('premium-buy'),
              onPressed: premium.busy ? null : premium.buy,
              child: premium.busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.premiumBuy),
            ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('premium-restore'),
            onPressed: premium.busy ? null : premium.restore,
            child: Text(l10n.premiumRestore),
          ),
          if (premium.notice != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _notice(l10n, premium.notice!),
              style: TextStyle(fontSize: 12.5, color: p.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  String _notice(L10n l10n, PremiumNotice notice) {
    switch (notice) {
      case PremiumNotice.restored:
        return l10n.premiumRestored;
      case PremiumNotice.nothing:
        return l10n.premiumNothing;
      case PremiumNotice.failed:
        return l10n.premiumFailed;
      case PremiumNotice.storeUnavailable:
        return l10n.premiumStoreUnavailable;
    }
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      children: <Widget>[
        Icon(
          unlocked ? Icons.check_circle : Icons.lock_open_outlined,
          size: 18,
          color: unlocked ? p.up : p.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: p.textPrimary),
          ),
        ),
      ],
    );
  }
}
