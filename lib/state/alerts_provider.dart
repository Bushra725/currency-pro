import 'package:flutter/material.dart';

import '../data/models/rate_alert.dart';
import '../data/services/prefs_service.dart';

/// Stores the user's rate alerts and marks them achieved when the live rate
/// crosses the target.
class AlertsProvider extends ChangeNotifier {
  AlertsProvider(this._prefs) {
    _items = RateAlert.decodeList(_prefs.getString(PrefsService.kAlerts));
  }

  final PrefsService _prefs;
  List<RateAlert> _items = <RateAlert>[];

  List<RateAlert> get all => List<RateAlert>.unmodifiable(_items);

  List<RateAlert> get pending =>
      _items.where((RateAlert a) => !a.isAchieved).toList();

  List<RateAlert> get achieved =>
      _items.where((RateAlert a) => a.isAchieved).toList();

  Future<void> add(RateAlert alert) async {
    _items = <RateAlert>[alert, ..._items];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items = _items.where((RateAlert a) => a.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> clearAchieved() async {
    _items = _items.where((RateAlert a) => !a.isAchieved).toList();
    notifyListeners();
    await _save();
  }

  /// Checks every pending alert against the live table.
  ///
  /// Returns the alerts that just fired so the caller can show a banner.
  Future<List<RateAlert>> evaluate(
    double? Function(String from, String to) rateOf,
  ) async {
    final List<RateAlert> fired = <RateAlert>[];
    for (final RateAlert alert in _items) {
      if (alert.isAchieved) continue;
      final double? current = rateOf(alert.from, alert.to);
      if (current == null) continue;
      if (alert.isTriggered(current)) {
        alert.achievedAt = DateTime.now();
        fired.add(alert);
      }
    }
    if (fired.isNotEmpty) {
      notifyListeners();
      await _save();
    }
    return fired;
  }

  Future<void> _save() =>
      _prefs.setString(PrefsService.kAlerts, RateAlert.encodeList(_items));
}
