import 'dart:convert';

import 'package:currency_pro/data/models/rate_snapshot.dart';
import 'package:currency_pro/data/services/history_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('a failed chart request does not expose the URL or query', () async {
    final HistoryApi api = HistoryApi(client: _RejectingClient());
    final HistorySeries result = await api.series('USD', 'EUR', 30);

    expect(result.failed, isTrue);
    expect(result.points, isEmpty);
    expect(result.toString(), isNot(contains('http')));
    expect(result.toString(), isNot(contains('from=')));
    expect(result.toString(), isNot(contains('Connection failed')));
    api.dispose();
  });

  test('a pair loads from the currency archive when the market chart is down',
      () async {
    final HistoryApi api = HistoryApi(client: _ArchiveClient());
    final HistorySeries result = await api.series('USD', 'PKR', 10);

    expect(result.failed, isFalse);
    expect(result.points.length, greaterThanOrEqualTo(2));
    expect(result.points.first.value, greaterThan(200));
    expect(result.points.last.value, greaterThan(200));
    api.dispose();
  });

  test('an exotic pair loads from the currency-api mirror', () async {
    final HistoryApi api = HistoryApi(client: _PagesClient());
    final HistorySeries result = await api.series('ANG', 'AED', 10);

    expect(result.failed, isFalse);
    expect(result.points.length, greaterThanOrEqualTo(2));
    expect(result.points.last.value, closeTo(2.05, 0.001));
    api.dispose();
  });

  test('a currency outside the ECB basket still loads from the market chart',
      () async {
    final HistoryApi api = HistoryApi(client: _ChartClient());
    final HistorySeries result = await api.series('USD', 'PKR', 30);

    expect(result.failed, isFalse);
    expect(result.points, hasLength(3));
    expect(result.points.last.value, closeTo(277.03, 0.001));
    api.dispose();
  });
}

class _ArchiveClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String url = request.url.toString();
    final RegExpMatch? date = RegExp(r'@(\d{4}-\d{2}-\d{2})').firstMatch(url);
    if (date != null && url.contains('/currencies/usd.min.json')) {
      final int day = int.parse(date.group(1)!.substring(8));
      return _json(<String, dynamic>{
        'usd': <String, double>{'pkr': 270 + day.toDouble()},
      });
    }
    return _json(<String, dynamic>{'message': 'not found'}, status: 404);
  }

  http.StreamedResponse _json(Map<String, dynamic> body, {int status = 200}) {
    final List<int> bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}

class _PagesClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String url = request.url.toString();
    if (url.contains('currency-api.pages.dev') &&
        url.contains('/currencies/ang.min.json')) {
      return _json(<String, dynamic>{
        'ang': <String, double>{'aed': 2.05},
      });
    }
    return _json(<String, dynamic>{'message': 'not found'}, status: 404);
  }

  http.StreamedResponse _json(Map<String, dynamic> body, {int status = 200}) {
    final List<int> bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}

class _ChartClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String url = request.url.toString();
    if (url.contains('finance/chart/USDPKR')) {
      return _json(<String, dynamic>{
        'chart': <String, dynamic>{
          'result': <Map<String, dynamic>>[
            <String, dynamic>{
              'timestamp': <int>[1700000000, 1700086400, 1700172800],
              'indicators': <String, dynamic>{
                'quote': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'close': <double>[276.1, 276.8, 277.03],
                  },
                ],
              },
            },
          ],
        },
      });
    }
    return _json(<String, dynamic>{'message': 'not found'}, status: 404);
  }

  http.StreamedResponse _json(Map<String, dynamic> body, {int status = 200}) {
    final List<int> bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      status,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}

class _RejectingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw http.ClientException(
      'Connection failed ${request.url}',
      request.url,
    );
  }
}
