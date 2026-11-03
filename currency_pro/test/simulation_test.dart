import 'package:currency_pro/core/theme/app_palette.dart';
import 'package:currency_pro/core/theme/app_theme.dart';
import 'package:currency_pro/core/utils/formatting.dart';
import 'package:currency_pro/core/widgets/trend_chart.dart';
import 'package:currency_pro/data/models/rate_snapshot.dart';
import 'package:currency_pro/data/repositories/rates_repository.dart';
import 'package:currency_pro/data/services/history_api.dart';
import 'package:currency_pro/data/services/prefs_service.dart';
import 'package:currency_pro/features/currency/simulation_page.dart';
import 'package:currency_pro/state/rates_provider.dart';
import 'package:currency_pro/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefsService.kDefaultThemeV2: true,
      PrefsService.kDefaultThemeV3: true,
      PrefsService.kFeedbackDefaultsV2: true,
      PrefsService.kOnboardingDone: true,
    });
  });

  testWidgets('simulation shows 10D 1M 3M chips, a chart, and date-wise rates',
      (WidgetTester tester) async {
    final List<RatePoint> eur = _series(startRate: 0.90);
    final _FakeHistory history = _FakeHistory(<String, List<RatePoint>>{
      'USD>EUR': eur,
      'EUR>USD': _series(startRate: 1.10),
    });
    await tester.pumpWidget(await _app(history));
    await tester.pumpAndSettle();

    expect(find.text('10D'), findsOneWidget);
    expect(find.text('1M'), findsOneWidget);
    expect(find.text('3M'), findsOneWidget);
    expect(find.byKey(const Key('sim-range-10D')), findsOneWidget);
    expect(find.byType(TrendChart), findsOneWidget);
    expect(find.text('-10%'), findsNothing);
    expect(find.text('-5%'), findsNothing);

    await _scrollTo(tester, find.byKey(const Key('sim-history-table')));
    expect(find.text('Historical rates'), findsOneWidget);
    expect(find.text(Fmt.date(DateTime(2026, 11, 2))), findsWidgets);
    expect(find.text(Fmt.date(DateTime(2026, 11, 1))), findsWidgets);
    expect(find.text(Fmt.date(DateTime(2026, 10, 31))), findsWidgets);
    expect(find.text(Fmt.date(DateTime(2026, 10, 4))), findsNothing);

    await tester.tap(find.byKey(const Key('sim-range-1M')));
    await tester.pumpAndSettle();
    expect(history.requestedDays, contains(30));
    await _scrollTo(tester, find.text(Fmt.date(DateTime(2026, 10, 4))));
    expect(find.text(Fmt.date(DateTime(2026, 10, 4))), findsWidgets);

    await tester.tap(find.byKey(const Key('sim-range-3M')));
    await tester.pumpAndSettle();
    expect(history.requestedDays, contains(90));
    await _scrollTo(tester, find.text(Fmt.date(DateTime(2026, 8, 5))));
    expect(find.text(Fmt.date(DateTime(2026, 8, 5))), findsWidgets);
  });
}

Finder _simScrollable() {
  return find
      .descendant(
        of: find.byKey(const Key('sim-scroll')),
        matching: find.byType(Scrollable),
      )
      .first;
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    500,
    scrollable: _simScrollable(),
  );
}

Future<Widget> _app(_FakeHistory history) async {
  final SharedPreferences raw = await SharedPreferences.getInstance();
  final PrefsService prefs = PrefsService(raw);
  await prefs.setString(
    PrefsService.kRateSnapshot,
    RateSnapshot(
      base: 'USD',
      rates: const <String, double>{'USD': 1, 'EUR': 0.9, 'GBP': 0.8},
      fetchedAt: DateTime(2026, 11, 3),
      providerUpdatedAt: DateTime(2026, 11, 3),
    ).encode(),
  );
  final SettingsProvider settings = SettingsProvider(prefs);
  final RatesProvider rates = RatesProvider(RatesRepository(prefs: prefs));
  return MultiProvider(
    providers: <ChangeNotifierProvider<dynamic>>[
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<RatesProvider>.value(value: rates),
    ],
    child: MaterialApp(
      theme: AppTheme.build(kFallbackPalette),
      locale: const Locale('en'),
      home: SimulationPage(historyApi: history),
    ),
  );
}

List<RatePoint> _series({required double startRate}) {
  return <RatePoint>[
    for (int i = 89; i >= 0; i--)
      RatePoint(
        DateTime(2026, 11, 2).subtract(Duration(days: i)),
        startRate + (89 - i) * 0.0002,
      ),
  ];
}

class _FakeHistory extends HistoryApi {
  _FakeHistory(this.pointsByPair) : super(client: _SilentClient());

  final Map<String, List<RatePoint>> pointsByPair;
  final List<int> requestedDays = <int>[];

  @override
  Future<HistorySeries> series(String from, String to, int days) async {
    requestedDays.add(days);
    final List<RatePoint> all =
        pointsByPair['$from>$to'] ?? const <RatePoint>[];
    if (all.isEmpty) return const HistorySeries.ok(<RatePoint>[]);
    final DateTime cutoff = all.last.date.subtract(Duration(days: days));
    return HistorySeries.ok(
      all.where((RatePoint point) => point.date.isAfter(cutoff)).toList(),
    );
  }
}

class _SilentClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnsupportedError('network');
  }
}
