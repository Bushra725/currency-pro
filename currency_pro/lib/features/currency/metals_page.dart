import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_dropdown.dart';
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
  static const String _pricesKey = 'price_currencies';
  static const String _crossKey = 'cross_currencies';
  static const String _crossBaseKey = 'cross_base';
  static const String _metalUnitsKey = 'metal_units';
  static const String _metalUnitKey = 'metal_unit';
  static const double _troyOzGrams = 31.1034768;

  /// Cards always shown on the Price tab. Anything else is chosen by the user.
  static const List<String> _defaultPrices = <String>[
    'USD',
    'BTC',
    'XAU',
    'XAG',
    'ETH',
  ];

  static const List<String> _defaultCross = <String>[
    'USD',
    'EUR',
    'BTC',
    'XAU',
    'XAG',
  ];

  /// Weight units offered for the metal cards, expressed in grams.
  static const Map<String, double> _weightUnits = <String, double>{
    'oz t': 31.1034768,
    'g': 1,
    'kg': 1000,
    'tola': 11.6638,
  };

  late final TabController _tabs = TabController(length: 3, vsync: this);
  String _unit = 'oz t';
  Map<String, String> _metalUnits = <String, String>{};
  Map<String, double> _holdings = <String, double>{};
  List<String> _extraPrices = <String>[];
  List<String> _extraCross = <String>[];
  String _crossBase = 'USD';

  @override
  void initState() {
    super.initState();
    final PrefsService prefs = context.read<PrefsService>();
    _extraPrices = _savedCodes(prefs.getStringList(_pricesKey), _defaultPrices);
    _extraCross = _savedCodes(prefs.getStringList(_crossKey), _defaultCross);
    final String savedBase =
        (prefs.getString(_crossBaseKey) ?? 'USD').toUpperCase();
    _crossBase = CurrencyLookup.exists(savedBase) ? savedBase : 'USD';
    final String? savedUnit = prefs.getString(_metalUnitKey);
    if (savedUnit != null && _weightUnits.containsKey(savedUnit)) {
      _unit = savedUnit;
    }
    _metalUnits = _savedMetalUnits(prefs.getString(_metalUnitsKey));
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

  List<String> _savedCodes(List<String> stored, List<String> defaults) {
    final List<String> loaded = <String>[];
    final Set<String> seen = <String>{};
    for (final String raw in stored) {
      final String code = raw.toUpperCase();
      if (!CurrencyLookup.exists(code) || defaults.contains(code)) {
        continue;
      }
      if (seen.add(code)) loaded.add(code);
    }
    return loaded;
  }

  List<String> get _priceCodes => <String>[..._defaultPrices, ..._extraPrices];

  /// Base currency first, then the built-in set, then currencies the user added.
  List<String> get _crossCodes {
    final List<String> codes = <String>[
      ..._defaultCross,
      ..._extraCross.where((String c) => !_defaultCross.contains(c)),
    ];
    if (!codes.contains(_crossBase) && CurrencyLookup.exists(_crossBase)) {
      codes.add(_crossBase);
    }
    if (codes.contains(_crossBase)) {
      codes.remove(_crossBase);
      codes.insert(0, _crossBase);
    }
    return codes;
  }

  Future<void> _savePrices() async {
    await context.read<PrefsService>().setStringList(_pricesKey, _extraPrices);
  }

  Map<String, String> _savedMetalUnits(String? raw) {
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((String code, dynamic unit) {
        final String value = unit.toString();
        return MapEntry<String, String>(
          code.toUpperCase(),
          _weightUnits.containsKey(value) ? value : 'oz t',
        );
      });
    } catch (_) {
      return <String, String>{};
    }
  }

  String _unitFor(String code) {
    final String unit = _metalUnits[code] ?? _unit;
    return _weightUnits.containsKey(unit) ? unit : 'oz t';
  }

  double _gramsOf(String unit) => _weightUnits[unit] ?? _troyOzGrams;

  /// Holdings are stored in troy ounces. Screens show the unit the user picked.
  double _fromOunces(double ounces, String unit) =>
      ounces * _troyOzGrams / _gramsOf(unit);

  double _toOunces(double amount, String unit) =>
      amount * _gramsOf(unit) / _troyOzGrams;

  List<AppDropdownEntry<String>> get _unitEntries => _weightUnits.keys
      .map((String unit) => AppDropdownEntry<String>(value: unit, label: unit))
      .toList(growable: false);

  Future<void> _saveMetalUnits() async {
    final PrefsService prefs = context.read<PrefsService>();
    await prefs.setString(_metalUnitKey, _unit);
    await prefs.setString(_metalUnitsKey, jsonEncode(_metalUnits));
  }

  /// The Price screen's unit control applies to every metal, so both screens match.
  Future<void> _setAllMetalUnits(String unit) async {
    setState(() {
      _unit = unit;
      final Map<String, String> next = <String, String>{..._metalUnits};
      for (final String code in _priceCodes) {
        if (CurrencyLookup.of(code).isMetal) next[code] = unit;
      }
      for (final String code in _holdings.keys) {
        if (CurrencyLookup.of(code).isMetal) next[code] = unit;
      }
      _metalUnits = next;
    });
    await _saveMetalUnits();
  }

  Future<void> _setMetalUnit(String code, String unit) async {
    setState(() => _metalUnits[code] = unit);
    await _saveMetalUnits();
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
    final L10n l10n = L10n.of(context);

    return Scaffold(
      drawer: const AppDrawer(current: Routes.assets),
      appBar: RateAppBar(title: l10n.metalCrypto),
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
              tabs: <Widget>[
                Tab(height: 38, text: l10n.tabPrice),
                Tab(height: 38, text: l10n.tabCross),
                Tab(height: 38, text: l10n.tabAssets),
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

  Widget _baseCurrencyRow(
    AppPalette p,
    SettingsProvider settings,
    Currency base,
    Key key,
  ) {
    final L10n l10n = L10n.of(context);
    return Row(
      children: <Widget>[
        FieldLabel(l10n.baseCurrency, width: 104),
        Expanded(
          child: InkWell(
            key: key,
            onTap: () async {
              final Currency? picked = await CurrencyPicker.show(
                context,
                title: L10n.read(context).baseCurrency,
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
                Icon(Icons.expand_more, size: 18, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -- Price --------------------------------------------------------------

  Widget _priceTab(AppPalette p) {
    final L10n l10n = L10n.of(context);
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
              _baseCurrencyRow(p, settings, base, const Key('price-base')),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  FieldLabel(l10n.metalUnit, width: 104),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppDropdown<String>(
                        key: const Key('price-metal-unit'),
                        value: _unit,
                        entries: _unitEntries,
                        onChanged: _setAllMetalUnits,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._priceCodes.map(
          (String code) => _assetCard(
            p,
            settings,
            rates,
            base,
            code,
            onRemove: _defaultPrices.contains(code)
                ? null
                : () => _removePriceCurrency(code),
          ),
        ),
        OutlinedButton.icon(
          key: const Key('price-add-currency'),
          onPressed: _addPriceCurrency,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addCurrency),
        ),
      ],
    );
  }

  Future<void> _addPriceCurrency() async {
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: L10n.read(context).selectCurrency,
      exclude: _priceCodes,
    );
    if (picked == null || !mounted) return;
    if (_priceCodes.contains(picked.code)) return;
    setState(() => _extraPrices.add(picked.code));
    await _savePrices();
  }

  Future<void> _removePriceCurrency(String code) async {
    setState(() => _extraPrices.remove(code));
    await _savePrices();
  }

  Widget _assetCard(
    AppPalette p,
    SettingsProvider settings,
    RatesProvider rates,
    Currency base,
    String code, {
    VoidCallback? onRemove,
  }) {
    final L10n l10n = L10n.of(context);
    final Currency asset = CurrencyLookup.of(code);
    final double? perUnitInBase = rates.convert(1, code, base.code);
    final double? change = rates.assetChange24h(code);
    final String unit = _unitFor(code);

    // Metals are quoted per troy ounce; convert to this metal's weight unit.
    double? shown = perUnitInBase;
    if (asset.isMetal && perUnitInBase != null) {
      shown = perUnitInBase / _troyOzGrams * _gramsOf(unit);
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
                      if (onRemove != null)
                        IconButton(
                          tooltip: asset.code,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: Icon(Icons.close, size: 16, color: p.textSecondary),
                          onPressed: onRemove,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.isMetal
                        ? l10n.pricePer(unit)
                        : l10n.oneCode(asset.code),
                    style: TextStyle(fontSize: 10.5, color: p.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shown == null
                        ? l10n.unavailable
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
                            '${Fmt.percent(change, decimals: 2)} · ${l10n.window24h}',
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
                        l10n.spotSource,
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

  Future<void> _pickCrossBase() async {
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: L10n.read(context).baseCurrency,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _crossBase = picked.code;
      if (!_defaultCross.contains(picked.code) &&
          !_extraCross.contains(picked.code)) {
        _extraCross.add(picked.code);
      }
    });
    final PrefsService prefs = context.read<PrefsService>();
    await prefs.setString(_crossBaseKey, _crossBase);
    await prefs.setStringList(_crossKey, _extraCross);
  }

  Future<void> _addCrossCurrency() async {
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: L10n.read(context).selectCurrency,
      exclude: _crossCodes,
    );
    if (picked == null || !mounted) return;
    if (_crossCodes.contains(picked.code)) return;
    setState(() => _extraCross.add(picked.code));
    await context.read<PrefsService>().setStringList(_crossKey, _extraCross);
  }

  Future<void> _removeCrossCurrency(String code) async {
    setState(() {
      _extraCross.remove(code);
      if (_crossBase == code) _crossBase = 'USD';
    });
    final PrefsService prefs = context.read<PrefsService>();
    await prefs.setStringList(_crossKey, _extraCross);
    await prefs.setString(_crossBaseKey, _crossBase);
  }

  Widget _crossTab(AppPalette p) {
    final L10n l10n = L10n.of(context);
    final RatesProvider rates = context.watch<RatesProvider>();
    final List<String> codes = _crossCodes;
    final Currency base = CurrencyLookup.of(_crossBase);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        SectionCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              FieldLabel(l10n.baseCurrency, width: 104),
              Expanded(
                child: InkWell(
                  key: const Key('cross-base'),
                  onTap: _pickCrossBase,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FlagAvatar(base, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          base.code,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.expand_more, size: 18, color: p.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _tableHeading(p, l10n.tabCross),
        SectionCard(
          padding: const EdgeInsets.all(10),
          child: _crossMatrix(p, rates, codes),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('cross-add-currency'),
          onPressed: _addCrossCurrency,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addCurrency),
        ),
        const SizedBox(height: 16),
        _tableHeading(p, l10n.keyPoints),
        SectionCard(
          padding: const EdgeInsets.all(10),
          child: _keyPointsTable(p, l10n, rates, codes),
        ),
      ],
    );
  }

  Widget _tableHeading(AppPalette p, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
        ),
      ),
    );
  }

  Widget _crossMatrix(AppPalette p, RatesProvider rates, List<String> codes) {
    const double labelWidth = 72;
    const double colWidth = 68;
    const double rowHeight = 36;

    TextStyle head(Color color) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Column(
            children: <Widget>[
              const SizedBox(height: rowHeight),
              for (final String row in codes)
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          row,
                          key: ValueKey<String>('cross-row-$row'),
                          overflow: TextOverflow.ellipsis,
                          style: head(p.primary),
                        ),
                      ),
                      if (_extraCross.contains(row))
                        GestureDetector(
                          key: ValueKey<String>('cross-remove-$row'),
                          onTap: () => _removeCrossCurrency(row),
                          child: Icon(Icons.close, size: 14, color: p.textSecondary),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    for (final String code in codes)
                      SizedBox(
                        width: colWidth,
                        height: rowHeight,
                        child: Center(
                          child: Text(code, style: head(p.textSecondary)),
                        ),
                      ),
                  ],
                ),
                for (final String row in codes)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: p.outline.withOpacity(0.6)),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        for (final String col in codes)
                          SizedBox(
                            width: colWidth,
                            height: rowHeight,
                            child: Center(
                              child: Text(
                                _crossCell(rates, row, col),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: row == col
                                      ? p.textSecondary
                                      : p.textPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _crossCell(RatesProvider rates, String row, String col) {
    if (row == col) return '1';
    final double? value = rates.pairRate(row, col);
    if (value == null) return '—';
    return Fmt.smart(value, maxDecimals: 4);
  }

  Widget _keyPointsTable(
    AppPalette p,
    L10n l10n,
    RatesProvider rates,
    List<String> codes,
  ) {
    final TextStyle head = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: p.textSecondary,
    );
    final List<String> others =
        codes.where((String code) => code != _crossBase).toList(growable: false);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(flex: 3, child: Text(l10n.currency, style: head)),
            Expanded(
              flex: 4,
              child: Text(
                l10n.oneCode(_crossBase),
                textAlign: TextAlign.end,
                style: head,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(l10n.colInverse, textAlign: TextAlign.end, style: head),
            ),
          ],
        ),
        for (final String code in others)
          Container(
            key: ValueKey<String>('key-point-$code'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: p.outline.withOpacity(0.6)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    _rateText(rates.pairRate(_crossBase, code)),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: p.textPrimary),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _rateText(rates.pairRate(code, _crossBase)),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 12, color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _rateText(double? value) {
    if (value == null) return '—';
    return Fmt.smart(value, maxDecimals: 4);
  }

  // -- My assets ----------------------------------------------------------

  Widget _assetsTab(AppPalette p) {
    final L10n l10n = L10n.of(context);
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
          padding: const EdgeInsets.all(12),
          child: _baseCurrencyRow(
            p,
            settings,
            base,
            const Key('assets-base'),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          color: p.primary.withOpacity(0.12),
          borderColor: p.primary.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.portfolioValue,
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
          EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.noHoldingsTitle,
            message: l10n.noHoldingsBody,
          )
        else
          ..._holdings.entries.map((MapEntry<String, double> entry) {
            final Currency c = CurrencyLookup.of(entry.key);
            final double? value =
                rates.convert(entry.value, entry.key, base.code);
            final String unit = _unitFor(c.code);
            final double shownQty =
                c.isMetal ? _fromOunces(entry.value, unit) : entry.value;
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
                            '${Fmt.smart(shownQty)} ${c.isMetal ? unit : c.code}',
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
                          if (c.isMetal) ...<Widget>[
                            const SizedBox(height: 6),
                            AppDropdown<String>(
                              key: ValueKey<String>('asset-unit-${c.code}'),
                              value: unit,
                              entries: _unitEntries,
                              onChanged: (String next) =>
                                  _setMetalUnit(c.code, next),
                            ),
                          ],
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
          label: Text(l10n.addHolding),
        ),
      ],
    );
  }

  Future<void> _addHolding() async {
    final L10n l10n = L10n.read(context);
    final Currency? picked = await CurrencyPicker.show(
      context,
      title: l10n.whatDoYouHold,
    );
    if (picked == null || !mounted) return;

    final String unit = _unitFor(picked.code);
    final double? stored = _holdings[picked.code];
    final TextEditingController controller = TextEditingController(
      text: stored == null
          ? ''
          : Fmt.smart(
              picked.isMetal ? _fromOunces(stored, unit) : stored,
              grouping: false,
            ),
    );

    final double? qty = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        final L10n dialogL10n = L10n.read(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.amountOf(picked.code)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: picked.isMetal ? unit : dialogL10n.quantity,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(Fmt.parse(controller.text)),
              child: Text(dialogL10n.save),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (qty == null) return;
    final double storedQty = picked.isMetal ? _toOunces(qty, unit) : qty;
    setState(() {
      if (storedQty <= 0) {
        _holdings.remove(picked.code);
      } else {
        _holdings[picked.code] = storedQty;
      }
    });
    await _saveHoldings();
  }
}
