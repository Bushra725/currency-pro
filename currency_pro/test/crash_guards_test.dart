import 'package:currency_pro/core/notifications/notification_permission.dart';
import 'package:currency_pro/core/theme/app_palette.dart';
import 'package:currency_pro/core/theme/app_theme.dart';
import 'package:currency_pro/data/models/trip.dart';
import 'package:currency_pro/data/services/prefs_service.dart';
import 'package:currency_pro/state/trips_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a missing notification plugin does not throw', () async {
    expect(await NotificationPermission.request(), isFalse);
    expect(await NotificationPermission.isGranted(), isFalse);
  });

  test('a second notification request waits instead of throwing', () async {
    final Future<bool> first = NotificationPermission.request();
    final Future<bool> second = NotificationPermission.request();
    expect(await first, isFalse);
    expect(await second, isFalse);
  });

  test('adding a trip expense survives a non-finite amount', () async {
    final SharedPreferences raw = await SharedPreferences.getInstance();
    final TripsProvider trips = TripsProvider(PrefsService(raw));
    const String id = 'trip-1';
    await trips.add(
      Trip(
        id: id,
        name: 'Lisbon',
        homeCurrency: 'USD',
        localCurrency: 'EUR',
        budget: 1000,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 7),
      ),
    );

    await trips.addExpense(
      id,
      Expense(
        id: 'bad',
        title: 'oops',
        amount: double.infinity,
        category: ExpenseCategory.food,
        date: DateTime(2026, 6, 2),
      ),
    );
    expect(trips.byId(id)!.expenses, isEmpty);

    await trips.addExpense(
      id,
      Expense(
        id: 'meal',
        title: 'Lunch',
        amount: 12.5,
        category: ExpenseCategory.food,
        date: DateTime(2026, 6, 2),
      ),
    );
    expect(trips.byId(id)!.expenses, hasLength(1));
    expect(trips.byId(id)!.expenses.single.amount, 12.5);

    final TripsProvider restored = TripsProvider(PrefsService(raw));
    expect(restored.byId(id)!.expenses.single.title, 'Lunch');
  });

  test('iOS taps use a ripple instead of the sparkle shader', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      AppTheme.build(kFallbackPalette).splashFactory,
      InkRipple.splashFactory,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      AppTheme.build(kFallbackPalette).splashFactory,
      InkSparkle.splashFactory,
    );
  });
}
