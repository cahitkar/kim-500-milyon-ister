import 'dart:io';

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'assets/data/veri.txt';
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Bulunamadı: $path');
    exit(1);
  }
  final raw = await file.readAsString();

  int currentLevel = 1;
  final Map<int, int> perLevel = { for (var i = 1; i <= 13; i++) i: 0 };
  final List<String> questions = [];
  final List<String> qLines = [];

  void flush() {
    if (qLines.isEmpty) return;
    final q = qLines.join(' ').trim();
    if (q.isNotEmpty) {
      questions.add(q);
      perLevel[currentLevel] = (perLevel[currentLevel] ?? 0) + 1;
    }
    qLines.clear();
  }

  for (final line in raw.split(RegExp(r'\r?\n'))) {
    final t = line.trim();
    if (t.isEmpty) continue;
    if (t.startsWith('=== SEVİYE')) {
      flush();
      final m = RegExp(r'SEVİYE\s+(\d+)').firstMatch(t);
      if (m != null) currentLevel = int.parse(m.group(1)!);
      continue;
    }
    if (RegExp(r'^\d\)').hasMatch(t)) {
      // options ignored
      continue;
    }
    if (t.startsWith('Doğru Cevap:')) {
      flush();
      continue;
    }
    qLines.add(t);
  }
  flush();

  int total = 0;
  for (int i = 1; i <= 13; i++) {
    total += (perLevel[i] ?? 0);
  }

  stdout.writeln('TXT_TOTAL=$total');
  for (int i = 1; i <= 13; i++) {
    stdout.writeln('LVL=$i;COUNT=${perLevel[i] ?? 0}');
  }
}


