import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ads_service.dart';
import '../../core/app_config.dart';
import '../../core/l10n/l10n.dart';
import '../../core/notifications/notification_permission.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/links.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import '../currency/currency_picker.dart';

/// Number formatting, feedback, data source and reset.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final Currency base = CurrencyLookup.of(settings.baseCode);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.settings),
      appBar: AppBar(title: Text(l10n.appSettings.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
        children: <Widget>[
          SectionLabel(l10n.rateSource),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.dns_outlined, color: p.primary),
                  title: Text(l10n.currencyServer),
                  subtitle: Text(
                    rates.hasData
                        ? l10n.serverUpdated(
                            rates.provider,
                            Fmt.ago(rates.snapshot.fetchedAt),
                          )
                        : l10n.noDataYet,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: TextButton(
                    onPressed: () => rates.refresh(),
                    child: Text(l10n.update),
                  ),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: p.primary),
                  title: Text(l10n.baseCurrency),
                  subtitle: Text(
                    '${base.code} — ${base.name}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () async {
                    final Currency? picked =
                        await CurrencyPicker.show(context,
                            title: l10n.baseCurrency);
                    if (picked != null) {
                      await settings.setBaseCode(picked.code);
                    }
                  },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.autorenew, color: p.primary),
                  title: Text(l10n.autoRefresh),
                  subtitle: Text(
                    l10n.autoRefreshSub,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  value: settings.autoRefresh,
                  onChanged: (bool v) {
                    settings.setAutoRefresh(v);
                    if (v) {
                      rates.startAutoRefresh();
                    } else {
                      rates.stopAutoRefresh();
                    }
                  },
                ),
              ],
            ),
          ),
          SectionLabel(l10n.numberFormat),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.numbers, color: p.primary),
                  title: Text(l10n.decimalPlaces),
                  subtitle: Text(
                    'Example: ${settings.format(1234.56789)}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: DropdownButton<int>(
                    value: settings.decimals,
                    underline: const SizedBox.shrink(),
                    items: List<DropdownMenuItem<int>>.generate(
                      7,
                      (int i) => DropdownMenuItem<int>(
                        value: i,
                        child: Text('$i'),
                      ),
                    ),
                    onChanged: (int? v) =>
                        settings.setDecimals(v ?? 2),
                  ),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.swap_vert_circle_outlined,
                      color: p.primary),
                  title: const Text('Rounding mode'),
                  subtitle: Text(
                    settings.rounding.label,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () async {
                    final RoundingMode? picked =
                        await showModalBottomSheet<RoundingMode>(
                      context: context,
                      builder: (BuildContext context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: RoundingMode.values
                              .map((RoundingMode m) => ListTile(
                                    title: Text(m.label),
                                    trailing: m == settings.rounding
                                        ? Icon(Icons.check,
                                            color: p.primary)
                                        : null,
                                    onTap: () =>
                                        Navigator.of(context).pop(m),
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                    if (picked != null) await settings.setRounding(picked);
                  },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.format_list_numbered,
                      color: p.primary),
                  title: const Text('Thousands separator'),
                  subtitle: const Text(
                    'Show 1,234,567 instead of 1234567',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  value: settings.grouping,
                  onChanged: settings.setGrouping,
                ),
              ],
            ),
          ),
          SectionLabel('Keypad'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  secondary: Icon(Icons.vibration, color: p.primary),
                  title: const Text('Vibrate on key press'),
                  value: settings.vibrate,
                  onChanged: (bool v) {
                    settings.setVibrate(v);
                    if (v) Haptics.tap(vibrate: true, sound: false);
                  },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.volume_up_outlined, color: p.primary),
                  title: const Text('Typing sound'),
                  value: settings.keySound,
                  onChanged: (bool v) {
                    settings.setKeySound(v);
                    if (v) Haptics.tap(vibrate: false, sound: true);
                  },
                ),
              ],
            ),
          ),
          SectionLabel(l10n.alerts),
          SectionCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              secondary: Icon(Icons.notifications_active_outlined,
                  color: p.primary),
              title: Text(l10n.rateAlertNotifs),
              subtitle: Text(
                l10n.rateAlertNotifsSub,
                style: const TextStyle(fontSize: 11.5),
              ),
              value: settings.notificationsEnabled,
              onChanged: (bool v) async {
                if (v) {
                  final bool granted =
                      await NotificationPermission.request();
                  await settings.setNotificationsEnabled(granted);
                } else {
                  await settings.setNotificationsEnabled(false);
                }
              },
            ),
          ),
          SectionLabel(l10n.appearance),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.language_outlined,
                      color: Color(0xFF2F80ED)),
                  title: Text(l10n.language),
                  subtitle: Text(
                    settings.localeCode == AppLocales.systemCode
                        ? '${l10n.systemDefault} · ${AppLocales.nativeName(Localizations.localeOf(context).languageCode)}'
                        : AppLocales.nativeName(settings.localeCode),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context).pushNamed(Routes.language),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: p.primary),
                  title: Text(l10n.selectTheme),
                  subtitle: Text(
                    '${settings.palette.city} — ${settings.palette.name}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(Routes.theme),
                ),
              ],
            ),
          ),
          SectionLabel(l10n.defaults),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.restaurant_outlined, color: p.primary),
                  title: Text(l10n.defaultTip),
                  subtitle: Text(
                    '${settings.tipPercent.toStringAsFixed(0)} %',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
                Slider(
                  value: settings.tipPercent.clamp(0.0, 30.0),
                  max: 30,
                  divisions: 60,
                  onChanged: settings.setTipPercent,
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.account_balance_outlined,
                      color: p.primary),
                  title: const Text('Default bank spread'),
                  subtitle: Text(
                    '${settings.bankFeePercent.toStringAsFixed(2)} %',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
                Slider(
                  value: settings.bankFeePercent.clamp(0.0, 10.0),
                  max: 10,
                  divisions: 200,
                  onChanged: settings.setBankFeePercent,
                ),
              ],
            ),
          ),
          SectionLabel('Ads'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Builder(
              builder: (BuildContext context) {
                final AdsService ads = context.watch<AdsService>();
                final Duration left = ads.adsFreeRemaining;
                final String subtitle = left > Duration.zero
                    ? 'Ads hidden for ${left.inMinutes} more minutes'
                    : 'Watch a short video to hide ads for 1 hour';
                return ListTile(
                  leading: Icon(Icons.ondemand_video_outlined, color: p.primary),
                  title: Text(
                    left > Duration.zero ? 'Ads paused' : 'Hide ads for 1 hour',
                  ),
                  subtitle: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: left > Duration.zero
                      ? Icon(Icons.check_circle, color: p.up)
                      : const Icon(Icons.play_circle_outline),
                  onTap: left > Duration.zero
                      ? null
                      : () async {
                          final bool earned = await ads.watchToHideAds();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                earned
                                    ? 'Ads hidden for 1 hour'
                                    : 'Ad not ready yet. Try again in a moment.',
                              ),
                            ),
                          );
                        },
                );
              },
            ),
          ),
          SectionLabel(l10n.about),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.info_outline, color: p.primary),
                  title: Text(l10n.aboutThisApp),
                  subtitle: Text(
                    '${AppConfig.appName} v${AppConfig.appVersion}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(Routes.about),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: p.primary),
                  title: Text(l10n.privacyPolicy),
                  subtitle: Text(
                    l10n.privacyPolicySub,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () { openPrivacyPolicy(); },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.restart_alt, color: p.down),
                  title: Text(
                    l10n.resetAll,
                    style: TextStyle(color: p.down),
                  ),
                  subtitle: Text(
                    l10n.resetAllSub,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(l10n.resetEverything),
                        content: Text(l10n.resetEverythingBody),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: Text(l10n.reset),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await settings.resetAll();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.settingsReset)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
