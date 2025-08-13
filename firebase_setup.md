# Firebase Kurulum Rehberi

## 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Proje Ekle" butonuna tıklayın
3. Proje adını "kim-500-milyon-ister" olarak belirleyin
4. Google Analytics'i etkinleştirin (isteğe bağlı)
5. "Proje Oluştur" butonuna tıklayın

## 2. Firestore Database Kurulumu

1. Sol menüden "Firestore Database"i seçin
2. "Veritabanı oluştur" butonuna tıklayın
3. "Test modunda başlat" seçeneğini seçin
4. Bölge olarak "europe-west3" (Frankfurt) seçin
5. "Bitti" butonuna tıklayın

## 3. Güvenlik Kuralları

Firestore Database > Kurallar sekmesinde aşağıdaki kuralları ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /questions/{questionId} {
      allow read: if true;  // Herkes okuyabilir
      allow write: if false; // Sadece admin yazabilir (güvenlik için)
    }
  }
}
```

## 4. Flutter Firebase CLI Kurulumu

Terminal'de şu komutları çalıştırın:

```bash
# Firebase CLI kurulumu
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# Flutter Firebase CLI kurulumu
dart pub global activate flutterfire_cli

# Firebase projesini yapılandırın
flutterfire configure --project=kim-500-milyon-ister
```

## 5. Android Yapılandırması

1. `android/app/build.gradle` dosyasına şunu ekleyin:
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Firebase için gerekli
    }
}
```

2. `android/app/google-services.json` dosyasını Firebase Console'dan indirin

## 6. iOS Yapılandırması

1. `ios/Runner/GoogleService-Info.plist` dosyasını Firebase Console'dan indirin
2. Xcode'da projeyi açın ve dosyayı Runner klasörüne ekleyin

## 7. Soru Ekleme

Firebase Console > Firestore Database > Veri sekmesinde:

1. "Koleksiyon başlat" butonuna tıklayın
2. Koleksiyon ID'si: `questions`
3. Belge ID'si: `otomatik`
4. Alanları ekleyin:
   - `question` (string): Soru metni
   - `options` (array): Seçenekler ["A", "B", "C", "D"]
   - `correctAnswer` (number): Doğru cevap indexi (0-3)
   - `level` (number): Seviye (1-13)
   - `prize` (number): Ödül miktarı

## 8. Örnek Soru Formatı

```json
{
  "question": "Türkiye'nin başkenti neresidir?",
  "options": ["İstanbul", "Ankara", "İzmir", "Bursa"],
  "correctAnswer": 1,
  "level": 1,
  "prize": 5000
}
```

## 9. Manuel Soru Ekleme

Firebase Console'da manuel olarak soru eklemek için:

1. Firestore Database > Veri
2. `questions` koleksiyonuna tıklayın
3. "Belge ekle" butonuna tıklayın
4. Yukarıdaki formatı kullanarak soru ekleyin

## 10. Toplu Soru Ekleme

JSON dosyasından toplu soru eklemek için:

1. Soruları JSON formatında hazırlayın
2. Firebase Console > Firestore Database > Veri
3. "İçe aktar" butonunu kullanın (JSON formatında)

## 11. Güvenlik

- Sadece okuma izni verin (yukarıdaki kurallar)
- Soru ekleme/düzenleme için ayrı admin paneli oluşturun
- API anahtarlarını güvenli tutun

## 12. Test

Uygulamayı çalıştırın ve:
1. Ayarlar > Online Soruları Güncelle
2. Firebase'den soruların yüklendiğini kontrol edin
3. Yeni soruların oyunda göründüğünü doğrulayın
