import 'package:flutter/material.dart';

import '../data/models/trip.dart';
import '../data/services/prefs_service.dart';

/// Travel budgets and their expenses.
class TripsProvider extends ChangeNotifier {
  TripsProvider(this._prefs) {
    _items = Trip.decodeList(_prefs.getString(PrefsService.kTrips));
  }

  final PrefsService _prefs;
  List<Trip> _items = <Trip>[];

  List<Trip> get all => List<Trip>.unmodifiable(_items);

  List<Trip> get ongoing => _items.where((Trip t) => !t.completed).toList();

  List<Trip> get completed => _items.where((Trip t) => t.completed).toList();

  Trip? byId(String id) {
    for (final Trip t in _items) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> add(Trip trip) async {
    _items = <Trip>[trip, ..._items];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items = _items.where((Trip t) => t.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> update(Trip trip) async {
    _items = _items.map((Trip t) => t.id == trip.id ? trip : t).toList();
    notifyListeners();
    await _save();
  }

  Future<void> addExpense(String tripId, Expense expense) async {
    final Trip? trip = byId(tripId);
    if (trip == null) return;
    trip.expenses = <Expense>[expense, ...trip.expenses];
    notifyListeners();
    await _save();
  }

  Future<void> updateExpense(String tripId, Expense expense) async {
    final Trip? trip = byId(tripId);
    if (trip == null) return;
    trip.expenses = trip.expenses
        .map((Expense e) => e.id == expense.id ? expense : e)
        .toList();
    notifyListeners();
    await _save();
  }

  Future<void> removeExpense(String tripId, String expenseId) async {
    final Trip? trip = byId(tripId);
    if (trip == null) return;
    trip.expenses =
        trip.expenses.where((Expense e) => e.id != expenseId).toList();
    notifyListeners();
    await _save();
  }

  Future<void> toggleCompleted(String tripId) async {
    final Trip? trip = byId(tripId);
    if (trip == null) return;
    trip.completed = !trip.completed;
    notifyListeners();
    await _save();
  }

  Future<void> _save() =>
      _prefs.setString(PrefsService.kTrips, Trip.encodeList(_items));
}
