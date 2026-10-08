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
  /// A pair with no published history comes back empty and not failed, so
  /// the screen does not call a working connection a network error.
  /// The request URL, status code and query string are not logged and are
  /// not part of the result the screen can display.
  Future<HistorySeries> series(String from, String to, int days) async {
    if (from == to) return HistorySeries.ok(const <RatePoint>[]);
    try {
      return HistorySeries.ok(await _bestSeries(from, to, days));
    } catch (_) {
      // The thrown error includes the host and query string. Do not log or
      // return it — the screen only gets [HistorySeries.failed].
      debugPrint('History series failed for $from/$to');
      return HistorySeries.failed();
    }
  }

  /// The currency archive is tried first because it is the same host the
  /// live rate table already uses, including currencies outside the ECB
  /// basket. Yahoo and the ECB feed cover gaps in that archive.
  Future<List<RatePoint>> _bestSeries(String from, String to, int days) async {
    final bool fromCrypto = AppConfig.coinGeckoIds.containsKey(from);
    final bool toCrypto = AppConfig.coinGeckoIds.containsKey(to);
    bool reachedHost = false;
    Object? lastError;

    Future<List<RatePoint>> attempt(
      Future<List<RatePoint>> Function() load,
    ) async {
      try {
        final List<RatePoint> points = await load();
        reachedHost = true;
        return points;
      } catch (e) {
        lastError = e;
        return const <RatePoint>[];
      }
    }

    if (fromCrypto || toCrypto) {
      final List<RatePoint> crypto = await attempt(
        () => _cryptoSeries(from, to, days, fromCrypto, toCrypto),
      );
      if (crypto.length >= 2) return crypto;
    }

    final List<RatePoint> archived = await attempt(
      () => _archiveSeries(from, to, days),
    );
    if (archived.length >= 2) return _tail(archived, days);

    final List<RatePoint> direct = await attempt(
      () => _yahooSymbol(_fxSymbol(from, to), days, invert: _invertYahoo(from, to)),
    );
    if (direct.length >= 2) return _tail(direct, days);

    if (from != 'USD' && to != 'USD') {
      final List<RatePoint> fromUsd = await attempt(
        () => _yahooSymbol(_fxSymbol(from, 'USD'), days),
      );
      final List<RatePoint> usdTo = await attempt(
        () => _yahooSymbol(
          _fxSymbol('USD', to),
          days,
          invert: _invertYahoo('USD', to),
        ),
      );
      final List<RatePoint> crossed = _cross(fromUsd, usdTo);
      if (crossed.length >= 2) return _tail(crossed, days);
    }

    // An unsupported pair returns no points without contacting the ECB.
    // That must not count as a successful response, or a failed archive
    // looks like "no history" instead of a connection problem.
    if (ecbSupported.contains(from) && ecbSupported.contains(to)) {
      final List<RatePoint> ecb =
          await attempt(() => _ecbSeries(from, to, days));
      if (ecb.length >= 2) return ecb;
    }

    if (!reachedHost && lastError != null) {
      throw lastError!;
    }
    return const <RatePoint>[];
  }

  /// Daily closes from the public currency archive. Missing days are skipped.
  /// A total network failure is thrown so another source can still be tried.
  Future<List<RatePoint>> _archiveSeries(
    String from,
    String to,
    int days,
  ) async {
    final int step = days <= 16
        ? 1
        : days <= 100
            ? 4
            : days <= 370
                ? 14
                : 28;
    final DateTime end = DateTime.now().toUtc();
    final List<DateTime> dates = <DateTime>[];
    for (int ago = days; ago >= 1; ago -= step) {
      dates.add(end.subtract(Duration(days: ago)));
    }

    Object? failure;
    final List<RatePoint> points = <RatePoint>[];
    const int batchSize = 6;
    for (int start = 0; start < dates.length; start += batchSize) {
      final int endIndex = start + batchSize > dates.length
          ? dates.length
          : start + batchSize;
      final List<RatePoint?> batch = await Future.wait(
        dates.sublist(start, endIndex).map((DateTime day) async {
          try {
            return await _archiveDay(from, to, day);
          } catch (e) {
            failure = e;
            return null;
          }
        }),
      );
      for (final RatePoint? point in batch) {
        if (point != null) points.add(point);
      }
    }

    if (points.length < 2 && failure != null) {
      throw failure!;
    }
    points.sort((RatePoint a, RatePoint b) => a.date.compareTo(b.date));
    return points;
  }

  Future<RatePoint?> _archiveDay(String from, String to, DateTime day) async {
    final DateTime utc = day.toUtc();
    Object? failure;
    for (final String url in AppConfig.fawazOn(utc, from)) {
      try {
        final http.Response res = await AppHttp.get(
          _client,
          Uri.parse(url),
          timeout: const Duration(seconds: 12),
        );
        if (res.statusCode == 404) continue;
        if (res.statusCode != 200) {
          failure = StateError('Chart history request was rejected');
          continue;
        }
        final RatePoint? point = _archivePoint(res.body, from, to, utc);
        if (point != null) return point;
      } catch (e) {
        failure = e;
      }
    }
    if (failure != null) throw failure;
    return null;
  }

  RatePoint? _archivePoint(
    String body,
    String from,
    String to,
    DateTime utc,
  ) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final dynamic table = decoded[from.toLowerCase()];
    if (table is! Map) return null;
    final dynamic value = table[to.toLowerCase()];
    if (value is! num || value <= 0) return null;
    return RatePoint(
      DateTime.utc(utc.year, utc.month, utc.day, 12),
      value.toDouble(),
    );
  }

  /// `BTC-USD` is one bitcoin in dollars. `USDGBP=X` is one dollar in pounds.
  String _fxSymbol(String from, String to) {
    if (AppConfig.coinGeckoIds.containsKey(from) && to == 'USD') {
      return '$from-USD';
    }
    if (from == 'USD' && AppConfig.coinGeckoIds.containsKey(to)) {
      return '$to-USD';
    }
    return '$from$to=X';
  }

  bool _invertYahoo(String from, String to) =>
      from == 'USD' && AppConfig.coinGeckoIds.containsKey(to);

  Future<List<RatePoint>> _yahooSymbol(
    String symbol,
    int days, {
    bool invert = false,
  }) async {
    final http.Response res = await AppHttp.get(
      _client,
      Uri.parse(AppConfig.yahooChart(symbol, days)),
    );
    if (res.statusCode == 404) return <RatePoint>[];
    if (res.statusCode != 200) {
      throw StateError('Chart history request was rejected');
    }
    final List<RatePoint> points = _yahooPoints(res.body);
    if (!invert) return points;
    return points
        .where((RatePoint point) => point.value != 0)
        .map((RatePoint point) => RatePoint(point.date, 1 / point.value))
        .toList();
  }

  List<RatePoint> _yahooPoints(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map) return <RatePoint>[];
    final dynamic chart = decoded['chart'];
    if (chart is! Map) return <RatePoint>[];
    final dynamic result = chart['result'];
    if (result is! List || result.isEmpty || result.first is! Map) {
      return <RatePoint>[];
    }
    final Map<dynamic, dynamic> row = result.first as Map<dynamic, dynamic>;
    final dynamic stamps = row['timestamp'];
    final dynamic indicators = row['indicators'];
    if (stamps is! List || indicators is! Map) return <RatePoint>[];
    final dynamic quote = indicators['quote'];
    if (quote is! List || quote.isEmpty || quote.first is! Map) {
      return <RatePoint>[];
    }
    final dynamic closes = (quote.first as Map<dynamic, dynamic>)['close'];
    if (closes is! List) return <RatePoint>[];

    final List<RatePoint> points = <RatePoint>[];
    final int count = stamps.length < closes.length ? stamps.length : closes.length;
    for (int i = 0; i < count; i++) {
      final dynamic stamp = stamps[i];
      final dynamic close = closes[i];
      if (stamp is num && close is num && close > 0) {
        points.add(RatePoint(
          DateTime.fromMillisecondsSinceEpoch(stamp.toInt() * 1000, isUtc: true),
          close.toDouble(),
        ));
      }
    }
    points.sort((RatePoint a, RatePoint b) => a.date.compareTo(b.date));
    return points;
  }

  /// [fromInUsd] is "1 from = USD". [usdInTo] is "1 USD = to".
  List<RatePoint> _cross(List<RatePoint> fromInUsd, List<RatePoint> usdInTo) {
    final Map<String, double> toByDay = <String, double>{
      for (final RatePoint point in usdInTo) _dayKey(point.date): point.value,
    };
    final List<RatePoint> out = <RatePoint>[];
    for (final RatePoint point in fromInUsd) {
      final double? other = toByDay[_dayKey(point.date)];
      if (other == null || other == 0 || point.value == 0) continue;
      out.add(RatePoint(point.date, point.value * other));
    }
    out.sort((RatePoint a, RatePoint b) => a.date.compareTo(b.date));
    return out;
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
