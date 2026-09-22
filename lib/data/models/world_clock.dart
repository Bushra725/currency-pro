import 'dart:convert';

/// A city shown on the World Clock screen.
///
/// Offsets are stored in minutes from UTC so half-hour and 45-minute zones
/// (India, Nepal, Chatham Islands) work correctly.
class ClockEntry {
  const ClockEntry({
    required this.id,
    required this.city,
    required this.region,
    required this.offsetMinutes,
  });

  final String id;
  final String city;
  final String region;
  final int offsetMinutes;

  DateTime nowThere() => DateTime.now().toUtc().add(
        Duration(minutes: offsetMinutes),
      );

  String get offsetLabel {
    final sign = offsetMinutes < 0 ? '-' : '+';
    final abs = offsetMinutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$sign$h:$m';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'city': city,
        'region': region,
        'offsetMinutes': offsetMinutes,
      };

  factory ClockEntry.fromJson(Map<String, dynamic> json) => ClockEntry(
        id: json['id'] as String,
        city: json['city'] as String,
        region: json['region'] as String? ?? '',
        offsetMinutes: (json['offsetMinutes'] as num).toInt(),
      );

  static String encodeList(List<ClockEntry> items) =>
      jsonEncode(items.map((ClockEntry c) => c.toJson()).toList());

