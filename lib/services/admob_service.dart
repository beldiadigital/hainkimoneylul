import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_service.dart';

class AdMobService {
  static const int maxFailedLoadAttempts = 3;
  static int _numBannerLoadAttempts = 0;
  static int _numInterstitialLoadAttempts = 0;
  static int _numRewardedLoadAttempts = 0;

  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  // Test Ad Unit IDs (production'da gerçek ID'ler kullanılacak)
  static String get bannerAdUnitId {
    if (kIsWeb) return ''; // Web'de AdMob yok

    if (kDebugMode) {
      // Test Ad Unit IDs
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Test Banner
          : 'ca-app-pub-3940256099942544/2934735716'; // Test Banner iOS
    } else {
      // Production Ad Unit IDs - YENİ BANNER ID'Sİ GÜNCELLENDİ
      return Platform.isAndroid
          ? 'ca-app-pub-9098317866883430/6819583156' // Android Banner (YENİ)
          : 'ca-app-pub-9098317866883430/6819583156'; // iOS Banner (YENİ)
    }
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return ''; // Web'de AdMob yok

    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Test Interstitial
          : 'ca-app-pub-3940256099942544/4411468910'; // Test Interstitial iOS
    } else {
      // Production Ad Unit IDs - Gerçek ID'ler
      return Platform.isAndroid
          ? 'ca-app-pub-9098317866883430/8982674071' // Android Interstitial
          : 'ca-app-pub-9098317866883430/8982674071'; // iOS Interstitial (aynı ID)
    }
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return ''; // Web'de AdMob yok

    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Test Rewarded
          : 'ca-app-pub-3940256099942544/1712485313'; // Test Rewarded iOS
    } else {
      // Production Ad Unit IDs - Bu ID'leri AdMob konsolundan oluşturmanız gerekiyor
      return Platform.isAndroid
          ? 'ca-app-pub-9098317866883430/REWARDED_ANDROID_ID'
          : 'ca-app-pub-9098317866883430/REWARDED_IOS_ID';
    }
  }

  // AdMob'u başlat
  static Future<void> initializeAdMob() async {
    await MobileAds.instance.initialize();

    // GDPR ve CCPA compliance için
    RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: kDebugMode ? ['TEST_DEVICE_ID'] : [],
    );
    MobileAds.instance.updateRequestConfiguration(configuration);
  }

  // Banner reklam oluştur
  static BannerAd? createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded.');
          _numBannerLoadAttempts = 0;
          FirebaseService.logAdViewed('banner');
        },
        onAdFailedToLoad: (ad, err) {
          print('Banner ad failed to load: $err');
          ad.dispose();
          _numBannerLoadAttempts += 1;
        },
        onAdOpened: (ad) {
          print('Banner ad opened.');
          FirebaseService.logEvent('ad_clicked', {'ad_type': 'banner'});
        },
        onAdClosed: (ad) {
          print('Banner ad closed.');
        },
      ),
    );
  }

  // Banner reklam durumu
  static bool get isBannerAdReady => _bannerAd != null;
  static BannerAd? get bannerAd => _bannerAd;

  // Banner reklam yükle
  static void loadBannerAd() {
    _bannerAd = createBannerAd();
    _bannerAd!.load();
  }

  // Interstitial reklam yükle
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded.');
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (err) {
          print('Interstitial ad failed to load: $err');
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  // Rewarded reklam yükle
  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('Rewarded ad loaded.');
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (err) {
          print('Rewarded ad failed to load: $err');
          _numRewardedLoadAttempts += 1;
          _rewardedAd = null;
          if (_numRewardedLoadAttempts < maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  // Banner reklam widget'ı al
  static Widget? getBannerAdWidget() {
    if (_bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return null;
  }

  // Interstitial reklam göster
  static void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('Interstitial ad showed fullscreen content.');
        FirebaseService.logAdViewed('interstitial');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('Interstitial ad dismissed fullscreen content.');
        ad.dispose();
        loadInterstitialAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        print('Interstitial ad failed to show fullscreen content: $err');
        ad.dispose();
        loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  // Rewarded reklam göster
  static void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      onAdDismissed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('Rewarded ad showed fullscreen content.');
        FirebaseService.logAdViewed('rewarded');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('Rewarded ad dismissed fullscreen content.');
        ad.dispose();
        loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        print('Rewarded ad failed to show fullscreen content: $err');
        ad.dispose();
        loadRewardedAd();
        onAdDismissed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('User earned reward: ${reward.amount} ${reward.type}');
        FirebaseService.logEvent('rewarded_ad_earned', {
          'reward_amount': reward.amount,
          'reward_type': reward.type,
        });
        onUserEarnedReward();
      },
    );

    _rewardedAd = null;
  }

  // Reklamları önceden yükle
  static void preloadAds() {
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // Tüm reklamları dispose et
  static void disposeAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }

  // Interstitial reklam hazır mı?
  static bool get isInterstitialReady => _interstitialAd != null;

  // Rewarded reklam hazır mı?
  static bool get isRewardedReady => _rewardedAd != null;

  // Banner reklam hazır mı?
  static bool get isBannerReady => _bannerAd != null;
}
