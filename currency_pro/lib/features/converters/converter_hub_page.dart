import 'package:flutter/material.dart';

import '../../core/ads/native_ad_card.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/screen_title.dart';
import '../../core/widgets/section_card.dart';
import '../../routes.dart';
import 'unit_catalog.dart';
import 'unit_converter_page.dart';
import 'unit_models.dart';

/// Grid of every measurement category the app can convert.
class ConverterHubPage extends StatelessWidget {
  const ConverterHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.converters),
      appBar: AppBar(title: ScreenTitle(l10n.unitConverters)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          const NativeAdCard(),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: <Widget>[
          ...kUnitCategories.map(
            (UnitCategory c) => _tile(
              context,
              p,
              icon: c.icon,
              label: c.name,
              subtitle: l10n.unitsCount('${c.units.length}'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UnitConverterPage(category: c),
                ),
              ),
            ),
          ),
          _tile(
            context,
            p,
            icon: Icons.height,
            label: l10n.height,
            subtitle: l10n.heightSub,
            onTap: () => Navigator.of(context).pushNamed(Routes.height),
          ),
          _tile(
            context,
            p,
            icon: Icons.pin,
            label: l10n.numberBase,
            subtitle: l10n.numberBaseSub,
            onTap: () => Navigator.of(context).pushNamed(Routes.numberBase),
          ),
          _tile(
            context,
            p,
            icon: Icons.currency_exchange,
            label: l10n.currency,
            subtitle: l10n.currencySub,
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.home,
              (Route<dynamic> r) => false,
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    AppPalette p, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: p.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: p.primary),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
