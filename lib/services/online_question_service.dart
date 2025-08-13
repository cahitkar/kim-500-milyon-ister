import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/questions.dart';

class OnlineQuestionService {
  // Firebase Firestore kullanarak
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // HTTP ile JSON dosyasından
  static const String _jsonUrl = 'https://your-domain.com/questions.json';
  
  // Firebase'den soruları getir
  static Future<List<Question>> getQuestionsFromFirebase() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('questions').get();
      
      List<Question> questions = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        questions.add(Question(
          question: data['question'] ?? '',
          options: List<String>.from(data['options'] ?? []),
          correctAnswer: data['correctAnswer'] ?? 0,
          level: data['level'] ?? 1,
          prize: data['prize'] ?? 0,
        ));
      }
      
      print('Firebase\'den ${questions.length} soru yüklendi');
      return questions;
    } catch (e) {
      print('Firebase\'den soru yüklenirken hata: $e');
      return [];
    }
  }
  
  // HTTP ile JSON dosyasından soruları getir
  static Future<List<Question>> getQuestionsFromJson() async {
    try {
      final response = await http.get(Uri.parse(_jsonUrl));
      
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
        
        print('JSON\'dan ${questions.length} soru yüklendi');
        return questions;
      } else {
        print('HTTP hatası: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('JSON\'dan soru yüklenirken hata: $e');
      return [];
    }
  }
  
  // Firebase'e yeni soru ekle
  static Future<bool> addQuestionToFirebase(Question question) async {
    try {
      await _firestore.collection('questions').add({
        'question': question.question,
        'options': question.options,
        'correctAnswer': question.correctAnswer,
        'level': question.level,
        'prize': question.prize,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Soru Firebase\'e eklendi');
      return true;
    } catch (e) {
      print('Firebase\'e soru eklenirken hata: $e');
      return false;
    }
  }
  
  // Firebase'den soru sil
  static Future<bool> deleteQuestionFromFirebase(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      print('Soru Firebase\'den silindi');
      return true;
    } catch (e) {
      print('Firebase\'den soru silinirken hata: $e');
      return false;
    }
  }
  
  // Firebase'de soru güncelle
  static Future<bool> updateQuestionInFirebase(String questionId, Question question) async {
    try {
      await _firestore.collection('questions').doc(questionId).update({
        'question': question.question,
        'options': question.options,
        'correctAnswer': question.correctAnswer,
        'level': question.level,
        'prize': question.prize,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Soru Firebase\'de güncellendi');
      return true;
    } catch (e) {
      print('Firebase\'de soru güncellenirken hata: $e');
      return false;
    }
  }
  
  // Tüm soruları senkronize et
  static Future<bool> syncQuestionsWithFirebase() async {
    try {
      final onlineQuestions = await getQuestionsFromFirebase();
      if (onlineQuestions.isNotEmpty) {
        // GameData'yı güncelle
        GameData.externalQuestions = onlineQuestions;
        print('Sorular Firebase ile senkronize edildi');
        return true;
      }
      return false;
    } catch (e) {
      print('Senkronizasyon hatası: $e');
      return false;
    }
  }
}
