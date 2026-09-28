import 'package:flutter/material.dart';

import '../data/models/world_clock.dart';
import '../data/services/prefs_service.dart';

/// The cities pinned on the World Clock screen.
class ClocksProvider extends ChangeNotifier {
  ClocksProvider(this._prefs) {
    final List<ClockEntry> saved =
        ClockEntry.decodeList(_prefs.getString(PrefsService.kClocks));
    _items = saved.isEmpty ? _defaults() : saved;
  }

  final PrefsService _prefs;
  List<ClockEntry> _items = <ClockEntry>[];

  List<ClockEntry> get all => List<ClockEntry>.unmodifiable(_items);

  static List<ClockEntry> _defaults() {
    const List<String> ids = <String>['utc', 'newyork', 'london', 'tokyo'];
    return kWorldCities
        .where((ClockEntry c) => ids.contains(c.id))
        .toList();
  }

  bool contains(String id) => _items.any((ClockEntry c) => c.id == id);

  Future<void> add(ClockEntry entry) async {
    if (contains(entry.id)) return;
    _items = <ClockEntry>[..._items, entry];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items = _items.where((ClockEntry c) => c.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final List<ClockEntry> next = List<ClockEntry>.from(_items);
    final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final ClockEntry moved = next.removeAt(oldIndex);
    next.insert(target, moved);
    _items = next;
    notifyListeners();
    await _save();
  }

  Future<void> _save() =>
      _prefs.setString(PrefsService.kClocks, ClockEntry.encodeList(_items));
}
