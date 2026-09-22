/// Central place for every remote endpoint and tunable constant.
///
/// All providers used by default are free and require **no API key**, so the
/// app works the moment you install it. If you later buy a paid plan, drop the
/// key into [exchangeRateApiKey] / [metalsApiKey] and the repository will
/// automatically prefer the keyed endpoints.
class AppConfig {
  const AppConfig._();

  static const String appName = 'CurrencyPro';
  static const String appVersion = '1.0.1';
  static const String supportEmail = 'app@theoccess.com';
  static const String githubRepo = 'https://github.com/theoccess/currency-pro';

  // ---------------------------------------------------------------------
  // Live exchange rates
  // ---------------------------------------------------------------------

  /// Primary provider — open.er-api.com. Free, no key, 160+ currencies.
  /// Response: { result, base_code, time_last_update_unix, rates: {...} }
  static const String erApiBase = 'https://open.er-api.com/v6/latest';

  /// Optional: https://v6.exchangerate-api.com with a personal key.
  /// Leave empty to stay on the free open endpoint.
  static const String exchangeRateApiKey = '';

  static String erApiUrl(String base) {
    if (exchangeRateApiKey.isEmpty) return '$erApiBase/$base';
    return 'https://v6.exchangerate-api.com/v6/$exchangeRateApiKey/latest/$base';
  }

  /// Secondary provider — European Central Bank reference rates.
  /// Fewer currencies, but a completely independent source, so it is used
  /// as an automatic fallback and for historical charts.
  static const String frankfurterBase = 'https://api.frankfurter.dev/v1';
  static const String frankfurterAppBase = 'https://api.frankfurter.app';

  /// Community CDN mirror used as a last-resort fiat fallback.
  static const String fawazLatest =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json';

  static String frankfurterLatest(String base) =>
      '$frankfurterBase/latest?base=$base';

  static String frankfurterSeries(
    String from,
    String to,
    DateTime start,
    DateTime end,
  ) {
    String d(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-'
        '${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';
    return '$frankfurterBase/${d(start)}..${d(end)}?base=$from&symbols=$to';
  }

  // ---------------------------------------------------------------------
  // Crypto and precious metals
  // ---------------------------------------------------------------------

  /// CoinGecko public API — free, no key, generous rate limit.
  static const String coinGeckoBase = 'https://api.coingecko.com/api/v3';

  /// Maps an asset ticker used inside the app to a CoinGecko coin id.
  ///
  /// PAXG and KAG are fully backed tokens that track one troy ounce of gold
  /// and silver respectively, which makes them a reliable free proxy for the
  /// XAU / XAG spot price.
  static const Map<String, String> coinGeckoIds = <String, String>{
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'USDT': 'tether',
    'BNB': 'binancecoin',
    'SOL': 'solana',
    'XRP': 'ripple',
    'XAU': 'pax-gold',
    'XAG': 'kinesis-silver',
  };

  static String coinGeckoPrices(Iterable<String> ids) =>
      '$coinGeckoBase/simple/price?ids=${ids.join(',')}&vs_currencies=usd'
      '&include_24hr_change=true';

  static String coinGeckoChart(String id, int days) =>
      '$coinGeckoBase/coins/$id/market_chart?vs_currency=usd&days=$days'
      '&interval=daily';

  /// Optional metals-api.com / goldapi.io key for XPT and XPD spot prices.
  static const String metalsApiKey = '';

  // ---------------------------------------------------------------------
  // Behaviour
  // ---------------------------------------------------------------------

  /// How long a cached snapshot is considered fresh enough to skip a refetch.
  static const Duration rateFreshness = Duration(minutes: 15);

  /// Network timeout for a single request.
  static const Duration requestTimeout = Duration(seconds: 20);

  /// Codes shown on the dashboard card.
  static const List<String> dashboardAssets = <String>['USD', 'BTC', 'XAU', 'XAG'];

  /// Currencies a fresh install starts with in the multi-converter.
  static const List<String> defaultMultiSet = <String>[
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'INR',
    'PKR',
    'AED',
    'CNY',
  ];
}
