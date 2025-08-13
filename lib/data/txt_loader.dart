import 'package:flutter/services.dart' show rootBundle;
import 'questions.dart';

class TxtQuestionLoader {
  static const Map<int, int> _levelToPrize = {
    1: 5000,
    2: 10000,
    3: 30000,
    4: 90000,
    5: 200000,
    6: 400000,
    7: 600000,
    8: 800000,
    9: 1000000,
    10: 1500000,
    11: 2000000,
    12: 3000000,
    13: 5000000,
  };

  static Future<List<Question>> loadFromAssets(String path) async {
    final raw = await rootBundle.loadString(path);
    final parsed = parseFromText(raw);

    // Mevcut dahili ve harici sorulara karşı deduplikasyon
    final Set<String> existing = {
      ...GameData.questions.map((q) => _normalize(q.question)),
      ...GameData.externalQuestions.map((q) => _normalize(q.question)),
    };

    final List<Question> unique = [];
    for (final q in parsed) {
      final key = _normalize(q.question);
      if (!existing.contains(key)) {
        existing.add(key);
        unique.add(q);
      }
    }
    return unique;
  }

  static List<Question> parseFromText(String raw) {
    final List<Question> questions = [];
    final Set<String> seenInFile = <String>{};
    int currentLevel = 1;
    final List<String> qLines = [];
    final List<String> opts = [];
    String? correctText;

    void flush() {
      final qText = qLines.join(' ').trim();
      if (qText.isNotEmpty && opts.length == 4 && correctText != null) {
        final String normQ = _normalize(qText);
        if (!seenInFile.contains(normQ)) {
          seenInFile.add(normQ);
          final int correctIndex = _findCorrectIndex(opts, correctText!);
          final prize = _levelToPrize[currentLevel] ?? 0;
          questions.add(Question(
            question: qText,
            options: List<String>.from(opts),
            correctAnswer: correctIndex,
            level: currentLevel,
            prize: prize,
          ));
        }
      }
      qLines.clear();
      opts.clear();
      correctText = null;
    }

    final lines = raw.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        // soru bloğu sonu olabilir
        continue;
      }
      if (trimmed.startsWith('=== SEVİYE')) {
        flush();
        final lvl = _extractLevel(trimmed);
        if (lvl != null) currentLevel = lvl;
        continue;
      }
      if (RegExp(r'^\d\)').hasMatch(trimmed)) {
        final content = trimmed.substring(2).trim();
        opts.add(content);
        continue;
      }
      if (trimmed.startsWith('Doğru Cevap:')) {
        correctText = trimmed.substring('Doğru Cevap:'.length).trim();
        // Bu noktada blok tamam, flush et
        flush();
        continue;
      }
      // soru satırı
      qLines.add(trimmed);
    }

    // dosya sonu için flush
    flush();
    return questions;
  }

  static int _findCorrectIndex(List<String> options, String correctText) {
    // 1) metinlerinin eşleşmediği durumlar için trim/normalize et
    final norm = correctText.replaceAll('"', '"').trim().toLowerCase();
    for (int i = 0; i < options.length; i++) {
      final o = options[i].trim().toLowerCase();
      if (o == norm) return i;
    }
    // Bulunamazsa ilk seçenek
    return 0;
  }

  static int? _extractLevel(String header) {
    final match = RegExp(r'SEVİYE\s+(\d+)').firstMatch(header);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}


