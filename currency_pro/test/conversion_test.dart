import 'package:currency_pro/core/utils/expression_parser.dart';
import 'package:currency_pro/core/utils/formatting.dart';
import 'package:currency_pro/data/currency_catalog.dart';
import 'package:currency_pro/data/currency_lookup.dart';
import 'package:currency_pro/data/fallback_rates.dart';
import 'package:currency_pro/data/models/currency.dart';
import 'package:currency_pro/data/models/rate_snapshot.dart';
import 'package:currency_pro/features/converters/unit_catalog.dart';
import 'package:currency_pro/features/converters/unit_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RateSnapshot', () {
    final RateSnapshot snapshot = RateSnapshot(
      base: 'USD',
      rates: const <String, double>{
        'USD': 1,
        'EUR': 0.92,
        'GBP': 0.78,
        'JPY': 155.0,
      },
      fetchedAt: DateTime(2026, 9, 22),
      providerUpdatedAt: DateTime(2026, 9, 22),
    );

    test('converts through the base currency', () {
      expect(snapshot.convert(100, 'USD', 'EUR'), closeTo(92, 1e-9));
      expect(snapshot.convert(100, 'EUR', 'USD'), closeTo(108.6956, 1e-3));
    });

    test('cross rates do not depend on the base', () {
      final double? eurGbp = snapshot.convert(1, 'EUR', 'GBP');
      expect(eurGbp, closeTo(0.78 / 0.92, 1e-9));
    });

    test('returns null for unknown codes', () {
      expect(snapshot.convert(1, 'USD', 'ZZZ'), isNull);
    });

    test('survives a JSON round trip', () {
      final RateSnapshot restored =
          RateSnapshot.decode(snapshot.encode())!;
      expect(restored.base, 'USD');
      expect(restored.rates['JPY'], 155.0);
      expect(restored.isStale, isFalse);
    });
  });

  group('FallbackRates', () {
    test('ships a usable USD table', () {
      expect(FallbackRates.snapshot.isEmpty, isFalse);
      expect(FallbackRates.snapshot.convert(100, 'USD', 'EUR'), isNotNull);
      expect(FallbackRates.snapshot.convert(1, 'USD', 'BTC'), isNotNull);
    });
  });

  group('ExpressionParser', () {
    final ExpressionParser parser = ExpressionParser();

    test('respects operator precedence', () {
      expect(parser.evaluate('2+3*4'), 14);
      expect(parser.evaluate('(2+3)*4'), 20);
    });

    test('handles the on-screen symbols', () {
      expect(parser.evaluate('10×5÷2'), 25);
      expect(parser.evaluate('10−4'), 6);
    });

    test('supports functions and constants', () {
      expect(parser.evaluate('sin(30)'), closeTo(0.5, 1e-9));
      expect(parser.evaluate('sqrt(81)'), 9);
      expect(parser.evaluate('pi'), closeTo(3.14159, 1e-4));
    });

    test('treats a trailing % as a percentage', () {
      expect(parser.evaluate('50%'), 0.5);
    });

    test('reports errors instead of crashing', () {
      expect(parser.tryEvaluate('5/0'), isNull);
      expect(parser.tryEvaluate('((2'), isNull);
    });
  });

  group('Unit conversion', () {
    UnitCategory byId(String id) =>
        kUnitCategories.firstWhere((UnitCategory c) => c.id == id);

    test('length round trips', () {
      final UnitCategory length = byId('length');
      final Unit km = length.unitBySymbol('km');
      final Unit mi = length.unitBySymbol('mi');
      expect(length.convert(1, mi, km), closeTo(1.609344, 1e-9));
      expect(length.convert(length.convert(5, km, mi), mi, km),
          closeTo(5, 1e-9));
    });

    test('temperature handles offsets', () {
      final UnitCategory temp = byId('temperature');
      final Unit c = temp.unitBySymbol('°C');
      final Unit f = temp.unitBySymbol('°F');
      expect(temp.convert(0, c, f), closeTo(32, 1e-6));
      expect(temp.convert(100, c, f), closeTo(212, 1e-6));
      expect(temp.convert(-40, c, f), closeTo(-40, 1e-6));
    });

    test('fuel economy inverts correctly', () {
      final UnitCategory fuel = byId('fuel');
      final Unit mpg = fuel.unitBySymbol('mpg');
      final Unit l100 = fuel.unitBySymbol('L/100km');
      expect(fuel.convert(30, mpg, l100), closeTo(7.8405, 1e-3));
    });

    test('every unit symbol inside a category is unique', () {
      for (final UnitCategory category in kUnitCategories) {
        final Set<String> symbols =
            category.units.map((Unit u) => u.symbol).toSet();
        expect(symbols.length, category.units.length,
            reason: 'duplicate symbol in ${category.id}');
      }
    });
  });

  group('Currency catalog', () {
    test('has no duplicate codes', () {
      final Set<String> codes =
          kAllCurrencies.map((Currency c) => c.code).toSet();
      expect(codes.length, kAllCurrencies.length);
    });

    test('builds flag emoji for fiat currencies', () {
      expect(CurrencyLookup.of('US' 'D').flag, '🇺🇸');
      expect(CurrencyLookup.of('JPY').flag, '🇯🇵');
      expect(CurrencyLookup.of('BTC').flag, '');
    });

    test('search matches code, name and country', () {
      expect(CurrencyLookup.search('yen').first.code, 'JPY');
      expect(CurrencyLookup.search('pakistan').first.code, 'PKR');
    });
  });

  group('Formatting', () {
    test('respects decimals and grouping', () {
      expect(Fmt.amount(1234.5678, decimals: 2), '1,234.57');
      expect(Fmt.amount(1234.5678, decimals: 0, grouping: false), '1235');
    });

    test('rounding modes behave', () {
      expect(Fmt.round(2.345, 2, RoundingMode.down), closeTo(2.34, 1e-9));
      expect(Fmt.round(2.341, 2, RoundingMode.up), closeTo(2.35, 1e-9));
    });

    test('smart trims trailing zeros', () {
      expect(Fmt.smart(12.500000), '12.5');
      expect(Fmt.smart(0), '0');
    });
  });
}
