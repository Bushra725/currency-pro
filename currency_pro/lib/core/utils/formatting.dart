import 'dart:math' as math;

import 'package:intl/intl.dart';

/// How fractional amounts are cut off.
enum RoundingMode { halfUp, down, up }

extension RoundingModeLabel on RoundingMode {
  String get label {
    switch (this) {
      case RoundingMode.halfUp:
        return 'Round half up';
      case RoundingMode.down:
        return 'Always round down';
      case RoundingMode.up:
        return 'Always round up';
    }
  }
}

/// Number formatting helpers shared by every screen.
class Fmt {
  const Fmt._();

  /// Applies [mode] to [value] at [decimals] fraction digits.
  static double round(double value, int decimals, RoundingMode mode) {
    if (!value.isFinite) return value;
    final double factor = math.pow(10, decimals).toDouble();
    final double scaled = value * factor;
    switch (mode) {
      case RoundingMode.halfUp:
        return scaled.roundToDouble() / factor;
      case RoundingMode.down:
        return (value.isNegative ? scaled.ceilToDouble() : scaled.floorToDouble()) /
            factor;
      case RoundingMode.up:
        return (value.isNegative ? scaled.floorToDouble() : scaled.ceilToDouble()) /
            factor;
    }
  }

  /// Money / measurement formatting with optional thousands separators.
  static String amount(
    double value, {
    int decimals = 2,
    RoundingMode mode = RoundingMode.halfUp,
    bool grouping = true,
  }) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';

    final double v = round(value, decimals, mode);
    final String pattern = decimals <= 0
        ? (grouping ? '#,##0' : '0')
        : '${grouping ? '#,##0' : '0'}.${'0' * decimals}';
    return NumberFormat(pattern, 'en_US').format(v);
  }

  /// Like [amount] but drops trailing zeros — used by unit converters where
  /// "12.5" reads better than "12.500000".
  static String smart(double value, {int maxDecimals = 8, bool grouping = true}) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-∞' : '∞';
    if (value == 0) return '0';

    final double abs = value.abs();
    if (abs >= 1e12 || (abs < 1e-6 && abs > 0)) {
      return value.toStringAsExponential(6);
    }

    // Keep more decimals for tiny values so 0.00000123 is still readable.
    int decimals = maxDecimals;
    if (abs >= 1000) {
      decimals = math.min(maxDecimals, 2);
    } else if (abs >= 1) {
      decimals = math.min(maxDecimals, 6);
    }

    String out = value.toStringAsFixed(decimals);
    if (out.contains('.')) {
      out = out.replaceAll(RegExp(r'0+$'), '');
      out = out.replaceAll(RegExp(r'\.$'), '');
    }
    if (!grouping) return out;

    final List<String> parts = out.split('.');
    final String intPart = parts.first.replaceAll('-', '');
    final String grouped =
        NumberFormat('#,##0', 'en_US').format(int.tryParse(intPart) ?? 0);
    final String sign = value.isNegative ? '-' : '';
    return parts.length > 1 ? '$sign$grouped.${parts[1]}' : '$sign$grouped';
  }

  /// Signed percentage, e.g. `+0.137%`.
  static String percent(double value, {int decimals = 3}) {
    final String sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}%';
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);

  static String dateShort(DateTime d) => DateFormat('d MMM').format(d);

  static String dateTime(DateTime d) =>
      DateFormat('d MMM yyyy HH:mm:ss').format(d.toLocal());

  static String time(DateTime d) => DateFormat('HH:mm:ss').format(d);

  static String weekday(DateTime d) => DateFormat('EEE').format(d);

  /// "2 hours ago" style label for the last refresh time.
  static String ago(DateTime d) {
    final Duration diff = DateTime.now().difference(d);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} d ago';
    return date(d);
  }

  /// Parses user input that may contain grouping separators.
  static double? parse(String text) {
    final String cleaned =
        text.replaceAll(',', '').replaceAll(' ', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