  static List<ClockEntry> decodeList(String? source) {
    if (source == null || source.isEmpty) return <ClockEntry>[];
    try {
      final list = jsonDecode(source) as List<dynamic>;
      return list
          .map((dynamic e) => ClockEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <ClockEntry>[];
    }
  }
}

/// A searchable table of world cities with their standard UTC offsets.
///
/// Note: these are standard-time offsets and do not track daylight saving.
const List<ClockEntry> kWorldCities = <ClockEntry>[
  ClockEntry(id: 'utc', city: 'GMT', region: 'Greenwich Mean Time', offsetMinutes: 0),
  ClockEntry(id: 'honolulu', city: 'Honolulu', region: 'United States', offsetMinutes: -600),
  ClockEntry(id: 'anchorage', city: 'Anchorage', region: 'United States', offsetMinutes: -540),
  ClockEntry(id: 'losangeles', city: 'Los Angeles', region: 'United States', offsetMinutes: -480),
  ClockEntry(id: 'vancouver', city: 'Vancouver', region: 'Canada', offsetMinutes: -480),
  ClockEntry(id: 'denver', city: 'Denver', region: 'United States', offsetMinutes: -420),
  ClockEntry(id: 'mexicocity', city: 'Mexico City', region: 'Mexico', offsetMinutes: -360),
  ClockEntry(id: 'chicago', city: 'Chicago', region: 'United States', offsetMinutes: -360),
  ClockEntry(id: 'newyork', city: 'New York', region: 'United States', offsetMinutes: -300),
  ClockEntry(id: 'toronto', city: 'Toronto', region: 'Canada', offsetMinutes: -300),
  ClockEntry(id: 'bogota', city: 'Bogotá', region: 'Colombia', offsetMinutes: -300),
  ClockEntry(id: 'santiago', city: 'Santiago', region: 'Chile', offsetMinutes: -240),
  ClockEntry(id: 'saopaulo', city: 'São Paulo', region: 'Brazil', offsetMinutes: -180),
  ClockEntry(id: 'buenosaires', city: 'Buenos Aires', region: 'Argentina', offsetMinutes: -180),
  ClockEntry(id: 'reykjavik', city: 'Reykjavík', region: 'Iceland', offsetMinutes: 0),
  ClockEntry(id: 'london', city: 'London', region: 'United Kingdom', offsetMinutes: 0),
  ClockEntry(id: 'lisbon', city: 'Lisbon', region: 'Portugal', offsetMinutes: 0),
  ClockEntry(id: 'dublin', city: 'Dublin', region: 'Ireland', offsetMinutes: 0),
  ClockEntry(id: 'paris', city: 'Paris', region: 'France', offsetMinutes: 60),
  ClockEntry(id: 'madrid', city: 'Madrid', region: 'Spain', offsetMinutes: 60),
  ClockEntry(id: 'berlin', city: 'Berlin', region: 'Germany', offsetMinutes: 60),
  ClockEntry(id: 'rome', city: 'Rome', region: 'Italy', offsetMinutes: 60),
  ClockEntry(id: 'amsterdam', city: 'Amsterdam', region: 'Netherlands', offsetMinutes: 60),
  ClockEntry(id: 'zurich', city: 'Zürich', region: 'Switzerland', offsetMinutes: 60),
  ClockEntry(id: 'stockholm', city: 'Stockholm', region: 'Sweden', offsetMinutes: 60),
  ClockEntry(id: 'oslo', city: 'Oslo', region: 'Norway', offsetMinutes: 60),
  ClockEntry(id: 'copenhagen', city: 'Copenhagen', region: 'Denmark', offsetMinutes: 60),
  ClockEntry(id: 'prague', city: 'Prague', region: 'Czechia', offsetMinutes: 60),
  ClockEntry(id: 'warsaw', city: 'Warsaw', region: 'Poland', offsetMinutes: 60),
  ClockEntry(id: 'lagos', city: 'Lagos', region: 'Nigeria', offsetMinutes: 60),
  ClockEntry(id: 'cairo', city: 'Cairo', region: 'Egypt', offsetMinutes: 120),
  ClockEntry(id: 'athens', city: 'Athens', region: 'Greece', offsetMinutes: 120),
  ClockEntry(id: 'helsinki', city: 'Helsinki', region: 'Finland', offsetMinutes: 120),
  ClockEntry(id: 'johannesburg', city: 'Johannesburg', region: 'South Africa', offsetMinutes: 120),
  ClockEntry(id: 'istanbul', city: 'Istanbul', region: 'Türkiye', offsetMinutes: 180),
  ClockEntry(id: 'moscow', city: 'Moscow', region: 'Russia', offsetMinutes: 180),
  ClockEntry(id: 'nairobi', city: 'Nairobi', region: 'Kenya', offsetMinutes: 180),
  ClockEntry(id: 'riyadh', city: 'Riyadh', region: 'Saudi Arabia', offsetMinutes: 180),
  ClockEntry(id: 'tehran', city: 'Tehran', region: 'Iran', offsetMinutes: 210),
  ClockEntry(id: 'dubai', city: 'Dubai', region: 'United Arab Emirates', offsetMinutes: 240),
  ClockEntry(id: 'baku', city: 'Baku', region: 'Azerbaijan', offsetMinutes: 240),
  ClockEntry(id: 'karachi', city: 'Karachi', region: 'Pakistan', offsetMinutes: 300),
  ClockEntry(id: 'tashkent', city: 'Tashkent', region: 'Uzbekistan', offsetMinutes: 300),
  ClockEntry(id: 'delhi', city: 'New Delhi', region: 'India', offsetMinutes: 330),
  ClockEntry(id: 'mumbai', city: 'Mumbai', region: 'India', offsetMinutes: 330),
  ClockEntry(id: 'colombo', city: 'Colombo', region: 'Sri Lanka', offsetMinutes: 330),
  ClockEntry(id: 'kathmandu', city: 'Kathmandu', region: 'Nepal', offsetMinutes: 345),
  ClockEntry(id: 'dhaka', city: 'Dhaka', region: 'Bangladesh', offsetMinutes: 360),
  ClockEntry(id: 'almaty', city: 'Almaty', region: 'Kazakhstan', offsetMinutes: 360),
  ClockEntry(id: 'yangon', city: 'Yangon', region: 'Myanmar', offsetMinutes: 390),
  ClockEntry(id: 'bangkok', city: 'Bangkok', region: 'Thailand', offsetMinutes: 420),
  ClockEntry(id: 'jakarta', city: 'Jakarta', region: 'Indonesia', offsetMinutes: 420),
  ClockEntry(id: 'hanoi', city: 'Hanoi', region: 'Vietnam', offsetMinutes: 420),
  ClockEntry(id: 'singapore', city: 'Singapore', region: 'Singapore', offsetMinutes: 480),
  ClockEntry(id: 'hongkong', city: 'Hong Kong', region: 'Hong Kong', offsetMinutes: 480),
  ClockEntry(id: 'beijing', city: 'Beijing', region: 'China', offsetMinutes: 480),
  ClockEntry(id: 'shanghai', city: 'Shanghai', region: 'China', offsetMinutes: 480),
  ClockEntry(id: 'taipei', city: 'Taipei', region: 'Taiwan', offsetMinutes: 480),
  ClockEntry(id: 'kualalumpur', city: 'Kuala Lumpur', region: 'Malaysia', offsetMinutes: 480),
  ClockEntry(id: 'manila', city: 'Manila', region: 'Philippines', offsetMinutes: 480),
  ClockEntry(id: 'perth', city: 'Perth', region: 'Australia', offsetMinutes: 480),
  ClockEntry(id: 'seoul', city: 'Seoul', region: 'South Korea', offsetMinutes: 540),
  ClockEntry(id: 'tokyo', city: 'Tokyo', region: 'Japan', offsetMinutes: 540),
  ClockEntry(id: 'adelaide', city: 'Adelaide', region: 'Australia', offsetMinutes: 570),
  ClockEntry(id: 'sydney', city: 'Sydney', region: 'Australia', offsetMinutes: 600),
  ClockEntry(id: 'brisbane', city: 'Brisbane', region: 'Australia', offsetMinutes: 600),
  ClockEntry(id: 'melbourne', city: 'Melbourne', region: 'Australia', offsetMinutes: 600),
  ClockEntry(id: 'noumea', city: 'Nouméa', region: 'New Caledonia', offsetMinutes: 660),
  ClockEntry(id: 'auckland', city: 'Auckland', region: 'New Zealand', offsetMinutes: 720),
  ClockEntry(id: 'suva', city: 'Suva', region: 'Fiji', offsetMinutes: 720),
  ClockEntry(id: 'apia', city: 'Apia', region: 'Samoa', offsetMinutes: 780),
];
