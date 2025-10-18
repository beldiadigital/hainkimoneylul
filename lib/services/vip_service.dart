import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VipSubscriptionService {
  // Production App Store Product IDs - Bu ID'leri App Store Connect'te oluşturmanız gerekiyor
  static const String _monthlyProductId = '6754197922';
  static const String _yearlyProductId = 'hain_kim_vip_yearly';
  
  // Local storage keys
  static const String _vipStatusKey = 'vip_status';
  static const String _vipExpiryKey = 'vip_expiry';
  static const String _lastReceiptKey = 'last_receipt';

  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static List<ProductDetails> _products = [];
  static bool _isAvailable = false;

  // VIP özellikler
  static bool _isVipActive = false;
  static DateTime? _vipExpiryDate;

  // Getter'lar
  static bool get isVipActive => _isVipActive;
  static DateTime? get vipExpiryDate => _vipExpiryDate;
  static List<ProductDetails> get products => _products;
  static bool get isAvailable => _isAvailable;

  /// Abonelik servisini başlat
  static Future<void> initialize() async {
    try {
      // In-app purchase kullanılabilir mi?
      _isAvailable = await _inAppPurchase.isAvailable();
      
      if (!_isAvailable) {
        print('⚠️ In-app purchase kullanılamıyor');
        return;
      }

      // Mevcut VIP durumunu yükle
      await _loadVipStatus();

      // Ürünleri yükle
      await _loadProducts();

      // Satın alma dinleyicisini başlat
      _listenToPurchaseUpdated();

      // Mevcut satın almaları geri yükle (önemli: uygulama her açıldığında)
      await _restorePurchases();

      print('✅ VIP abonelik servisi başlatıldı - VIP Active: $_isVipActive');
    } catch (e) {
      print('❌ VIP servis başlatma hatası: $e');
    }
  }

  /// Ürünleri App Store/Play Store'dan yükle
  static Future<void> _loadProducts() async {
    try {
      // Şu anda sadece aylık abonelik mevcut
      const Set<String> productIds = {_monthlyProductId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Bulunamayan ürünler: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('✅ ${_products.length} ürün yüklendi');
      
      for (var product in _products) {
        print('📦 Ürün: ${product.id} - ${product.price}');
      }
    } catch (e) {
      print('❌ Ürün yükleme hatası: $e');
    }
  }

  /// Satın alma işlemlerini dinle
  static void _listenToPurchaseUpdated() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('❌ Satın alma dinleme hatası: $error'),
    );
  }

  /// Satın alma güncellemelerini işle
  static Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('⏳ Satın alma beklemede...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print('❌ Satın alma hatası: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // VIP aboneliği aktif et
          await _activateVip(purchaseDetails.productID);
          print('✅ VIP abonelik aktif edildi: ${purchaseDetails.productID}');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// VIP aboneliği aktif et
  static Future<void> _activateVip(String productId) async {
    try {
      _isVipActive = true;
      
      // Sadece aylık abonelik için süre belirle
      if (productId == _monthlyProductId) {
        _vipExpiryDate = DateTime.now().add(const Duration(days: 30));
      }

      // Local storage'a kaydet
      await _saveVipStatus();
    } catch (e) {
      print('❌ VIP aktivasyon hatası: $e');
    }
  }

  /// VIP durumunu local storage'dan yükle
  static Future<void> _loadVipStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVipActive = prefs.getBool(_vipStatusKey) ?? false;
      
      final expiryTimestamp = prefs.getInt(_vipExpiryKey);
      if (expiryTimestamp != null) {
        _vipExpiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
        
        // Süre dolmuş mu kontrol et
        if (_vipExpiryDate!.isBefore(DateTime.now())) {
          _isVipActive = false;
          _vipExpiryDate = null;
          await _saveVipStatus();
        }
      }
    } catch (e) {
      print('❌ VIP durum yükleme hatası: $e');
    }
  }

  /// VIP durumunu local storage'a kaydet
  static Future<void> _saveVipStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vipStatusKey, _isVipActive);
      
      if (_vipExpiryDate != null) {
        await prefs.setInt(_vipExpiryKey, _vipExpiryDate!.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_vipExpiryKey);
      }
    } catch (e) {
      print('❌ VIP durum kaydetme hatası: $e');
    }
  }

  /// Aylık abonelik satın al
  static Future<bool> purchaseMonthly() async {
    return await _purchaseProduct(_monthlyProductId);
  }

  /// Yıllık abonelik satın al
  static Future<bool> purchaseYearly() async {
    return await _purchaseProduct(_yearlyProductId);
  }

  /// Ürün satın al
  static Future<bool> _purchaseProduct(String productId) async {
    try {
      final ProductDetails? product = _products.where((p) => p.id == productId).firstOrNull;
      
      if (product == null) {
        print('❌ Ürün bulunamadı: $productId');
        return false;
      }

      print('🛒 Satın alma başlatılıyor: ${product.id} - ${product.price}');

      // Abonelik satın alma
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      return true;
    } catch (e) {
      print('❌ Satın alma hatası: $e');
      return false;
    }
  }

  /// Satın almaları geri yükle
  static Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      print('✅ Satın almalar geri yüklendi');
    } catch (e) {
      print('❌ Satın alma geri yükleme hatası: $e');
    }
  }

  /// Satın almaları geri yükle (private)
  static Future<void> _restorePurchases() async {
    await restorePurchases();
  }

  /// Aboneliği iptal et (sadece durum güncelleme)
  static Future<void> cancelSubscription() async {
    _isVipActive = false;
    _vipExpiryDate = null;
    await _saveVipStatus();
  }

  /// Servisi temizle
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Test için VIP aktif et (sadece debug)
  static Future<void> activateVipForTesting() async {
    if (kDebugMode) {
      _isVipActive = true;
      _vipExpiryDate = DateTime.now().add(const Duration(days: 30));
      await _saveVipStatus();
      print('🔧 Test için VIP aktif edildi');
    }
  }

  /// Production'da test modu kontrolü
  static bool get isProductionMode {
    return const bool.fromEnvironment('dart.vm.product');
  }

  /// VIP durumu debug bilgisi
  static void logVipStatus() {
    if (kDebugMode) {
      print('📊 VIP Durum Raporu:');
      print('  - VIP Aktif: $_isVipActive');
      print('  - Bitiş Tarihi: $_vipExpiryDate');
      print('  - Servis Hazır: $_isAvailable');
      print('  - Ürün Sayısı: ${_products.length}');
      print('  - Production Mode: $isProductionMode');
    }
  }

  /// VIP özelliklerini kontrol et
  static Map<String, dynamic> getVipFeatures() {
    return {
      'no_ads': _isVipActive,
      'remove_banner_ads': _isVipActive,
      'remove_interstitial_ads': _isVipActive,
    };
  }
}