import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IapService {
  IapService(this._prefs);

  static const String productId = 'quietly_calls_monthly';
  final SharedPreferences _prefs;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool get isPro => _prefs.getBool('iap_pro') ?? false;

  Future<ProductDetails?> loadProduct() async {
    final bool available = await _iap.isAvailable();
    if (!available) return null;
    final ProductDetailsResponse r =
        await _iap.queryProductDetails(<String>{productId});
    return r.productDetails.isEmpty ? null : r.productDetails.first;
  }

  Future<void> buy() async {
    final ProductDetails? p = await loadProduct();
    if (p == null) return;
    _sub ??= _iap.purchaseStream.listen(_handle);
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _handle(List<PurchaseDetails> list) async {
    for (final PurchaseDetails d in list) {
      if (d.status == PurchaseStatus.purchased || d.status == PurchaseStatus.restored) {
        await _prefs.setBool('iap_pro', true);
      }
      if (d.pendingCompletePurchase) await _iap.completePurchase(d);
    }
  }

  void dispose() => _sub?.cancel();
}
