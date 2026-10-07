import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../models/rate_snapshot.dart';
import 'app_http.dart';
import 'metals_api.dart';

/// Historical exchange-rate series used by the Trend Charts screen.
///
/// * Fiat pairs come from the European Central Bank feed (frankfurter.dev),
///   which offers daily reference rates going back to 1999.
/// * Crypto and metals come from CoinGecko's market chart endpoint.
/// * If a pair is not covered by either source (many exotic currencies are
///   not in the ECB basket) the caller receives an empty list and the UI
///   explains that history is unavailable for that pair.
class HistoryApi {
  HistoryApi({http.Client? client, MetalsApi? metals})
      : _client = client ?? http.Client(),
        _metals = metals ?? MetalsApi();

  final http.Client _client;
  final MetalsApi _metals;

  /// ECB basket — the only codes frankfurter can chart.
  static const Set<String> ecbSupported = <String>{
    'AUD', 'BGN', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'EUR', 'GBP',
    'HKD', 'HUF', 'IDR', 'ILS', 'INR', 'ISK', 'JPY', 'KRW', 'MXN', 'MYR',
    'NOK', 'NZD', 'PHP', 'PLN', 'RON', 'SEK', 'SGD', 'THB', 'TRY', 'USD',
    'ZAR',
  };

  bool supports(String from, String to) {
    final cryptoish = AppConfig.coinGeckoIds.containsKey(from) ||
        AppConfig.coinGeckoIds.containsKey(to);
    if (cryptoish) return true;
    return ecbSupported.contains(from) && ecbSupported.contains(to);
  }

  /// Daily points of "1 [from] = value [to]" for the last [days].
  ///
  /// Network, HTTP and parse failures come back as [HistorySeries.failed].
  /// The request URL, status code and query string are not logged and are
  /// not part of the result the screen can display.
  Future<HistorySeries> series(String from, String to, int days) async {
    if (from == to) return HistorySeries.ok(const <RatePoint>[]);
    try {
      final bool fromCrypto = AppConfig.coinGeckoIds.containsKey(from);
      final bool toCrypto = AppConfig.coinGeckoIds.containsKey(to);
      final List<RatePoint> points = (fromCrypto || toCrypto)
          ? await _cryptoSeries(from, to, days, fromCrypto, toCrypto)
          : await _ecbSeries(from, to, days);
      return HistorySeries.ok(points);
    } catch (_) {
      // The thrown error includes the host and query string. Do not log or
      // return it — the screen only gets [HistorySeries.failed].
      debugPrint('History series failed for $from/$to');
      return HistorySeries.failed();
    }
  }

  Future<List<RatePoint>> _ecbSeries(String from, String to, int days) async {
    if (!ecbSupported.contains(from) || !ecbSupported.contains(to)) {
      return <RatePoint>[];
    }
    final end = DateTime.now();
    // Ask for extra calendar days so weekends/holidays still leave enough
    // trading days inside the requested window.
    final DateTime start = end.subtract(Duration(days: (days * 1.5).ceil() + 5));
    String isoDate(DateTime x) =>
        '${x.year.toString().padLeft(4, '0')}-'
        '${x.month.toString().padLeft(2, '0')}-'
        '${x.day.toString().padLeft(2, '0')}';

    Future<http.Response> getSeries(String url) =>
        AppHttp.get(_client, Uri.parse(url));

    http.Response res = await getSeries(
      AppConfig.frankfurterSeries(from, to, start, end),
    );
    if (res.statusCode != 200) {
      final String alt =
          '${AppConfig.frankfurterAppBase}/${isoDate(start)}..${isoDate(end)}?from=$from&to=$to';
      res = await getSeries(alt);
    }
    if (res.statusCode != 200) {
      throw StateError('Chart history request was rejected');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = body['rates'];
    if (rates is! Map) return <RatePoint>[];

    final points = <RatePoint>[];
    rates.forEach((dynamic dateKey, dynamic value) {
      final date = DateTime.tryParse(dateKey.toString());
      if (date == null || value is! Map) return;
      final v = value[to];
      if (v is num) points.add(RatePoint(date, v.toDouble()));
    });

    points.sort((RatePoint a, RatePoint b) => a.date.compareTo(b.date));
    return _tail(points, days);
  }

  Future<List<RatePoint>> _cryptoSeries(
    String from,
    String to,
    int days,
    bool fromCrypto,
    bool toCrypto,
  ) async {
    // Both sides in USD, then divide: (1 from in USD) / (1 to in USD).
    final fromUsd = await _usdSeries(from, days);
    final toUsd = await _usdSeries(to, days);
    if (fromUsd.isEmpty || toUsd.isEmpty) return <RatePoint>[];

    final toByDay = <String, double>{
      for (final RatePoint p in toUsd) _dayKey(p.date): p.value,
    };

    final out = <RatePoint>[];
    for (final RatePoint p in fromUsd) {
      final other = toByDay[_dayKey(p.date)];
      if (other == null || other == 0) continue;
      out.add(RatePoint(p.date, p.value / other));
    }
    out.sort((RatePoint a, RatePoint b) => a.date.compareTo(b.date));
    return _tail(out, days);
  }

  /// Daily "1 [code] = value USD" series.
  Future<List<RatePoint>> _usdSeries(String code, int days) async {
    if (code == 'USD') {
      final now = DateTime.now();
      return List<RatePoint>.generate(
        days + 1,
        (int i) => RatePoint(now.subtract(Duration(days: days - i)), 1.0),
      );
    }

    if (AppConfig.coinGeckoIds.containsKey(code)) {
      final raw = await _metals.fetchHistory(code, days);
      return raw
          .map((MapEntry<DateTime, double> e) => RatePoint(e.key, e.value))
          .toList();
    }

    // Fiat: ECB gives USD per unit directly.
    final fiat = await _ecbSeries(code, 'USD', days);
    return fiat;
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static List<RatePoint> _tail(List<RatePoint> points, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered =
        points.where((RatePoint p) => p.date.isAfter(cutoff)).toList();
    return filtered.isEmpty ? points : filtered;
  }

  void dispose() {
    _client.close();
    _metals.dispose();
  }
}

/// Chart points, or a failure that carries no URL, status code, or query.
class HistorySeries {
  const HistorySeries.ok(this.points) : failed = false;

  const HistorySeries.failed()
      : points = const <RatePoint>[],
        failed = true;

  final List<RatePoint> points;
  final bool failed;
}
