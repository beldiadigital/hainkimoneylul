import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import '../firebase_options.dart';
import '../celebrities.dart';

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
      }

      // Firestore settings (production için optimize)
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // Online-only için cache kapalı
        cacheSizeBytes: 1048576, // 1MB cache limit
      );
    } catch (e) {
      // Sessiz hata yönetimi
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
      // Sessiz hata yönetimi
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
      final connectivityResults = await Connectivity().checkConnectivity();

      // Bağlantı yoksa direkt false döndür
      if (connectivityResults.contains(ConnectivityResult.none) ||
          connectivityResults.isEmpty) {
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
        'creator': hostName, // Lobi kurucusu
        'players': [hostName],
        'status': 'waiting',
        'created_at': FieldValue.serverTimestamp(),
        'max_players': 8,
        'game_started': false,
        'celebrity': null,
        'impostor': null,
        'game_settings': {
          'duration': 300, // 5 dakika default
          'hints_enabled': true,
        },
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

      return await firestore.runTransaction((transaction) async {
        final lobbyDoc = await transaction.get(lobbyRef);

        if (!lobbyDoc.exists) return false;

        final lobbyData = lobbyDoc.data()!;

        print(
          '🔍 startGame başında lobby durumu: started=${lobbyData['game_started']}, ended=${lobbyData['game_ended']}, status=${lobbyData['status']}',
        );

        final List<String> players = List<String>.from(
          lobbyData['players'] ?? [],
        );

        if (players.isEmpty) {
          // SCREENSHOT: 1 oyuncuyla test
          print('En az 1 oyuncu gerekli');
          return false;
        }

        // Sadece gerçekten aktif oyun varsa dur
        if (lobbyData['status'] == 'playing' &&
            lobbyData['game_started'] == true &&
            lobbyData['game_ended'] != true) {
          print(
            '🎮 Oyun zaten aktif - çıkılıyor (started: ${lobbyData['game_started']}, ended: ${lobbyData['game_ended']})',
          );
          return true;
        }

        print('🆕 Yeni oyun başlatılıyor (game_ended yok)');

        // ZORLA TEMİZLİK - hiçbir kalıntı bırakma
        // 1. Tüm eski verileri temizle

        // Rastgele ünlü ve hain seç (atomic operation sayesinde sadece bir kez)
        final Random random = Random();

        // Ünlüleri kategoriye göre filtrele
        List<Map<String, dynamic>> availableCelebrities = [];
        final selectedCategories = List<String>.from(
          lobbyData['gameSettings']?['selectedCategories'] ?? [],
        );

        if (selectedCategories.isNotEmpty) {
          // Sadece seçili kategorilerden ünlüleri al
          for (final celebrity in celebrities) {
            if (selectedCategories.contains(celebrity['category'])) {
              availableCelebrities.add(celebrity);
            }
          }
        } else {
          // Kategoriler boşsa tüm ünlüleri dahil et
          availableCelebrities = List.from(celebrities);
        }

        // Eğer hiç ünlü yoksa varsayılan liste kullan
        if (availableCelebrities.isEmpty) {
          availableCelebrities = List.from(celebrities);
        }

        final selectedCelebrity =
            availableCelebrities[random.nextInt(availableCelebrities.length)];
        final String celebrity = selectedCelebrity['name'];

        // Oyuncu rollerini belirle (impostor/masum dağılımı)
        final int totalPlayers = players.length;
        final gameSettings = Map<String, dynamic>.from(
          lobbyData['gameSettings'] ?? {},
        );

        // Hain sayısını belirle (ayarlardan veya varsayılan)
        int impostorCount;
        if (gameSettings.containsKey('impostorCount') &&
            gameSettings['impostorCount'] != null) {
          impostorCount = gameSettings['impostorCount'];
        } else {
          // DEBUG: 1 oyuncu = 0 hain, 2+ oyuncu normal mantık
          if (totalPlayers == 1) {
            impostorCount = 0; // 1 oyuncuda hain yok
          } else if (totalPlayers == 2) {
            impostorCount = 1;
          } else {
            impostorCount = (totalPlayers / 3).ceil().clamp(
              1,
              totalPlayers - 1,
            );
          }
        }

        // Hain sayısını güvenli aralıkta tut
        impostorCount = impostorCount.clamp(0, totalPlayers - 1);

        // Rastgele oyuncuları hain olarak seç
        final List<String> shuffledPlayers = List.from(players);
        shuffledPlayers.shuffle(random);
        final List<String> impostors = shuffledPlayers
            .take(impostorCount)
            .toList();

        // Tüm oyuncular için role map'i oluştur
        final Map<String, String> playerRoles = {};
        for (final player in players) {
          playerRoles[player] = impostors.contains(player)
              ? 'impostor'
              : 'innocent';
        }

        transaction.update(lobbyRef, {
          'status': 'playing',
          'game_started': true,
          'celebrity': celebrity,
          'impostor': impostors.isNotEmpty
              ? impostors.first
              : null, // Boş liste kontrolü
          'impostors': impostors, // Yeni sistem
          'player_roles': playerRoles, // Her oyuncunun rolü
          'start_time': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Oyun başlatma hatası: $e');
      await recordError(e, StackTrace.current);
      return false;
    }
  }

  // Oyunu bitir (senkronize)
  static Future<bool> endGame(String lobbyId, String playerName) async {
    try {
      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);

      return await firestore.runTransaction((transaction) async {
        final lobbyDoc = await transaction.get(lobbyRef);

        if (!lobbyDoc.exists) return false;

        final lobbyData = lobbyDoc.data()!;

        // Eğer oyun zaten bitmişse, duplicate request'i önle
        if (lobbyData['game_ended'] == true) {
          return true; // Zaten bitmiş
        }

        // Oyunu bitir ve lobby'yi yeni oyuna hazırla
        transaction.update(lobbyRef, {
          'game_ended': true,
          'ended_by': playerName,
          'end_time': FieldValue.serverTimestamp(),
          'status': 'finished', // Oyun bittiğinde 'finished' yap
          'game_started': false, // Hemen yeni oyuna hazır hale getir
          'celebrity': FieldValue.delete(), // Eski oyun verilerini temizle
          'impostor': FieldValue.delete(),
          'impostors': FieldValue.delete(),
          'player_roles': FieldValue.delete(),
          'start_time': FieldValue.delete(),
        });

        return true;
      });
    } catch (e) {
      print('Oyun bitirme hatası: $e');
      await recordError(e, StackTrace.current);
      return false;
    }
  }

  // Lobby'yi yeni oyuna hazırla
  static Future<bool> resetLobbyForNewGame(String lobbyId) async {
    try {
      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);

      return await firestore.runTransaction((transaction) async {
        final lobbyDoc = await transaction.get(lobbyRef);

        if (!lobbyDoc.exists) return false;

        // KOMPLE TEMİZLİK - her şeyi sıfırla
        transaction.update(lobbyRef, {
          'status': 'waiting',
          'game_started': false,
          'game_ended': FieldValue.delete(),
          'ended_by': FieldValue.delete(),
          'end_time': FieldValue.delete(),
          'start_time': FieldValue.delete(),
          'celebrity': FieldValue.delete(),
          'player_roles': FieldValue.delete(),
          'current_round': FieldValue.delete(),
          'game_duration': FieldValue.delete(),
          // Lobii tamamen temiz duruma getir
        });

        return true;
      });
    } catch (e) {
      print('❌ Lobby reset hatası: $e');
      await recordError(e, StackTrace.current);
      return false;
    }
  }

  // Lobiden ayrıl
  static Future<void> leaveLobby(String lobbyId, String playerName) async {
    try {
      print('🚪 Oyuncu lobiden ayrılıyor: $playerName (Lobi: $lobbyId)');

      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);
      final lobbyDoc = await lobbyRef.get();

      if (!lobbyDoc.exists) {
        print('❌ Lobi bulunamadı: $lobbyId');
        return;
      }

      final lobbyData = lobbyDoc.data()!;
      final List<String> players = List<String>.from(
        lobbyData['players'] ?? [],
      );

      if (!players.contains(playerName)) {
        print('⚠️ Oyuncu zaten lobide değil: $playerName');
        return;
      }

      players.remove(playerName);
      print('✅ Oyuncu listesinden çıkarıldı. Kalan oyuncular: $players');

      if (players.isEmpty) {
        // Son oyuncu ayrıldıysa lobi sil
        print('🗑️ Son oyuncu ayrıldı, lobi siliniyor');
        await lobbyRef.delete();
      } else {
        await lobbyRef.update({'players': players});
        print('📝 Lobi güncellendi - yeni oyuncu sayısı: ${players.length}');

        // Host ayrıldıysa yeni host ata
        if (lobbyData['host'] == playerName && players.isNotEmpty) {
          print('👑 Host ayrıldı, yeni host atanıyor: ${players.first}');
          await lobbyRef.update({'host': players.first});
        }
      }

      await logEvent('lobby_left', {'lobby_id': lobbyId, 'player': playerName});
    } catch (e) {
      print('❌ Lobiden ayrılma hatası: $e');
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

  // Lobi ayarlarını güncelle
  static Future<bool> updateLobbySettings(
    String lobbyId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final lobbyRef = firestore.collection('lobbies').doc(lobbyId);
      await lobbyRef.update({
        'game_settings': settings,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Ayar güncelleme hatası: $e');
      await recordError(e, StackTrace.current);
      return false;
    }
  }

  // Oyun bittikten sonra yeni lobi oluştur ve tüm oyuncuları aktar (sadece host)
  static Future<String?> createNewLobbyWithPlayers(
    String oldLobbyId,
    String currentPlayerName,
  ) async {
    try {
      print('🔄 Yeni lobi oluşturuluyor - eski oyuncularla...');

      // Eski lobinin verilerini al
      final oldLobbyRef = firestore.collection('lobbies').doc(oldLobbyId);
      final oldLobbyDoc = await oldLobbyRef.get();

      if (!oldLobbyDoc.exists) {
        print('❌ Eski lobi bulunamadı');
        return null;
      }

      final oldLobbyData = oldLobbyDoc.data()!;
      final List<String> players = List<String>.from(
        oldLobbyData['players'] ?? [],
      );
      final String host = oldLobbyData['host'] ?? '';
      final Map<String, dynamic> gameSettings = Map<String, dynamic>.from(
        oldLobbyData['gameSettings'] ?? {},
      );

      if (players.isEmpty || host.isEmpty) {
        print('❌ Oyuncu listesi veya host bilgisi eksik');
        return null;
      }

      // SADECE HOST YENİ LOBİ OLUŞTURABİLİR
      if (currentPlayerName != host) {
        print(
          '⚠️ Sadece host ($host) yeni lobi oluşturabilir. Current: $currentPlayerName',
        );

        // Host değilse, eski lobide new_lobby_id field'ini bekle
        int attempts = 0;
        while (attempts < 30) {
          // 15 saniye bekle
          await Future.delayed(const Duration(milliseconds: 500));
          final updatedDoc = await oldLobbyRef.get();
          if (updatedDoc.exists) {
            final data = updatedDoc.data()!;
            if (data['new_lobby_id'] != null) {
              print(
                '✅ Host tarafından oluşturulan yeni lobi bulundu: ${data['new_lobby_id']}',
              );
              return data['new_lobby_id'] as String;
            }
          }
          attempts++;
        }

        print('❌ Host yeni lobi oluşturmadı, timeout');
        return null;
      }

      // Host ise yeni lobi oluştur
      final newLobbyId = DateTime.now().millisecondsSinceEpoch.toString();
      final newLobbyRef = firestore.collection('lobbies').doc(newLobbyId);

      // Önce eski lobiye yeni lobi ID'sini yaz (diğer oyuncular için)
      await oldLobbyRef.update({
        'new_lobby_id': newLobbyId,
        'status': 'migrating',
      });

      // Sonra yeni lobiyi oluştur
      await newLobbyRef.set({
        'created_at': FieldValue.serverTimestamp(),
        'host': host,
        'players': players,
        'status': 'waiting',
        'max_players': oldLobbyData['max_players'] ?? 8,
        'gameSettings': gameSettings,
        'game_started': false,
        // Temiz başlangıç - oyun verileri yok
      });

      // Biraz bekle ki diğer oyuncular görebilsin
      await Future.delayed(const Duration(milliseconds: 1000));

      // Eski lobiyi sil
      await oldLobbyRef.delete();

      print('✅ Yeni lobi oluşturuldu: $newLobbyId');
      print('✅ ${players.length} oyuncu aktarıldı');

      return newLobbyId;
    } catch (e) {
      print('❌ Yeni lobi oluşturma hatası: $e');
      await recordError(e, StackTrace.current);
      return null;
    }
  }

  // Tüm oyuncular için yeni lobby isteği gönder
  static Future<void> requestNewLobbyForAllPlayers(String lobbyId) async {
    try {
      print('🔄 Tüm oyuncular için yeni lobby isteği gönderiliyor...');

      final lobbyRef = FirebaseFirestore.instance
          .collection('lobbies')
          .doc(lobbyId);

      await lobbyRef.update({
        'new_lobby_requested': true,
        'new_lobby_requested_at': FieldValue.serverTimestamp(),
      });

      print('✅ Yeni lobby isteği başarıyla gönderildi');
    } catch (e) {
      print('❌ Yeni lobby isteği gönderme hatası: $e');
      await recordError(e, StackTrace.current);
      rethrow;
    }
  }
}
