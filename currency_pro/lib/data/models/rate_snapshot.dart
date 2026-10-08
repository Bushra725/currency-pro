import 'dart:convert';

/// An immutable set of exchange rates expressed against a single base code.
///
/// Rates are stored as "1 [base] = value [code]".
class RateSnapshot {
  const RateSnapshot({
    required this.base,
    required this.rates,
    required this.fetchedAt,
    required this.providerUpdatedAt,
    this.provider = 'unknown',
    this.isStale = false,
  });

  final String base;
  final Map<String, double> rates;

  /// When this device downloaded the data.
  final DateTime fetchedAt;

  /// When the provider says the rates themselves were last refreshed.
  final DateTime providerUpdatedAt;

  final String provider;

  /// True when the values came from the offline cache rather than the network.
  final bool isStale;

  static final RateSnapshot empty = RateSnapshot(
    base: 'USD',
    rates: const <String, double>{'USD': 1.0},
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
    providerUpdatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    provider: 'none',
    isStale: true,
  );

  bool get isEmpty => rates.length <= 1;

  bool has(String code) => rates.containsKey(code);

  /// Rate of `1 base` in [code].
  double? rateOf(String code) => rates[code];

  /// Converts [amount] from [from] to [to] using cross rates through [base].
  double? convert(double amount, String from, String to) {
    if (from == to) return amount;
    final fromRate = rates[from];
    final toRate = rates[to];
    if (fromRate == null || toRate == null || fromRate == 0) return null;
    return amount / fromRate * toRate;
  }

  /// Price of one unit of [from] expressed in [to].
  double? pairRate(String from, String to) => convert(1, from, to);

  RateSnapshot copyWith({
    Map<String, double>? rates,
    bool? isStale,
    DateTime? fetchedAt,
    DateTime? providerUpdatedAt,
    String? provider,
  }) {
    return RateSnapshot(
      base: base,
      rates: rates ?? this.rates,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      providerUpdatedAt: providerUpdatedAt ?? this.providerUpdatedAt,
      provider: provider ?? this.provider,
      isStale: isStale ?? this.isStale,
    );
  }

  /// Returns a copy with extra rows merged in (used for metals and crypto).
  RateSnapshot merge(Map<String, double> extra) {
    if (extra.isEmpty) return this;
    return copyWith(rates: <String, double>{...rates, ...extra});
  }

  /// Overlays [live] quotes on this wider table so majors stay real-time
  /// while less common codes still have a value.
  ///
  /// A live quote that disagrees with the wider table by more than
  /// [maxDrift] is left out. That keeps a bad or inverted ticker from
  /// replacing a real fiat rate.
  RateSnapshot overlay(RateSnapshot live, {double maxDrift = 0.12}) {
    final Map<String, double> merged = <String, double>{...rates};
    live.rates.forEach((String code, double value) {
      if (value <= 0) return;
      final double? current = merged[code];
      if (current == null || current <= 0) {
        merged[code] = value;
        return;
      }
      final double ratio = value / current;
      if (ratio >= 1 - maxDrift && ratio <= 1 + maxDrift) {
        merged[code] = value;
      }
    });
    return RateSnapshot(
      base: base,
      rates: merged,
      fetchedAt: DateTime.now(),
      providerUpdatedAt: DateTime.now(),
      provider: '$provider+${live.provider}',
      isStale: false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'base': base,
        'rates': rates,
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
        'providerUpdatedAt': providerUpdatedAt.millisecondsSinceEpoch,
        'provider': provider,
        'isStale': isStale,
      };

  factory RateSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = (json['rates'] as Map?) ?? <String, dynamic>{};
    return RateSnapshot(
      base: json['base'] as String? ?? 'USD',
      rates: raw.map(
        (dynamic k, dynamic v) =>
            MapEntry<String, double>(k.toString(), (v as num).toDouble()),
      ),
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['fetchedAt'] as num?)?.toInt() ?? 0),
      providerUpdatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['providerUpdatedAt'] as num?)?.toInt() ?? 0),
      provider: json['provider'] as String? ?? 'cache',
      isStale: json['isStale'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toJson());

  static RateSnapshot? decode(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      return RateSnapshot.fromJson(
          jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// One point on a historical rate chart.
class RatePoint {
  const RatePoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// A named span of history offered by the trend chart screen.
class ChartRange {
  const ChartRange(this.label, this.days);

  final String label;
  final int days;

  static const List<ChartRange> all = <ChartRange>[
    ChartRange('10D', 10),
    ChartRange('1M', 30),
    ChartRange('3M', 90),
    ChartRange('6M', 180),
    ChartRange('1Y', 365),
    ChartRange('2Y', 730),
  ];
}
