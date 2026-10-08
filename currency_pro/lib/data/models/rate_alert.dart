import 'dart:convert';

/// Direction a rate has to move for an alert to fire.
enum AlertDirection { above, below }

/// "Tell me when 1 USD is worth more than 1,371 KRW".
class RateAlert {
  RateAlert({
    required this.id,
    required this.from,
    required this.to,
    required this.startRate,
    required this.targetRate,
    required this.direction,
    required this.createdAt,
    this.achievedAt,
    this.note = '',
  });

  final String id;
  final String from;
  final String to;

  /// Rate at the moment the alert was created — used to draw progress.
  final double startRate;
  final double targetRate;
  final AlertDirection direction;
  final DateTime createdAt;
  DateTime? achievedAt;
  String note;

  bool get isAchieved => achievedAt != null;

  /// Percentage difference between the target and the rate at creation time.
  double get targetDeltaPercent =>
      startRate == 0 ? 0 : (targetRate - startRate) / startRate * 100;

  /// Rate after [percent] has been applied in [direction].
  ///
  /// Five percent above 1.00 is 1.05. Five percent below 1.00 is 0.95.
  static double targetForPercent(
    double start,
    double percent,
    AlertDirection direction,
  ) {
    final double move = percent.abs();
    final double signed = direction == AlertDirection.above ? move : -move;
    return start * (1 + signed / 100);
  }

  /// 0..1 progress of [current] between [startRate] and [targetRate].
  double progress(double current) {
    final span = targetRate - startRate;
    if (span == 0) return 1;
    final done = (current - startRate) / span;
    if (done.isNaN || done.isInfinite) return 0;
    return done.clamp(0.0, 1.0);
  }

  bool isTriggered(double current) => direction == AlertDirection.above
      ? current >= targetRate
      : current <= targetRate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'from': from,
        'to': to,
        'startRate': startRate,
        'targetRate': targetRate,
        'direction': direction.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'achievedAt': achievedAt?.millisecondsSinceEpoch,
        'note': note,
      };

  factory RateAlert.fromJson(Map<String, dynamic> json) => RateAlert(
        id: json['id'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        startRate: (json['startRate'] as num).toDouble(),
        targetRate: (json['targetRate'] as num).toDouble(),
        direction: AlertDirection.values.firstWhere(
          (AlertDirection d) => d.name == json['direction'],
          orElse: () => AlertDirection.above,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (json['createdAt'] as num).toInt()),
        achievedAt: json['achievedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (json['achievedAt'] as num).toInt()),
        note: json['note'] as String? ?? '',
      );

  static String encodeList(List<RateAlert> items) =>
      jsonEncode(items.map((RateAlert a) => a.toJson()).toList());

  static List<RateAlert> decodeList(String? source) {
    if (source == null || source.isEmpty) return <RateAlert>[];
    try {
      final list = jsonDecode(source) as List<dynamic>;
      return list
          .map((dynamic e) => RateAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <RateAlert>[];
    }
  }
}
