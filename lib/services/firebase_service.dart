import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;

  static FirebaseFirestore get firestore =>
      _firestore ?? FirebaseFirestore.instance;
  static FirebaseAnalytics get analytics =>
      _analytics ?? FirebaseAnalytics.instance;
  static FirebaseCrashlytics get crashlytics =>
      _crashlytics ?? FirebaseCrashlytics.instance;

  // Firebase'i başlat - tüm platformlarda
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firestore = FirebaseFirestore.instance;
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Crashlytics'i sadece gerçek Android cihazlarda etkinleştir
      if (Platform.isAndroid && !kIsWeb) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
        print('✅ Crashlytics etkinleştirildi');
      }

      // Firestore settings (production için optimize)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // Online-only için cache kapalı
        cacheSizeBytes: 1048576, // 1MB cache limit
      );

      print('✅ Firebase başlatıldı - Strict online mode aktif');
    } catch (e) {
      print('⚠️ Firebase başlatma hatası: $e');
    }
  }

  // Kullanıcı istatistikleri
  static Future<void> logEvent(
    String eventName,
    Map<String, Object> parameters,
  ) async {
    try {
      await analytics.logEvent(name: eventName, parameters: parameters);
    } catch (e) {
      print('Analytics event log error: $e');
    }
  }

  // Oyun başlama eventi
  static Future<void> logGameStart(int playerCount, int gameDuration) async {
    await logEvent('game_start', {
      'player_count': playerCount,
      'game_duration_minutes': gameDuration,
    });
  }

  // Oyun bitirme eventi
  static Future<void> logGameEnd(
    int gameDurationSeconds,
    bool wasCompleted,
  ) async {
    await logEvent('game_end', {
      'game_duration_seconds': gameDurationSeconds,
      'was_completed': wasCompleted,
    });
  }

  // VIP satın alma eventi
  static Future<void> logVipPurchase(String productId, double price) async {
    await logEvent('vip_purchase', {'product_id': productId, 'price': price});
  }

  // Reklam görüntüleme eventi
  static Future<void> logAdViewed(String adType) async {
    await logEvent('ad_viewed', {'ad_type': adType});
  }

  // Hata raporlama (sadece desteklenen platformlarda)
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace,
  ) async {
    try {
      // Crashlytics sadece Android'de güvenilir çalışır
      if (!kIsWeb && Platform.isAndroid) {
        await crashlytics.recordError(exception, stackTrace);
      } else {
        print(
          'Crashlytics desteklenmiyor, hata konsola yazdırıldı: $exception',
        );
      }
    } catch (e) {
      print('Crashlytics error record failed: $e');
    }
  }

  // Oyun verilerini Firestore'a kaydet (isteğe bağlı)
  static Future<void> saveGameResult({
    required String gameId,
    required List<String> players,
    required String impostor,
    required String celebrity,
    required int duration,
  }) async {
    try {
      await firestore.collection('game_results').doc(gameId).set({
        'players': players,
        'impostor': impostor,
        'celebrity': celebrity,
        'duration_seconds': duration,
        'created_at': FieldValue.serverTimestamp(),
        'device_id': 'anonymous', // Authentication yok, device_id kullan
      });
    } catch (e) {
      print('Firestore save error: $e');
      await recordError(e, StackTrace.current);
    }
  }

  // Kullanıcı tercihlerini kaydet
  static Future<void> saveUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      // Authentication yok, local storage kullan veya device_id ile kaydet
      await firestore
          .collection('user_preferences')
          .doc('anonymous')
          .set(preferences, SetOptions(merge: true));
    } catch (e) {
      print('User preferences save error: $e');
    }
  }

  // Kullanıcı tercihlerini al
  static Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final doc = await firestore
          .collection('user_preferences')
          .doc('anonymous')
          .get();
      return doc.data();
    } catch (e) {
      print('User preferences get error: $e');
    }
    return null;
  }

  // ============ MULTIPLAYER LOBİ SİSTEMİ ============

  // İnternet bağlantı kontrolü (geliştirilmiş)
  static Future<bool> checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      // Bağlantı yoksa direkt false döndür
      if (connectivityResult == ConnectivityResult.none) {
        print('❌ İnternet bağlantısı yok');
        return false;
      }

      // Gerçek internet erişimi test et
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5));

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('✅ İnternet bağlantısı aktif');
          return true;
        }
      } catch (e) {
        print('❌ İnternet erişimi başarısız: $e');
        return false;
      }

      return false;
    } catch (e) {
      print('❌ Bağlantı kontrolü hatası: $e');
      return false;
    }
  }

  // Lobi oluştur (Sadece Online Mode)
  static Future<String?> createLobby(String hostName) async {
    print('🔥 Firebase createLobby çağrıldı: $hostName');

    // İnternet bağlantısını kontrol et
    final hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      print('❌ İnternet bağlantısı yok - Lobi oluşturulamaz');
      return null; // İnternet yoksa null döndür
    }

    try {
      final String lobbyId = DateTime.now().millisecondsSinceEpoch.toString();
      print('📝 Lobi ID oluşturuldu: $lobbyId');

      final lobbyData = {
        'id': lobbyId,
        'host': hostName,
        'players': [hostName],
        'status': 'waiting',
        'created_at': FieldValue.serverTimestamp(),
        'max_players': 8,
        'game_started': false,
        'celebrity': null,
        'impostor': null,
      };

      // Firebase'e kaydet (online only)
      await firestore
          .collection('lobbies')
          .doc(lobbyId)
          .set(lobbyData)
          .timeout(
            Duration(seconds: 10), // Timeout'u geri yükselttik
          );

      print('✅ Firebase online lobi oluşturuldu!');
      await logEvent('lobby_created', {'lobby_id': lobbyId, 'host': hostName});
      return lobbyId;
    } catch (e, stackTrace) {
      print('❌ Firebase bağlantı hatası - İnternet gerekli: $e');
      await recordError(e, stackTrace);
      return null; // Firebase hatası durumunda da null döndür
    }
  }

  // Lobiye katıl
  static Future<bool> joinLobby(String lobbyId, String playerName) async {
    // İnternet bağlantısını kontrol et
    final hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      print('❌ İnternet bağlantısı yok - Lobiye katılınamaz');
      return false; // İnternet yoksa katılamaz
    }

    try {
      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);
      final lobbyDoc = await lobbyRef.get().timeout(Duration(seconds: 10));

      if (!lobbyDoc.exists) {
        print('❌ Lobi bulunamadı: $lobbyId');
        return false; // Lobi yoksa katılamaz
      }

      final lobbyData = lobbyDoc.data()!;
      final List<String> players = List<String>.from(
        lobbyData['players'] ?? [],
      );

      if (players.length >= (lobbyData['max_players'] ?? 8)) {
        print('❌ Lobi dolu');
        return false;
      }

      if (lobbyData['status'] != 'waiting') {
        print('❌ Oyun başlamış');
        return false;
      }

      if (!players.contains(playerName)) {
        players.add(playerName);
        await lobbyRef.update({'players': players});
      }

      await logEvent('lobby_joined', {
        'lobby_id': lobbyId,
        'player': playerName,
      });
      return true;
    } catch (e) {
      print('❌ Firebase bağlantı hatası - İnternet gerekli: $e');
      await recordError(e, StackTrace.current);
      return false; // Firebase hatası durumunda katılım başarısız
    }
  }

  // Lobi dinleyicisi (gerçek zamanlı güncellemeler)
  // Lobi dinleme
  static Stream<DocumentSnapshot> listenToLobby(String lobbyId) {
    try {
      return firestore.collection('lobbies').doc(lobbyId).snapshots();
    } catch (e) {
      print('❌ Firebase dinleme hatası - Boş stream döndürülüyor: $e');
      // Hata durumunda boş stream döndür
      return Stream.empty();
    }
  }

  // Oyunu başlat
  static Future<bool> startGame(String lobbyId) async {
    try {
      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);
      final lobbyDoc = await lobbyRef.get();

      if (!lobbyDoc.exists) return false;

      final lobbyData = lobbyDoc.data()!;
      final List<String> players = List<String>.from(
        lobbyData['players'] ?? [],
      );

      if (players.length < 3) {
        print('En az 3 oyuncu gerekli');
        return false;
      }

      // Rastgele ünlü ve hain seç
      final Random random = Random();
      final celebrities = [
        'Hadise',
        'Tarkan',
        'Sezen Aksu',
        'Cem Yılmaz',
        'Şahan Gökbakar',
        'Gülben Ergen',
        'İbrahim Tatlıses',
        'Ajda Pekkan',
        'Barış Manço',
      ];
      final String celebrity = celebrities[random.nextInt(celebrities.length)];
      final String impostor = players[random.nextInt(players.length)];

      await lobbyRef.update({
        'status': 'playing',
        'game_started': true,
        'celebrity': celebrity,
        'impostor': impostor,
        'start_time': FieldValue.serverTimestamp(),
      });

      await logEvent('game_started', {
        'lobby_id': lobbyId,
        'players': players.length,
        'celebrity': celebrity,
      });

      return true;
    } catch (e) {
      print('Oyun başlatma hatası: $e');
      await recordError(e, StackTrace.current);
      return false;
    }
  }

  // Lobiden ayrıl
  static Future<void> leaveLobby(String lobbyId, String playerName) async {
    try {
      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);
      final lobbyDoc = await lobbyRef.get();

      if (!lobbyDoc.exists) return;

      final lobbyData = lobbyDoc.data()!;
      final List<String> players = List<String>.from(
        lobbyData['players'] ?? [],
      );

      players.remove(playerName);

      if (players.isEmpty) {
        // Son oyuncu ayrıldıysa lobi sil
        await lobbyRef.delete();
      } else {
        await lobbyRef.update({'players': players});

        // Host ayrıldıysa yeni host ata
        if (lobbyData['host'] == playerName && players.isNotEmpty) {
          await lobbyRef.update({'host': players.first});
        }
      }

      await logEvent('lobby_left', {'lobby_id': lobbyId, 'player': playerName});
    } catch (e) {
      print('Lobiden ayrılma hatası: $e');
      await recordError(e, StackTrace.current);
    }
  }

  // Aktif lobileri listele
  static Future<List<Map<String, dynamic>>> getActiveLobbies() async {
    try {
      final QuerySnapshot snapshot = await firestore
          .collection('lobbies')
          .where('status', isEqualTo: 'waiting')
          .orderBy('created_at', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Lobi listesi alma hatası: $e');
      return [];
    }
  }
}
