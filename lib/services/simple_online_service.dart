import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/questions.dart';

class SimpleOnlineService {
  // GitHub Pages, Netlify, Vercel gibi ücretsiz hosting servisleri kullanabilirsiniz
  static const String _jsonUrl = 'https://your-username.github.io/kim-500-milyon-ister/questions.json';
  
  // Alternatif URL'ler (bunlardan birini kullanın):
  // static const String _jsonUrl = 'https://your-app.netlify.app/questions.json';
  // static const String _jsonUrl = 'https://your-app.vercel.app/questions.json';
  // static const String _jsonUrl = 'https://your-domain.com/questions.json';
  
  // JSON dosyasından soruları getir
  static Future<List<Question>> getQuestionsFromJson() async {
    try {
      print('SimpleOnlineService: JSON dosyasından sorular yükleniyor...');
      
      final response = await http.get(
        Uri.parse(_jsonUrl),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        List<Question> questions = [];
        for (var item in jsonData) {
          questions.add(Question(
            question: item['question'] ?? '',
            options: List<String>.from(item['options'] ?? []),
            correctAnswer: item['correctAnswer'] ?? 0,
            level: item['level'] ?? 1,
            prize: item['prize'] ?? 0,
          ));
        }
        
        print('SimpleOnlineService: ${questions.length} soru başarıyla yüklendi');
        return questions;
      } else {
        print('SimpleOnlineService: HTTP hatası: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('SimpleOnlineService: Soru yükleme hatası: $e');
      return [];
    }
  }
  
  // Soruları senkronize et
  static Future<bool> syncQuestions() async {
    try {
      final onlineQuestions = await getQuestionsFromJson();
      if (onlineQuestions.isNotEmpty) {
        // GameData'yı güncelle
        GameData.externalQuestions = onlineQuestions;
        print('SimpleOnlineService: Sorular başarıyla senkronize edildi');
        return true;
      }
      return false;
    } catch (e) {
      print('SimpleOnlineService: Senkronizasyon hatası: $e');
      return false;
    }
  }
  
  // JSON dosyası formatı örneği
  static String getJsonExample() {
    return '''
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
''';
  }
}
