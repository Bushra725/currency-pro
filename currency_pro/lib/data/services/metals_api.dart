import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import 'app_http.dart';

/// Live USD price of one unit of a crypto asset or one troy ounce of a metal.
class AssetQuote {
  const AssetQuote({
    required this.code,
    required this.priceUsd,
    this.changePercent24h,
  });

  final String code;
  final double priceUsd;
  final double? changePercent24h;

  /// Price expressed the same way fiat rates are: "how much of this asset
  /// is one USD worth".
  double get unitsPerUsd => priceUsd == 0 ? 0 : 1 / priceUsd;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'priceUsd': priceUsd,
        'changePercent24h': changePercent24h,
      };

  factory AssetQuote.fromJson(Map<String, dynamic> json) => AssetQuote(
        code: json['code'] as String,
        priceUsd: (json['priceUsd'] as num).toDouble(),
        changePercent24h: (json['changePercent24h'] as num?)?.toDouble(),
      );

  static String encodeMap(Map<String, AssetQuote> quotes) => jsonEncode(
        quotes.map(
          (String k, AssetQuote v) =>
              MapEntry<String, dynamic>(k, v.toJson()),
        ),
      );

  static Map<String, AssetQuote> decodeMap(String? source) {
    if (source == null || source.isEmpty) return <String, AssetQuote>{};
    try {
      final raw = jsonDecode(source) as Map<String, dynamic>;
      return raw.map(
        (String k, dynamic v) => MapEntry<String, AssetQuote>(
          k,
          AssetQuote.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return <String, AssetQuote>{};
    }
  }
}

/// Fetches Bitcoin, Ethereum, gold and silver prices from CoinGecko's free
/// public API (no key required).
///
/// Gold and silver come from PAXG and KAG — tokens that are each redeemable
/// for one troy ounce of the physical metal, so their USD price tracks spot
/// very closely. If you buy a dedicated metals feed, put the key in
/// [AppConfig.metalsApiKey] and extend [fetchKeyedMetals].
class MetalsApi {
  MetalsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, AssetQuote>> fetchQuotes([
    Iterable<String>? codes,
  ]) async {
    final wanted = (codes ?? AppConfig.coinGeckoIds.keys)
        .where(AppConfig.coinGeckoIds.containsKey)
        .toList();
    if (wanted.isEmpty) return <String, AssetQuote>{};

    final ids = wanted.map((String c) => AppConfig.coinGeckoIds[c]!).toSet();
    final uri = Uri.parse(AppConfig.coinGeckoPrices(ids));

    final res = await AppHttp.get(_client, uri);
    if (res.statusCode != 200) {
      throw Exception('CoinGecko returned ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final out = <String, AssetQuote>{};

    for (final String code in wanted) {
      final id = AppConfig.coinGeckoIds[code]!;
      final entry = body[id];
      if (entry is! Map) continue;
      final price = entry['usd'];
      if (price is! num || price <= 0) continue;
      final change = entry['usd_24h_change'];
      out[code] = AssetQuote(
        code: code,
        priceUsd: price.toDouble(),
        changePercent24h: change is num ? change.toDouble() : null,
      );
    }
    return out;
  }

  /// Daily USD price history for a crypto/metal asset.
  Future<List<MapEntry<DateTime, double>>> fetchHistory(
    String code,
    int days,
  ) async {
    final id = AppConfig.coinGeckoIds[code];
    if (id == null) return <MapEntry<DateTime, double>>[];

    final uri = Uri.parse(AppConfig.coinGeckoChart(id, days));
    final res = await AppHttp.get(_client, uri);
    if (res.statusCode != 200) {
      // Status only. The chart URL and its query string must not travel
      // with the error, because a caller might otherwise print them.
      throw StateError('Chart history request was rejected');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final prices = body['prices'];
    if (prices is! List) return <MapEntry<DateTime, double>>[];

    final out = <MapEntry<DateTime, double>>[];
    for (final dynamic row in prices) {
      if (row is List && row.length >= 2) {
        final ts = row[0];
        final value = row[1];
        if (ts is num && value is num) {
          out.add(MapEntry<DateTime, double>(
            DateTime.fromMillisecondsSinceEpoch(ts.toInt()),
            value.toDouble(),
          ));
        }
      }
    }
    return out;
  }

  /// Placeholder for a paid metals provider (platinum, palladium, intraday
  /// spot). Returns an empty map while no key is configured.
  Future<Map<String, AssetQuote>> fetchKeyedMetals() async {
    if (AppConfig.metalsApiKey.isEmpty) return <String, AssetQuote>{};
    // Example shape for metals-api.com:
    //   https://metals-api.com/api/latest?access_key=KEY&base=USD&symbols=XAU,XAG,XPT,XPD
    // The response returns "rates" as troy-ounces-per-USD, i.e. already in
    // the unitsPerUsd form this app uses.
    final uri = Uri.parse(
      'https://metals-api.com/api/latest'
      '?access_key=${AppConfig.metalsApiKey}&base=USD&symbols=XAU,XAG,XPT,XPD',
    );
    final res = await AppHttp.get(_client, uri);
    if (res.statusCode != 200) return <String, AssetQuote>{};
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = body['rates'];
    if (rates is! Map) return <String, AssetQuote>{};

    final out = <String, AssetQuote>{};
    rates.forEach((dynamic key, dynamic value) {
      if (value is num && value > 0) {
        out[key.toString()] =
            AssetQuote(code: key.toString(), priceUsd: 1 / value.toDouble());
      }
    });
    return out;
  }

  void dispose() => _client.close();
}
