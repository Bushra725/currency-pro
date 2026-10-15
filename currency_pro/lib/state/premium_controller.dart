import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../data/services/prefs_service.dart';
import 'premium_billing.dart';

enum PremiumNotice { restored, nothing, failed, storeUnavailable }

/// Owns the premium flag and talks to the store sandbox.
class PremiumController extends ChangeNotifier {
  PremiumController(this._prefs, {PremiumBilling? billing})
      : _billing = billing ?? StorePremiumBilling() {
    _billing.attach();
    _subscription = _billing.updates.listen(_onUpdate);
  }

  final PrefsService _prefs;
  final PremiumBilling _billing;
  late final StreamSubscription<PremiumUpdate> _subscription;

  bool isPremium = false;
  bool busy = false;
  String? storePrice;
  PremiumNotice? notice;

  Future<void> start() async {
    isPremium = _prefs.getBool(PrefsService.kPremium) ?? false;
    notifyListeners();
    try {
      storePrice = await _billing.loadPrice(AppConfig.premiumProductId);
    } catch (_) {
      storePrice = null;
    }
    notifyListeners();
  }

  Future<void> buy() async {
    if (isPremium || busy) return;
    busy = true;
    notice = null;
    notifyListeners();
    final bool started;
    try {
      started = await _billing.buy(AppConfig.premiumProductId);
    } catch (_) {
      busy = false;
      notice = PremiumNotice.failed;
      notifyListeners();
      return;
    }
    if (!started && !isPremium) {
      busy = false;
      notice = PremiumNotice.storeUnavailable;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (busy) return;
    busy = true;
    notice = null;
    notifyListeners();
    try {
      await _billing.restore();
    } catch (_) {
      busy = false;
      notice = PremiumNotice.failed;
      notifyListeners();
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    if (isPremium) {
      busy = false;
      notice ??= PremiumNotice.restored;
      notifyListeners();
      return;
    }
    busy = false;
    notice = PremiumNotice.nothing;
    notifyListeners();
  }

  void _onUpdate(PremiumUpdate update) {
    if (update.productId != AppConfig.premiumProductId) return;
    switch (update.kind) {
      case PremiumUpdateKind.purchased:
      case PremiumUpdateKind.restored:
        unawaited(_grant());
        busy = false;
        if (update.kind == PremiumUpdateKind.restored) {
          notice = PremiumNotice.restored;
        }
      case PremiumUpdateKind.pending:
        busy = true;
      case PremiumUpdateKind.failed:
        busy = false;
        notice = PremiumNotice.failed;
      case PremiumUpdateKind.canceled:
        busy = false;
    }
    notifyListeners();
  }

  Future<void> _grant() async {
    isPremium = true;
    await _prefs.setBool(PrefsService.kPremium, true);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _billing.dispose();
    super.dispose();
  }
}
