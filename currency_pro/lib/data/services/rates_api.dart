import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../models/rate_snapshot.dart';
import 'app_http.dart';

/// Thrown when every configured provider fails.
class RatesUnavailable implements Exception {
  RatesUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads live fiat exchange rates.
///
/// Prefers frequently updated market tables (currency-api + Coinbase) so
/// online quotes stay close to the mid-market numbers people see on Google.
/// ECB / open.er-api.com are daily fallbacks if those hosts are unreachable.
class RatesApi {
  RatesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RateSnapshot> fetchLatest(String base) async {
    final List<String> errors = <String>[];

    Future<RateSnapshot?> tryProvider(
      String label,
      Future<RateSnapshot> Function() fetch,
    ) async {
      try {
        return await fetch();
      } catch (e) {
        errors.add('$label: $e');
        return null;
      }
    }

    final List<RateSnapshot?> liveWave = await Future.wait(<Future<RateSnapshot?>>[
      tryProvider('currency-api', () => _fetchFawazUsd(AppConfig.fawazPagesLatest)),
      tryProvider('currency-api-cdn', () => _fetchFawazUsd(AppConfig.fawazLatest)),
      tryProvider('open.er-api.com', () => _fetchErApi('USD')),
      tryProvider('coinbase', _fetchCoinbaseUsd),
      tryProvider('yahoo', _fetchYahooUsdMajors),
    ]);

    RateSnapshot? wide = liveWave[0] ?? liveWave[1] ?? liveWave[2];
    final RateSnapshot? coinbase = liveWave[3];
    final RateSnapshot? yahoo = liveWave[4];

    RateSnapshot? live = wide;
    if (live != null && coinbase != null) {
      live = live.overlay(coinbase);
    } else {
      live ??= coinbase;
    }
    if (live != null && yahoo != null) {
      live = live.overlay(yahoo);
    } else {
      live ??= yahoo;
    }

    if (live != null) {
      final DateTime now = DateTime.now();
      return _maybeRebase(
        live.copyWith(
          fetchedAt: now,
          providerUpdatedAt: now,
          isStale: false,
        ),
        base,
      );
    }

    final RateSnapshot? primary =
        await tryProvider('open.er-api.com', () => _fetchErApi(base));
    if (primary != null) return primary;

    final RateSnapshot? frankfurter = await tryProvider(
      'frankfurter.dev',
      () => _fetchFrankfurter(base, AppConfig.frankfurterLatest(base)),
    );
    if (frankfurter != null) return frankfurter;

    final RateSnapshot? frankfurterApp = await tryProvider(
      'frankfurter.app',
      () => _fetchFrankfurter(
        base,
        '${AppConfig.frankfurterAppBase}/latest?from=$base',
      ),
    );
    if (frankfurterApp != null) return frankfurterApp;

    throw RatesUnavailable(
      'Could not reach any rate provider.\n${errors.join('\n')}',
    );
  }

  RateSnapshot _maybeRebase(RateSnapshot usd, String base) {
    final String wanted = base.toUpperCase();
    if (wanted == 'USD' || wanted == usd.base) return usd;
    final double? baseRate = usd.rates[wanted];
    if (baseRate == null || baseRate == 0) return usd;
    final Map<String, double> rates = <String, double>{};
    usd.rates.forEach((String code, double value) {
      rates[code] = value / baseRate;
    });
    rates[wanted] = 1.0;
    return RateSnapshot(
      base: wanted,
      rates: rates,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: DateTime.now(),
      provider: usd.provider,
      isStale: false,
    );
  }

