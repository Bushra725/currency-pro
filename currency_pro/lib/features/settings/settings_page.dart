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
import '../../core/widgets/app_dropdown.dart';
import '../../core/widgets/screen_title.dart';
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
      appBar: AppBar(title: ScreenTitle(l10n.appSettings.toUpperCase())),
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
                    l10n.exampleValue(settings.format(1234.56789)),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: AppDropdown<int>(
                    value: settings.decimals,
                    entries: List<AppDropdownEntry<int>>.generate(
                      7,
                      (int i) => AppDropdownEntry<int>(
                        value: i,
                        label: '$i',
                      ),
                    ),
                    onChanged: settings.setDecimals,
                  ),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.swap_vert_circle_outlined,
                      color: p.primary),
                  title: Text(l10n.roundingMode),
                  subtitle: Text(
                    _roundingLabel(l10n, settings.rounding),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () async {
                    final RoundingMode? picked =
                        await showModalBottomSheet<RoundingMode>(
                      context: context,
                      builder: (BuildContext sheetContext) {
                        final L10n sheetL10n = L10n.read(sheetContext);
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: RoundingMode.values
                                .map((RoundingMode m) => ListTile(
                                      title: Text(
                                        _roundingLabel(sheetL10n, m),
                                      ),
                                      trailing: m == settings.rounding
                                          ? Icon(Icons.check,
                                              color: p.primary)
                                          : null,
                                      onTap: () =>
                                          Navigator.of(sheetContext).pop(m),
                                    ))
                                .toList(),
                          ),
                        );
                      },
                    );
                    if (picked != null) await settings.setRounding(picked);
                  },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.format_list_numbered,
                      color: p.primary),
                  title: Text(l10n.thousandsSeparator),
                  subtitle: Text(
                    l10n.thousandsSeparatorSub,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  value: settings.grouping,
                  onChanged: settings.setGrouping,
                ),
              ],
            ),
          ),
          SectionLabel(l10n.keypad),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  secondary: Icon(Icons.vibration, color: p.primary),
                  title: Text(l10n.vibrateOnKey),
                  value: settings.vibrate,
                  onChanged: (bool v) {
                    settings.setVibrate(v);
                    if (v) Haptics.tap(vibrate: true, sound: false);
                  },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.volume_up_outlined, color: p.primary),
                  title: Text(l10n.typingSound),
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
                  title: Text(l10n.defaultBankSpread),
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
          SectionLabel(l10n.ads),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Builder(
              builder: (BuildContext context) {
                final AdsService ads = context.watch<AdsService>();
                final Duration left = ads.adsFreeRemaining;
                final String subtitle = left > Duration.zero
                    ? l10n.adsHiddenFor('${left.inMinutes}')
                    : l10n.adsWatchToHide;
                return ListTile(
                  leading: Icon(Icons.ondemand_video_outlined, color: p.primary),
                  title: Text(
                    left > Duration.zero ? l10n.adsPaused : l10n.hideAdsHour,
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
                                    ? L10n.read(context).adsHiddenHour
                                    : L10n.read(context).adNotReady,
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

String _roundingLabel(L10n l10n, RoundingMode mode) {
  switch (mode) {
    case RoundingMode.halfUp:
      return l10n.roundHalfUp;
    case RoundingMode.down:
      return l10n.roundAlwaysDown;
    case RoundingMode.up:
      return l10n.roundAlwaysUp;
  }
}
