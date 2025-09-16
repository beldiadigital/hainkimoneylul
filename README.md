# Kim Hain? - Flutter Oyun Uygulaması

Türkiye'nin popüler "Kim Hain?" oyununun mobil versiyonu. Firebase, AdMob reklamları ve VIP abonelik sistemi ile geliştirilmiştir.

## Özellikler

### 🎮 Oyun Özellikleri
- **Çok oyunculu lobi sistemi** - Arkadaşlarınızla birlikte oynayın
- **400+ Türk ünlüsü** - Geniş ünlü veritabanı
- **Kategori bazlı seçim** - Müzik, spor, sinema kategorileri
- **Özelleştirilebilir oyun ayarları** - Süre, hain sayısı, ipucu sayısı
- **Admin panel** - Test oyunları için bot ekleme
- **Koyu/Açık tema** - Kullanıcı dostu arayüz

### 💎 VIP Üyelik Özellikleri
- **Reklamsız deneyim** - Hiç reklam görmeden oynayın
- **Özel ünlü koleksiyonu** - Sadece VIP'lere özel içerik
- **Sınırsız oyun** - Süre kısıtlaması yok
- **Özel temalar** - VIP'lere özel renkli temalar
- **Aylık/Yıllık abonelik** - Esnek fiyatlandırma

### 📊 Teknoloji Stack
- **Flutter 3.8+** - Cross-platform mobil uygulama
- **Firebase** - Backend hizmetleri
  - Authentication (Anonymous)
  - Firestore Database
  - Analytics
  - Crashlytics
- **Google AdMob** - Reklam sistemi
- **In-App Purchase** - VIP abonelik sistemi
- **Provider** - State management

## Kurulum ve Yapılandırma

### 1. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 2. Firebase Kurulumu

#### Firebase Console Kurulumu:
1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. Yeni proje oluşturun
3. Android ve iOS uygulamaları ekleyin
4. Gerekli servisleri etkinleştirin:
   - Authentication (Anonymous)
   - Firestore Database
   - Analytics
   - Crashlytics

#### Firebase CLI ile Yapılandırma:
```bash
# Firebase CLI'yi yükleyin
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# FlutterFire CLI'yi yükleyin
dart pub global activate flutterfire_cli

# Firebase'i yapılandırın
flutterfire configure
```

#### Manuel Yapılandırma:
Eğer CLI kullanmak istemiyorsanız:

1. `lib/firebase_options.dart` dosyasındaki YOUR_* değerlerini Firebase Console'dan aldığınız gerçek değerlerle değiştirin
2. Android için `google-services.json` dosyasını `android/app/` dizinine koyun
3. iOS için `GoogleService-Info.plist` dosyasını `ios/Runner/` dizinine koyun

### 3. AdMob Kurulumu

#### AdMob Console Kurulumu:
1. [AdMob Console](https://apps.admob.com/)'a gidin
2. Yeni uygulama oluşturun
3. Reklam birimleri oluşturun:
   - Banner Ad
   - Interstitial Ad
   - Rewarded Ad

#### Kod Yapılandırması:
`lib/services/admob_service.dart` dosyasında YOUR_PUBLISHER_ID değerlerini gerçek AdMob ID'lerinizle değiştirin:

```dart
// Production Ad Unit IDs
return Platform.isAndroid
    ? 'ca-app-pub-YOUR_PUBLISHER_ID/BANNER_AD_UNIT_ID'
    : 'ca-app-pub-YOUR_PUBLISHER_ID/BANNER_AD_UNIT_ID';
```

### 4. In-App Purchase Kurulumu

#### Apple App Store Connect:
1. App Store Connect'e gidin
2. Uygulamanızı oluşturun
3. In-App Purchase ürünleri oluşturun:
   - `vip_monthly_subscription` - Aylık abonelik
   - `vip_yearly_subscription` - Yıllık abonelik

#### Google Play Console:
1. Play Console'a gidin
2. Uygulamanızı oluşturun
3. In-app products bölümünden abonelik ürünleri oluşturun

### 5. Platform Yapılandırması

#### Android (android/app/build.gradle):
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

#### iOS (ios/Podfile):
```ruby
platform :ios, '12.0'
```

## Geliştirme

### Uygulamayı Çalıştırma
```bash
# Debug modda çalıştır
flutter run

# Release modda çalıştır
flutter run --release
```

### Test Etme
```bash
# Unit testleri çalıştır
flutter test

# Widget testleri çalıştır
flutter test test/widget_test.dart
```

### Admin Panel Erişimi
Admin paneline erişmek için oyuncu adı olarak "dört" yazın.

## Build ve Deployment

### Android APK/AAB Build:
```bash
# APK build
flutter build apk --release

# Android App Bundle build
flutter build appbundle --release
```

### iOS Build:
```bash
# iOS build
flutter build ios --release
```

## Önemli Notlar

### 🔧 Production'a Çıkmadan Önce:

1. **Firebase yapılandırması** - Gerçek Firebase proje bilgileriyle güncelleyin
2. **AdMob ID'leri** - Test ID'lerini gerçek AdMob ID'leriyle değiştirin
3. **Bundle ID/Package Name** - Gerçek uygulama kimliklerinizi kullanın
4. **In-App Purchase ürünleri** - Store'larda gerçek ürünleri oluşturun
5. **App Store/Play Store** - Mağaza listelerinizi hazırlayın

### 📱 Test ID'leri:
Uygulama şu anda test ID'leri kullanıyor. Production öncesi bunları değiştirmeyi unutmayın:

**AdMob Test ID'leri:**
- Android Banner: `ca-app-pub-3940256099942544/6300978111`
- iOS Banner: `ca-app-pub-3940256099942544/2934735716`
- Android Interstitial: `ca-app-pub-3940256099942544/1033173712`
- iOS Interstitial: `ca-app-pub-3940256099942544/4411468910`

### 🔐 Güvenlik:
- Firebase Security Rules'ları güncelleyin
- API anahtarlarını güvenli tutun
- Release build'lerde debug bilgilerini kapatın

## Sorun Giderme

### Firebase Bağlantı Problemi:
```bash
# Firebase yapılandırmasını yeniden çalıştırın
flutterfire configure

# Paketleri temizleyin ve yeniden yükleyin
flutter clean
flutter pub get
```

### AdMob Reklam Gösterilmiyor:
1. Test cihazınızı AdMob test cihazları listesine ekleyin
2. Internet bağlantısını kontrol edin
3. AdMob hesabınızın aktif olduğundan emin olun

### In-App Purchase Çalışmıyor:
1. Store'larda ürünlerin aktif olduğundan emin olun
2. Test hesapları oluşturun (iOS için Sandbox, Android için Test accounts)
3. Uygulama bundle ID'lerinin eşleştiğinden emin olun

## Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

## İletişim

Geliştirici: BelDiaDigital
Email: contact@beldiadigital.com

---

### 🚀 Happy Coding!

Uygulamanızı App Store ve Google Play'de yayınlamadan önce tüm yapılandırmaları kontrol etmeyi unutmayın!
