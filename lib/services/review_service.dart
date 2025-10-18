import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static const String _lastReviewPromptKey = 'last_review_prompt';
  static const String _gameCountKey = 'game_count';
  static const String _hasRatedKey = 'has_rated';

  // Her 5 oyunda bir değerlendirme iste
  static const int gamesUntilReview = 5;

  // Son değerlendirmeden sonra 7 gün bekle
  static const int daysBetweenReviews = 7;

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Oyun tamamlandığında çağrılır
  static Future<void> onGameCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Daha önce değerlendirme yapılmış mı?
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;
      if (hasRated) return;

      // Oyun sayısını artır
      final gameCount = prefs.getInt(_gameCountKey) ?? 0;
      final newGameCount = gameCount + 1;
      await prefs.setInt(_gameCountKey, newGameCount);

      // Değerlendirme zamanı geldi mi?
      if (newGameCount >= gamesUntilReview) {
        final lastPrompt = prefs.getInt(_lastReviewPromptKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final daysSinceLastPrompt = (now - lastPrompt) / (1000 * 60 * 60 * 24);

        if (daysSinceLastPrompt >= daysBetweenReviews) {
          await _showReviewPrompt();
          await prefs.setInt(_lastReviewPromptKey, now);
          // Oyun sayısını sıfırla (bir sonraki döngü için)
          await prefs.setInt(_gameCountKey, 0);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Review service hatası: $e');
      }
    }
  }

  /// Değerlendirme popup'ını göster
  static Future<void> _showReviewPrompt() async {
    try {
      // In-app review kullanılabilir mi?
      if (await _inAppReview.isAvailable()) {
        print('🌟 Değerlendirme popup gösteriliyor...');
        await _inAppReview.requestReview();

        // Kullanıcının değerlendirme yaptığını varsay
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_hasRatedKey, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Review prompt hatası: $e');
      }
    }
  }

  /// Manuel olarak App Store'u aç (Ayarlar sayfası için)
  static Future<void> openAppStore() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ App Store açma hatası: $e');
      }
    }
  }

  /// Kullanıcı değerlendirme yaptı olarak işaretle
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  /// Test için değerlendirme durumunu sıfırla
  static Future<void> resetForTesting() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastReviewPromptKey);
      await prefs.remove(_gameCountKey);
      await prefs.remove(_hasRatedKey);
      print('🔄 Review durumu test için sıfırlandı');
    }
  }

  /// Mevcut istatistikleri göster (debug)
  static Future<void> showStats() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      final gameCount = prefs.getInt(_gameCountKey) ?? 0;
      final hasRated = prefs.getBool(_hasRatedKey) ?? false;
      final lastPrompt = prefs.getInt(_lastReviewPromptKey) ?? 0;

      print('📊 Review Stats:');
      print('  - Oyun sayısı: $gameCount');
      print('  - Değerlendirme yapıldı: $hasRated');
      print(
        '  - Son prompt: ${DateTime.fromMillisecondsSinceEpoch(lastPrompt)}',
      );
    }
  }
}
