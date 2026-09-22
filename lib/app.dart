import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'data/models/rate_alert.dart';
import 'routes.dart';
import 'state/alerts_provider.dart';
import 'state/rates_provider.dart';
import 'state/settings_provider.dart';

class CurrencyProApp extends StatefulWidget {
  const CurrencyProApp({super.key});

  @override
  State<CurrencyProApp> createState() => _CurrencyProAppState();
}

class _CurrencyProAppState extends State<CurrencyProApp>
    with WidgetsBindingObserver {
  RatesProvider? _rates;
  int _seenGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _rates?.removeListener(_onRatesChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _bootstrap() {
    final RatesProvider rates = context.read<RatesProvider>();
    final SettingsProvider settings = context.read<SettingsProvider>();
    _rates = rates;
    rates.addListener(_onRatesChanged);
    rates.ensureFresh();
    if (settings.autoRefresh) rates.startAutoRefresh();
  }

  void _onRatesChanged() {
    final RatesProvider? rates = _rates;
    if (rates == null) return;
    if (rates.generation <= _seenGeneration) return;
    _seenGeneration = rates.generation;
    _evaluateAlerts();
  }

  Future<void> _evaluateAlerts() async {
    if (!mounted) return;
    final RatesProvider rates = context.read<RatesProvider>();
    final AlertsProvider alerts = context.read<AlertsProvider>();
    final List<RateAlert> fired = await alerts.evaluate(rates.pairRate);
    if (fired.isEmpty || !mounted) return;
    final ScaffoldMessengerState? messenger = scaffoldMessengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          fired.length == 1
              ? '${fired.first.from}/${fired.first.to} reached its target'
              : '${fired.length} alerts reached their target',
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RatesProvider>().ensureFresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final AppPalette palette = settings.palette;

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.build(palette),
      initialRoute: Routes.home,
      routes: Routes.table(),
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              mq.textScaler.scale(1).clamp(0.85, 1.25),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
