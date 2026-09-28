import 'currency_catalog.dart';
import 'models/currency.dart';

/// Fast lookups over [kAllCurrencies].
class CurrencyLookup {
  const CurrencyLookup._();

  static final Map<String, Currency> _byCode = <String, Currency>{
    for (final Currency c in kAllCurrencies) c.code: c,
  };

  /// Never returns null — unknown codes get a neutral placeholder so the UI
  /// can still render a row if a provider sends something unexpected.
  static Currency of(String code) {
    final String upper = code.toUpperCase();
    return _byCode[upper] ??
        Currency(
          code: upper,
          name: upper,
          country: '',
          iso2: '',
          symbol: '',
          decimals: 2,
          subunit: '—',
          kind: CurrencyKind.fiat,
        );
  }

  static bool exists(String code) => _byCode.containsKey(code.toUpperCase());

  static List<Currency> get fiat =>
      kAllCurrencies.where((Currency c) => c.isFiat).toList();

  static List<Currency> get metals =>
      kAllCurrencies.where((Currency c) => c.isMetal).toList();

  static List<Currency> get crypto =>
      kAllCurrencies.where((Currency c) => c.isCrypto).toList();

  /// Case-insensitive search over code, name and country.
  static List<Currency> search(String query, {List<Currency>? source}) {
    final List<Currency> pool = source ?? kAllCurrencies;
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return pool;
    final List<Currency> starts = <Currency>[];
    final List<Currency> contains = <Currency>[];
    for (final Currency c in pool) {
      if (c.code.toLowerCase().startsWith(q)) {
        starts.add(c);
      } else if (c.searchIndex.contains(q)) {
        contains.add(c);
      }
    }
    return <Currency>[...starts, ...contains];
  }
}
