import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/app_config.dart';

/// Outcome of a store purchase, with no receipt or token attached.
enum PremiumUpdateKind { purchased, restored, pending, failed, canceled }

class PremiumUpdate {
  const PremiumUpdate(this.productId, this.kind);

  final String productId;
  final PremiumUpdateKind kind;
}

/// Store access used by [PremiumController]. Tests supply a fake.
abstract class PremiumBilling {
  Stream<PremiumUpdate> get updates;

  void attach();

  /// Localized store price, or null when the product is not on sale yet.
  Future<String?> loadPrice(String productId);

  /// Starts the store sheet. False when the store or product is unavailable.
  Future<bool> buy(String productId);

  Future<void> restore();

  void dispose();
}

/// Google Play and App Store billing. Sandbox and license-tester accounts
/// complete the same purchase path without a real charge.
class StorePremiumBilling implements PremiumBilling {
  StorePremiumBilling({InAppPurchase? store})
      : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final StreamController<PremiumUpdate> _updates =
      StreamController<PremiumUpdate>.broadcast();
  final Map<String, ProductDetails> _products = <String, ProductDetails>{};
  StreamSubscription<List<PurchaseDetails>>? _purchases;

  @override
  Stream<PremiumUpdate> get updates => _updates.stream;

  @override
  void attach() {
    _purchases ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object _) {
        _emit(const PremiumUpdate(
          AppConfig.premiumProductId,
          PremiumUpdateKind.failed,
        ));
      },
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (_) {}
      }
      if (purchase.productID != AppConfig.premiumProductId) continue;
      final PremiumUpdateKind kind = switch (purchase.status) {
        PurchaseStatus.purchased => PremiumUpdateKind.purchased,
        PurchaseStatus.restored => PremiumUpdateKind.restored,
        PurchaseStatus.pending => PremiumUpdateKind.pending,
        PurchaseStatus.canceled => PremiumUpdateKind.canceled,
        PurchaseStatus.error => PremiumUpdateKind.failed,
      };
      _emit(PremiumUpdate(purchase.productID, kind));
    }
  }

  void _emit(PremiumUpdate update) {
    if (!_updates.isClosed) _updates.add(update);
  }

  @override
  Future<String?> loadPrice(String productId) async {
    final bool available = await _store.isAvailable();
    if (!available) return null;
    final ProductDetailsResponse response =
        await _store.queryProductDetails(<String>{productId});
    if (response.productDetails.isEmpty) return null;
    final ProductDetails product = response.productDetails.first;
    _products[product.id] = product;
    return product.price;
  }

  @override
  Future<bool> buy(String productId) async {
    ProductDetails? product = _products[productId];
    if (product == null) {
      await loadPrice(productId);
      product = _products[productId];
    }
    if (product == null) return false;
    return _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> restore() => _store.restorePurchases();

  @override
  void dispose() {
    _purchases?.cancel();
    _updates.close();
  }
}
