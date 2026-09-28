import 'package:flutter/material.dart';

/// One measurement unit.
///
/// Conversions run through a category base unit:
/// ```
/// toBase(v)   = reciprocal ? factor / v : v * factor + offset
/// fromBase(b) = reciprocal ? factor / b : (b - offset) / factor
/// ```
/// The `reciprocal` flag exists for inverse scales such as miles-per-gallon
/// versus litres-per-100 km.
class Unit {
  const Unit({
    required this.name,
    required this.symbol,
    required this.factor,
    this.offset = 0,
    this.reciprocal = false,
  });

  final String name;
  final String symbol;
  final double factor;
  final double offset;
  final bool reciprocal;

  double toBase(double value) {
    if (reciprocal) {
      if (value == 0) return double.infinity;
      return factor / value;
    }
    return value * factor + offset;
  }

  double fromBase(double base) {
    if (reciprocal) {
      if (base == 0) return double.infinity;
      return factor / base;
    }
    if (factor == 0) return double.nan;
    return (base - offset) / factor;
  }

  String get label => '$name ($symbol)';
}

/// A family of units that can be converted between each other.
class UnitCategory {
  const UnitCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.baseUnitLabel,
    required this.units,
  });

  final String id;
  final String name;
  final IconData icon;
  final String baseUnitLabel;
  final List<Unit> units;

  /// Converts [value] from [from] to [to] inside this category.
  double convert(double value, Unit from, Unit to) =>
      to.fromBase(from.toBase(value));

  Unit unitBySymbol(String symbol) => units.firstWhere(
        (Unit u) => u.symbol == symbol,
        orElse: () => units.first,
      );
}
