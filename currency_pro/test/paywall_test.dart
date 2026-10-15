import 'dart:async';

import 'package:currency_pro/core/app_config.dart';
import 'package:currency_pro/core/theme/app_palette.dart';
import 'package:currency_pro/core/theme/app_theme.dart';
import 'package:currency_pro/data/services/prefs_service.dart';
import 'package:currency_pro/features/premium/paywall_page.dart';
import 'package:currency_pro/state/premium_billing.dart';
import 'package:currency_pro/state/premium_controller.dart';
import 'package:currency_pro/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBilling implements PremiumBilling {
  _FakeBilling({this.grantOnBuy = true, this.grantOnRestore = false});

  final StreamController<PremiumUpdate> _updates =
      StreamController<PremiumUpdate>.broadcast();
  final bool grantOnBuy;
  final bool grantOnRestore;

  @override
  Stream<PremiumUpdate> get updates => _updates.stream;

  @override
  void attach() {}

  @override
  Future<String?> loadPrice(String productId) async => r'US$4.99';

  @override
  Future<bool> buy(String productId) async {
    if (!grantOnBuy) return false;
    _updates.add(PremiumUpdate(productId, PremiumUpdateKind.purchased));
    return true;
  }

  @override
  Future<void> restore() async {
    if (!grantOnRestore) return;
    _updates.add(PremiumUpdate(
      AppConfig.premiumProductId,
      PremiumUpdateKind.restored,
    ));
  }

  @override
  void dispose() {
    _updates.close();
  }
}

Future<PremiumController> _open(
  WidgetTester tester, {
  required _FakeBilling billing,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    PrefsService.kLocaleCode: 'en',
  });
  final PrefsService prefs = await PrefsService.create();
  final SettingsProvider settings = SettingsProvider(prefs);
  final PremiumController premium =
      PremiumController(prefs, billing: billing);
  await premium.start();
  await tester.pumpWidget(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<PremiumController>.value(value: premium),
      ],
      child: MaterialApp(
        theme: AppTheme.build(kFallbackPalette),
        locale: const Locale('en'),
        home: const PaywallPage(),
      ),
    ),
  );
  await tester.pump();
  return premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buying premium shows the unlocked content', (tester) async {
    final PremiumController premium =
        await _open(tester, billing: _FakeBilling());

    expect(find.text('CurrencyPro Premium'), findsOneWidget);
    expect(find.text('WHAT YOU UNLOCK'), findsOneWidget);
    expect(find.text('No ads on any screen'), findsOneWidget);
    expect(find.text('Unlimited rate alerts'), findsOneWidget);
    expect(find.text('Full trend-chart history'), findsOneWidget);
    expect(find.text('Trip budget export'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
    expect(find.text(r'US$4.99'), findsOneWidget);
    expect(find.textContaining('sandbox account'), findsOneWidget);

    await tester.tap(find.text('Buy Premium'));
    await tester.pump();

    expect(find.text('Premium is active'), findsOneWidget);
    expect(
      find.text('Buying unlocked these on this account'),
      findsOneWidget,
    );
    expect(find.text('BUYING UNLOCKED THESE ON THIS ACCOUNT'), findsOneWidget);
    expect(find.text('No ads on any screen'), findsOneWidget);
    expect(find.text('Buy Premium'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    premium.dispose();
  });

  testWidgets('restore with no purchase says nothing was found', (tester) async {
    final PremiumController premium = await _open(
      tester,
      billing: _FakeBilling(grantOnBuy: false),
    );

    await tester.tap(find.text('Restore Purchases'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      find.text('No previous purchase was found for this account'),
      findsOneWidget,
    );
    expect(find.text('Premium is active'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    premium.dispose();
  });

  testWidgets('restore brings premium back', (tester) async {
    final PremiumController premium = await _open(
      tester,
      billing: _FakeBilling(grantOnRestore: true),
    );

    await tester.tap(find.text('Restore Purchases'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Premium is active'), findsOneWidget);
    expect(find.text('Purchases restored'), findsOneWidget);
    expect(find.text('No ads on any screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    premium.dispose();
  });
}
