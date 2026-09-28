import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../data/fallback_rates.dart';
import '../data/models/rate_snapshot.dart';
import '../data/repositories/rates_repository.dart';
import '../data/services/metals_api.dart';

enum RatesStatus { idle, loading, ready, error }

/// Holds the live rate table and exposes conversion helpers to the UI.
class RatesProvider extends ChangeNotifier {
  RatesProvider(this._repo) {
    _snapshot = _repo.loadCached();
    if (!_snapshot.isEmpty) _status = RatesStatus.ready;
    _usingFallback = _snapshot.provider == FallbackRates.providerName;
  }

  final RatesRepository _repo;

  RateSnapshot _snapshot = RateSnapshot.empty;
  RatesStatus _status = RatesStatus.idle;
  String? _error;
  Timer? _autoTimer;
  bool _lastFetchFailed = false;
  bool _usingFallback = false;
  int _generation = 0;

  RateSnapshot get snapshot => _snapshot;
  RatesStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == RatesStatus.loading;
  bool get hasData => !_snapshot.isEmpty;
  bool get isOffline =>
      hasData &&
      _status != RatesStatus.loading &&
      (_lastFetchFailed || _usingFallback);
  DateTime get updatedAt => _snapshot.providerUpdatedAt;
  String get provider => _snapshot.provider;
  Map<String, AssetQuote> get quotes => _repo.quotes;
  int get generation => _generation;

  /// Refreshes if the cached data is older than [AppConfig.rateFreshness].
  Future<void> ensureFresh() async {
    if (_status == RatesStatus.loading) return;
    if (_repo.isFresh(_snapshot)) return;
    await refresh();
  }

  Future<void> refresh() async {
    _status = RatesStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _snapshot = await _repo.refresh();
      _status = RatesStatus.ready;
      _lastFetchFailed = false;
      _usingFallback = false;
      _generation++;
    } catch (e) {
      _error = e.toString();
      _lastFetchFailed = true;
      _status = hasData ? RatesStatus.ready : RatesStatus.error;
    }
    notifyListeners();
  }

  /// Refreshes every 15 minutes while the app is open.
  void startAutoRefresh() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      AppConfig.rateFreshness,
      (_) => refresh(),
    );
  }

  void stopAutoRefresh() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  // -- conversion ---------------------------------------------------------

  /// `amount` of [from] expressed in [to]; null when a code has no rate.
  double? convert(double amount, String from, String to) =>
      _snapshot.convert(amount, from, to);

  /// Price of one [from] in [to].
  double? pairRate(String from, String to) => _snapshot.pairRate(from, to);

  bool has(String code) => _snapshot.has(code);

  /// USD price of one unit of a crypto asset or one troy ounce of a metal.
  double? assetPriceUsd(String code) {
    final AssetQuote? q = quotes[code];
    if (q != null) return q.priceUsd;
    final double? rate = _snapshot.rateOf(code);
    if (rate == null || rate == 0) return null;
    return 1 / rate;
  }

  double? assetChange24h(String code) => quotes[code]?.changePercent24h;

  @override
  void dispose() {
    _autoTimer?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
