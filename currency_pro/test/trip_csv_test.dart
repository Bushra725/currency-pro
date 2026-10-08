import 'package:currency_pro/core/l10n/l10n.dart';
import 'package:currency_pro/data/models/trip.dart';
import 'package:currency_pro/features/travel/trip_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a trip export lists the budget, expenses, and category totals', () {
    final Trip trip = Trip(
      id: '1',
      name: 'Paris, spring',
      homeCurrency: 'USD',
      localCurrency: 'EUR',
      budget: 100,
      budgetInLocal: true,
      startDate: DateTime(2026, 10, 8),
      endDate: DateTime(2026, 10, 14),
      expenses: <Expense>[
        Expense(
          id: 'e2',
          title: 'Museum "Louvre"',
          amount: 20,
          category: ExpenseCategory.sightseeing,
          date: DateTime(2026, 10, 9, 15, 30),
        ),
        Expense(
          id: 'e1',
          title: 'Lunch',
          note: 'Shared, with tip',
          amount: 40,
          category: ExpenseCategory.food,
          date: DateTime(2026, 10, 8, 12),
        ),
      ],
    );

    final String csv = buildTripCsv(
      trip: trip,
      l10n: L10n('en'),
      categoryLabel: (ExpenseCategory category) => category.name,
      budgetAmount: 100,
      budgetCurrency: 'EUR',
      remainingAmount: 40,
      budgetHome: 111.11,
      spentHome: 66.67,
      remainingHome: 44.44,
      toHome: (double amount) => amount / 0.9,
    );

    expect(
      csv,
      contains(
        '"Paris, spring",USD,EUR,100.00,EUR,2026-10-08,2026-10-14,7,Ongoing,60.00,40.00,111.11,66.67,44.44',
      ),
    );
    expect(csv.indexOf('Lunch'), lessThan(csv.indexOf('Museum')));
    expect(
      csv,
      contains('2026-10-08 12:00,Lunch,"Shared, with tip",food,40.00,EUR,44.44'),
    );
    expect(csv, contains('"Museum ""Louvre""",,sightseeing,20.00,EUR,22.22'));
    expect(csv, contains('food,40.00,EUR,44.44'));
    expect(csv, contains('sightseeing,20.00,EUR,22.22'));
    expect(tripCsvFileName('Paris, spring'), 'Paris, spring.csv');
    expect(tripCsvFileName('a/b:c'), 'a b c.csv');
    expect(tripCsvFileName('   '), 'trip.csv');
  });
}
