import 'package:flutter/material.dart';

import '../../routes.dart';
import '../app_config.dart';
import '../l10n/l10n.dart';
import '../theme/app_palette.dart';
import 'brand_logo.dart';

/// The navigation drawer shared by every screen.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.current});

  /// Route name of the screen that is showing, so it can be highlighted.
  final String current;

  static const List<Color> _tints = <Color>[
    Color(0xFF2F80ED),
    Color(0xFF27AE60),
    Color(0xFFF2994A),
    Color(0xFF9B51E0),
    Color(0xFFEB5757),
    Color(0xFF56CCF2),
    Color(0xFF219653),
    Color(0xFFF2C94C),
    Color(0xFFBB6BD9),
    Color(0xFF2D9CDB),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    int i = 0;
    Color nextTint() => _tints[(i++) % _tints.length];

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 6, right: 6),
          children: <Widget>[
            _header(context, p, l10n),
            _group(p, l10n.gConvert),
            _item(context, p, Icons.sync_alt, l10n.realTimeCurrency, Routes.home,
                nextTint()),
            _item(context, p, Icons.grid_view_rounded, l10n.multiCurrency,
                Routes.multi, nextTint()),
            _item(context, p, Icons.show_chart, l10n.trendCharts, Routes.charts,
                nextTint()),
            _item(context, p, Icons.diamond_outlined, l10n.metalCrypto,
                Routes.assets, nextTint()),
            _group(p, l10n.gAnalysis),
            _item(context, p, Icons.table_rows_outlined, l10n.rateList,
                Routes.rateList, nextTint()),
            _item(context, p, Icons.tune, l10n.simulation, Routes.simulation,
                nextTint()),
            _item(context, p, Icons.account_balance_outlined, l10n.adjustment,
                Routes.adjustment, nextTint()),
            _item(context, p, Icons.badge_outlined, l10n.currencyProfile,
                Routes.profile, nextTint()),
            _group(p, l10n.gAlertTravel),
            _item(context, p, Icons.notifications_active_outlined,
                l10n.rateAlert, Routes.alerts, nextTint()),
            _item(context, p, Icons.flight_takeoff, l10n.travelBudget,
                Routes.travel, nextTint()),
            _group(p, l10n.gCalculators),
            _item(context, p, Icons.calculate_outlined, l10n.calculatorHub,
                Routes.calculators, nextTint()),
            _item(context, p, Icons.straighten, l10n.unitConverters,
                Routes.converters, nextTint()),
            _item(context, p, Icons.restaurant_outlined, l10n.tipCalculator,
                Routes.tip, nextTint()),
            _group(p, l10n.gTools),
            _item(context, p, Icons.public, l10n.worldClock, Routes.clock,
                nextTint()),
            _group(p, l10n.gInfo),
            _item(context, p, Icons.settings_outlined, l10n.appSettings,
                Routes.settings, nextTint()),
            _item(context, p, Icons.language_outlined, l10n.language,
                Routes.language, nextTint()),
            _item(context, p, Icons.palette_outlined, l10n.selectTheme,
                Routes.theme, nextTint()),
            _item(context, p, Icons.info_outline, l10n.aboutApp, Routes.about,
                nextTint()),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppPalette p, L10n l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[p.primary, p.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BrandLogo(size: 42, radius: 12),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppConfig.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: p.onPrimary,
                    ),
                  ),
                  Text(
                    'v${AppConfig.appVersion}',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.onPrimary.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.drawerTagline,
            style: TextStyle(
              fontSize: 11.5,
              color: p.onPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(AppPalette p, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: p.textSecondary,
          ),
        ),
      );

  Widget _item(
    BuildContext context,
    AppPalette p,
    IconData icon,
    String label,
    String route,
    Color tint,
  ) {
    final bool selected = route == current;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      minLeadingWidth: 28,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Icon(icon, size: 20, color: selected ? p.primary : tint),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? p.primary : p.textPrimary,
        ),
      ),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        if (selected) return;
        if (route == Routes.home) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.home,
            (Route<dynamic> r) => false,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            route,
            (Route<dynamic> r) => r.isFirst,
          );
        }
      },
    );
  }
}
