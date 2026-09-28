import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper over [SharedPreferences].
///
/// A single instance is created in `main()` and injected into the providers,
/// which keeps every screen free of async storage plumbing.
class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> create() async =>
      PrefsService(await SharedPreferences.getInstance());

  // -- keys ---------------------------------------------------------------
  static const String kThemeId = 'theme_id';
  static const String kThemeMode = 'theme_mode';
  static const String kDecimals = 'decimals';
  static const String kRounding = 'rounding';
  static const String kGrouping = 'grouping';
  static const String kVibrate = 'vibrate';
  static const String kKeySound = 'key_sound';
  static const String kAutoRefresh = 'auto_refresh';
  static const String kFromCode = 'from_code';
  static const String kToCode = 'to_code';
  static const String kBaseCode = 'base_code';
  static const String kFavorites = 'favorites';
  static const String kMultiSet = 'multi_set';
  static const String kMultiCount = 'multi_count';
  static const String kRateSnapshot = 'rate_snapshot';
  static const String kAssetQuotes = 'asset_quotes';
  static const String kAlerts = 'alerts';
  static const String kTrips = 'trips';
  static const String kClocks = 'clocks';
  static const String kBankFeePercent = 'bank_fee_percent';
  static const String kTipPercent = 'tip_percent';
  static const String kRecentUnits = 'recent_units';

  // -- primitives ---------------------------------------------------------
  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  List<String> getStringList(String key) =>
      _prefs.getStringList(key) ?? <String>[];

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clearAll() => _prefs.clear();
}
