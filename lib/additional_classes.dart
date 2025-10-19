import 'package:flutter/material.dart';
import 'dart:math'; // Random için gerekli
import 'dart:async'; // Timer için gerekli
import 'package:provider/provider.dart'; // Provider paketi
import 'celebrities.dart';
import 'package:flutter/services.dart'; // Clipboard için gerekli
import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:share_plus/share_plus.dart'; // Share için gerekli
// Firebase ve AdMob sadece desteklenen platformlarda
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/admob_service.dart';
import 'services/firebase_service.dart';
import 'services/review_service.dart';
import 'services/vip_service.dart';

// Tema değişikliklerini yöneten Provider sınıfı
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark; // Varsayılan tema koyu

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners(); // Tema değiştiğinde dinleyicilere haber ver
  }
}

// Oyun Ayarlarını tutan sınıf
class GameSettings {
  int impostorCount;
  int gameDurationMinutes; // Dakika cinsinden
  int hintsCount; // İpucu sayısı
  List<String> selectedCategories;

  GameSettings({
    this.impostorCount = 1,
    this.gameDurationMinutes = 10,
    this.hintsCount = 4,
    this.selectedCategories = const [],
  });

  GameSettings copyWith({
    int? impostorCount,
    int? gameDurationMinutes,
    int? hintsCount,
    List<String>? selectedCategories,
  }) {
    return GameSettings(
      impostorCount: impostorCount ?? this.impostorCount,
      gameDurationMinutes: gameDurationMinutes ?? this.gameDurationMinutes,
      hintsCount: hintsCount ?? this.hintsCount,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }
}

// VIP Provider - Basitleştirildi (In-App Purchase kaldırıldı)
class VipProvider extends ChangeNotifier {
  bool _isVip = false;
  bool get isVip => _isVip;

