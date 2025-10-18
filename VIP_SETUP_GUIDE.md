# 📱 App Store Connect VIP Abonelik Kurulumu

## 🍎 iOS App Store Connect

### 1. App Store Connect'e Giriş
1. https://appstoreconnect.apple.com adresine git
2. Developer hesabınla giriş yap
3. "Apps" sekmesine tıkla
4. "Hain Kim?" uygulamanı seç

### 2. In-App Purchases Oluştur
1. **Features** -> **In-App Purchases** menüsüne git
2. **Auto-Renewable Subscriptions** seç
3. **Create** butonuna tıkla

#### Aylık Abonelik:
- **Product ID**: `hain_kim_vip_monthly`
- **Reference Name**: VIP Monthly Subscription
- **Subscription Group**: VIP Membership (yeni grup oluştur)
- **Duration**: 1 Month
- **Price**: Türkiye için ₺9,99 seç

#### Yıllık Abonelik:
- **Product ID**: `hain_kim_vip_yearly`
- **Reference Name**: VIP Yearly Subscription  
- **Subscription Group**: VIP Membership (aynı grup)
- **Duration**: 1 Year
- **Price**: Türkiye için ₺59,99 seç

### 3. Localizations Ekle
Her iki ürün için:
- **Turkish (Turkey)**:
  - Display Name: "VIP Aylık Üyelik" / "VIP Yıllık Üyelik"
  - Description: "Tüm reklamları kaldırır ve kesintisiz oyun deneyimi sunar"

### 4. Review Information
- **Screenshot**: Uygulamanın VIP özelliklerini gösteren ekran görüntüsü
- **Review Notes**: "VIP membership removes all ads for uninterrupted gaming experience"

### 5. Submit for Review
- Her iki ürünü de **Submit for Review** yap
- Apple'ın onaylamasını bekle (1-3 gün)

---

## 🤖 Google Play Console

### 1. Google Play Console'a Giriş
1. https://play.google.com/console adresine git
2. Developer hesabınla giriş yap
3. "Hain Kim?" uygulamanı seç

### 2. Subscriptions Oluştur
1. **Monetize** -> **Products** -> **Subscriptions** menüsüne git
2. **Create subscription** butonuna tıkla

#### Aylık Abonelik:
- **Product ID**: `hain_kim_vip_monthly`
- **Name**: VIP Aylık Üyelik
- **Description**: Tüm reklamları kaldırır ve kesintisiz oyun deneyimi sunar
- **Billing period**: Monthly
- **Price**: ₺9,99 (Turkey)

#### Yıllık Abonelik:
- **Product ID**: `hain_kim_vip_yearly`
- **Name**: VIP Yıllık Üyelik
- **Description**: Tüm reklamları kaldırır ve kesintisiz oyun deneyimi sunar (%50 tasarruf!)
- **Billing period**: Yearly
- **Price**: ₺59,99 (Turkey)

### 3. Base Plans Ayarla
- **Auto-renewing** seç
- **Backwards compatible** işaretle
- **Save** butonuna tıkla

### 4. Activate Subscriptions
- Her iki ürünü de **Activate** et
- Durumlarının **Active** olduğunu kontrol et

---

## 🧪 Test Etme

### iOS Test:
1. Xcode'da **Scheme** -> **Edit Scheme** -> **Run** -> **Options**
2. **StoreKit Configuration File** -> **Configuration.storekit** seç
3. Simulator'da uygulamayı çalıştır
4. VIP satın alma işlemini test et

### Android Test:
1. Google Play Console'da **Internal Testing** oluştur
2. Test APK yükle
3. Test cihazında satın alma işlemini dene

---

## ⚠️ Önemli Notlar

### iOS:
- Product ID'ler kesinlikle eşleşmeli: `hain_kim_vip_monthly`, `hain_kim_vip_yearly`
- StoreKit Configuration dosyası test için gerekli
- Production'da Apple'ın onayı gerekli

### Android:
- Google Play Billing Library güncel olmalı
- Signed APK ile test gerekli
- Product ID'ler Play Console ile eşleşmeli

### Genel:
- Test satın almaları gerçek para almaz
- Production'da gerçek ödemeler alınır
- Abonelik iptal işlemi platform ayarlarından yapılır

---

## 🔧 Kod Güncellemeleri

VIP sistemi otomatik olarak:
- ✅ Abonelik durumunu kontrol eder
- ✅ Reklamları gizler/gösterir
- ✅ Satın almaları geri yükler
- ✅ Süre dolma kontrolü yapar

Herhangi bir ek kod değişikliği gerekmez! 🎉