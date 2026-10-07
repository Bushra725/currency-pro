import 'package:flutter/services.dart';

import '../app_config.dart';

const MethodChannel _links = MethodChannel('com.theoccess.currencypro/links');

Future<bool> openPrivacyPolicy() async {
  return _open(AppConfig.privacyPolicyUrl);
}

/// Opens the device's mail app with [address] already in the To field.
///
/// [subject] is filled in too, so support mail arrives pre-labelled.
Future<bool> openEmail(
  String address, {
  String subject = '',
  String body = '',
}) async {
  final String query = <String>[
    if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
    if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
  ].join('&');
  final String uri =
      'mailto:${Uri.encodeFull(address)}${query.isEmpty ? '' : '?$query'}';
  return _open(uri);
}

Future<bool> _open(String url) async {
  try {
    final bool? ok = await _links.invokeMethod<bool>('openUrl', url);
    return ok == true;
  } catch (_) {
    return false;
  }
}
