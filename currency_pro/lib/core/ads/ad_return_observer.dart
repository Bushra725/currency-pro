import 'package:flutter/material.dart';

import 'ads_service.dart';

/// Shows a full-screen ad when the user leaves a feature (back button /
/// toolbar back), not for dialogs, sheets or the navigation drawer.
class AdReturnObserver extends NavigatorObserver {
  AdReturnObserver(this._ads);

  final AdsService _ads;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!_shouldShow(route, previousRoute)) return;
    // Let the previous screen paint first, then show the interstitial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ads.showAfterReturningFromFeature();
    });
  }

  bool _shouldShow(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is! PageRoute) return false;
    if (route.settings.name == '/') return false;
    if (previousRoute == null) return false;
    return true;
  }
}
