import 'dart:io';

import 'package:kim_500_milyon_ister/data/questions.dart';

Future<void> main() async {
  // Dahili sorular
  final List<Question> internalQuestions = GameData.questions;

  // Harici TXT soruları
  final File externalFile = File('assets/data/veri.txt');
  List<Question> externalQuestions = [];
  if (await externalFile.exists()) {
    final String raw = await externalFile.readAsString();
    externalQuestions = _parseFromText(raw);
  }

  final List<Question> allQuestions = <Question>[
    ...internalQuestions,
    ...externalQuestions,
  ];

  final StringBuffer buffer = StringBuffer();
  for (final Question q in allQuestions) {
    buffer.writeln('=== SEVİYE ${q.level} | Ödül: ${_formatPrize(q.prize)} TL');
    buffer.writeln('Soru: ${q.question}');
    for (int i = 0; i < q.options.length; i++) {
      buffer.writeln('${i + 1}) ${q.options[i]}');
    }
    final String correctText = (q.correctAnswer >= 0 && q.correctAnswer < q.options.length)
        ? q.options[q.correctAnswer]
        : '';
    buffer.writeln('Doğru Cevap: $correctText');
    buffer.writeln();
  }

  const String outPath = 'exported_questions.txt';
  await File(outPath).writeAsString(buffer.toString());
  stdout.writeln('Yazıldı: $outPath (${allQuestions.length} soru)');
}

String _formatPrize(int prize) {
  // Türkçe sayı formatına kabaca uygunlaştır (nokta ayırıcı)
  final s = prize.toString();
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write('.');
      count = 0;
    }
  }
  return buf.toString().split('').reversed.join();
}

// Flutter bağımsız TXT ayrıştırıcı
List<Question> _parseFromText(String raw) {
  const Map<int, int> levelToPrize = {
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

  final List<Question> questions = [];
  int currentLevel = 1;
  final List<String> qLines = [];
  final List<String> opts = [];
  String? correctText;

  void flush() {
    final String qText = qLines.join(' ').trim();
    if (qText.isNotEmpty && opts.length == 4 && correctText != null) {
      final int correctIndex = _findCorrectIndex(opts, correctText!);
      final int prize = levelToPrize[currentLevel] ?? 0;
      questions.add(Question(
        question: qText,
        options: List<String>.from(opts),
        correctAnswer: correctIndex,
        level: currentLevel,
        prize: prize,
      ));
    }
    qLines.clear();
    opts.clear();
    correctText = null;
  }

  final List<String> lines = raw.split(RegExp(r'\r?\n'));
  for (final String line in lines) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (trimmed.startsWith('=== SEVİYE')) {
      flush();
      final int? lvl = _extractLevel(trimmed);
      if (lvl != null) currentLevel = lvl;
      continue;
    }
    if (RegExp(r'^\d\)').hasMatch(trimmed)) {
      final String content = trimmed.substring(2).trim();
      opts.add(content);
      continue;
    }
    if (trimmed.startsWith('Doğru Cevap:')) {
      correctText = trimmed.substring('Doğru Cevap:'.length).trim();
      flush();
      continue;
    }
    qLines.add(trimmed);
  }

  flush();
  return questions;
}

int _findCorrectIndex(List<String> options, String correctText) {
  final String norm = correctText.trim().toLowerCase();
  for (int i = 0; i < options.length; i++) {
    final String o = options[i].trim().toLowerCase();
    if (o == norm) return i;
  }
  return 0;
}

int? _extractLevel(String header) {
  final match = RegExp(r'SEVİYE\s+(\d+)').firstMatch(header);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}


