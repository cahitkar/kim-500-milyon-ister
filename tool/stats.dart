import 'dart:io';

import 'package:kim_500_milyon_ister/data/questions.dart';

void main() async {
  // Internal (Dart) questions
  final List<Question> internal = GameData.questions;

  // External (TXT) questions parsed without Flutter
  final File txtFile = File('assets/data/veri.txt');
  final List<Question> external = await _loadTxt(txtFile);

  // Dedupe across combined by normalized question text
  final Map<String, Question> uniqueByQ = {};
  final Map<String, String> sourceByQ = {}; // 'dart' or 'txt'
  for (final q in internal) {
    final key = _norm(q.question);
    uniqueByQ[key] = q;
    sourceByQ[key] = 'dart';
  }
  for (final q in external) {
    final key = _norm(q.question);
    if (!uniqueByQ.containsKey(key)) {
      uniqueByQ[key] = q;
      sourceByQ[key] = 'txt';
    }
  }

  final List<Question> combined = uniqueByQ.values.toList();

  // Per-level counts (combined, internal-only, external-only)
  final Map<int, int> combinedPerLevel = { for (var i=1; i<=13; i++) i: 0 };
  final Map<int, int> internalPerLevel = { for (var i=1; i<=13; i++) i: 0 };
  final Map<int, int> externalPerLevel = { for (var i=1; i<=13; i++) i: 0 };

  for (final q in combined) {
    combinedPerLevel[q.level] = (combinedPerLevel[q.level] ?? 0) + 1;
  }
  for (final q in internal) {
    final key = _norm(q.question);
    if (sourceByQ[key] == 'dart') {
      internalPerLevel[q.level] = (internalPerLevel[q.level] ?? 0) + 1;
    }
  }
  for (final q in external) {
    final key = _norm(q.question);
    if (sourceByQ[key] == 'txt') {
      externalPerLevel[q.level] = (externalPerLevel[q.level] ?? 0) + 1;
    }
  }

  // Simple category counts on combined
  final Map<String, int> categoryCounts = {};
  for (final q in combined) {
    final c = _category(q.question);
    categoryCounts[c] = (categoryCounts[c] ?? 0) + 1;
  }

  // Output
  stdout.writeln('TOPLAM (benzersiz): ${combined.length}');
  stdout.writeln('Dahili (benzersiz): ${internalPerLevel.values.reduce((a,b)=>a+b)}');
  stdout.writeln('Harici TXT (benzersiz): ${externalPerLevel.values.reduce((a,b)=>a+b)}');
  stdout.writeln('');
  stdout.writeln('SEVİYE | TOPLAM | DAHİLİ | HARİCİ');
  stdout.writeln('------ | -----: | -----: | -----:');
  for (int lvl = 1; lvl <= 13; lvl++) {
    stdout.writeln('${lvl.toString().padLeft(2)}     | '
        '${(combinedPerLevel[lvl] ?? 0).toString().padLeft(5)} | '
        '${(internalPerLevel[lvl] ?? 0).toString().padLeft(6)} | '
        '${(externalPerLevel[lvl] ?? 0).toString().padLeft(6)}');
  }
  stdout.writeln('');
  stdout.writeln('KATEGORİ | ADET');
  stdout.writeln('-------- | ----:');
  final entries = categoryCounts.entries.toList()
    ..sort((a,b)=>b.value.compareTo(a.value));
  for (final e in entries) {
    stdout.writeln('${e.key} | ${e.value}');
  }
}

Future<List<Question>> _loadTxt(File file) async {
  if (!await file.exists()) return [];
  final raw = await file.readAsString();
  return _parseTxt(raw);
}

List<Question> _parseTxt(String raw) {
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
    final qText = qLines.join(' ').trim();
    if (qText.isNotEmpty && opts.length == 4 && correctText != null) {
      final int correctIndex = _findCorrectIndex(opts, correctText!);
      final prize = levelToPrize[currentLevel] ?? 0;
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

  final lines = raw.split(RegExp(r'\r?\n'));
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
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
      flush();
      continue;
    }
    qLines.add(trimmed);
  }

  flush();
  return questions;
}

int _findCorrectIndex(List<String> options, String correctText) {
  final norm = correctText.trim().toLowerCase();
  for (int i = 0; i < options.length; i++) {
    if (options[i].trim().toLowerCase() == norm) return i;
  }
  return 0;
}

int? _extractLevel(String header) {
  final match = RegExp(r'SEVİYE\s+(\d+)').firstMatch(header);
  if (match != null) return int.tryParse(match.group(1)!);
  return null;
}

String _norm(String input) => input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _category(String q) {
  final l = q.toLowerCase();
  if (RegExp(r'islam|peygamber|namaz|secde|rükü|kuran|tevrat|incil|zebur').hasMatch(l)) return 'Din';
  if (RegExp(r'dağ|göl|nehir|çöl|volkan|ülke|yüzölçüm').hasMatch(l)) return 'Coğrafya';
  if (RegExp(r'roman|yazarı|eseri|kitabını kim|romanı kimin|kimin eseri').hasMatch(l)) return 'Edebiyat';
  if (RegExp(r'film|yönetmen|yönetmeni|filmi kimin').hasMatch(l)) return 'Sinema';
  if (RegExp(r'atasözü|anlamı nedir|neyi anlatır|ne demektir|anlamı\?').hasMatch(l)) return 'Atasözü/Deyim';
  if (RegExp(r'organ|kemik|kan|akciğer|beyin|pankreas|kalp|hücre|kafatası|insülin').hasMatch(l)) return 'Biyoloji/Anatomi';
  if (RegExp(r'gezegen|güneş|jüpiter|merkür|venus|venüs|mars|satürn').hasMatch(l)) return 'Astronomi';
  if (RegExp(r'yıl|latin alfabesi|dünya savaşı|cumhuriyet|kabul edil').hasMatch(l)) return 'Tarih';
  if (RegExp(r'gol|olimpiyat').hasMatch(l)) return 'Spor';
  if (RegExp(r'bilgisayar|televizyon').hasMatch(l)) return 'Teknoloji';
  return 'Genel';
}


