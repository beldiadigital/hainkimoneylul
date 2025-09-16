import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'firebase_service.dart';

class InAppPurchaseService {
  static const String _kVipMonthlyId = 'vip_monthly_subscription';
  static const String _kVipYearlyId = 'vip_yearly_subscription';
  static const List<String> _kProductIds = <String>[
    _kVipMonthlyId,
    _kVipYearlyId,
  ];

  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static late StreamSubscription<List<PurchaseDetails>> _subscription;
  static List<ProductDetails> _products = <ProductDetails>[];
  static bool _isAvailable = false;
  static bool _purchasePending = false;
  static String? _queryProductError;

  // Callbacks
  static Function(bool)? onVipStatusChanged;
  static Function(String)? onPurchaseError;
  static Function()? onPurchaseSuccess;

  // VIP durumu
  static bool _isVip = false;
  static bool get isVip => _isVip;

  // In-App Purchase servisini başlat
  static Future<void> initializeInAppPurchase() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        print('In-app purchase not available');
        return;
      }

      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      }

      final Stream<List<PurchaseDetails>> purchaseUpdated =
          _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        (purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {
          _subscription.cancel();
        },
        onError: (error) {
          print('Purchase stream error: $error');
        },
      );

      await _loadProducts();
      await _restorePurchases();
    } catch (e) {
      print('Initialize in-app purchase error: $e');
      FirebaseService.recordError(e, StackTrace.current);
    }
  }

  // Ürünleri yükle
  static Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_kProductIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        _queryProductError = response.error!.message;
        print('Query products error: $_queryProductError');
        return;
      }

      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Load products error: $e');
      FirebaseService.recordError(e, StackTrace.current);
    }
  }

  // Satın alma dinleyicisi
  static void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchasePending = true;
        print('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _purchasePending = false;
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _purchasePending = false;
        _handleSuccessfulPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Başarılı satın alma işlemi
  static void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    print('Purchase successful: ${purchaseDetails.productID}');

    if (purchaseDetails.productID == _kVipMonthlyId ||
        purchaseDetails.productID == _kVipYearlyId) {
      _setVipStatus(true);

      // Firebase Analytics'e log at
      FirebaseService.logVipPurchase(
        purchaseDetails.productID,
        _getProductPrice(purchaseDetails.productID),
      );

      onPurchaseSuccess?.call();
    }
  }

  // Hata işleme
  static void _handleError(IAPError error) {
    print('Purchase error: ${error.message}');
    onPurchaseError?.call(error.message);
  }

  // VIP durumunu ayarla
  static void _setVipStatus(bool isVip) {
    _isVip = isVip;
    onVipStatusChanged?.call(isVip);
  }

  // Ürün fiyatını al
  static double _getProductPrice(String productId) {
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) return 0.0;

    // Fiyat string'inden double'a çevir
    final priceString = product.price
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .replaceAll(',', '.');
    return double.tryParse(priceString) ?? 0.0;
  }

  // Aylık VIP satın al
  static Future<void> buyMonthlyVip() async {
    await _buyProduct(_kVipMonthlyId);
  }

  // Yıllık VIP satın al
  static Future<void> buyYearlyVip() async {
    await _buyProduct(_kVipYearlyId);
  }

  // Ürün satın al
  static Future<void> _buyProduct(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('In-app purchase not available');
      return;
    }

    final ProductDetails? productDetails = _products
        .where((product) => product.id == productId)
        .firstOrNull;

    if (productDetails == null) {
      onPurchaseError?.call('Product not found');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      if (productId == _kVipMonthlyId || productId == _kVipYearlyId) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Buy product error: $e');
      onPurchaseError?.call('Purchase failed: $e');
      FirebaseService.recordError(e, StackTrace.current);
    }
  }

  // Satın almaları geri yükle
  static Future<void> _restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Restore purchases error: $e');
      FirebaseService.recordError(e, StackTrace.current);
    }
  }

  // Manuel restore
  static Future<void> restorePurchases() async {
    await _restorePurchases();
  }

  // Mevcut ürünler listesi
  static List<ProductDetails> get products => _products;

  // Satın alma durumu
  static bool get isPurchasePending => _purchasePending;

  // Servis mevcut mu
  static bool get isAvailable => _isAvailable;

  // Servis temizliği
  static void dispose() {
    _subscription.cancel();
  }

  // Test için VIP durumunu manuel ayarla (sadece debug modda)
  static void setVipForTesting(bool isVip) {
    if (kDebugMode) {
      _setVipStatus(isVip);
    }
  }
}

// iOS Payment Queue Delegate
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
