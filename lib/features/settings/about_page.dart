import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_catalog.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../converters/unit_catalog.dart';
import '../converters/unit_models.dart';

/// What the app does, where the numbers come from, and the fine print.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final RatesProvider rates = context.watch<RatesProvider>();

    final int unitCount = kUnitCategories.fold<int>(
      0,
      (int sum, UnitCategory c) => sum + c.units.length,
    );

    return Scaffold(
      drawer: const AppDrawer(current: Routes.about),
      appBar: AppBar(title: const Text('ABOUT APP')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              children: <Widget>[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[p.primary, p.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '\$',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: p.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  'Version ${AppConfig.appVersion}',
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Real-time currency conversion with Bitcoin, gold and '
                  'silver — plus every everyday calculator in one app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _stat(p, '${kAllCurrencies.length}', 'assets'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(p, '${kUnitCategories.length}', 'categories'),
              ),
              const SizedBox(width: 10),
              Expanded(child: _stat(p, '$unitCount', 'units')),
            ],
          ),
          const SizedBox(height: 12),
          SectionLabel('Where the numbers come from'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _source(
                  p,
                  'Fiat exchange rates',
                  'open.er-api.com — free, no API key, 160+ currencies. '
                      'The European Central Bank feed (frankfurter.dev) is '
                      'used automatically if the primary source is down.',
                ),
                const SizedBox(height: 12),
                _source(
                  p,
                  'Historical charts',
                  'European Central Bank daily reference rates via '
                      'frankfurter.dev, and CoinGecko for crypto and metals.',
                ),
                const SizedBox(height: 12),
                _source(
                  p,
                  'Bitcoin, gold and silver',
                  'CoinGecko public API. Gold and silver track PAXG and KAG, '
                      'tokens each redeemable for one troy ounce of the '
                      'physical metal.',
                ),
                const SizedBox(height: 12),
                _source(
                  p,
                  'Status',
                  rates.hasData
                      ? 'Last successful download '
                          '${Fmt.ago(rates.snapshot.fetchedAt)} from '
                          '${rates.provider}.'
                      : 'No successful download yet.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionLabel('Good to know'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _bullet(p,
                    'Rates are mid-market reference values. Banks, cards and '
                    'exchanges add their own spread — model it on the '
                    'Exchange Rate Adjustment screen.'),
                _bullet(p,
                    'The last downloaded table is cached, so conversions keep '
                    'working with no connection.'),
                _bullet(p,
                    'Everything you save — favourites, alerts, trips and '
                    'holdings — stays on this device. Nothing is uploaded.'),
                _bullet(p,
                    'This app is a reference tool, not financial advice.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.mail_outline, size: 18, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Feedback: ${AppConfig.supportEmail}',
                    style: TextStyle(fontSize: 12.5, color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(AppPalette p, String value, String label) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: p.primary,
            ),
          ),
          Text(label,
              style: TextStyle(fontSize: 11, color: p.textSecondary)),
        ],
      ),
    );
  }

  Widget _source(AppPalette p, String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: TextStyle(fontSize: 11.5, height: 1.45, color: p.textSecondary),
        ),
      ],
    );
  }

  Widget _bullet(AppPalette p, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: p.primary, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 11.5, height: 1.45, color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
