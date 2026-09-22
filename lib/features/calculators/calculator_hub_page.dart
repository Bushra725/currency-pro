import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/section_card.dart';
import '../../routes.dart';

/// Landing screen listing every calculator in the app.
class CalculatorHubPage extends StatelessWidget {
  const CalculatorHubPage({super.key});

  static const List<_Entry> _entries = <_Entry>[
    _Entry(Icons.calculate_outlined, 'Scientific', 'Full expression calculator',
        Routes.scientific),
    _Entry(Icons.cake_outlined, 'Age', 'Years, months, days & next birthday',
        Routes.age),
    _Entry(Icons.event_outlined, 'Date Difference', 'Days between two dates',
        Routes.dateDiff),
    _Entry(Icons.local_offer_outlined, 'Discount',
        'Sale price, savings & double discounts', Routes.discount),
    _Entry(Icons.percent, 'Percentage', 'Six everyday percentage problems',
        Routes.percentage),
    _Entry(Icons.monitor_heart_outlined, 'BMI', 'Body mass index & healthy range',
        Routes.bmi),
    _Entry(Icons.account_balance_outlined, 'Loan / EMI',
        'Monthly payment & total interest', Routes.loan),
    _Entry(Icons.restaurant_outlined, 'Tip', 'Tip, total and split',
        Routes.tip),
    _Entry(Icons.straighten, 'Unit Converters',
        '21 categories, 199 units', Routes.converters),
    _Entry(Icons.height, 'Height', 'Feet & inches ↔ cm', Routes.height),
    _Entry(Icons.pin, 'Number Base', 'Binary, octal, hex', Routes.numberBase),
    _Entry(Icons.currency_exchange, 'Currency', '171 live rates', Routes.home),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      drawer: const AppDrawer(current: Routes.calculators),
      appBar: AppBar(title: const Text('CALCULATORS')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final _Entry e = _entries[index];
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
                    color: p.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(e.icon, size: 20, color: p.primary),
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
                Icon(Icons.chevron_right, size: 20, color: p.textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.route);

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
