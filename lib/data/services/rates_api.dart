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
/// Tries the primary provider first (open.er-api.com, free and key-less) and
/// silently falls back to independent sources if it is down.
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

    final RateSnapshot? primary = await tryProvider('open.er-api.com', () => _fetchErApi(base));
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

    if (base.toUpperCase() == 'USD') {
      final RateSnapshot? fawaz = await tryProvider(
        'currency-api',
        _fetchFawazUsd,
      );
      if (fawaz != null) return fawaz;
    }

    throw RatesUnavailable(
      'Could not reach any rate provider.\n${errors.join('\n')}',
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

    final updatedUnix = (body['time_last_update_unix'] as num?)?.toInt();

    return RateSnapshot(
      base: (body['base_code'] as String?) ?? base,
      rates: _toDoubleMap(rawRates),
      fetchedAt: DateTime.now(),
      providerUpdatedAt: updatedUnix == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(updatedUnix * 1000),
      provider: 'open.er-api.com',
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

    DateTime updated = DateTime.now();
    final dateText = body['date'] as String?;
    if (dateText != null) {
      updated = DateTime.tryParse(dateText) ?? updated;
    }

    return RateSnapshot(
      base: (body['base'] as String?) ??
          (body['base_code'] as String?) ??
          base,
      rates: rates,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: updated,
      provider: 'ECB / frankfurter',
    );
  }

  Future<RateSnapshot> _fetchFawazUsd() async {
    final uri = Uri.parse(AppConfig.fawazLatest);
    final res = await AppHttp.get(_client, uri);
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

    DateTime updated = DateTime.now();
    final dateText = body['date'] as String?;
    if (dateText != null) {
      updated = DateTime.tryParse(dateText) ?? updated;
    }

    return RateSnapshot(
      base: 'USD',
      rates: rates,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: updated,
      provider: 'currency-api',
    );
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
