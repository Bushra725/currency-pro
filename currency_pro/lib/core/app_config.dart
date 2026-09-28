/// Central place for every remote endpoint and tunable constant.
///
/// All providers used by default are free and require **no API key**, so the
/// app works the moment you install it. If you later buy a paid plan, drop the
/// key into [exchangeRateApiKey] / [metalsApiKey] and the repository will
/// automatically prefer the keyed endpoints.
class AppConfig {
  const AppConfig._();

  static const String appName = 'CurrencyPro';
  static const String appVersion = '1.6.0';
  static const String supportEmail = 'app@theoccess.com';
  static const String githubRepo = 'https://github.com/theoccess/currency-pro';
  static const String privacyPolicyUrl =
      'https://sites.google.com/view/mob-apps-inc/privacy-policy';

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

  /// Community market table — updated frequently, 200+ codes including metals.
  static const String fawazLatest =
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/usd.min.json';
  static const String fawazPagesLatest =
      'https://latest.currency-api.pages.dev/v1/currencies/usd.min.json';

  /// Coinbase mid-market majors, refreshed continuously while online.
  static const String coinbaseUsdRates =
      'https://api.coinbase.com/v2/exchange-rates?currency=USD';

  /// Yahoo Finance USD crosses — same mid-market feed Google Finance uses.
  static const List<String> yahooUsdMajors = <String>[
    'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'PKR', 'AED', 'SAR', 'CAD', 'AUD',
    'CHF', 'TRY', 'KRW', 'BRL', 'MXN', 'ZAR', 'THB', 'MYR', 'SGD', 'NZD',
    'HKD', 'PHP', 'IDR', 'VND', 'EGP', 'BDT', 'NGN', 'KWD', 'QAR', 'OMR',
    'RUB', 'PLN', 'SEK', 'NOK', 'DKK', 'HUF', 'CZK', 'ILS', 'CLP', 'ARS',
  ];

  static String yahooUsdQuoteUrl() {
    final String symbols =
        yahooUsdMajors.map((String code) => 'USD$code=X').join(',');
    return 'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$symbols';
  }

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

  /// How often the in-app timer pulls a new live table while the app is open.
  static const Duration rateFreshness = Duration(minutes: 5);

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

  // ---------------------------------------------------------------------
  // Ads (AdMob)
  // ---------------------------------------------------------------------
  //
  // Production units from AdMob app ca-app-pub-9297250663056879~6205423802.
  // google-services.json (package com.mai.calculator.currency.converter.app)
  // is applied by the Google Services Gradle plugin.

  static const String androidAdMobAppId =
      'ca-app-pub-9297250663056879~6205423802';
  static const String iosAdMobAppId =
      'ca-app-pub-3940256099942544~1458002511';

  static const String androidBannerAdUnitId =
      'ca-app-pub-9297250663056879/1893298457';
  static const String iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2435281174';

  static const String androidInterstitialAdUnitId =
      'ca-app-pub-9297250663056879/4421628563';
  static const String iosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  static const String androidRewardedAdUnitId =
      'ca-app-pub-9297250663056879/9482383550';
  static const String iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String androidRewardedInterstitialAdUnitId =
      'ca-app-pub-9297250663056879/8561640933';
  static const String iosRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/6978759866';

  static const String androidNativeAdUnitId =
      'ca-app-pub-9297250663056879/6411413373';
  static const String iosNativeAdUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  static const String androidAppOpenAdUnitId =
      'ca-app-pub-9297250663056879/6954053441';
  static const String iosAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/5575463023';

  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';
  static const String testNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String testAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const List<String> adMobTestDeviceIds = <String>[
    '74DFDA033802094C51DF4784538EFD9E',
    '1B5C6FC753A164B061651D9B83735417',
  ];

  /// Reserved height of the bottom banner slot, in logical pixels.
  static const double bannerAdSlotHeight = 50;

  /// How long a rewarded video hides ads.
  static const Duration rewardedAdFree = Duration(hours: 1);

  /// Minimum gap between full-screen ads (Play / AdMob policy).
  static const Duration interstitialGap = Duration(seconds: 80);

  /// Minimum gap between app-open ads.
  static const Duration appOpenGap = Duration(minutes: 30);
}
