import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ads/native_ad_card.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../core/widgets/rate_app_bar.dart';
import '../../core/widgets/section_card.dart';
import '../../data/currency_catalog.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../routes.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';
import 'currency_picker.dart';

/// "1 USD = …" for every currency the app knows about.
class RateListPage extends StatefulWidget {
  const RateListPage({super.key});

  @override
  State<RateListPage> createState() => _RateListPageState();
}

class _RateListPageState extends State<RateListPage> {
  final TextEditingController _amount = TextEditingController(text: '1');
  final TextEditingController _search = TextEditingController();
  bool _favoritesOnly = false;
  double _baseAmount = 1;

  @override
  void dispose() {
    _amount.dispose();
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    setState(() => _baseAmount = Fmt.parse(_amount.text) ?? 1);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final Currency base = CurrencyLookup.of(settings.baseCode);

    List<Currency> pool = _favoritesOnly
        ? settings.favorites.map(CurrencyLookup.of).toList()
        : kAllCurrencies;
    pool = CurrencyLookup.search(_search.text, source: pool)
        .where((Currency c) => c.code != base.code && rates.has(c.code))
        .toList();

    return Scaffold(
      drawer: const AppDrawer(current: Routes.rateList),
      appBar: RateAppBar(
        title: 'Exchange Rate List',
        actions: <Widget>[
          IconButton(
            tooltip: _favoritesOnly ? 'Show all' : 'Favorites only',
            icon: Icon(
              _favoritesOnly ? Icons.star : Icons.star_border,
              size: 20,
              color: _favoritesOnly ? p.primary : null,
            ),
            onPressed: () =>
                setState(() => _favoritesOnly = !_favoritesOnly),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineBanner(),
          SectionCard(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: p.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              FlagAvatar(base, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${base.code} — ${base.name}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.expand_more,
                                  size: 18, color: p.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const FieldLabel('Base amount', width: 104),
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        onSubmitted: (_) => _apply(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _apply,
                      child: const Text('APPLY'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Filter currencies',
                prefixIcon: Icon(Icons.search, size: 19),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlagAvatar(base, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${Fmt.smart(_baseAmount)} ${base.code} (${base.name})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_downward, size: 14, color: p.primary),
              ],
            ),
          ),
          Expanded(
            child: pool.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Nothing to show',
                    message: 'Try a different filter, or refresh the rates.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: pool.length + (pool.length >= 4 ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      const int adAt = 3;
                      if (pool.length >= 4 && index == adAt) {
                        return const NativeAdCard();
                      }
                      final int dataIndex =
                          pool.length >= 4 && index > adAt ? index - 1 : index;
                      final Currency c = pool[dataIndex];
                      final double? value =
                          rates.convert(_baseAmount, base.code, c.code);
                      final bool fav = settings.isFavorite(c.code);

                      // Spaced cards instead of a rule under every name.
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => settings.setPair(
                              from: base.code,
                              to: c.code,
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 9, 4, 9),
                              child: Row(
                                children: <Widget>[
                                  FlagAvatar(c, size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          c.code,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: p.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          c.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: p.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    value == null
                                        ? '—'
                                        : Fmt.smart(value, maxDecimals: 6),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: p.primary,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      fav
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 19,
                                      color: fav ? p.primary : p.textSecondary,
                                    ),
                                    onPressed: () =>
                                        settings.toggleFavorite(c.code),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
