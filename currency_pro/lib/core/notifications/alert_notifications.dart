import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/formatting.dart';
import '../../data/models/rate_alert.dart';
import 'notification_permission.dart';

/// System notifications for rate alerts.
///
/// Until this existed, a hit target only produced an in-app SnackBar — so
/// nothing was delivered if the user was on another screen or the banner
/// never attached.
class AlertNotifications {
  AlertNotifications._();

  static const String channelId = 'rate_alerts';
  static const String channelName = 'Rate alerts';
  static const String channelDescription =
      'Fires when a watched currency pair hits your target';
  static const String _icon = '@drawable/ic_stat_notify';
  static const String _fallbackIcon = '@mipmap/ic_launcher';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String _androidIcon = _icon;

  static Future<void> initialize() async {
    if (_ready) return;
    try {
      await _bind(_icon);
    } catch (e) {
      debugPrint('Alert icon $_icon missing, falling back: $e');
      await _bind(_fallbackIcon);
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> _bind(String icon) async {
    _androidIcon = icon;
    await _plugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings(icon),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );
  }

  static Future<void> showFired(
    List<RateAlert> fired,
    double? Function(String from, String to) rateOf,
  ) async {
    if (fired.isEmpty) return;
    if (kIsWeb) return;
    try {
      await initialize();
    } catch (_) {
      return;
    }

    for (final RateAlert alert in fired) {
      final double? current = rateOf(alert.from, alert.to);
      final String rateText = current == null
          ? Fmt.smart(alert.targetRate, maxDecimals: 6)
          : Fmt.smart(current, maxDecimals: 6);
      final String targetText = Fmt.smart(alert.targetRate, maxDecimals: 6);
      final String verb =
          alert.direction == AlertDirection.above ? 'rose to' : 'fell to';
      try {
        await _plugin.show(
          alert.id.hashCode & 0x7fffffff,
          '${alert.from} → ${alert.to} target hit',
          '1 ${alert.from} $verb $rateText ${alert.to} (target $targetText)',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDescription,
              importance: Importance.max,
              priority: Priority.high,
              icon: _androidIcon,
              playSound: true,
              enableVibration: true,
              ticker: 'Rate alert',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
            ),
          ),
        );
      } catch (_) {
        // Keep evaluating remaining alerts.
      }
    }
  }

  /// Ask the OS for permission and report whether we can post alerts.
  static Future<bool> ensurePermission() async {
    final bool granted = await NotificationPermission.request();
    try {
      await initialize();
    } catch (_) {}
    return granted;
  }
}
