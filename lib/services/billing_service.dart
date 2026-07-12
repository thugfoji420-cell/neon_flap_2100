import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:neon_flap_2100/models/store_product.dart';
import 'package:neon_flap_2100/services/coin_service.dart';

/// Integrates Google Play Billing for the Coin Shop.
///
/// Products are consumable coin packs. Purchases are acknowledged via
/// [InAppPurchase.completePurchase] (required by Play policy) and the coin
/// balance is credited only after a successful, verified purchase. For a
/// production release, add server-side signature verification here; the local
/// check below guards against unknown product ids.
class BillingService extends ChangeNotifier {
  BillingService(this._coins);

  final CoinService _coins;

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _available = false;
  bool get available => _available;

  final List<ProductDetails> _products = [];
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Set by [purchaseSuccess] so the shop UI can react (sound, toast).
  ValueNotifier<CoinPack?> lastPurchased = ValueNotifier(null);

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;
    _subscription = _iap.purchaseStream.listen(
      _handlePurchases,
      onError: (_) => _available = false,
    );
    await _loadProducts();
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final ids = CoinPack.catalogue.map((p) => p.productId).toSet();
    final response = await _iap.queryProductDetails(ids);
    _products
      ..clear()
      ..addAll(response.productDetails);
    notifyListeners();
  }

  ProductDetails? detailsFor(String productId) {
    for (final p in _products) {
      if (p.id == productId) return p;
    }
    return null;
  }

  /// Launch the Google Play purchase flow for a coin pack.
  Future<void> buy(CoinPack pack) async {
    if (!_available) return;
    final details = detailsFor(pack.productId);
    if (details == null) return;
    final param = PurchaseParam(productDetails: details);
    // autoConsume=false so we explicitly acknowledge after crediting coins.
    await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _creditIfValid(purchase);
      }
      // Always acknowledge/consume so Play does not refund the purchase.
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Verifies the product id against our catalogue and credits the balance.
  Future<void> _creditIfValid(PurchaseDetails purchase) async {
    final pack = CoinPack.catalogue.firstWhere(
      (p) => p.productId == purchase.productID,
      orElse: () => CoinPack.catalogue.first,
    );
    if (pack.productId != purchase.productID) return; // unknown product
    await _coins.addCoins(pack.coins);
    lastPurchased.value = pack;
    notifyListeners();
  }

  /// Refresh available products (e.g. after returning from settings).
  Future<void> refresh() async {
    if (_available) await _loadProducts();
  }

  void disposeBilling() {
    _subscription?.cancel();
  }
}
