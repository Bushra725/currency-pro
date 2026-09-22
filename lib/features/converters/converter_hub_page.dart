import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_drawer.dart';
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

    return Scaffold(
      drawer: const AppDrawer(current: Routes.converters),
      appBar: AppBar(title: const Text('UNIT CONVERTERS')),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
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
              subtitle: '${c.units.length} units',
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
            label: 'Height',
            subtitle: 'ft/in ↔ cm',
            onTap: () => Navigator.of(context).pushNamed(Routes.height),
          ),
          _tile(
            context,
            p,
            icon: Icons.pin,
            label: 'Number Base',
            subtitle: 'bin/oct/hex',
            onTap: () => Navigator.of(context).pushNamed(Routes.numberBase),
          ),
          _tile(
            context,
            p,
            icon: Icons.currency_exchange,
            label: 'Currency',
            subtitle: '171 live rates',
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.home,
              (Route<dynamic> r) => false,
            ),
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
