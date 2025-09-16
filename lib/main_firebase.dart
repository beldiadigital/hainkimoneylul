import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'additional_classes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase başlatma - daha güvenli şekilde
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase başlatıldı');
    }
  } catch (e) {
    print('⚠️ Firebase başlatma hatası: $e');
    // Firebase olmadan da devam et
  }
  
  // AdMob başlatma - sadece Android gerçek cihazlarda
  try {
    if (!kIsWeb && Platform.isAndroid) {
      await MobileAds.instance.initialize();
      print('✅ AdMob başlatıldı');
    }
  } catch (e) {
    print('⚠️ AdMob başlatma hatası: $e');
  }
  
  runApp(const KimHainApp());
}