  Future<RateSnapshot> _fetchYahooUsdMajors() async {
    final uri = Uri.parse(AppConfig.yahooUsdQuoteUrl());
    final res = await AppHttp.get(
      _client,
      uri,
      timeout: const Duration(seconds: 10),
    );
    if (res.statusCode != 200) {
      throw RatesUnavailable('yahoo returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) {
      throw RatesUnavailable('Malformed Yahoo response');
    }

    final rates = <String, double>{'USD': 1.0};
    body.forEach((dynamic key, dynamic row) {
      if (row is! Map) return;
      final String symbol = key.toString().toUpperCase();
      if (!symbol.startsWith('USD') || !symbol.endsWith('=X')) return;
      final String code = symbol.substring(3, symbol.length - 2);
      if (code.isEmpty || code == 'USD') return;
      final dynamic raw = row['fulldayPrice'] ?? _lastNum(row['close']);
      final double? value = raw is num
          ? raw.toDouble()
          : double.tryParse(raw?.toString() ?? '');
      if (value != null && value > 0) {
        rates[code] = value;
      }
    });
    if (rates.length <= 1) throw RatesUnavailable('No Yahoo USD crosses');

    final DateTime now = DateTime.now();
    return RateSnapshot(
      base: 'USD',
      rates: rates,
      fetchedAt: now,
      providerUpdatedAt: now,
      provider: 'yahoo',
      isStale: false,
    );
  }

  Future<RateSnapshot> _fetchCoinbaseUsd() async {
    final uri = Uri.parse(AppConfig.coinbaseUsdRates);
    final res = await AppHttp.get(
      _client,
      uri,
      timeout: const Duration(seconds: 10),
    );
    if (res.statusCode != 200) {
      throw RatesUnavailable('coinbase returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map) throw RatesUnavailable('Malformed Coinbase response');
    final raw = data['rates'];
    if (raw is! Map) throw RatesUnavailable('Malformed Coinbase rates');

    final rates = <String, double>{'USD': 1.0};
    raw.forEach((dynamic key, dynamic value) {
      final double? parsed = value is num
          ? value.toDouble()
          : double.tryParse(value.toString());
      if (parsed != null && parsed > 0) {
        rates[key.toString().toUpperCase()] = parsed;
      }
    });
    if (rates.length <= 1) throw RatesUnavailable('Empty Coinbase table');

    return RateSnapshot(
      base: 'USD',
      rates: rates,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: DateTime.now(),
      provider: 'coinbase',
      isStale: false,
    );
  }

  Future<RateSnapshot> _fetchErApi(String base) async {
    final uri = Uri.parse(AppConfig.erApiUrl(base));
    final res = await AppHttp.get(_client, uri);
    if (res.statusCode != 200) {
      throw RatesUnavailable('open.er-api.com returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;

    final result = body['result'] as String?;
    if (result != null && result != 'success') {
      throw RatesUnavailable('Provider error: ${body['error-type'] ?? result}');
    }

    final rawRates = (body['rates'] ?? body['conversion_rates']) as Map?;
    if (rawRates == null) throw RatesUnavailable('Malformed response');

    return RateSnapshot(
      base: (body['base_code'] as String?) ?? base,
      rates: _toDoubleMap(rawRates),
      fetchedAt: DateTime.now(),
      providerUpdatedAt: DateTime.now(),
      provider: 'open.er-api.com',
      isStale: false,
    );
  }

  Future<RateSnapshot> _fetchFrankfurter(String base, String url) async {
    final uri = Uri.parse(url);
    final res = await AppHttp.get(_client, uri);
    if (res.statusCode != 200) {
      throw RatesUnavailable('frankfurter returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawRates = body['rates'] as Map?;
    if (rawRates == null) throw RatesUnavailable('Malformed response');

    final rates = _toDoubleMap(rawRates);
    rates[base] = 1.0;

    return RateSnapshot(
      base: (body['base'] as String?) ??
          (body['base_code'] as String?) ??
          base,
      rates: rates,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: DateTime.now(),
      provider: 'ECB / frankfurter',
      isStale: false,
    );
  }

  Future<RateSnapshot> _fetchFawazUsd(String url) async {
    final uri = Uri.parse(url);
    final res = await AppHttp.get(
      _client,
      uri,
      timeout: const Duration(seconds: 10),
    );
    if (res.statusCode != 200) {
      throw RatesUnavailable('currency-api returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final usd = body['usd'];
    if (usd is! Map) throw RatesUnavailable('Malformed currency-api response');

    final rates = <String, double>{'USD': 1.0};
    usd.forEach((dynamic key, dynamic value) {
      if (value is num && value > 0) {
        rates[key.toString().toUpperCase()] = value.toDouble();
      }
    });
    if (rates.length <= 1) throw RatesUnavailable('Empty currency-api table');

    return RateSnapshot(
      base: 'USD',
      rates: rates,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: DateTime.now(),
      provider: 'currency-api',
      isStale: false,
    );
  }

  static num? _lastNum(dynamic raw) {
    if (raw is! List) return null;
    for (int i = raw.length - 1; i >= 0; i--) {
      final dynamic value = raw[i];
      if (value is num && value > 0) return value;
    }
    return null;
  }

  static Map<String, double> _toDoubleMap(Map<dynamic, dynamic> raw) {
    final out = <String, double>{};
    raw.forEach((dynamic key, dynamic value) {
      if (value is num) out[key.toString().toUpperCase()] = value.toDouble();
    });
    return out;
  }

  void dispose() => _client.close();
}
