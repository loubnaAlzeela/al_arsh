import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import 'gift_package.dart';

part 'iap_service.g.dart';

class IapService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  Future<void>? _initFuture;

  /// Pending purchases keyed by productID, resolved once the purchase
  /// stream reports a terminal status and the server verifies the receipt.
  final Map<String, Completer<int>> _pendingPurchases = {};

  IapService() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
    _initFuture = initialize();
  }

  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('Store is not available');
      return;
    }

    final kIds = GiftPackage.values.map((p) => p.productId).toSet();

    final ProductDetailsResponse productDetailResponse =
        await _inAppPurchase.queryProductDetails(kIds);

    if (productDetailResponse.error != null) {
      debugPrint('Product Details Error: ${productDetailResponse.error}');
      return;
    }
    if (productDetailResponse.notFoundIDs.isNotEmpty) {
      debugPrint(
        'IAP products not found in store listing: ${productDetailResponse.notFoundIDs}',
      );
    }

    _products = productDetailResponse.productDetails;
  }

  Future<void> ensureInitialized() => _initFuture ?? initialize();

  List<ProductDetails> get products => _products;

  /// Starts a Play Billing purchase for [package] and resolves with the
  /// number of crowns credited once the server confirms the receipt.
  Future<int> buyPackage(GiftPackage package) async {
    await ensureInitialized();

    if (!_isAvailable) {
      throw Exception('متجر التطبيقات غير متاح على هذا الجهاز');
    }

    final product = _products.firstWhere(
      (p) => p.id == package.productId,
      orElse: () => throw Exception('هذا المنتج غير متوفر حاليًا على المتجر'),
    );

    if (_pendingPurchases.containsKey(package.productId)) {
      throw Exception('هناك عملية شراء قيد التنفيذ لهذا المنتج بالفعل');
    }

    final completer = Completer<int>();
    _pendingPurchases[package.productId] = completer;

    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
    );

    if (!started) {
      _pendingPurchases.remove(package.productId);
      throw Exception('تعذر بدء عملية الشراء');
    }

    return completer.future;
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      final completer = _pendingPurchases[purchaseDetails.productID];

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.error:
          _pendingPurchases.remove(purchaseDetails.productID);
          completer?.completeError(
            Exception(purchaseDetails.error?.message ?? 'فشلت عملية الشراء'),
          );

        case PurchaseStatus.canceled:
          _pendingPurchases.remove(purchaseDetails.productID);
          completer?.completeError(Exception('تم إلغاء الشراء'));

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final crownsAdded = await _verifyPurchase(purchaseDetails);
          _pendingPurchases.remove(purchaseDetails.productID);
          if (crownsAdded != null) {
            completer?.complete(crownsAdded);
          } else {
            completer?.completeError(Exception('فشل التحقق من عملية الشراء'));
          }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<int?> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final response = await supabase.functions.invoke(
        'verify_purchase',
        body: {
          'product_id': purchaseDetails.productID,
          'receipt_data': purchaseDetails.verificationData.serverVerificationData,
          'source': purchaseDetails.verificationData.source,
        },
      );
      if (response.status != 200) {
        debugPrint('Verify Purchase failed: ${response.data}');
        return null;
      }
      return (response.data['crowns_added'] as num?)?.toInt();
    } catch (e) {
      debugPrint('Verify Purchase Exception: $e');
      return null;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}

@riverpod
IapService iapService(Ref ref) {
  final service = IapService();
  ref.onDispose(() => service.dispose());
  return service;
}
