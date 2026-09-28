import 'package:flutter/material.dart';

import '../../routes.dart';
import '../app_config.dart';
import '../theme/app_palette.dart';

/// The navigation drawer shared by every screen.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.current});

  /// Route name of the screen that is showing, so it can be highlighted.
  final String current;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _header(context, p),
            _group(p, 'Convert'),
            _item(context, p, Icons.sync_alt, 'Real-Time Currency', Routes.home),
            _item(context, p, Icons.grid_view_rounded,
                'Multi Currency Converter', Routes.multi),
            _item(context, p, Icons.show_chart, 'Trend Charts', Routes.charts),
            _item(context, p, Icons.diamond_outlined,
                'Dollar, Bitcoin, Gold, Silver', Routes.assets),
            _group(p, 'Analysis'),
            _item(context, p, Icons.table_rows_outlined, 'Exchange Rate List',
                Routes.rateList),
            _item(context, p, Icons.tune, 'Currency Simulation',
                Routes.simulation),
            _item(context, p, Icons.account_balance_outlined,
                'Exchange Rate Adjustment', Routes.adjustment),
            _item(context, p, Icons.badge_outlined, 'Currency Profile',
                Routes.profile),
            _group(p, 'Alert & Travel'),
            _item(context, p, Icons.notifications_active_outlined,
                'Rate Alert', Routes.alerts),
            _item(context, p, Icons.flight_takeoff, 'Travel Budget',
                Routes.travel),
            _group(p, 'Calculators'),
            _item(context, p, Icons.calculate_outlined, 'Calculator Hub',
                Routes.calculators),
            _item(context, p, Icons.straighten, 'Unit Converters',
                Routes.converters),
            _item(context, p, Icons.restaurant_outlined, 'Tip Calculator',
                Routes.tip),
            _group(p, 'Tools'),
            _item(context, p, Icons.public, 'World Clock', Routes.clock),
            _group(p, 'Info & Settings'),
            _item(context, p, Icons.settings_outlined, 'App Settings',
                Routes.settings),
            _item(context, p, Icons.palette_outlined, 'Select Theme',
                Routes.theme),
            _item(context, p, Icons.info_outline, 'About App', Routes.about),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppPalette p) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[p.primary, p.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.onPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: p.onPrimary,
                  ),
                ),
              ),
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
            '171 currencies · Bitcoin · Gold · Silver',
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
  ) {
    final bool selected = route == current;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: Icon(icon, size: 20, color: selected ? p.primary : p.textSecondary),
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
