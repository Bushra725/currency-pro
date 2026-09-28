import 'package:flutter/material.dart';

import '../../core/ads/native_ad_card.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/section_card.dart';
import '../../routes.dart';

/// Landing screen listing every calculator in the app.
class CalculatorHubPage extends StatelessWidget {
  const CalculatorHubPage({super.key});

  static const List<Color> _tints = <Color>[
    Color(0xFF2F80ED),
    Color(0xFFE67E22),
    Color(0xFF27AE60),
    Color(0xFF9B51E0),
    Color(0xFFEB5757),
    Color(0xFF2D9CDB),
    Color(0xFF219653),
    Color(0xFFF2C94C),
    Color(0xFFBB6BD9),
    Color(0xFF56CCF2),
    Color(0xFFD35400),
    Color(0xFF1ABC9C),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final List<_Entry> entries = <_Entry>[
      _Entry(Icons.calculate_outlined, l10n.scientific, l10n.scientificSub,
          Routes.scientific, _tints[0]),
      _Entry(Icons.cake_outlined, l10n.age, l10n.ageSub, Routes.age, _tints[1]),
      _Entry(Icons.event_outlined, l10n.dateDiff, l10n.dateDiffSub,
          Routes.dateDiff, _tints[2]),
      _Entry(Icons.local_offer_outlined, l10n.discount, l10n.discountSub,
          Routes.discount, _tints[3]),
      _Entry(Icons.percent, l10n.percentage, l10n.percentageSub,
          Routes.percentage, _tints[4]),
      _Entry(Icons.monitor_heart_outlined, l10n.bmi, l10n.bmiSub, Routes.bmi,
          _tints[5]),
      _Entry(Icons.account_balance_outlined, l10n.loan, l10n.loanSub,
          Routes.loan, _tints[6]),
      _Entry(Icons.restaurant_outlined, l10n.tip, l10n.tipSub, Routes.tip,
          _tints[7]),
      _Entry(Icons.straighten, l10n.unitConverters, l10n.convertersSub,
          Routes.converters, _tints[8]),
      _Entry(Icons.height, l10n.height, l10n.heightSub, Routes.height,
          _tints[9]),
      _Entry(Icons.pin, l10n.numberBase, l10n.numberBaseSub, Routes.numberBase,
          _tints[10]),
      _Entry(Icons.currency_exchange, l10n.currency, l10n.currencySub,
          Routes.home, _tints[11]),
    ];

    return Scaffold(
      drawer: const AppDrawer(current: Routes.calculators),
      appBar: AppBar(title: Text(l10n.calculators)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: entries.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index == 4) {
            return const NativeAdCard();
          }
          final _Entry e = entries[index > 4 ? index - 1 : index];
          return SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () {
              if (e.route == Routes.home) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Routes.home,
                  (Route<dynamic> r) => false,
                );
              } else {
                Navigator.of(context).pushNamed(e.route);
              }
            },
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: e.tint.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(e.icon, size: 20, color: e.tint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        e.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        e.subtitle,
                        style: TextStyle(
                            fontSize: 11.5, color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: e.tint),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.route, this.tint);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color tint;
}
