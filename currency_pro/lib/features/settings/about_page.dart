import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/screen_title.dart';
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
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();

    final int unitCount = kUnitCategories.fold<int>(
      0,
      (int sum, UnitCategory c) => sum + c.units.length,
    );

    return Scaffold(
      drawer: const AppDrawer(current: Routes.about),
      appBar: AppBar(title: ScreenTitle(l10n.aboutApp)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: <Widget>[
          SectionCard(
            child: Column(
              children: <Widget>[
                const BrandLogo(size: 72, radius: 16),
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
                  l10n.versionLabel(AppConfig.appVersion),
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.aboutTagline,
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
                child: _stat(p, '${kAllCurrencies.length}', l10n.statAssets),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(p, '${kUnitCategories.length}', l10n.statCategories),
              ),
              const SizedBox(width: 10),
              Expanded(child: _stat(p, '$unitCount', l10n.statUnits)),
            ],
          ),
          const SizedBox(height: 12),
          SectionLabel(l10n.aboutSources),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _source(p, l10n.sourceFiatTitle, l10n.sourceFiatBody),
                const SizedBox(height: 12),
                _source(p, l10n.sourceChartsTitle, l10n.sourceChartsBody),
                const SizedBox(height: 12),
                _source(p, l10n.sourceMetalsTitle, l10n.sourceMetalsBody),
                const SizedBox(height: 12),
                _source(
                  p,
                  l10n.statusLabel,
                  rates.hasData
                      ? l10n.lastDownload(
                          Fmt.ago(rates.snapshot.fetchedAt),
                          rates.provider,
                        )
                      : l10n.noDownloadYet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionLabel(l10n.goodToKnow),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _bullet(p, l10n.aboutNoteRates),
                _bullet(p, l10n.aboutNoteCache),
                _bullet(p, l10n.aboutNoteLocal),
                _bullet(p, l10n.aboutNoteAdvice),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            onTap: () => _sendFeedback(context),
            child: Row(
              children: <Widget>[
                Icon(Icons.mail_outline, size: 18, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.feedback,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConfig.supportEmail,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: p.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded,
                    size: 16, color: p.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            onTap: () { openPrivacyPolicy(); },
            child: Row(
              children: <Widget>[
                Icon(Icons.privacy_tip_outlined, size: 18, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.privacyPolicy,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.privacyPolicySub,
                        style: TextStyle(
                          fontSize: 11,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, size: 16, color: p.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the mail app with the support address already filled in.
  ///
  /// If the device has no mail client the address is copied instead, so the
  /// tap always does something useful.
  Future<void> _sendFeedback(BuildContext context) async {
    final bool opened = await openEmail(
      AppConfig.supportEmail,
      subject:
          '${AppConfig.appName} v${AppConfig.appVersion} ${L10n.read(context).feedback}',
    );
    if (opened || !context.mounted) return;

    await Clipboard.setData(
      const ClipboardData(text: AppConfig.supportEmail),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          L10n.read(context).noMailFound(AppConfig.supportEmail),
        ),
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
