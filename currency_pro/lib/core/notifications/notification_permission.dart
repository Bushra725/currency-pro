import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the OS notification permission used for rate alerts.
class NotificationPermission {
  const NotificationPermission._();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<bool> request() async {
    if (!isSupported) return false;
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> isGranted() async {
    if (!isSupported) return false;
    final PermissionStatus status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }
}
