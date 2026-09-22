import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final RatesProvider rates = context.watch<RatesProvider>();

    final List<Currency> results = CurrencyLookup
        .search(_search.text, source: _pool(settings))
        .where((Currency c) => !widget.exclude.contains(c.code))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
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
                      widget.title,
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
                  hintText: 'Search code, name or country',
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
                  _chip(p, 'All', CurrencyPickerTab.all),
                  _chip(p, 'Favorites', CurrencyPickerTab.favorites),
                  _chip(p, 'Metals', CurrencyPickerTab.metals),
                  _chip(p, 'Crypto', CurrencyPickerTab.crypto),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: p.outline),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No match for "${_search.text}"',
                        style: TextStyle(color: p.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: p.outline.withOpacity(0.5)),
                      itemBuilder: (BuildContext context, int index) {
                        final Currency c = results[index];
                        final double? rate =
                            rates.pairRate(settings.baseCode, c.code);
                        final bool fav = settings.isFavorite(c.code);

                        return ListTile(
                          dense: true,
                          leading: FlagAvatar(c, size: 24),
                          title: Text(
                            c.code,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                                Text(
                                  Fmt.smart(rate, maxDecimals: 6),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.textSecondary,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  fav ? Icons.star : Icons.star_border,
                                  size: 19,
                                  color: fav ? p.primary : p.textSecondary,
                                ),
                                onPressed: () =>
                                    settings.toggleFavorite(c.code),
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        );
      },
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
