class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int level;
  final int prize;

  const Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.level,
    required this.prize,
  });
}

class GameData {
  // Sabit sorular kaldırıldı - artık sadece harici dosyadan okunuyor
  static final List<Question> questions = [];

  // Dışarıdan TXT ile gelen sorular
  static List<Question> externalQuestions = [];

  // Tüm soruları seviye sırasına göre döndür
  static List<Question> getAllQuestionsOrdered() {
    final all = <Question>[]
      ..addAll(questions)
      ..addAll(externalQuestions);
    
    // Seviyeye göre sırala (1'den 13'e kadar)
    all.sort((a, b) => a.level.compareTo(b.level));
    return all;
  }

  static List<Question> getQuestionsForLevel(int level) {
    final all = <Question>[]
      ..addAll(questions)
      ..addAll(externalQuestions);
    return all.where((q) => q.level == level).toList();
  }

  static Question getRandomQuestionForLevel(int level) {
    try {
      final levelQuestions = getQuestionsForLevel(level);
      if (levelQuestions.isEmpty) {
        // Eğer seviye için soru yoksa, ilk seviye sorularından birini döndür
        final firstLevelQuestions = getQuestionsForLevel(1);
        if (firstLevelQuestions.isNotEmpty) {
          firstLevelQuestions.shuffle();
          return firstLevelQuestions.first;
        }
        // Hiç soru yoksa varsayılan soru döndür
        return _getDefaultQuestion();
      }
      levelQuestions.shuffle();
      return levelQuestions.first;
    } catch (e) {
      // Hata durumunda varsayılan soru döndür
      return _getDefaultQuestion();
    }
  }

  // Sıralı soru sistemi - tüm soruları sıra ile ver
  static Question? getSequentialQuestion(int currentIndex, Set<String> usedQuestions) {
    try {
      final allQuestions = getAllQuestionsOrdered();
      print('GameData: Toplam soru sayısı: ${allQuestions.length}');
      print('GameData: Mevcut index: $currentIndex');
      
      if (allQuestions.isEmpty) {
        return null; // Hiç soru yok
      }
      
      // Eğer tüm sorular kullanılmışsa, null döndür (oyun biter)
      if (currentIndex >= allQuestions.length) {
        return null; // Oyun biter
      }
      
      // Sıradaki soruyu al
      final question = allQuestions[currentIndex];
      print('GameData: Seçilen soru seviyesi: ${question.level}, Soru: ${question.question.substring(0, 30)}...');
      
      // Bu soru kullanılmış mı kontrol et
      if (usedQuestions.contains(question.question)) {
        // Kullanılmışsa, sonraki kullanılmamış soruyu bul
        for (int i = currentIndex + 1; i < allQuestions.length; i++) {
          if (!usedQuestions.contains(allQuestions[i].question)) {
            final nextQuestion = allQuestions[i];
            print('GameData: Kullanılmış soru atlandı, sonraki soru seviyesi: ${nextQuestion.level}');
            return nextQuestion;
          }
        }
        // Kullanılmamış soru bulunamadıysa null döndür (oyun biter)
        return null; // Oyun biter
      }
      
      return question;
    } catch (e) {
      return null; // Hata durumunda oyun biter
    }
  }

  static Question getUnusedRandomQuestionForLevel(int level, Set<String> usedQuestions) {
    try {
      final levelQuestions = getQuestionsForLevel(level);
      if (levelQuestions.isEmpty) {
        // Eğer seviye için soru yoksa, ilk seviye sorularından kullanılmamış birini döndür
        final firstLevelQuestions = getQuestionsForLevel(1);
        if (firstLevelQuestions.isNotEmpty) {
          final unusedFirstLevelQuestions = firstLevelQuestions
              .where((q) => !usedQuestions.contains(q.question))
              .toList();
          if (unusedFirstLevelQuestions.isNotEmpty) {
            unusedFirstLevelQuestions.shuffle();
            return unusedFirstLevelQuestions.first;
          }
          // Tüm sorular kullanılmışsa, kullanılan soruları sıfırla
          usedQuestions.clear();
          firstLevelQuestions.shuffle();
          return firstLevelQuestions.first;
        }
        return _getDefaultQuestion();
      }
      
      // Kullanılmamış soruları filtrele
      final unusedLevelQuestions = levelQuestions
          .where((q) => !usedQuestions.contains(q.question))
          .toList();
      
      if (unusedLevelQuestions.isNotEmpty) {
        unusedLevelQuestions.shuffle();
        return unusedLevelQuestions.first;
      }
      
      // Tüm sorular kullanılmışsa, kullanılan soruları sıfırla
      usedQuestions.clear();
      levelQuestions.shuffle();
      return levelQuestions.first;
    } catch (e) {
      return _getDefaultQuestion();
    }
  }

  // Varsayılan soru (hata durumunda kullanılır)
  static Question _getDefaultQuestion() {
    return Question(
      question: "Türkiye'nin başkenti neresidir?",
      options: ["İstanbul", "Ankara", "İzmir", "Bursa"],
      correctAnswer: 1,
      level: 1,
      prize: 5000,
    );
  }
}