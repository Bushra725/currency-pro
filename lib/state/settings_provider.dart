import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/theme_catalog.dart';
import '../core/utils/formatting.dart';
import '../data/services/prefs_service.dart';

/// Every user preference in one place, persisted to shared preferences.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _load();
  }

  final PrefsService _prefs;

  String _themeId = ThemeCatalog.defaultId;
  int _decimals = 2;
  RoundingMode _rounding = RoundingMode.halfUp;
  bool _grouping = true;
  bool _vibrate = true;
  bool _keySound = false;
  bool _autoRefresh = true;
  String _fromCode = 'USD';
  String _toCode = 'EUR';
  String _baseCode = 'USD';
  List<String> _favorites = <String>['USD', 'EUR', 'GBP', 'JPY'];
  List<String> _multiSet = List<String>.from(AppConfig.defaultMultiSet);
  int _multiCount = 4;
  double _bankFeePercent = 0;
  double _tipPercent = 15;

  // -- getters ------------------------------------------------------------
  String get themeId => _themeId;
  AppPalette get palette => ThemeCatalog.byId(_themeId);
  int get decimals => _decimals;
  RoundingMode get rounding => _rounding;
  bool get grouping => _grouping;
  bool get vibrate => _vibrate;
  bool get keySound => _keySound;
  bool get autoRefresh => _autoRefresh;
  String get fromCode => _fromCode;
  String get toCode => _toCode;
  String get baseCode => _baseCode;
  List<String> get favorites => List<String>.unmodifiable(_favorites);
  List<String> get multiSet => List<String>.unmodifiable(_multiSet);
  int get multiCount => _multiCount;
  double get bankFeePercent => _bankFeePercent;
  double get tipPercent => _tipPercent;

  /// The slice of [multiSet] currently displayed (2, 4 or 8 rows).
  List<String> get activeMultiSet =>
      _multiSet.take(_multiCount).toList(growable: false);

  // -- loading ------------------------------------------------------------
  void _load() {
    _themeId = _prefs.getString(PrefsService.kThemeId) ?? _themeId;
    _decimals = _prefs.getInt(PrefsService.kDecimals) ?? _decimals;
    final int roundingIndex = _prefs.getInt(PrefsService.kRounding) ?? 0;
    _rounding = RoundingMode.values[
        roundingIndex.clamp(0, RoundingMode.values.length - 1)];
    _grouping = _prefs.getBool(PrefsService.kGrouping) ?? _grouping;
    _vibrate = _prefs.getBool(PrefsService.kVibrate) ?? _vibrate;
    _keySound = _prefs.getBool(PrefsService.kKeySound) ?? _keySound;
    _autoRefresh = _prefs.getBool(PrefsService.kAutoRefresh) ?? _autoRefresh;
    _fromCode = _prefs.getString(PrefsService.kFromCode) ?? _fromCode;
    _toCode = _prefs.getString(PrefsService.kToCode) ?? _toCode;
    _baseCode = _prefs.getString(PrefsService.kBaseCode) ?? _baseCode;

    final List<String> favs = _prefs.getStringList(PrefsService.kFavorites);
    if (favs.isNotEmpty) _favorites = favs;

    final List<String> multi = _prefs.getStringList(PrefsService.kMultiSet);
    if (multi.length >= 8) _multiSet = multi;

    _multiCount = _prefs.getInt(PrefsService.kMultiCount) ?? _multiCount;
    _bankFeePercent =
        _prefs.getDouble(PrefsService.kBankFeePercent) ?? _bankFeePercent;
    _tipPercent = _prefs.getDouble(PrefsService.kTipPercent) ?? _tipPercent;
  }

  // -- setters ------------------------------------------------------------
  Future<void> setTheme(String id) async {
    _themeId = id;
    notifyListeners();
    await _prefs.setString(PrefsService.kThemeId, id);
  }

  Future<void> setDecimals(int value) async {
    _decimals = value.clamp(0, 8);
    notifyListeners();
    await _prefs.setInt(PrefsService.kDecimals, _decimals);
  }

  Future<void> setRounding(RoundingMode mode) async {
    _rounding = mode;
    notifyListeners();
    await _prefs.setInt(PrefsService.kRounding, mode.index);
  }

  Future<void> setGrouping(bool value) async {
    _grouping = value;
    notifyListeners();
    await _prefs.setBool(PrefsService.kGrouping, value);
  }

  Future<void> setVibrate(bool value) async {
    _vibrate = value;
    notifyListeners();
    await _prefs.setBool(PrefsService.kVibrate, value);
  }

  Future<void> setKeySound(bool value) async {
    _keySound = value;
    notifyListeners();
    await _prefs.setBool(PrefsService.kKeySound, value);
  }

  Future<void> setAutoRefresh(bool value) async {
    _autoRefresh = value;
    notifyListeners();
    await _prefs.setBool(PrefsService.kAutoRefresh, value);
  }

  Future<void> setPair({String? from, String? to}) async {
    if (from != null) _fromCode = from;
    if (to != null) _toCode = to;
    notifyListeners();
    await _prefs.setString(PrefsService.kFromCode, _fromCode);
    await _prefs.setString(PrefsService.kToCode, _toCode);
  }

  Future<void> swapPair() async {
    final String old = _fromCode;
    _fromCode = _toCode;
    _toCode = old;
    notifyListeners();
    await _prefs.setString(PrefsService.kFromCode, _fromCode);
    await _prefs.setString(PrefsService.kToCode, _toCode);
  }

  Future<void> setBaseCode(String code) async {
    _baseCode = code;
    notifyListeners();
    await _prefs.setString(PrefsService.kBaseCode, code);
  }

  bool isFavorite(String code) => _favorites.contains(code);

  Future<void> toggleFavorite(String code) async {
    final List<String> next = List<String>.from(_favorites);
    if (!next.remove(code)) next.add(code);
    _favorites = next;
    notifyListeners();
    await _prefs.setStringList(PrefsService.kFavorites, next);
  }

  Future<void> setMultiCount(int count) async {
    _multiCount = count;
    notifyListeners();
    await _prefs.setInt(PrefsService.kMultiCount, count);
  }

  Future<void> setMultiAt(int index, String code) async {
    if (index < 0 || index >= _multiSet.length) return;
    final List<String> next = List<String>.from(_multiSet);
    next[index] = code;
    _multiSet = next;
    notifyListeners();
    await _prefs.setStringList(PrefsService.kMultiSet, next);
  }

  Future<void> setBankFeePercent(double value) async {
    _bankFeePercent = value;
    notifyListeners();
    await _prefs.setDouble(PrefsService.kBankFeePercent, value);
  }

  Future<void> setTipPercent(double value) async {
    _tipPercent = value;
    notifyListeners();
    await _prefs.setDouble(PrefsService.kTipPercent, value);
  }

  /// Formats an amount using the user's decimal / rounding / grouping rules.
  String format(double value, {int? decimals}) => Fmt.amount(
        value,
        decimals: decimals ?? _decimals,
        mode: _rounding,
        grouping: _grouping,
      );

  Future<void> resetAll() async {
    await _prefs.clearAll();
    _themeId = ThemeCatalog.defaultId;
    _decimals = 2;
    _rounding = RoundingMode.halfUp;
    _grouping = true;
    _vibrate = true;
    _keySound = false;
    _autoRefresh = true;
    _fromCode = 'USD';
    _toCode = 'EUR';
    _baseCode = 'USD';
    _favorites = <String>['USD', 'EUR', 'GBP', 'JPY'];
    _multiSet = List<String>.from(AppConfig.defaultMultiSet);
    _multiCount = 4;
    _bankFeePercent = 0;
    _tipPercent = 15;
    notifyListeners();
  }
}
