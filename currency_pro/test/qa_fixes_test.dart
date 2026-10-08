import 'package:audioplayers/audioplayers.dart';
import 'package:currency_pro/core/l10n/l10n.dart';
import 'package:currency_pro/core/theme/app_palette.dart';
import 'package:currency_pro/core/theme/app_theme.dart';
import 'package:currency_pro/core/utils/haptics.dart';
import 'package:currency_pro/core/widgets/app_drawer.dart';
import 'package:currency_pro/core/widgets/brand_logo.dart';
import 'package:currency_pro/core/widgets/app_dropdown.dart';
import 'package:currency_pro/core/widgets/calc_keypad.dart';
import 'package:currency_pro/core/widgets/rate_app_bar.dart';
import 'package:currency_pro/core/widgets/screen_title.dart';
import 'package:currency_pro/core/widgets/trend_chart.dart';
import 'package:currency_pro/data/models/rate_snapshot.dart';
import 'package:currency_pro/data/repositories/rates_repository.dart';
import 'package:currency_pro/data/services/prefs_service.dart';
import 'package:currency_pro/features/alerts/rate_alert_page.dart';
import 'package:currency_pro/features/travel/travel_budget_page.dart';
import 'package:currency_pro/state/trips_provider.dart';
import 'package:currency_pro/features/currency/metals_page.dart';
import 'package:currency_pro/state/alerts_provider.dart';
import 'package:currency_pro/features/currency/multi_currency_page.dart';
import 'package:currency_pro/routes.dart';
import 'package:currency_pro/state/rates_provider.dart';
import 'package:currency_pro/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
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

  test('keypad click asks for no audio focus and does not duck music', () {
    final AudioContext ctx = Haptics.clickContext;
    expect(ctx.android.audioFocus, AndroidAudioFocus.none);
    expect(ctx.android.contentType, AndroidContentType.sonification);
    expect(ctx.android.usageType, AndroidUsageType.assistanceSonification);
    expect(ctx.iOS.category, AVAudioSessionCategory.ambient);
    expect(ctx.iOS.options, isNot(contains(AVAudioSessionOptions.duckOthers)));
    expect(
      ctx.iOS.options,
      isNot(contains(AVAudioSessionOptions.mixWithOthers)),
    );
  });

  test('system language follows the phone after a manual language was chosen',
      () {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('fr'),
    ];
    addTearDown(binding.platformDispatcher.clearLocalesTestValue);

    expect(AppLocales.effectiveLocale('es').languageCode, 'es');
    expect(AppLocales.effectiveLocale('system').languageCode, 'fr');

    binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('de'),
    ];
    expect(AppLocales.effectiveLocale('system').languageCode, 'de');
    expect(AppLocales.effectiveLocale('es').languageCode, 'es');
  });

  testWidgets('choosing device language drops the previous app language',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[
      Locale('fr'),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final _Boot boot = await _boot();
    await tester.pumpWidget(_localeHost(boot.settings));
    expect(find.text('Devises en temps réel'), findsOneWidget);

    await tester.tap(find.text('pick-es'));
    await tester.pumpAndSettle();
    expect(find.text('Divisa en tiempo real'), findsOneWidget);
    expect(find.text('Devises en temps réel'), findsNothing);

    await tester.tap(find.text('pick-system'));
    await tester.pumpAndSettle();
    expect(find.text('Devises en temps réel'), findsOneWidget);
    expect(find.text('Divisa en tiempo real'), findsNothing);
  });

  testWidgets('sidebar highlight scrolls with its row', (WidgetTester tester) async {
    final _Boot boot = await _boot();
    final SettingsProvider settings = boot.settings;
    await tester.pumpWidget(_app(
      settings,
      home: const Scaffold(
        drawer: AppDrawer(current: Routes.home),
        body: _OpenDrawer(),
      ),
    ));
    await tester.tap(find.text('open-drawer'));
    await tester.pumpAndSettle();

    final Finder label = find.text('Real-Time Currency');
    expect(label, findsOneWidget);
    final Finder highlight = find.ancestor(
      of: label,
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is Material && w.color == settings.palette.primarySoft,
      ),
    );
    expect(highlight, findsOneWidget);
    final double highlightBefore = tester.getTopLeft(highlight).dy;
    final double labelBefore = tester.getTopLeft(label).dy;

    await tester.drag(
      find.descendant(of: find.byType(Drawer), matching: find.byType(ListView)),
      const Offset(0, -160),
    );
    await tester.pumpAndSettle();

    final double highlightDelta = tester.getTopLeft(highlight).dy - highlightBefore;
    final double labelDelta = tester.getTopLeft(label).dy - labelBefore;
    expect(labelDelta, lessThan(-80));
    expect(highlightDelta, closeTo(labelDelta, 1));
  });

  testWidgets('dropdown opens from the button for every selected unit',
      (WidgetTester tester) async {
    String unit = 'oz t';
    final List<String> units = <String>['oz t', 'g', 'kg', 'tola'];

    Future<void> pump() {
      return tester.pumpWidget(_app(
        null,
        home: Scaffold(
          body: Center(
            child: AppDropdown<String>(
              value: unit,
              entries: units
                  .map((String u) => AppDropdownEntry<String>(value: u, label: u))
                  .toList(growable: false),
              onChanged: (String v) => unit = v,
            ),
          ),
        ),
      ));
    }

    Future<double> firstItemOffset() async {
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();
      final double buttonBottom =
          tester.getBottomLeft(find.byType(AppDropdown<String>)).dy;
      final double firstItemTop =
          tester.getTopLeft(find.byType(PopupMenuItem<String>).first).dy;
      return firstItemTop - buttonBottom;
    }

    await pump();
    final double fromFirst = await firstItemOffset();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    unit = 'tola';
    await pump();
    final double fromLast = await firstItemOffset();

    expect(fromFirst, greaterThan(0));
    expect(fromLast, closeTo(fromFirst, 1));
  });

  testWidgets('an open dropdown closes on an outside tap without changing',
      (WidgetTester tester) async {
    String unit = 'g';
    await tester.pumpWidget(_app(
      null,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Center(
              child: AppDropdown<String>(
                value: unit,
                entries: const <AppDropdownEntry<String>>[
                  AppDropdownEntry(value: 'oz t', label: 'oz t'),
                  AppDropdownEntry(value: 'g', label: 'g'),
                  AppDropdownEntry(value: 'kg', label: 'kg'),
                  AppDropdownEntry(value: 'tola', label: 'tola'),
                ],
                onChanged: (String v) => setState(() => unit = v),
              ),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.byType(AppDropdown<String>));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsWidgets);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(unit, 'g');
  });

  testWidgets('tapping the dropdown button again dismisses it',
      (WidgetTester tester) async {
    String unit = 'kg';
    await tester.pumpWidget(_app(
      null,
      home: Scaffold(
        body: Center(
          child: AppDropdown<String>(
            value: unit,
            entries: const <AppDropdownEntry<String>>[
              AppDropdownEntry(value: 'oz t', label: 'oz t'),
              AppDropdownEntry(value: 'g', label: 'g'),
              AppDropdownEntry(value: 'kg', label: 'kg'),
              AppDropdownEntry(value: 'tola', label: 'tola'),
            ],
            onChanged: (String v) => unit = v,
          ),
        ),
      ),
    ));

    final Offset button = tester.getCenter(find.byType(AppDropdown<String>));
    await tester.tap(find.byType(AppDropdown<String>));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsWidgets);

    await tester.tapAt(button);
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(unit, 'kg');
  });

  testWidgets('a one-letter unit keeps the standard dropdown width',
      (WidgetTester tester) async {
    const List<AppDropdownEntry<String>> units = <AppDropdownEntry<String>>[
      AppDropdownEntry<String>(value: 'oz t', label: 'oz t'),
      AppDropdownEntry<String>(value: 'g', label: 'g'),
      AppDropdownEntry<String>(value: 'kg', label: 'kg'),
      AppDropdownEntry<String>(value: 'tola', label: 'tola'),
    ];

    Future<double> widthOf(String unit) async {
      await tester.pumpWidget(_app(
        null,
        home: Scaffold(
          body: Center(
            child: AppDropdown<String>(
              value: unit,
              entries: units,
              onChanged: (_) {},
            ),
          ),
        ),
      ));
      return tester.getSize(find.byType(AppDropdown<String>)).width;
    }

    final double grams = await widthOf('g');
    final double troy = await widthOf('oz t');
    final double tola = await widthOf('tola');
    expect(grams, closeTo(troy, 0.5));
    expect(grams, closeTo(tola, 0.5));
  });

  testWidgets('metal unit menu stays under the selector for the last unit',
      (WidgetTester tester) async {
    final _Boot boot = await _boot();
    await tester.pumpWidget(_app(
      boot.settings,
      prefs: boot.prefs,
      rates: _rates(boot.prefs),
      home: const MetalsPage(),
    ));
    await tester.pump();

    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.byKey(const Key('price-metal-unit')), findsOneWidget);

    final double fromDefault = await _menuOffset(tester);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('price-metal-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'tola'));
    await tester.pumpAndSettle();

    final double fromLast = await _menuOffset(tester);
    expect(fromDefault, greaterThan(0));
    expect(fromLast, closeTo(fromDefault, 1));
  });

  testWidgets('action button labels stay fully inside their pills',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const List<String> labels = <String>[
      'EXCHANGE\nUPDATE',
      'EXCHANGE\nCHART',
      'FAVORITES',
      'CURRENCY\nSWITCH',
    ];
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
        child: _app(
          null,
          home: Scaffold(
            body: QuickActionBar(
              actions: <QuickAction>[
                for (final String label in labels)
                  QuickAction(
                    icon: Icons.circle,
                    label: label,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final String label in labels) {
      final Finder text = find.text(label);
      expect(text, findsOneWidget);
      final RenderBox box = tester.renderObject<RenderBox>(text);
      final RenderBox pill = tester.renderObject<RenderBox>(
        find.ancestor(of: text, matching: find.byType(Material)).first,
      );
      expect(box.size.width, lessThanOrEqualTo(pill.size.width + 0.5));
      expect(box.size.height, greaterThan(0));
      expect(tester.widget<Text>(text).overflow, isNot(TextOverflow.ellipsis));
    }
  });

  testWidgets('main screen titles stay complete in a crowded app bar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const List<String> titles = <String>[
      'REAL-TIME CURRENCY',
      'MULTI CURRENCY CONVERTER',
      'BMI CALCULATOR',
      'PERCENTAGE CALCULATOR',
      'LOAN / EMI CALCULATOR',
      'DISCOUNT CALCULATOR',
      'SCIENTIFIC CALCULATOR',
      'DATE DIFFERENCE',
      'NUMBER BASE',
      'UNIT CONVERTERS',
      'HEIGHT CONVERTER',
      'ABOUT APP',
    ];

    for (final String title in titles) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
          child: _app(
            null,
            home: Scaffold(
              appBar: AppBar(
                title: ScreenTitle(title),
                actions: const <Widget>[
                  Icon(Icons.refresh_rounded),
                  Icon(Icons.grid_view_rounded),
                  Icon(Icons.more_vert),
                ],
              ),
            ),
          ),
        ),
      );
      final Text text = tester.widget<Text>(find.text(title));
      final RenderParagraph paragraph =
          tester.renderObject<RenderParagraph>(find.text(title));
      expect(text.overflow, TextOverflow.visible);
      expect(text.softWrap, isFalse);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.text.toPlainText(), title);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('screen titles are the name only, with no brand icon',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _Boot boot = await _boot();
    final RatesProvider rates = _rates(boot.prefs);

    Future<void> expectNameOnly(String title) async {
      await tester.pumpWidget(_app(
        boot.settings,
        prefs: boot.prefs,
        rates: rates,
        home: Scaffold(
          appBar: RateAppBar(title: title),
        ),
      ));
      await tester.pump();
      expect(find.byType(BrandLogo), findsNothing);
      final String shown = title.toUpperCase();
      final Text text = tester.widget<Text>(find.text(shown));
      final RenderParagraph paragraph =
          tester.renderObject<RenderParagraph>(find.text(shown));
      expect(text.style?.fontSize, 16);
      expect(text.maxLines, 1);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    }

    await expectNameOnly('Real-Time Currency');
    await expectNameOnly('Multi Currency Converter');
    await expectNameOnly('Trend Charts');
  });

  testWidgets('multi currency count uses a flag, not a copy icon',
      (WidgetTester tester) async {
    final _Boot boot = await _boot();
    await tester.pumpWidget(_app(
      boot.settings,
      prefs: boot.prefs,
      rates: _rates(boot.prefs),
      home: const MultiCurrencyPage(),
    ));
    await tester.pump();

    final Finder selector = find.descendant(
      of: find.byType(RateAppBar),
      matching: find.byType(AppDropdown<int>),
    );
    expect(selector, findsOneWidget);
    expect(
      find.descendant(of: selector, matching: find.byIcon(Icons.flag_outlined)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: selector, matching: find.byIcon(Icons.content_copy)),
      findsNothing,
    );
    expect(
      find.descendant(of: selector, matching: find.byIcon(Icons.copy)),
      findsNothing,
    );
    expect(
      find.descendant(of: selector, matching: find.byIcon(Icons.copy_rounded)),
      findsNothing,
    );
  });

  testWidgets('price tab can add a currency beyond the defaults',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _Boot boot = await _boot();
    final RatesProvider rates = _rates(boot.prefs);

    Future<void> openPrices() async {
      await tester.pumpWidget(_app(
        boot.settings,
        prefs: boot.prefs,
        rates: rates,
        home: const MetalsPage(),
      ));
      await tester.pump();
    }

    await openPrices();
    expect(find.text('U.S. Dollar'), findsOneWidget);
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Gold (troy ounce)'), findsOneWidget);
    expect(find.text('Silver (troy ounce)'), findsOneWidget);
    expect(find.text('Euro'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('price-add-currency')));
    await tester.tap(find.byKey(const Key('price-add-currency')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Euro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR'));
    await tester.pumpAndSettle();

    expect(find.text('Euro'), findsOneWidget);
    expect(boot.prefs.getStringList('price_currencies'), <String>['EUR']);

    await openPrices();
    await tester.ensureVisible(find.text('Euro'));
    expect(find.text('Euro'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Euro'), findsNothing);
    expect(boot.prefs.getStringList('price_currencies'), isEmpty);
  });

  testWidgets('cross rate can add a currency, set the base, and show key points',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final _Boot boot = await _boot();
    await tester.pumpWidget(_app(
      boot.settings,
      prefs: boot.prefs,
      rates: _rates(boot.prefs),
      home: const MetalsPage(),
    ));
    await tester.pump();

    await tester.tap(find.widgetWithText(Tab, 'Cross rate'));
    await tester.pumpAndSettle();

    expect(find.text('Key points'), findsOneWidget);
    expect(find.byKey(const Key('cross-base')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('cross-row-USD')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('key-point-EUR')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('key-point-USD')), findsNothing);

    await tester.tap(find.byKey(const Key('cross-add-currency')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'GBP');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.data == 'GBP',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('cross-row-GBP')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('key-point-GBP')), findsOneWidget);
    expect(boot.prefs.getStringList('cross_currencies'), <String>['GBP']);

    await tester.tap(find.byKey(const Key('cross-base')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'GBP');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.data == 'GBP',
      ),
    ));
    await tester.pumpAndSettle();

    final List<Text> rows = tester
        .widgetList<Text>(find.byWidgetPredicate((Widget widget) {
          final Key? key = widget.key;
          return key is ValueKey<String> && key.value.startsWith('cross-row-');
        }))
        .toList();
    expect(rows.first.data, 'GBP');
    expect(find.byKey(const ValueKey<String>('key-point-GBP')), findsNothing);
    expect(find.byKey(const ValueKey<String>('key-point-USD')), findsOneWidget);
    expect(boot.prefs.getString('cross_base'), 'GBP');
  });

  testWidgets('assets and price share the base currency and each metal unit',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefsService.kDefaultThemeV2: true,
      PrefsService.kDefaultThemeV3: true,
      PrefsService.kFeedbackDefaultsV2: true,
      PrefsService.kOnboardingDone: true,
      'my_assets': '{"XAU":1,"USD":10}',
    });
    final _Boot boot = await _boot();
    await tester.pumpWidget(_app(
      boot.settings,
      prefs: boot.prefs,
      rates: _rates(boot.prefs),
      home: const MetalsPage(),
    ));
    await tester.pump();

    await tester.tap(find.widgetWithText(Tab, 'My assets'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assets-base')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('asset-unit-XAU')), findsOneWidget);

    await tester.tap(find.byKey(const Key('assets-base')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Euro');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.data == 'EUR',
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Price'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('price-base')),
        matching: find.text('EUR'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(Tab, 'My assets'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('asset-unit-XAU')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'g'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Price'));
    await tester.pumpAndSettle();
    expect(find.text('Price per g'), findsOneWidget);

    await tester.tap(find.byKey(const Key('price-metal-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'tola'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'My assets'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('asset-unit-XAU')),
        matching: find.text('tola'),
      ),
      findsOneWidget,
    );
    expect(boot.prefs.getString('metal_unit'), 'tola');
  });

  testWidgets('a rate alert can be set from a rise or fall percentage',
      (WidgetTester tester) async {
    final _Boot boot = await _boot();
    final RateSnapshot snapshot = RateSnapshot(
      base: 'USD',
      rates: const <String, double>{'USD': 1, 'EUR': 0.9},
      fetchedAt: DateTime(2026, 10, 8),
      providerUpdatedAt: DateTime(2026, 10, 8),
    );
    await boot.prefs.setString(PrefsService.kRateSnapshot, snapshot.encode());
    final RatesProvider rates = _rates(boot.prefs);
    final AlertsProvider alerts = AlertsProvider(boot.prefs);

    await tester.pumpWidget(_app(
      boot.settings,
      prefs: boot.prefs,
      rates: rates,
      alerts: alerts,
      home: const RateAlertPage(),
    ));
    await tester.pump();

    await tester.tap(find.text('Add new alert'));
    await tester.pumpAndSettle();

    expect(find.text('Percentage change'), findsWidgets);
    expect(find.text('5%'), findsOneWidget);

    String targetText() {
      final List<TextField> fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      return fields.last.controller!.text;
    }

    expect(targetText(), '0.945');

    await tester.tap(find.text('10%'));
    await tester.pumpAndSettle();
    expect(targetText(), '0.99');

    await tester.tap(find.text('Falls to'));
    await tester.pumpAndSettle();
    expect(targetText(), '0.81');
  });

  testWidgets('a trip budget is entered in the destination currency',
      (WidgetTester tester) async {
    final _Boot boot = await _boot();
    final RateSnapshot snapshot = RateSnapshot(
      base: 'USD',
      rates: const <String, double>{'USD': 1, 'EUR': 0.9},
      fetchedAt: DateTime(2026, 10, 8),
      providerUpdatedAt: DateTime(2026, 10, 8),
    );
    await boot.prefs.setString(PrefsService.kRateSnapshot, snapshot.encode());
    final RatesProvider rates = _rates(boot.prefs);
    final TripsProvider trips = TripsProvider(boot.prefs);

    await tester.pumpWidget(_app(
      boot.settings,
      prefs: boot.prefs,
      rates: rates,
      trips: trips,
      home: const TravelBudgetPage(),
    ));
    await tester.pump();

    await tester.tap(find.text('ADD NEW TRIP'));
    await tester.pumpAndSettle();

    final TextField budget =
        tester.widget<TextField>(find.byKey(const Key('trip-budget')));
    expect(budget.decoration!.suffixText, 'EUR');
    expect(find.text('About 1,111.11 USD at home'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('trip-budget')), '100');
    await tester.pumpAndSettle();
    expect(find.text('About 111.11 USD at home'), findsOneWidget);

    await tester.tap(find.text('CREATE TRIP'));
    await tester.pumpAndSettle();

    expect(find.text('100.00 EUR'), findsWidgets);
    expect(find.text('0.00 EUR'), findsOneWidget);
    expect(find.text('≈ 0.00 USD'), findsOneWidget);
    expect(find.text('≈ 111.11 USD'), findsOneWidget);

    await tester.tap(find.text('EXPENSE'));
    await tester.pumpAndSettle();
    final Finder expenseAmount = find.byWidgetPredicate(
      (Widget widget) =>
          widget is TextField && widget.decoration?.labelText == 'Amount',
    );
    expect(
      tester.widget<TextField>(expenseAmount).decoration!.suffixText,
      'EUR',
    );
    await tester.enterText(expenseAmount, '40');
    await tester.enterText(find.byKey(const Key('expense-note')), 'Airport taxi');
    expect(find.byKey(const Key('expense-date')), findsOneWidget);
    await tester.ensureVisible(find.text('SAVE EXPENSE'));
    await tester.tap(find.text('SAVE EXPENSE'));
    await tester.pumpAndSettle();

    expect(find.text('40.00 EUR'), findsOneWidget);
    expect(find.text('≈ 44.44 USD'), findsOneWidget);
    expect(find.text('60.00 EUR'), findsOneWidget);
    expect(find.text('≈ 66.67 USD'), findsOneWidget);

    await tester.tap(find.text('Spending overview'));
    await tester.pumpAndSettle();
    expect(find.text('Daily spending'), findsOneWidget);
    expect(find.text('Per day'), findsOneWidget);
    expect(find.textContaining('Airport taxi'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edit expense'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('expense-amount')), '25');
    await tester.enterText(
      find.byKey(const Key('expense-note')),
      'Airport taxi, tip',
    );
    await tester.ensureVisible(find.text('SAVE EXPENSE'));
    await tester.tap(find.text('SAVE EXPENSE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Airport taxi, tip'), findsOneWidget);
    expect(find.text('25.00 EUR'), findsWidgets);
    expect(find.text('75.00 EUR'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Export CSV'), findsOneWidget);
  });

  testWidgets('a failed chart shows the friendly message and nothing technical',
      (WidgetTester tester) async {
    final _Boot boot = await _boot();
    const String friendly =
        'Check your internet connection';
    expect(L10n('en').chartLoadFailed, friendly);

    await tester.pumpWidget(_app(
      boot.settings,
      home: const Scaffold(body: TrendChart(points: <RatePoint>[])),
    ));

    // An empty series is missing history, not a dropped connection.
    expect(find.text(L10n('en').chartNoHistory), findsOneWidget);
    expect(find.text(friendly), findsNothing);
    expect(find.textContaining('http'), findsNothing);
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('frankfurter'), findsNothing);
    expect(find.textContaining('from='), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  });
}

class _Boot {
  _Boot(this.settings, this.prefs);

  final SettingsProvider settings;
  final PrefsService prefs;
}

Future<_Boot> _boot() async {
  final SharedPreferences raw = await SharedPreferences.getInstance();
  final PrefsService prefs = PrefsService(raw);
  return _Boot(SettingsProvider(prefs), prefs);
}

RatesProvider _rates(PrefsService prefs) {
  return RatesProvider(RatesRepository(prefs: prefs));
}

Widget _app(
  SettingsProvider? settings, {
  PrefsService? prefs,
  RatesProvider? rates,
  AlertsProvider? alerts,
  TripsProvider? trips,
  required Widget home,
}) {
  final AppPalette palette = settings?.palette ?? kFallbackPalette;
  final Widget app = MaterialApp(
    theme: AppTheme.build(palette),
    locale: const Locale('en'),
    home: home,
  );
  final List<SingleChildWidget> providers = <SingleChildWidget>[
    if (settings != null)
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
    if (prefs != null) Provider<PrefsService>.value(value: prefs),
    if (rates != null) ChangeNotifierProvider<RatesProvider>.value(value: rates),
    if (alerts != null) ChangeNotifierProvider<AlertsProvider>.value(value: alerts),
    if (trips != null) ChangeNotifierProvider<TripsProvider>.value(value: trips),
  ];
  if (providers.isEmpty) return app;
  return MultiProvider(providers: providers, child: app);
}

Widget _localeHost(SettingsProvider settings) {
  return ChangeNotifierProvider<SettingsProvider>.value(
    value: settings,
    child: Builder(
      builder: (BuildContext context) {
        final SettingsProvider current = context.watch<SettingsProvider>();
        return MaterialApp(
          locale: AppLocales.effectiveLocale(current.localeCode),
          supportedLocales: AppLocales.materialLocales,
          localeListResolutionCallback:
              (List<Locale>? _, Iterable<Locale> __) {
            return AppLocales.effectiveLocale(current.localeCode);
          },
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.build(current.palette),
          home: Builder(
            builder: (BuildContext context) {
              return Column(
                children: <Widget>[
                  Text(L10n.of(context).realTimeCurrency),
                  TextButton(
                    onPressed: () => current.setLocaleCode('es'),
                    child: const Text('pick-es'),
                  ),
                  TextButton(
                    onPressed: () => current.setLocaleCode(AppLocales.systemCode),
                    child: const Text('pick-system'),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

class _OpenDrawer extends StatelessWidget {
  const _OpenDrawer();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Scaffold.of(context).openDrawer(),
      child: const Text('open-drawer'),
    );
  }
}

Future<double> _menuOffset(WidgetTester tester) async {
  final Finder dropdown = find.byKey(const Key('price-metal-unit'));
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final double buttonBottom = tester.getBottomLeft(dropdown).dy;
  final double firstItemTop =
      tester.getTopLeft(find.byType(PopupMenuItem<String>).first).dy;
  return firstItemTop - buttonBottom;
}
