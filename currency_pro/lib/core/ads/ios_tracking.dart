import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks iOS for the App Tracking Transparency prompt.
///
/// Apple only shows it once the app is active, so this is called after the
/// first frame rather than during `main()`.
class IosTracking {
  const IosTracking._();

  static const MethodChannel _channel =
      MethodChannel('com.theoccess.currencypro/ads');

  static Future<void> request() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _channel
          .invokeMethod<int>('requestTracking')
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('ATT request skipped: $e');
    }
  }
}
