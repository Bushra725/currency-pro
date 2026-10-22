import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/ads/ads_service.dart';
import 'core/notifications/alert_notifications.dart';
import 'core/utils/haptics.dart';
import 'data/repositories/rates_repository.dart';
import 'data/services/prefs_service.dart';
import 'state/alerts_provider.dart';
import 'state/clocks_provider.dart';
import 'state/rates_provider.dart';
import 'state/settings_provider.dart';
import 'state/trips_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  } catch (e) {
    debugPrint('System UI mode skipped: $e');
  }
  try {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Orientation lock skipped: $e');
  }

  final PrefsService prefs = await PrefsService.create();
  final RatesRepository repository = RatesRepository(prefs: prefs);
  final AdsService ads = AdsService(prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsService>.value(value: prefs),
        ChangeNotifierProvider<AdsService>.value(value: ads),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider<RatesProvider>(
          create: (_) => RatesProvider(repository),
        ),
        ChangeNotifierProvider<AlertsProvider>(
          create: (_) => AlertsProvider(prefs),
        ),
        ChangeNotifierProvider<TripsProvider>(
          create: (_) => TripsProvider(prefs),
        ),
        ChangeNotifierProvider<ClocksProvider>(
          create: (_) => ClocksProvider(prefs),
        ),
      ],
      child: const CurrencyProApp(),
    ),
  );

  // Plugins register when the iOS engine comes up, which is after runApp.
  // Calling ads, audio, or notifications before that crashes or no-ops on
  // physical iPhones, especially models older than iPhone 14.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _warmDeviceServices(ads);
  });
}

Future<void> _warmDeviceServices(AdsService ads) async {
  try {
    await ads.initialize();
  } catch (e) {
    debugPrint('Ads init failed: $e');
  }
  try {
    await Haptics.warmup();
  } catch (e) {
    debugPrint('Haptics warmup failed: $e');
  }
  try {
    await AlertNotifications.initialize();
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }
}
