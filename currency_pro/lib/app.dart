import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/ads/ad_return_observer.dart';
import 'core/ads/ads_service.dart';
import 'core/ads/bottom_ad_slot.dart';
import 'core/app_config.dart';
import 'core/l10n/l10n.dart';
import 'core/notifications/alert_notifications.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'data/models/rate_alert.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/onboarding/splash_page.dart';
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
  bool _showSplash = true;
  bool _returnAdsArmed = false;
  AdReturnObserver? _adObserver;

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
    if (!settings.autoRefresh) {
      settings.setAutoRefresh(true);
    }
    rates.startAutoRefresh();
    _evaluateAlerts();
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
    await AlertNotifications.showFired(fired, rates.pairRate);
    if (!mounted) return;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adObserver ??= AdReturnObserver(context.read<AdsService>());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final AdsService ads = context.read<AdsService>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ads.markBackgrounded();
    }
    if (state == AppLifecycleState.resumed) {
      final RatesProvider rates = context.read<RatesProvider>();
      rates.ensureFresh();
      if (context.read<SettingsProvider>().autoRefresh) {
        rates.startAutoRefresh();
      }
      _evaluateAlerts();
      if (!_showSplash && context.read<SettingsProvider>().onboardingDone) {
        ads.showAppOpenIfEligible();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final AppPalette palette = settings.palette;

    final SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          palette.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness:
          palette.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          palette.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: AppTheme.build(palette),
        locale: settings.localeCode == AppLocales.systemCode
            ? null
            : Locale(AppLocales.canonical(settings.localeCode)),
        supportedLocales: AppLocales.materialLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeListResolutionCallback:
            (List<Locale>? locales, Iterable<Locale> supported) {
          return AppLocales.resolve(
            settings.localeCode,
            locales ?? const <Locale>[],
          );
        },
        initialRoute: Routes.home,
        routes: Routes.table(),
        navigatorObservers: <NavigatorObserver>[
          if (_adObserver != null) _adObserver!,
        ],
        builder: (BuildContext context, Widget? child) {
          final MediaQueryData mq = MediaQuery.of(context);
          final double bottomInset = _bottomInset(mq);
          final bool showLaunch = _showSplash || !settings.onboardingDone;
          if (!showLaunch && !_returnAdsArmed) {
            _returnAdsArmed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<AdsService>().enableReturnAds();
            });
          }
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(
                mq.textScaler.scale(1).clamp(0.85, 1.25),
              ),
              padding: mq.padding.copyWith(
                bottom: 0,
                left: 0,
                right: 0,
              ),
              viewPadding: mq.viewPadding.copyWith(
                bottom: 0,
                left: 0,
                right: 0,
              ),
            ),
            child: ColoredBox(
              color: palette.background,
              // The launch experience is painted over the whole window rather
              // than inside the app's column. That keeps the splash and the
              // onboarding edge to edge, with no colour band along the
              // status bar or the navigation bar.
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: mq.viewPadding.left,
                            right: mq.viewPadding.right,
                          ),
                          child: Offstage(
                            offstage: showLaunch,
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      if (!showLaunch)
                        Padding(
                          padding: EdgeInsets.only(
                            left: mq.viewPadding.left,
                            right: mq.viewPadding.right,
                          ),
                          child: const BottomAdSlot(),
                        ),
                      ColoredBox(
                        color:
                            showLaunch ? palette.background : palette.surface,
                        child: SizedBox(
                          height: bottomInset,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                  if (showLaunch)
                    Positioned.fill(
                      child: _showSplash
                          ? SplashPage(
                              onFinished: () {
                                if (mounted) {
                                  setState(() => _showSplash = false);
                                }
                              },
                            )
                          : OnboardingPage(
                              onFinished: () {
                                if (mounted) setState(() {});
                              },
                            ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

double _bottomInset(MediaQueryData mq) {
  final double reported = mq.padding.bottom >= mq.viewPadding.bottom
      ? mq.padding.bottom
      : mq.viewPadding.bottom;
  if (reported > 0) return reported;
  // Android 15+ edge-to-edge can report 0 while the 3-button bar still
  // covers the bottom of the screen.
  return defaultTargetPlatform == TargetPlatform.android ? 48 : 0;
}
