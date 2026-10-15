import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the OS notification permission used for rate alerts.
class NotificationPermission {
  const NotificationPermission._();

  /// One in-flight request. A second tap while the system sheet is up used
  /// to hit `ERROR_ALREADY_REQUESTING_PERMISSIONS` and take the app down.
  static Future<bool>? _inFlight;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<bool> request() {
    final Future<bool>? pending = _inFlight;
    if (pending != null) return pending;
    final Future<bool> run = _request();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  static Future<bool> _request() async {
    if (!isSupported) return false;
    try {
      final PermissionStatus status = await Permission.notification.request();
      return status.isGranted || status.isLimited;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  static Future<bool> isGranted() async {
    if (!isSupported) return false;
    try {
      final PermissionStatus status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      debugPrint('Notification permission status failed: $e');
      return false;
    }
  }
}
