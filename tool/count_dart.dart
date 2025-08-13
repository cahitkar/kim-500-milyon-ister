import 'dart:io';

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'lib/data/questions.dart';
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Bulunamadı: $path');
    exit(1);
  }
  final lines = await file.readAsLines();
  final Map<int, int> perLevel = { for (var i = 1; i <= 13; i++) i: 0 };

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.contains('Question(')) {
      int level = 0;
      for (int j = i; j < lines.length && j <= i + 30; j++) {
        final l = lines[j];
        final m = RegExp(r'level:\s*(\d+)').firstMatch(l);
        if (m != null) {
          level = int.parse(m.group(1)!);
          break;
        }
      }
      if (level > 0) {
        perLevel[level] = (perLevel[level] ?? 0) + 1;
      }
    }
  }

  int total = 0;
  for (int i = 1; i <= 13; i++) {
    total += (perLevel[i] ?? 0);
  }

  stdout.writeln('DART_TOTAL=$total');
  for (int i = 1; i <= 13; i++) {
    stdout.writeln('LVL=$i;COUNT=${perLevel[i] ?? 0}');
  }
}


