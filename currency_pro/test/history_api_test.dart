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
