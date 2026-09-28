import 'package:flutter/services.dart';

import '../app_config.dart';

Future<bool> openPrivacyPolicy() async {
  try {
    final bool? ok = await const MethodChannel(
      'com.theoccess.currencypro/links',
    ).invokeMethod<bool>(
      'openUrl',
      AppConfig.privacyPolicyUrl,
    );
    return ok == true;
  } catch (_) {
    return false;
  }
}
