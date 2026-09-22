/// What kind of asset a "currency" row represents.
enum CurrencyKind { fiat, metal, crypto }

/// A single convertible asset: a fiat currency, a precious metal or a coin.
class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.country,
    required this.iso2,
    required this.symbol,
    required this.decimals,
    required this.subunit,
    required this.kind,
  });

  /// ISO 4217 code, e.g. `USD`, or the ticker for metals/crypto (`XAU`, `BTC`).
  final String code;

  /// Human readable name, e.g. `U.S. Dollar`.
  final String name;

  /// Issuing country or region.
  final String country;

  /// ISO 3166-1 alpha-2 country code used to build the flag emoji.
  /// Empty for metals and crypto.
  final String iso2;

  /// Currency symbol, e.g. `$`.
  final String symbol;

  /// Default number of fraction digits used when displaying amounts.
  final int decimals;

  /// Description of the minor unit, e.g. `1/100 cent`.
  final String subunit;

  final CurrencyKind kind;

  bool get isFiat => kind == CurrencyKind.fiat;
  bool get isMetal => kind == CurrencyKind.metal;
  bool get isCrypto => kind == CurrencyKind.crypto;

  /// Regional-indicator flag emoji, or an empty string for metals/crypto.
  String get flag {
    if (iso2.length != 2) return '';
    const base = 0x1F1E6;
    final upper = iso2.toUpperCase();
    return String.fromCharCode(base + upper.codeUnitAt(0) - 65) +
        String.fromCharCode(base + upper.codeUnitAt(1) - 65);
  }

  /// Text used by the search field in the currency picker.
  String get searchIndex => '$code $name $country'.toLowerCase();

  @override
  String toString() => '$code — $name';

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
