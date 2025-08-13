# Basit JSON Hosting Rehberi

## 1. GitHub Pages ile Ücretsiz Hosting

### Adım 1: GitHub Repository Oluşturma
1. GitHub'da yeni repository oluşturun: `kim-500-milyon-ister`
2. Repository'yi public yapın

### Adım 2: JSON Dosyası Oluşturma
Repository'de `questions.json` dosyası oluşturun:

```json
[
  {
    "question": "Türkiye'nin başkenti neresidir?",
    "options": ["İstanbul", "Ankara", "İzmir", "Bursa"],
    "correctAnswer": 1,
    "level": 1,
    "prize": 5000
  },
  {
    "question": "Hangi gezegen Güneş'e en yakındır?",
    "options": ["Mars", "Venüs", "Merkür", "Dünya"],
    "correctAnswer": 2,
    "level": 2,
    "prize": 7500
  },
  {
    "question": "İstanbul hangi yılda fethedilmiştir?",
    "options": ["1453", "1454", "1452", "1455"],
    "correctAnswer": 0,
    "level": 3,
    "prize": 15000
  }
]
```

### Adım 3: GitHub Pages Etkinleştirme
1. Repository Settings > Pages
2. Source: "Deploy from a branch"
3. Branch: "main"
4. Save

### Adım 4: URL Güncelleme
`lib/services/simple_online_service.dart` dosyasında URL'yi güncelleyin:

```dart
static const String _jsonUrl = 'https://your-username.github.io/kim-500-milyon-ister/questions.json';
```

## 2. Netlify ile Ücretsiz Hosting

### Adım 1: Netlify Hesabı
1. [Netlify](https://netlify.com) hesabı oluşturun
2. "New site from Git" seçin

### Adım 2: Repository Bağlama
1. GitHub repository'nizi seçin
2. Build settings:
   - Build command: boş bırakın
   - Publish directory: `/` (root)

### Adım 3: JSON Dosyası
Repository'de `questions.json` dosyası oluşturun (yukarıdaki gibi)

### Adım 4: URL Güncelleme
```dart
static const String _jsonUrl = 'https://your-app-name.netlify.app/questions.json';
```

## 3. Vercel ile Ücretsiz Hosting

### Adım 1: Vercel Hesabı
1. [Vercel](https://vercel.com) hesabı oluşturun
2. "New Project" seçin

### Adım 2: Repository Bağlama
1. GitHub repository'nizi seçin
2. Framework Preset: "Other"
3. Deploy

### Adım 3: JSON Dosyası
Repository'de `questions.json` dosyası oluşturun

### Adım 4: URL Güncelleme
```dart
static const String _jsonUrl = 'https://your-app-name.vercel.app/questions.json';
```

## 4. Soru Güncelleme Süreci

### Manuel Güncelleme
1. GitHub/Netlify/Vercel repository'nize gidin
2. `questions.json` dosyasını düzenleyin
3. Değişiklikleri commit edin
4. Otomatik olarak yayınlanır

### Toplu Soru Ekleme
1. Mevcut sorularınızı JSON formatına çevirin
2. `questions.json` dosyasını güncelleyin
3. Commit ve push

## 5. Soru Formatı

### Zorunlu Alanlar
- `question`: Soru metni (string)
- `options`: Seçenekler array'i (4 eleman)
- `correctAnswer`: Doğru cevap indexi (0-3)
- `level`: Seviye (1-13)
- `prize`: Ödül miktarı (number)

### Örnek Soru
```json
{
  "question": "Hangi yıl Türkiye Cumhuriyeti kurulmuştur?",
  "options": ["1920", "1921", "1922", "1923"],
  "correctAnswer": 3,
  "level": 4,
  "prize": 30000
}
```

## 6. Test Etme

### URL Testi
Tarayıcıda JSON URL'sini açın:
```
https://your-username.github.io/kim-500-milyon-ister/questions.json
```

### Uygulama Testi
1. Uygulamayı çalıştırın
2. Ayarlar > Online Soruları Güncelle
3. Soruların yüklendiğini kontrol edin

## 7. Güvenlik

### Öneriler
- JSON dosyasını public repository'de tutun
- Hassas bilgi içermeyen sorular ekleyin
- Düzenli yedekleme yapın

### CORS Ayarları
GitHub Pages, Netlify ve Vercel otomatik olarak CORS destekler.

## 8. Sorun Giderme

### Yaygın Sorunlar
1. **404 Hatası**: URL'yi kontrol edin
2. **JSON Parse Hatası**: JSON formatını kontrol edin
3. **Timeout**: İnternet bağlantısını kontrol edin

### Debug
```dart
// Debug için log ekleyin
print('JSON URL: $_jsonUrl');
print('Response status: ${response.statusCode}');
print('Response body: ${response.body}');
```

## 9. Performans

### Öneriler
- JSON dosyasını sıkıştırın
- CDN kullanın (otomatik)
- Cache headers ekleyin
- Gereksiz soruları kaldırın

### Cache Kontrolü
```dart
headers: {
  'Cache-Control': 'no-cache',
  'Pragma': 'no-cache',
}
```
