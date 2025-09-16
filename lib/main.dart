import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'additional_classes.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    if (!kIsWeb) {
      try {
        FirebaseService.recordError(details.exception, details.stack);
      } catch (e) {
        print('Error logging failed: $e');
      }
    }
  };

  // Firebase başlatma - iOS ve Android'de
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase başlatıldı');
    } catch (e) {
      print('⚠️ Firebase başlatma hatası: $e');
      // Firebase olmadan da devam et
    }
  }

  // AdMob başlatma - iOS ve Android'de
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      print('✅ AdMob başlatıldı');
    } catch (e) {
      print('⚠️ AdMob başlatma hatası: $e');
    }
  }

  runApp(const KimHainApp());
}

class KimHainApp extends StatelessWidget {
  const KimHainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Kim Hain?',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            home: const KimHainHome(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
