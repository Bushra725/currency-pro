import 'package:http/http.dart' as http;

import '../../core/app_config.dart';

/// Shared HTTP helpers. CoinGecko and several rate hosts reject requests
/// that do not send a User-Agent, so every call goes through here.
class AppHttp {
  const AppHttp._();

  static const Map<String, String> headers = <String, String>{
    'Accept': 'application/json',
    'User-Agent':
        '${AppConfig.appName}/${AppConfig.appVersion} (Flutter; currency converter)',
  };

  static Future<http.Response> get(
    http.Client client,
    Uri uri, {
    Duration? timeout,
  }) {
    return client
        .get(uri, headers: headers)
        .timeout(timeout ?? AppConfig.requestTimeout);
  }
}
