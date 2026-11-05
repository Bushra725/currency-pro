import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/flag_avatar.dart';
import '../../data/currency_catalog.dart';
import '../../data/currency_lookup.dart';
import '../../data/models/currency.dart';
import '../../state/rates_provider.dart';
import '../../state/settings_provider.dart';

/// Searchable currency chooser, opened as a bottom sheet.
///
/// ```dart
/// final Currency? picked = await CurrencyPicker.show(context);
/// ```
class CurrencyPicker extends StatefulWidget {
  const CurrencyPicker({
    super.key,
    this.title = 'Select currency',
    this.exclude = const <String>[],
    this.initialTab = CurrencyPickerTab.all,
  });

  final String title;
  final List<String> exclude;
  final CurrencyPickerTab initialTab;

  static Future<Currency?> show(
    BuildContext context, {
    String title = 'Select currency',
    List<String> exclude = const <String>[],
    CurrencyPickerTab initialTab = CurrencyPickerTab.all,
  }) {
    return showModalBottomSheet<Currency>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (_) => CurrencyPicker(
        title: title,
        exclude: exclude,
        initialTab: initialTab,
      ),
    );
  }

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

enum CurrencyPickerTab { all, favorites, metals, crypto }

class _CurrencyPickerState extends State<CurrencyPicker> {
  final TextEditingController _search = TextEditingController();
  CurrencyPickerTab _tab = CurrencyPickerTab.all;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Currency> _pool(SettingsProvider settings) {
    switch (_tab) {
      case CurrencyPickerTab.all:
        return kAllCurrencies;
      case CurrencyPickerTab.favorites:
        return settings.favorites.map(CurrencyLookup.of).toList();
      case CurrencyPickerTab.metals:
        return CurrencyLookup.metals;
      case CurrencyPickerTab.crypto:
        return CurrencyLookup.crypto;
    }
  }

  void _select(Currency currency) {
    Navigator.of(context).pop(currency);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final L10n l10n = L10n.of(context);
    final String title = widget.title == 'Select currency'
        ? l10n.selectCurrency
        : widget.title;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();
    final double height = MediaQuery.sizeOf(context).height * 0.88;

    final List<Currency> results = CurrencyLookup
        .search(_search.text, source: _pool(settings))
        .where((Currency c) => !widget.exclude.contains(c.code))
        .toList();

    return SizedBox(
      height: height,
      child: Material(
        color: p.background,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.searchCurrencyHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  _chip(p, l10n.tabAll, CurrencyPickerTab.all),
                  _chip(p, l10n.tabFavorites, CurrencyPickerTab.favorites),
                  _chip(p, l10n.tabMetals, CurrencyPickerTab.metals),
                  _chip(p, l10n.tabCrypto, CurrencyPickerTab.crypto),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noCurrencyMatch(_search.text),
                        style: TextStyle(color: p.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Currency c = results[index];
                        final double? rate =
                            rates.pairRate(settings.baseCode, c.code);
                        final bool fav = settings.isFavorite(c.code);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              key: Key('currency-pick-${c.code}'),
                              onTap: () => _select(c),
                              leading: FlagAvatar(c, size: 24),
                              title: Text(
                                c.code,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: p.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.textSecondary,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (rate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        Fmt.smart(rate, maxDecimals: 6),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: p.textSecondary,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      fav
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 20,
                                      color: fav ? p.primary : p.textSecondary,
                                    ),
                                    onPressed: () =>
                                        settings.toggleFavorite(c.code),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(AppPalette p, String label, CurrencyPickerTab tab) {
    final bool selected = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _tab = tab),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? p.onPrimary : p.textPrimary,
        ),
        showCheckmark: false,
      ),
    );
  }
}
