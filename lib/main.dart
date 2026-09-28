import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/rates_repository.dart';
import 'data/services/prefs_service.dart';
import 'state/alerts_provider.dart';
import 'state/clocks_provider.dart';
import 'state/rates_provider.dart';
import 'state/settings_provider.dart';
import 'state/trips_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final PrefsService prefs = await PrefsService.create();
  final RatesRepository repository = RatesRepository(prefs: prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsService>.value(value: prefs),
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
}
