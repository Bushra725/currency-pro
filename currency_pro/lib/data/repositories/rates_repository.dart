import '../../core/app_config.dart';
import '../fallback_rates.dart';
import '../models/rate_snapshot.dart';
import '../services/metals_api.dart';
import '../services/prefs_service.dart';
import '../services/rates_api.dart';

/// Owns the single source of truth for exchange rates.
///
/// The app always stores rates against USD internally; every pair the user
/// asks for is derived as a cross rate. That keeps one network call per
/// refresh no matter how many currencies are on screen.
class RatesRepository {
  RatesRepository({
    required PrefsService prefs,
    RatesApi? ratesApi,
    MetalsApi? metalsApi,
  })  : _prefs = prefs,
        _ratesApi = ratesApi ?? RatesApi(),
        _metalsApi = metalsApi ?? MetalsApi() {
    _lastQuotes = AssetQuote.decodeMap(_prefs.getString(PrefsService.kAssetQuotes));
  }

  static const String internalBase = 'USD';

  final PrefsService _prefs;
  final RatesApi _ratesApi;
  final MetalsApi _metalsApi;

  Map<String, AssetQuote> _lastQuotes = <String, AssetQuote>{};

  /// Latest crypto / metal quotes from the most recent refresh.
  Map<String, AssetQuote> get quotes =>
      Map<String, AssetQuote>.unmodifiable(_lastQuotes);

  /// Reads the last successful download from disk, or the bundled table.
  RateSnapshot loadCached() {
    final cached = RateSnapshot.decode(_prefs.getString(PrefsService.kRateSnapshot));
    if (cached != null && !cached.isEmpty) {
      return cached.copyWith(isStale: true);
    }
    return FallbackRates.snapshot;
  }

  bool isFresh(RateSnapshot snapshot) =>
      !snapshot.isEmpty &&
      snapshot.provider != FallbackRates.providerName &&
      DateTime.now().difference(snapshot.fetchedAt) < AppConfig.rateFreshness;

  /// Downloads fiat rates and merges in crypto / metals.
  ///
  /// Metal and crypto failures are non-fatal: if CoinGecko is unreachable the
  /// fiat rates still come through and the dashboard shows the previous
  /// values instead of an error.
  Future<RateSnapshot> refresh() async {
    final fiat = await _ratesApi.fetchLatest(internalBase);

    Map<String, AssetQuote> quotes = <String, AssetQuote>{};
    try {
      quotes = await _metalsApi.fetchQuotes();
    } catch (_) {
      quotes = <String, AssetQuote>{};
    }

    if (AppConfig.metalsApiKey.isNotEmpty) {
      try {
        quotes = <String, AssetQuote>{
          ...quotes,
          ...await _metalsApi.fetchKeyedMetals(),
        };
      } catch (_) {
        // keep the CoinGecko values
      }
    }

    if (quotes.isNotEmpty) {
      _lastQuotes = quotes;
      await _prefs.setString(
        PrefsService.kAssetQuotes,
        AssetQuote.encodeMap(_lastQuotes),
      );
    }

    final extra = <String, double>{
      for (final AssetQuote q in _lastQuotes.values)
        if (q.priceUsd > 0) q.code: q.unitsPerUsd,
    };

    final merged = fiat.merge(extra).copyWith(
          fetchedAt: DateTime.now(),
          providerUpdatedAt: DateTime.now(),
          isStale: false,
        );
    await _prefs.setString(PrefsService.kRateSnapshot, merged.encode());
    return merged;
  }

  void dispose() {
    _ratesApi.dispose();
    _metalsApi.dispose();
  }
}