  void setVip(bool value) {
    _isVip = value;
    notifyListeners();
  }
}

class KimHainApp extends StatelessWidget {
  const KimHainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VipProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Hain Kim?',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              fontFamily: 'Arial',
              brightness: Brightness.light,
              cardColor: Colors.white,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                centerTitle: true,
                elevation: 1,
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
              ),
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
                titleLarge: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
                bodyMedium: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontFamily: 'Arial',
                ),
                labelLarge: TextStyle(
                  color: Colors.black87,
                  fontFamily: 'Arial',
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF19B4FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00CFFF),
                  textStyle: const TextStyle(fontSize: 16, fontFamily: 'Arial'),
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[200],
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                labelStyle: TextStyle(
                  color: Colors.grey[700],
                  fontFamily: 'Arial',
                ),
              ),
            ),
            darkTheme: ThemeData(
              fontFamily: 'Arial',
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF19B4FF),
              secondaryHeaderColor: const Color(0xFF63D6FF),
              cardColor: const Color(0xFF151C28),
              scaffoldBackgroundColor: const Color(0xFF070C15),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
              ),
              textTheme: const TextTheme(
                displayLarge: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
                titleLarge: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
                bodyMedium: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'Arial',
                ),
                labelLarge: TextStyle(color: Colors.white, fontFamily: 'Arial'),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF19B4FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00CFFF),
                  textStyle: const TextStyle(fontSize: 16, fontFamily: 'Arial'),
                ),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF151C28),
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
              ),
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFF1F2837),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide.none,
                ),
                labelStyle: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Arial',
                ),
              ),
            ),
            home: const KimHainHome(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// Ana Sayfa (Home)
class KimHainHome extends StatefulWidget {
  const KimHainHome({super.key});

  @override
  State<KimHainHome> createState() => _KimHainHomeState();
}

class _KimHainHomeState extends State<KimHainHome>
    with SingleTickerProviderStateMixin {
  final TextEditingController _lobbyCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  String? _currentLobbyCode;
  String? _lobbyCreator; // Lobi kurucusu
  bool _isNavigatingToGame = false; // Çift navigation önleme
  bool _isStartingGame = false; // Çift oyun başlatma önleme
  final List<String> _playersInLobby = [];
  GameSettings _currentGameSettings = GameSettings();

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  // Drawer için
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // AdMob entegrasyonu
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  // Firebase entegrasyonu
  StreamSubscription<DocumentSnapshot>? _lobbySubscription;

  // Processing flag for preventing double taps
  bool _isJoiningLobby = false;

  @override
  void initState() {
    super.initState();

    // Flag'leri reset et (oyun ekranından dönüldükten sonra)
    _isNavigatingToGame = false;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _offsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -0.05),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // İnternet bağlantı kontrolü
    _checkInitialConnection();

    // Web'de AdMob çalışmaz, sadece mobile'da yükle
    if (!kIsWeb) {
      _loadBannerAd();
      // VIP abonelik servisini başlat
      VipSubscriptionService.initialize();
    }
  }

  // İlk internet kontrolü
  Future<void> _checkInitialConnection() async {
    final hasConnection = await FirebaseService.checkInternetConnection();
    if (!hasConnection && mounted) {
      _showConnectionError();
    }
  }

  // Bağlantı hatası gösterimi
  void _showConnectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ İnternet bağlantısı gerekli! Bu oyun sadece online çalışır.',
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Banner Ad yükleme fonksiyonu
  void _loadBannerAd() {
    // Mobile platformlarda AdMob çalıştır (iOS ve Android)
    if (!kIsWeb) {
      _bannerAd = BannerAd(
        adUnitId: AdMobService.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              _isBannerAdReady = true;
            });
          },
          onAdFailedToLoad: (ad, err) {
            print('Failed to load a banner ad: ${err.message}');
            _isBannerAdReady = false;
            ad.dispose();
          },
        ),
      );

      _bannerAd!.load();
    }
  }

  @override
  void dispose() {
    _lobbyCodeController.dispose();
    _playerNameController.dispose();
    _animationController.dispose();
    _bannerAd?.dispose();
    _lobbySubscription?.cancel();
    super.dispose();
  }

  void _createLobby() async {
    if (_playerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce bir oyuncu adı girin.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // Interstitial reklam göster (iOS ve Android'de)
    if (!kIsWeb) {
      AdMobService.showInterstitialAd();
    }

    try {
      // Firebase'de online lobi oluştur
      final createdLobbyCode = await FirebaseService.createLobby(
        _playerNameController.text.trim(),
      );

      if (createdLobbyCode != null) {
        // Lobi dinlemeye başla
        _startListeningToLobby(createdLobbyCode);

        setState(() {
          _currentLobbyCode = createdLobbyCode;
          _lobbyCreator = _playerNameController.text.trim(); // Creator'ı ayarla
          _playersInLobby.clear();
          _playersInLobby.add(_playerNameController.text.trim());
        });
        _animationController.forward();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Online lobi oluşturuldu: $createdLobbyCode'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ İnternet bağlantısı gerekli! Lütfen internet bağlantınızı kontrol edin.',
              ),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Bağlantı hatası: İnternet gerekli'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Firebase lobi dinleme
  void _startListeningToLobby(String lobbyCode) {
    _lobbySubscription?.cancel();
    _lobbySubscription = FirebaseService.listenToLobby(lobbyCode).listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final players = List<String>.from(data['players'] ?? []);
          final host = data['host'] as String?; // creator yerine host kullan
          final gameSettings = data['game_settings'] as Map<String, dynamic>?;

          if (mounted) {
            setState(() {
              _playersInLobby.clear();
              _playersInLobby.addAll(players);
              _lobbyCreator =
                  host; // Host bilgisini güncelle (dinamik transfer için)

              // Ayarları senkronize et
              if (gameSettings != null) {
                _currentGameSettings = GameSettings(
                  gameDurationMinutes:
                      (gameSettings['duration'] as int? ?? 600) ~/ 60,
                  hintsCount: gameSettings['hints_count'] as int? ?? 4,
                  impostorCount: gameSettings['impostor_count'] as int? ?? 1,
                  selectedCategories: List<String>.from(
                    gameSettings['selected_categories'] ?? [],
                  ),
                );
              }
            });

            // Oyun başlatma sinyalini kontrol et
            if (data['game_started'] == true && data['status'] == 'playing') {
              // Sadece aktif lobide olan oyuncular için oyun başlat
              final playerName = _playerNameController.text.trim();
              if (_currentLobbyCode != null &&
                  _playersInLobby.contains(playerName)) {
                // Çift navigasyon önleme kontrolü
                if (!_isNavigatingToGame) {
                  _isNavigatingToGame = true;

                  // Lobi dinlemeyi durdur
                  _lobbySubscription?.cancel();

                  Navigator.push(
                    context,
                    MaterialPageRoute<String>(
                      builder: (BuildContext context) => GameScreen(
                        players: _playersInLobby,
                        gameSettings: _currentGameSettings,
                        impostors: data['impostors'] != null
                            ? List<String>.from(data['impostors'])
                            : (data['impostor'] != null
                                  ? [data['impostor'] as String]
                                  : []),
                        celebrities: data['celebrity'] != null
                            ? [data['celebrity'] as String]
                            : [],
                        lobbyId:
                            _currentLobbyCode, // Current lobby code'u kullan
                        playerRoles: data['player_roles'] != null
                            ? Map<String, String>.from(data['player_roles'])
                            : null,
                        currentPlayerName: _playerNameController.text.trim(),
                      ),
                    ),
                  ).then((newLobbyId) {
                    // Oyun bittikten sonra flag'i sıfırla
                    _isNavigatingToGame = false;

                    // Eğer yeni lobi ID'si dönmüşse, o lobiye geç
                    if (newLobbyId != null && newLobbyId.isNotEmpty) {
                      print('🔄 Yeni lobiye geçiliyor: $newLobbyId');
                      _currentLobbyCode = newLobbyId;
                      _lobbySubscription?.cancel(); // Eski dinleyiciyi durdur
                      _startListeningToLobby(
                        newLobbyId,
                      ); // Yeni lobiyi dinlemeye başla
                    } else {
                      // Normal dönüş - aynı lobiyi dinlemeye devam et
                      if (_currentLobbyCode != null) {
                        _startListeningToLobby(_currentLobbyCode!);
                      }
                    }
                  });
                }
              }
            }
          }
        }
      },
      onError: (error) {
        print('Lobi dinleme hatası: $error');
      },
    );
  }

  void _joinLobby() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Lobiye Katıl',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Önce Lobi Kodu
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1F1F1F)
                          : const Color(0xFFF8F9FA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF28B463).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _lobbyCodeController,
                  autofocus: true, // İlk açıldığında focus burada olsun
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    labelText: '� Oda Kodu',
                    labelStyle: TextStyle(
                      color: const Color(0xFF28B463),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Lobinin kodunu girin',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF28B463),
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 16),
              // Sonra Oyuncu Adı
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1F1F1F)
                          : const Color(0xFFF8F9FA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19B4FF).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _playerNameController,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: '� Oyuncu Adı',
                    labelStyle: TextStyle(
                      color: const Color(0xFF19B4FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    hintText: 'Adınızı girin',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF19B4FF),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textButtonTheme.style?.foregroundColor?.resolve({}) ??
                      Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_playerNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen önce bir oyuncu adı girin.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }
                if (_lobbyCodeController.text.isNotEmpty) {
                  try {
                    if (_isJoiningLobby) return; // Double tap koruması
                    _isJoiningLobby = true;

                    // Loading göster
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lobiye katılınıyor...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }

                    // Firebase'de lobiye katıl
                    final joinResult = await FirebaseService.joinLobby(
                      _lobbyCodeController.text,
                      _playerNameController.text.trim(),
                    );

                    if (!mounted) return; // Widget dispose edilmiş kontrolü

                    if (joinResult) {
                      // Başarılı katılım
                      try {
                        // Lobi dinlemeye başla
                        _startListeningToLobby(_lobbyCodeController.text);

                        if (mounted) {
                          setState(() {
                            _currentLobbyCode = _lobbyCodeController.text;
                            _playersInLobby.clear();
                            _playersInLobby.add(
                              _playerNameController.text.trim(),
                            );
                          });
                        }

                        if (mounted) {
                          Navigator.of(context).pop();
                          _animationController.forward();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ Lobi ${_lobbyCodeController.text} odasına katıldın.',
                              ),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _lobbyCodeController.clear();
                        }
                      } catch (e) {
                        print('UI güncelleme hatası: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '⚠️ Lobiye katıldınız ama UI hatası: ${e.toString()}',
                              ),
                              duration: Duration(seconds: 1),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } else {
                      // Katılım başarısız
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '❌ Lobiye katılınamadı! Lobi kodu kontrol edin.',
                            ),
                            duration: Duration(seconds: 1),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('Lobiye katılma hatası: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Bağlantı hatası: ${e.toString()}'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    _isJoiningLobby = false; // Flag'i reset et
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen bir oda kodu girin.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text('Katıl'),
            ),
          ],
        );
      },
    );
  }

  void _startGameFromLobby() async {
    if (_isStartingGame) {
      print('⚠️ Oyun zaten başlatılıyor, buton göz ardı ediliyor');
      return;
    }

    print('🚀 _startGameFromLobby çağrıldı - isStarting: $_isStartingGame');
    _isStartingGame = true;

    if (_playersInLobby.isEmpty) {
      // SCREENSHOT: 1 oyuncuyla test
      _isStartingGame = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oyunu başlatmak için en az 1 oyuncu olmalı.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    if (_currentLobbyCode != null) {
      // Firebase'e oyun başlatma sinyali gönder (tüm oyuncular için senkronize)
      final gameStarted = await FirebaseService.startGame(_currentLobbyCode!);
      if (!gameStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oyun başlatılamadı. Tekrar deneyin.'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      _isStartingGame = false;
      // Lobi dinleyicisi otomatik olarak tüm oyuncuları oyuna yönlendirecek
    } else {
      // Lobi yoksa normal oyun başlat
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => GameScreen(
            players: _playersInLobby,
            gameSettings: _currentGameSettings,
            impostors: const [], // Local oyunda impostor bilgisi yok
            celebrities: const [], // Local oyunda celebrity bilgisi yok
            currentPlayerName: _playerNameController.text
                .trim(), // Local oyunda da current player
          ),
        ),
      );
    }
  }

  void _openGameSettings() async {
    final updatedSettings = await Navigator.push<GameSettings>(
      context,
      MaterialPageRoute<GameSettings>(
        builder: (BuildContext context) =>
            GameSettingsScreen(initialSettings: _currentGameSettings),
      ),
    );

    if (updatedSettings != null) {
      setState(() {
        _currentGameSettings = updatedSettings;
      });

      // Firebase'e ayarları senkronize et
      if (_currentLobbyCode != null) {
        final success = await FirebaseService.updateLobbySettings(
          _currentLobbyCode!,
          {
            'duration':
                updatedSettings.gameDurationMinutes * 60, // Saniyeye çevir
            'hints_count': updatedSettings.hintsCount,
            'impostor_count': updatedSettings.impostorCount,
            'selected_categories': updatedSettings.selectedCategories,
          },
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oyun ayarları tüm oyuncular için güncellendi.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oyun ayarları güncellendi.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }

  // View-only oyun ayarları
  void _viewGameSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            GameSettingsScreen(initialSettings: _currentGameSettings),
      ),
    );
  }

  // Oda kodunu paylaş
  void _shareRoomCode(String roomCode) async {
    try {
      final shareText =
          '🎮 HAİN KİM? Oyununa katıl!\n\n'
          '📱 Oda Kodu: $roomCode\n\n'
          '🔗 Bu kodu kopyalayıp oyunda "Lobiye Katıl" butonuna bas!\n'
          '👥 Arkadaşlarınla birlikte oyna ve hainleri bul!';

      // Gerçek paylaşım özelliği
      await Share.share(shareText, subject: 'HAİN KİM? Oyun Davetiyesi');
    } catch (e) {
      // Paylaşım başarısız olursa clipboard'a kopyala
      try {
        Clipboard.setData(
          ClipboardData(
            text:
                '🎮 HAİN KİM? Oyununa katıl!\n\n'
                '📱 Oda Kodu: $roomCode\n\n'
                '🔗 Bu kodu kopyalayıp oyunda "Lobiye Katıl" butonuna bas!\n'
                '👥 Arkadaşlarınla birlikte oyna ve hainleri bul!',
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '� Paylaşım metni kopyalandı!\n'
              'WhatsApp, Telegram vb. uygulamalarda paylaşabilirsin',
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } catch (clipboardError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paylaşım sırasında hata oluştu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Ayarlar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              // VIP Üyelik Bölümü
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF19B4FF), Color(0xFF63D6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.star, color: Colors.white),
                  title: Text(
                    VipSubscriptionService.isVipActive ? 'VIP Aktif' : 'VIP Ol',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    VipSubscriptionService.isVipActive 
                        ? 'Premium özellikler aktif' 
                        : 'Reklamları kaldır - \$1.99/ay',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: VipSubscriptionService.isVipActive 
                      ? const Icon(Icons.check_circle, color: Colors.white)
                      : const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    Navigator.pop(context);
                    if (!VipSubscriptionService.isVipActive) {
                      _showVipDialog(context);
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Hain Kim?',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        '© 2025 BelDiaDigital\n\nBu uygulama, eğlence amaçlı geliştirilmiştir.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Tema Değiştir'),
                onTap: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const SizedBox.shrink(),
        leading: IconButton(
          icon: Icon(
            Icons.settings,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black87
                : Colors.white70,
          ),
          tooltip: 'Ayarlar',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          if (_currentLobbyCode != null)
            IconButton(
              icon: Icon(
                Icons.home,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white70,
              ),
              tooltip: 'Girişe Dön',
              onPressed: () {
                setState(() {
                  _currentLobbyCode = null;
                  _playersInLobby.clear();
                });
              },
            ),
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black87
                  : Colors.white70,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 24.0,
        ), // 28->20, 40->24 azalttık
        child: AnimatedBuilder(
          animation: _offsetAnimation,
          builder: (context, child) {
            List<Widget> children = [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ChatGPT Image
                  SizedBox(
                    width: 140,
                    height: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/ChatGPT Image Sep 11, 2025, 12_13_28 AM.png',
                        width: 140,
                        height: 160,
                        fit: BoxFit
                            .contain, // Resmin orijinal oranını koru, arka plan şeffaf olsun
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 140,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF2D4A6B), Color(0xFF1A2332)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              '🕵️‍♂️',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Başlık - HAİN KİM? (görseldeki gibi)
                  RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "HAİN\n",
                          style: TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF19B4FF),
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: "KİM",
                          style: TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.w900,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Color(0xFF151C28)
                                : Colors.white,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // 25'ten 16'ya azalttık
              // Oyunu başlat butonu - lobby'deyken tüm oyunculara görünür, creator olmayanlara soluk
              if (_currentLobbyCode != null)
                _CustomLedButton(
                  text: 'OYUNU BAŞLAT',
                  gradientColors:
                      (_lobbyCreator != null &&
                          _lobbyCreator == _playerNameController.text.trim())
                      ? const [Color(0xFF19B4FF), Color(0xFF63D6FF)]
                      : [
                          const Color(0xFF19B4FF).withValues(alpha: 0.4),
                          const Color(0xFF63D6FF).withValues(alpha: 0.4),
                        ],
                  shadowColor:
                      (_lobbyCreator != null &&
                          _lobbyCreator == _playerNameController.text.trim())
                      ? const Color(0xFF19B4FF)
                      : const Color(0xFF19B4FF).withValues(alpha: 0.3),
                  fontSize: 24,
                  height: 60,
                  borderRadius: 18,
                  onTap: () {
                    print('🎯 Oyun Başlat butonuna basıldı');
                    if (_lobbyCreator != null &&
                        _lobbyCreator == _playerNameController.text.trim()) {
                      if (_currentLobbyCode != null &&
                          _playersInLobby.isNotEmpty) {
                        print('✅ Oyun başlatma koşulları sağlandı');
                        _startGameFromLobby();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lobi oluşturmadan oyun başlatılamaz!',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '👑 Sadece lobi kurucusu oyunu başlatabilir',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              const SizedBox(
                height: 14,
              ), // Oyunu başlat ve lobi butonları arası
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _CustomLedButton(
                      text: 'LOBİ OLUŞTUR',
                      gradientColors: const [
                        Color(0xFF28B463),
                        Color(0xFF58E093),
                      ],
                      shadowColor: const Color(0xFF28B463),
                      fontSize: 18,
                      height: 54,
                      borderRadius: 14,
                      onTap: _createLobby,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _joinLobby,
                            child: Center(
                              child: Text(
                                'LOBİ KATIL',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (_currentLobbyCode == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1F1F1F)
                              : const Color(0xFFF8F9FA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black.withValues(alpha: 0.3)
                              : const Color(0xFF19B4FF).withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _playerNameController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        labelText: '🎮 Oyuncu Adı',
                        hintText: 'Oyuncu adınızı giriniz...',
                        labelStyle: TextStyle(
                          color: const Color(0xFF19B4FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[500],
                          fontSize: 14,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF19B4FF),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ];

            // Lobi durumu ekranı
            if (_currentLobbyCode != null) {
              children.add(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 0,
                      ),
                      color: Theme.of(context).cardTheme.color,
                      shape: Theme.of(context).cardTheme.shape,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Oda Kodu: $_currentLobbyCode',
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Kopyala ve Paylaş butonları yan yana
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Kodu Kopyala',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: _currentLobbyCode!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '📋 Oda kodu kopyalandı!',
                                        ),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  tooltip: 'Kodu Paylaş',
                                  onPressed: () {
                                    _shareRoomCode(_currentLobbyCode!);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Katılan Oyuncular:',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 220,
                        minHeight: 40,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).cardTheme.color?.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _playersInLobby.length,
                        itemBuilder: (BuildContext context, int index) {
                          final isCreator =
                              _playersInLobby[index] == _lobbyCreator;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF19B4FF),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _playersInLobby[index],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 16),
                                  ),
                                ),
                                if (isCreator)
                                  const Text(
                                    '👑',
                                    style: TextStyle(fontSize: 20),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ), // Oyuncu listesi ve ayarlar arası
                    // Oyun ayarları butonu - tüm oyunculara görünür, creator olmayanlara soluk
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors:
                              (_lobbyCreator != null &&
                                  _lobbyCreator ==
                                      _playerNameController.text.trim())
                              ? [
                                  const Color(0xFF28C76F),
                                  const Color(0xFF00A86B),
                                ]
                              : [
                                  const Color(0xFF28C76F).withValues(alpha: 0.4),
                                  const Color(0xFF00A86B).withValues(alpha: 0.4),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF28C76F).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            (_lobbyCreator != null &&
                                _lobbyCreator ==
                                    _playerNameController.text.trim())
                            ? _openGameSettings // Creator için düzenleme
                            : _viewGameSettings, // Diğerleri için sadece görüntüleme
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings_applications_rounded,
                              color:
                                  (_lobbyCreator != null &&
                                      _lobbyCreator ==
                                          _playerNameController.text.trim())
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Oyun Ayarları',
                              style: TextStyle(
                                color:
                                    (_lobbyCreator != null &&
                                        _lobbyCreator ==
                                            _playerNameController.text.trim())
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF4757),
                            const Color(0xFFFF3742),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4757).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentLobbyCode != null) {
                            // Navigation flag'ini ayarla
                            _isNavigatingToGame = false;

                            // Firebase'den lobiden ayrıl
                            await FirebaseService.leaveLobby(
                              _currentLobbyCode!,
                              _playerNameController.text.trim(),
                            );

                            // Lobi dinlemeyi durdur
                            _lobbySubscription?.cancel();

                            // UI'yi güncelle
                            setState(() {
                              _currentLobbyCode = null;
                              _lobbyCreator = null;
                              _playersInLobby.clear();
                            });

                            // Animasyonu geri al
                            _animationController.reverse();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lobiden ayrıldınız.'),
                                duration: Duration(seconds: 1),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.exit_to_app_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Lobiden Ayrıl',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SlideTransition(
              position: _offsetAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: children,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar:
          (!kIsWeb && _isBannerAdReady && !VipSubscriptionService.isVipActive)
          ? Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  // VIP Dialog ve metodları
  void _showVipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                'VIP Üyelik',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 VIP Özellikler:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildVipFeature('🚫 Tüm reklamları kaldır'),
              const SizedBox(height: 20),
              _buildSubscriptionCard(
                'VIP Üyelik',
                '\$1.99',
                '/ay',
                () => _purchaseSubscription('monthly'),
                isPopular: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVipFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(String title, String price, String period, VoidCallback onTap, {bool isPopular = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isPopular
              ? const LinearGradient(
                  colors: [Color(0xFF19B4FF), Color(0xFF63D6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPopular ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(12),
          border: isPopular ? null : Border.all(color: const Color(0xFF19B4FF), width: 1),
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EN POPÜLER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPopular ? Colors.white : Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isPopular ? Colors.white : const Color(0xFF19B4FF),
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontSize: 12,
                color: isPopular ? Colors.white70 : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseSubscription(String type) async {
    try {
      bool success;
      if (type == 'monthly') {
        success = await VipSubscriptionService.purchaseMonthly();
      } else {
        // Yıllık abonelik şu anda desteklenmiyor
        throw Exception('Yıllık abonelik henüz mevcut değil');
      }
      
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 VIP abonelik başlatıldı!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // VIP durumunu güncelle
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Satın alma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class GameScreen extends StatefulWidget {
  final List<String> players;
  final GameSettings? gameSettings; // Oyun ayarlarını da alacak
  final List<String> impostors; // Hain oyuncular listesi
  final List<String> celebrities; // Seçilen ünlüler listesi
  final String? lobbyId; // Multiplayer lobby ID'si
  final Map<String, String>? playerRoles; // Her oyuncunun rolü
  final String? currentPlayerName; // Mevcut oyuncunun adı

  const GameScreen({
    super.key,
    required this.players,
    this.gameSettings,
    this.impostors = const [],
    this.celebrities = const [],
    this.lobbyId,
    this.playerRoles,
    this.currentPlayerName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  String? _assignedCelebrity;
  String? _impostorName;
  late List<Map<String, dynamic>> _celebritiesList;
  late int _countdownSeconds;
  late bool _gameEnded;
  Timer? _gameTimer;

  String? celebrityImageUrl; // Artık asset veya null olacak
  bool get _isCelebrityImageUrlNetwork =>
      celebrityImageUrl != null &&
      (celebrityImageUrl!.startsWith('http://') ||
          celebrityImageUrl!.startsWith('https://'));

  // Animasyon için Controller
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Hain ismini al (oyun bittiğinde herkes görebilir)
  String? _getImpostorNameForDisplay() {
    if (!_gameEnded) {
      // Oyun devam ediyorsa sadece hainler kendi ismini görebilir
      return _impostorName;
    }

    // Oyun bittiyse herkes hain ismini görebilir
    if (widget.playerRoles != null) {
      // Multiplayer: playerRoles'dan hain olanları bul
      for (final entry in widget.playerRoles!.entries) {
        if (entry.value == 'impostor') {
          return entry.key; // İlk hain ismini döndür
        }
      }
    } else if (widget.impostors.isNotEmpty) {
      // Eski sistem: impostors listesinden ilk ismi al
      return widget.impostors.first;
    } else if (_impostorName != null) {
      // Local oyun: belirlenen hain ismini göster
      return _impostorName;
    }

    return 'N/A';
  }

  @override
  void initState() {
    super.initState();

    // Oyun bittikten sonra kullanmak için interstitial reklamı yükle
    AdMobService.loadInterstitialAd();

    // Kategori filtrelemesi
    if (widget.gameSettings?.selectedCategories != null &&
        widget.gameSettings!.selectedCategories.isNotEmpty) {
      // Seçilen kategorilerden ünlüleri filtrele
      _celebritiesList = celebrities.where((celeb) {
        final category = celeb['category'] as String? ?? 'Diğer';
        return widget.gameSettings!.selectedCategories.contains(category);
      }).toList();
    } else {
      // Hiç kategori seçilmemişse tüm ünlüleri dahil et
      _celebritiesList = List<Map<String, dynamic>>.from(celebrities);
    }

    _countdownSeconds = (widget.gameSettings?.gameDurationMinutes ?? 10) * 60;
    _assignRoles();
    _gameEnded = false;
    _startCountdown();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    // Multiplayer oyunsa game_ended listener'ı ekle
    if (widget.lobbyId != null) {
      _startGameEndListener();
    }
  }

  // Oyun bitirme listener'ı
  void _startGameEndListener() {
    if (widget.lobbyId == null) return;

    FirebaseService.listenToLobby(widget.lobbyId!).listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Oyun bitti mi kontrol et
        if (data['game_ended'] == true && mounted) {
          _gameTimer?.cancel(); // Zamanlayıcıyı durdur
          _animationController.stop(); // Animasyonu durdur

          if (!_gameEnded) {
            setState(() {
              _gameEnded = true; // Oyunun bittiğini işaretle
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _assignRoles() {
    // Firebase'den gelen bilgileri kullan, yoksa rastgele seç
    if (widget.celebrities.isNotEmpty) {
      _assignedCelebrity = widget.celebrities.first;
    } else {
      final Random random = Random();
      final celebCount = _celebritiesList.length;
      _assignedCelebrity = _celebritiesList[random.nextInt(celebCount)]['name'];
    }

    // Rol assignment - multiplayer için playerRoles kullan
    if (widget.playerRoles != null && widget.currentPlayerName != null) {
      // Multiplayer: Firebase'den gelen rol bilgisini kullan
      final currentPlayerRole = widget.playerRoles![widget.currentPlayerName!];
      _impostorName = (currentPlayerRole == 'impostor')
          ? widget.currentPlayerName
          : null;
    } else if (widget.impostors.isNotEmpty) {
      // Eski sistem: impostors listesi kullan
      _impostorName = widget.impostors.contains(widget.currentPlayerName)
          ? widget.currentPlayerName
          : null;
    } else if (widget.players.isNotEmpty) {
      // Local oyun: rastgele impostor seç
      final Random random = Random();
      _impostorName = widget.players[random.nextInt(widget.players.length)];
    } else {
      _impostorName = null;
    }
  }

  void _startCountdown() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
          // Son 10 saniyede animasyonu başlat
          if (_countdownSeconds <= 10) {
            if (!_animationController.isAnimating) {
              _animationController.forward();
            }
          } else {
            // Animasyon devam ediyorsa durdur ve sıfırla
            if (_animationController.isAnimating) {
              _animationController.reset();
            }
          }
        } else {
          _gameEnded = true;
          _gameTimer?.cancel();
          _animationController.stop(); // Süre bitince animasyonu durdur
        }
      });
    });
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds <= 0) return "Süre Bitti!";
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimeColor(int totalSeconds) {
    // Mevcut oyuncunun hain olup olmadığını kontrol et
    bool isCurrentPlayerImpostor = false;

    if (widget.playerRoles != null && widget.currentPlayerName != null) {
      // Multiplayer: PlayerRoles'dan kontrol et
      isCurrentPlayerImpostor =
          widget.playerRoles![widget.currentPlayerName!] == 'impostor';
    } else if (_impostorName != null && widget.currentPlayerName != null) {
      // Local/eski sistem: impostorName ile karşılaştır
      isCurrentPlayerImpostor = (_impostorName == widget.currentPlayerName);
    }

    // Hain oyuncular için her zaman kırmızı
    if (isCurrentPlayerImpostor) {
      return Colors.redAccent;
    }

    // Masum oyuncular için mavi renk sistemi
    if (totalSeconds <= 10) {
      return Colors.redAccent; // Son 10 saniye kırmızı
    } else if (totalSeconds <= 60) {
      return Colors.orangeAccent; // Son 1 dakika turuncu
    }
    return const Color(0xFF19B4FF); // Varsayılan mavi
  }

  void _endGameEarly() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Oyunu Bitir',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Oyunu erken bitirmek istediğinizden emin misiniz?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Diyalogu kapat
              },
              child: Text(
                'İptal',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textButtonTheme.style?.foregroundColor?.resolve({}) ??
                      Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Diyalogu kapat

                // Multiplayer ise Firebase'e oyun bitirme sinyali gönder
                if (widget.lobbyId != null) {
                  await FirebaseService.endGame(
                    widget.lobbyId!,
                    widget.players.first,
                  );
                }

                _gameTimer?.cancel(); // Zamanlayıcıyı durdur
                _animationController.stop(); // Animasyonu durdur
                setState(() {
                  _gameEnded = true; // Oyunun bittiğini işaretle
                });
              },
              child: const Text('Evet, Bitir'),
            ),
          ],
        );
      },
    ); // showDialog'un kapanışı
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Mevcut oyuncunun hain olup olmadığını kontrol et
    bool isCurrentPlayerImpostor = false;

    if (widget.playerRoles != null && widget.currentPlayerName != null) {
      // Multiplayer: PlayerRoles'dan kontrol et
      isCurrentPlayerImpostor =
          widget.playerRoles![widget.currentPlayerName!] == 'impostor';
    } else if (_impostorName != null && widget.currentPlayerName != null) {
      // Local/eski sistem: impostorName ile karşılaştır
      isCurrentPlayerImpostor = (_impostorName == widget.currentPlayerName);
    }

    // Hain için sadece "HAİN" yazsın, masum için ünlü adı
    final String displayText = isCurrentPlayerImpostor
        ? 'HAİN'
        : (_assignedCelebrity ?? 'Bilinmiyor');

    // İpuçları için masumların ünlüsünün ipuçlarını al
    final celeb = _celebritiesList.firstWhere(
      (c) => c['name'] == _assignedCelebrity,
      orElse: () => {
        'name': _assignedCelebrity,
        'hints': ["", "", "", ""],
      },
    );
    final List<String> allHints = List<String>.from(
      celeb['hints'] ?? ["", "", "", ""],
    );
    final int hintsToShowCount = widget.gameSettings?.hintsCount ?? 4;
    final List<String> hintsToShow = allHints.take(hintsToShowCount).toList();

    // Eğer yeterli ipucu yoksa boş string ekle
    while (hintsToShow.length < hintsToShowCount) {
      hintsToShow.add('');
    }

    return PopScope(
      canPop: false, // Swipe back gestures'ı devre dışı bırak
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Eğer pop işlemi gerçekleşirse oyunu bitirme fonksiyonunu çağır
        if (!didPop) {
          _endGameEarly();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const SizedBox.shrink(),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).appBarTheme.foregroundColor,
              size: 28,
            ),
            onPressed: _endGameEarly,
          ),
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ],
        ),
        body: Center(
          child: _gameEnded
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Oyun Bitti!',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.redAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Ortak Ünlü: ${_assignedCelebrity ?? 'N/A'}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hain: ${_getImpostorNameForDisplay() ?? 'N/A'}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 50),
                    // Modern buton tasarımı
                    if (widget.lobbyId != null) ...[
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF19B4FF), Color(0xFF63D6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF19B4FF).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            print('🔄 Lobiye dönüş başlatılıyor...');

                            // Oyun tamamlandı - review service'e bildir
                            await ReviewService.onGameCompleted();

                            // VIP değilse interstitial reklam göster
                            if (!VipSubscriptionService.isVipActive) {
                              AdMobService.showInterstitialAd();
                            }

                            // Yeni lobi oluştur ve oyuncuları aktar
                            if (widget.lobbyId != null &&
                                widget.currentPlayerName != null) {
                              final newLobbyId =
                                  await FirebaseService.createNewLobbyWithPlayers(
                                    widget.lobbyId!,
                                    widget.currentPlayerName!,
                                  );

                              if (newLobbyId != null) {
                                print(
                                  '✅ Yeni lobiye aktarım başarılı: $newLobbyId',
                                );
                                // Ana ekrana dön ve yeni lobby kodu ile lobi oluştur
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KimHainHome(),
                                  ),
                                  (Route<dynamic> route) =>
                                      false, // Tüm stack'i temizle
                                );

                                // Kısa bir gecikme sonra yeni lobiye git
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (mounted) {
                                      // Burada yeni lobby ile lobiye katılma işlemi yapılacak
                                      // Şimdilik ana ekrana dönüyor, kullanıcı kodu girip katılabilir
                                    }
                                  },
                                );
                              } else {
                                print('❌ Yeni lobi oluşturulamadı');
                                // Ana ekrana dön
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KimHainHome(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            '🔄 Yeni Oyuna Hazırlan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(
                            context,
                            (Route<dynamic> route) => route.isFirst,
                          );
                        },
                        child: const Text('Yeni Oyun Başlat'),
                      ),
                    ],
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxImageSize = constraints.maxWidth < 400
                        ? 110
                        : 140;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Ünlü görseli veya hain ikonu (büyütülmüş)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCurrentPlayerImpostor
                                    ? [
                                        Colors.red,
                                        Colors.redAccent,
                                      ] // Hain için kırmızı
                                    : [
                                        const Color(0xFF19B4FF),
                                        const Color(0xFF63D6FF),
                                      ], // Masum için mavi
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: [
                                BoxShadow(
                                  offset: Offset(0, 8),
                                  color:
                                      (isCurrentPlayerImpostor
                                              ? Colors.red
                                              : const Color(0xFF19B4FF))
                                          .withValues(alpha: 0.13),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: isCurrentPlayerImpostor
                                  ? Icon(
                                      Icons.person_off, // Hain için özel ikon
                                      size: maxImageSize + 60,
                                      color: Colors.red,
                                    )
                                  : celebrityImageUrl != null
                                  ? (_isCelebrityImageUrlNetwork
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            child: Image.network(
                                              celebrityImageUrl ?? '',
                                              width: maxImageSize + 60,
                                              height: maxImageSize + 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.person,
                                                    size: maxImageSize + 60,
                                                    color: const Color(
                                                      0xFF19B4FF,
                                                    ),
                                                  ),
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            child: Image.asset(
                                              celebrityImageUrl ??
                                                  'assets/images/detective_logo.png',
                                              width: maxImageSize + 60,
                                              height: maxImageSize + 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.person,
                                                    size: maxImageSize + 60,
                                                    color: const Color(
                                                      0xFF19B4FF,
                                                    ),
                                                  ),
                                            ),
                                          ))
                                  : Icon(
                                      Icons.person, // Masum için mavi ikon
                                      size: maxImageSize + 60,
                                      color: const Color(0xFF19B4FF),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Ünlü adı veya HAİN yazısı (büyük)
                          Text(
                            displayText,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: isCurrentPlayerImpostor
                                      ? Colors.redAccent
                                      : null,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // "Masum" yazısı sadece masumlar için (büyük)
                          if (!isCurrentPlayerImpostor)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                bottom: 12,
                              ),
                              child: Text(
                                'MASUM',
                                style: TextStyle(
                                  color: const Color(0xFF19B4FF), // Masum mavi
                                  fontWeight: FontWeight.w900,
                                  fontSize: 32,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 10),
                          // İpuçları grid
                          SizedBox(
                            width: double.infinity,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: hintsToShow.length <= 2
                                        ? hintsToShow.length
                                        : 2,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    childAspectRatio: hintsToShow.length <= 2
                                        ? 6.0
                                        : 3.2,
                                  ),
                              itemCount: hintsToShow.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).cardTheme.color?.withValues(alpha: 0.93),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrentPlayerImpostor
                                          ? Colors.red.withOpacity(
                                              0.5,
                                            ) // Hain için kırmızı çerçeve
                                          : const Color(0xFF19B4FF).withOpacity(
                                              0.5,
                                            ), // Masum için mavi çerçeve
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    hintsToShow[index],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Kalan süre
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _countdownSeconds <= 10
                                    ? _scaleAnimation.value
                                    : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _getTimeColor(_countdownSeconds),
                                      width: 2.2,
                                    ),
                                  ),
                                  child: Text(
                                    _formatTime(_countdownSeconds),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: _getTimeColor(
                                            _countdownSeconds,
                                          ),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          // Bilgilendirici metin
                          if (isCurrentPlayerImpostor)
                            Text(
                              'Yukarıdaki ipuçları masumların ünlüsü için!\nOnları kandır!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            Text(
                              'Bu sizin ünlünüz ve ipuçlarınız!\nHaini bulun!',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF19B4FF),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// Özel LED Efektli Buton - Animasyonlu
class _CustomLedButton extends StatefulWidget {
  final String text;
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;
  final double fontSize;
  final double height;
  final double borderRadius;

  const _CustomLedButton({
    required this.text,
    required this.gradientColors,
    required this.shadowColor,
    required this.onTap,
    this.fontSize = 21,
    this.height = 54,
    this.borderRadius = 16,
  });

  @override
  State<_CustomLedButton> createState() => _CustomLedButtonState();
}

class _CustomLedButtonState extends State<_CustomLedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withOpacity(
                    _isPressed ? 0.25 : 0.35,
                  ),
                  blurRadius: _isPressed ? 12 : 16,
                  spreadRadius: _isPressed ? 1 : 2,
                  offset: Offset(0, _isPressed ? 4 : 6),
                ),
                BoxShadow(
                  color: widget.shadowColor.withOpacity(
                    _isPressed ? 0.12 : 0.18,
                  ),
                  blurRadius: _isPressed ? 24 : 32,
                  offset: Offset(0, _isPressed ? 6 : 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: widget.fontSize,
                        letterSpacing: 1.1,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Oyun Ayarları Ekranı
class GameSettingsScreen extends StatefulWidget {
  final GameSettings initialSettings;

  const GameSettingsScreen({super.key, required this.initialSettings});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  late int _impostorCount;
  late int _gameDurationMinutes;
  late int _hintsCount;
  late List<String> _selectedCategories;
  late List<String> _allCategories;

  @override
  void initState() {
    super.initState();
    _impostorCount = widget.initialSettings.impostorCount;
    _gameDurationMinutes = widget.initialSettings.gameDurationMinutes;
    _hintsCount = widget.initialSettings.hintsCount;
    _selectedCategories = List<String>.from(
      widget.initialSettings.selectedCategories,
    );
    // Tüm kategorileri celebrities listesinden çıkar
    _allCategories = celebrities
        .map((c) => c['category'] as String? ?? 'Diğer')
        .toSet()
        .toList();
    _allCategories.sort();
  }

  void _saveSettings() {
    Navigator.pop(
      context,
      GameSettings(
        impostorCount: _impostorCount,
        gameDurationMinutes: _gameDurationMinutes,
        hintsCount: _hintsCount,
        selectedCategories: _selectedCategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF070C15)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Oyun Ayarları',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Oyun Süresi
                  _ModernSettingsCard(
                    title: 'Oyun Süresi',
                    children: [
                      _SettingsRow(
                        title: 'Süre',
                        subtitle: '$_gameDurationMinutes dakika',
                        trailing: SizedBox(
                          width: 180, // 120'den 180'e artırdık
                          child: Slider(
                            value: _gameDurationMinutes.toDouble(),
                            min: 5,
                            max: 20,
                            divisions: 15,
                            activeColor: const Color(0xFF19B4FF),
                            onChanged: (value) {
                              setState(() {
                                _gameDurationMinutes = value.round();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Hain Sayısı
                  _ModernSettingsCard(
                    title: 'Hain Sayısı',
                    children: [
                      _SettingsRow(
                        title: 'Hain',
                        subtitle: '$_impostorCount oyuncu',
                        trailing: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1')),
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                          ],
                          selected: {_impostorCount},
                          onSelectionChanged: (Set<int> selection) {
                            setState(() {
                              _impostorCount = selection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: const Color(0xFF19B4FF),
                            selectedForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // İpucu Sayısı
                  _ModernSettingsCard(
                    title: 'İpucu Sayısı',
                    children: [
                      _SettingsRow(
                        title: 'İpucu',
                        subtitle: '$_hintsCount adet',
                        trailing: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                            ButtonSegment(value: 4, label: Text('4')),
                            ButtonSegment(value: 5, label: Text('5')),
                          ],
                          selected: {_hintsCount},
                          onSelectionChanged: (Set<int> selection) {
                            setState(() {
                              _hintsCount = selection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: const Color(0xFF19B4FF),
                            selectedForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Kategoriler
                  _ModernSettingsCard(
                    title: 'Kategoriler',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _allCategories.map((cat) {
                            final isSelected = _selectedCategories.contains(
                              cat,
                            );
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(cat);
                                  } else {
                                    _selectedCategories.add(cat);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            const Color(0xFF19B4FF),
                                            const Color(0xFF0FA0E6),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF2C2C2E)
                                                : Colors.white,
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFF1C1C1E)
                                                : const Color(0xFFF8F9FA),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Theme.of(context).brightness ==
                                              Brightness.dark
                                        ? const Color(0xFF38383A)
                                        : const Color(0xFFE5E5EA),
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF19B4FF,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    if (isSelected) const SizedBox(width: 6),
                                    Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.color,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Kaydet Butonu - herkes için
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19B4FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ayarları Kaydet',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modern ayarlar kartı - iOS tarzı
class _ModernSettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ModernSettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6D6D70),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF38383A)
                  : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// Ayar satırı widget'ı - iOS tarzı
class _SettingsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingsRow({required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6D6D70),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
