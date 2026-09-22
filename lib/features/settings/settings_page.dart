import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
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
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final Currency base = CurrencyLookup.of(settings.baseCode);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.settings),
      appBar: AppBar(title: const Text('APP SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 28),
        children: <Widget>[
          SectionLabel('Rate source'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.dns_outlined, color: p.primary),
                  title: const Text('Currency information server'),
                  subtitle: Text(
                    rates.hasData
                        ? '${rates.provider} · updated '
                            '${Fmt.ago(rates.snapshot.fetchedAt)}'
                        : 'No data downloaded yet',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: TextButton(
                    onPressed: () => rates.refresh(),
                    child: const Text('UPDATE'),
                  ),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: p.primary),
                  title: const Text('Base currency'),
                  subtitle: Text(
                    '${base.code} — ${base.name}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  onTap: () async {
                    final Currency? picked =
                        await CurrencyPicker.show(context,
                            title: 'Base currency');
                    if (picked != null) {
                      await settings.setBaseCode(picked.code);
                    }
                  },
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.autorenew, color: p.primary),
                  title: const Text('Auto-refresh while open'),
                  subtitle: const Text(
                    'Downloads new rates every 15 minutes',
                    style: TextStyle(fontSize: 11.5),
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
          SectionLabel('Number format'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.numbers, color: p.primary),
                  title: const Text('Decimal places'),
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
                  onChanged: settings.setVibrate,
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                SwitchListTile(
                  secondary: Icon(Icons.volume_up_outlined, color: p.primary),
                  title: const Text('Typing sound'),
                  value: settings.keySound,
                  onChanged: settings.setKeySound,
                ),
              ],
            ),
          ),
          SectionLabel('Appearance'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.palette_outlined, color: p.primary),
              title: const Text('Select theme'),
              subtitle: Text(
                '${settings.palette.city} — ${settings.palette.name}',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(Routes.theme),
            ),
          ),
          SectionLabel('Defaults'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.restaurant_outlined, color: p.primary),
                  title: const Text('Default tip rate'),
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
          SectionLabel('About'),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.info_outline, color: p.primary),
                  title: const Text('About this app'),
                  subtitle: Text(
                    '${AppConfig.appName} v${AppConfig.appVersion}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(Routes.about),
                ),
                Divider(height: 1, color: p.outline.withOpacity(0.5)),
                ListTile(
                  leading: Icon(Icons.restart_alt, color: p.down),
                  title: Text(
                    'Reset all settings',
                    style: TextStyle(color: p.down),
                  ),
                  subtitle: const Text(
                    'Clears favourites, alerts, trips and preferences',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onTap: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: const Text('Reset everything?'),
                        content: const Text(
                          'This removes your favourites, alerts, trips, '
                          'holdings and preferences from this device. '
                          'It cannot be undone.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('CANCEL'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('RESET'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await settings.resetAll();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings reset')),
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
