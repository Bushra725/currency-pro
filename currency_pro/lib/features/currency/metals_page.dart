import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../data/services/prefs_service.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import 'currency_picker.dart';

/// Dollar, Bitcoin, Gold and Silver — prices, cross rates and holdings.
class MetalsPage extends StatefulWidget {
  const MetalsPage({super.key});

  @override
  State<MetalsPage> createState() => _MetalsPageState();
}

class _MetalsPageState extends State<MetalsPage>
    with SingleTickerProviderStateMixin {
  static const String _assetsKey = 'my_assets';

  /// Weight units offered for the metal cards, expressed in grams.
  static const Map<String, double> _weightUnits = <String, double>{
    'oz t': 31.1034768,
    'g': 1,
    'kg': 1000,
    'tola': 11.6638,
  };

  late final TabController _tabs = TabController(length: 3, vsync: this);
  String _unit = 'oz t';
  Map<String, double> _holdings = <String, double>{};

  @override
  void initState() {
    super.initState();
    final PrefsService prefs = context.read<PrefsService>();
    final String? raw = prefs.getString(_assetsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        _holdings = decoded.map(
          (String k, dynamic v) =>
              MapEntry<String, double>(k, (v as num).toDouble()),
        );
      } catch (_) {
        _holdings = <String, double>{};
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _saveHoldings() async {
    await context.read<PrefsService>().setString(
          _assetsKey,
          jsonEncode(_holdings),
        );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      drawer: const AppDrawer(current: Routes.assets),
      appBar: RateAppBar(title: 'Dollar, Bitcoin, Gold, Silver'),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: p.onPrimary,
              unselectedLabelColor: p.textSecondary,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: p.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              tabs: const <Widget>[
                Tab(height: 38, text: 'Price'),
                Tab(height: 38, text: 'Cross Rate'),
                Tab(height: 38, text: 'My Assets'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _priceTab(p),
                _crossTab(p),
                _assetsTab(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Price --------------------------------------------------------------

  Widget _priceTab(AppPalette p) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final Currency base = CurrencyLookup.of(settings.baseCode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: <Widget>[
        SectionCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const FieldLabel('Base Currency', width: 104),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final Currency? picked = await CurrencyPicker.show(
                          context,
                          title: 'Base currency',
                        );
                        if (picked != null) {
                          await settings.setBaseCode(picked.code);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          FlagAvatar(base, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            base.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          Icon(Icons.expand_more,
                              size: 18, color: p.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const FieldLabel('Metal unit', width: 104),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: _unit,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(12),
                        items: _weightUnits.keys
                            .map((String u) => DropdownMenuItem<String>(
                                  value: u,
                                  child: Text(u),
                                ))
                            .toList(),
                        onChanged: (String? v) =>
                            setState(() => _unit = v ?? 'oz t'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...<String>['USD', 'BTC', 'XAU', 'XAG', 'ETH']
            .map((String code) => _assetCard(p, settings, rates, base, code)),
      ],
    );
  }

  Widget _assetCard(
    AppPalette p,
    SettingsProvider settings,
    RatesProvider rates,
    Currency base,
    String code,
  ) {
    final Currency asset = CurrencyLookup.of(code);
    final double? perUnitInBase = rates.convert(1, code, base.code);
    final double? change = rates.assetChange24h(code);

    // Metals are quoted per troy ounce; convert to the chosen weight unit.
    double? shown = perUnitInBase;
    if (asset.isMetal && perUnitInBase != null) {
      final double grams = _weightUnits[_unit] ?? 31.1034768;
      shown = perUnitInBase / 31.1034768 * grams;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Row(
          children: <Widget>[
            FlagAvatar(asset, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        asset.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        asset.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.isMetal
                        ? 'Price per $_unit'
                        : '1 ${asset.code} =',
                    style: TextStyle(fontSize: 10.5, color: p.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shown == null
                        ? 'unavailable'
                        : '${settings.format(shown, decimals: shown < 10 ? 4 : 2)} '
                            '${base.code}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: p.primary,
                    ),
                  ),
                  if (change != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            change >= 0
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            size: 17,
                            color: change >= 0 ? p.up : p.down,
                          ),
                          Text(
                            '${Fmt.percent(change, decimals: 2)} · 24h',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: change >= 0 ? p.up : p.down,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (asset.isMetal && shown != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Spot source: tokenised metal quote (1 token = 1 troy oz)',
                        style:
                            TextStyle(fontSize: 9.5, color: p.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Cross rate ---------------------------------------------------------

  Widget _crossTab(AppPalette p) {
    final RatesProvider rates = context.watch<RatesProvider>();
    const List<String> codes = <String>['USD', 'EUR', 'BTC', 'XAU', 'XAG'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: SectionCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: 52),
                ...codes.map(
                  (String c) => Expanded(
                    child: Text(
                      c,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...codes.map((String row) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: p.outline.withOpacity(0.6)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 52,
                      child: Text(
                        row,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: p.primary,
                        ),
                      ),
                    ),
                    ...codes.map((String col) {
                      final double? value = rates.pairRate(row, col);
                      return Expanded(
                        child: Text(
                          row == col
                              ? '1'
                              : (value == null
                                  ? '—'
                                  : Fmt.smart(value, maxDecimals: 6)),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: row == col
                                ? p.textSecondary
                                : p.textPrimary,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // -- My assets ----------------------------------------------------------

  Widget _assetsTab(AppPalette p) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final Currency base = CurrencyLookup.of(settings.baseCode);

    double total = 0;
    _holdings.forEach((String code, double qty) {
      final double? value = rates.convert(qty, code, base.code);
      if (value != null) total += value;
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        SectionCard(
          color: p.primary.withOpacity(0.12),
          borderColor: p.primary.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Portfolio value',
                style: TextStyle(fontSize: 11.5, color: p.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '${settings.format(total)} ${base.code}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: p.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_holdings.isEmpty)
          const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No holdings yet',
            message: 'Add the currencies, coins or metals you own to track '
                'their combined value.',
          )
        else
          ..._holdings.entries.map((MapEntry<String, double> entry) {
            final Currency c = CurrencyLookup.of(entry.key);
            final double? value =
                rates.convert(entry.value, entry.key, base.code);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SectionCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    FlagAvatar(c, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${Fmt.smart(entry.value)} ${c.code}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.textPrimary,
                            ),
                          ),
                          Text(
                            c.name,
                            style: TextStyle(
                                fontSize: 10.5, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      value == null
                          ? '—'
                          : '${settings.format(value)} ${base.code}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: p.textSecondary),
                      onPressed: () {
                        setState(() => _holdings.remove(entry.key));
                        _saveHoldings();
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addHolding,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('ADD HOLDING'),
        ),
      ],
    );
  }

  Future<void> _addHolding() async {
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: 'What do you hold?',
    );
    if (picked == null || !mounted) return;

    final TextEditingController controller = TextEditingController(
      text: _holdings[picked.code]?.toString() ?? '',
    );

    final double? qty = await showDialog<double>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Amount of ${picked.code}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: picked.isMetal ? 'Troy ounces' : 'Quantity',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(Fmt.parse(controller.text)),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (qty == null) return;
    setState(() {
      if (qty <= 0) {
        _holdings.remove(picked.code);
      } else {
        _holdings[picked.code] = qty;
      }
    });
    await _saveHoldings();
  }
}
