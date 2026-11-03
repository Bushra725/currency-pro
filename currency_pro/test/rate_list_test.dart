import 'package:currency_pro/core/theme/app_palette.dart';
import 'package:currency_pro/core/theme/app_theme.dart';
import 'package:currency_pro/core/utils/formatting.dart';
import 'package:currency_pro/data/models/rate_snapshot.dart';
import 'package:currency_pro/data/repositories/rates_repository.dart';
import 'package:currency_pro/data/services/prefs_service.dart';
import 'package:currency_pro/features/currency/rate_list_page.dart';
import 'package:currency_pro/state/rates_provider.dart';
import 'package:currency_pro/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('the rate list can change base currency and requotes every row',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final SharedPreferences raw = await SharedPreferences.getInstance();
    final PrefsService prefs = PrefsService(raw);
    await prefs.setString(
      PrefsService.kRateSnapshot,
      RateSnapshot(
        base: 'USD',
        rates: const <String, double>{
          'USD': 1,
          'EUR': 0.9,
          'GBP': 0.8,
        },
        fetchedAt: DateTime(2026, 11, 3),
        providerUpdatedAt: DateTime(2026, 11, 3),
      ).encode(),
    );
    final SettingsProvider settings = SettingsProvider(prefs);
    final RatesProvider rates = RatesProvider(RatesRepository(prefs: prefs));

    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<RatesProvider>.value(value: rates),
        ],
        child: MaterialApp(
          theme: AppTheme.build(kFallbackPalette),
          locale: const Locale('en'),
          home: const RateListPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('rate-list-base')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('rate-list-base')),
        matching: find.text('USD'),
      ),
      findsOneWidget,
    );
    expect(find.text('0.9'), findsWidgets);

    await tester.tap(find.byKey(const Key('rate-list-base')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(TextField),
      ),
      'Euro',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.data == 'EUR',
      ),
    ));
    await tester.pumpAndSettle();

    expect(settings.baseCode, 'EUR');
    expect(
      find.descendant(
        of: find.byKey(const Key('rate-list-base')),
        matching: find.text('EUR'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('EUR'), findsWidgets);
    expect(
      find.text(Fmt.smart(1 / 0.9, maxDecimals: 6)),
      findsOneWidget,
    );
    expect(
      find.text(Fmt.smart(0.8 / 0.9, maxDecimals: 6)),
      findsOneWidget,
    );
  });
}
