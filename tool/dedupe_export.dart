import 'dart:io';

void main(List<String> args) async {
  final String path = args.isNotEmpty ? args[0] : 'exported_questions.txt';
  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Bulunamadı: $path');
    exit(1);
  }

  final String content = await file.readAsString();
  final List<String> lines = content.split(RegExp(r'\r?\n'));

  final List<String> output = [];
  final Set<String> seenQuestions = <String>{};

  int kept = 0;
  int removed = 0;

  int i = 0;
  while (i < lines.length) {
    final String line = lines[i];
    if (line.startsWith('=== SEVİYE')) {
      final List<String> block = [];
      // Topla: başlık dahil, bir sonraki '=== SEVİYE' satırına kadar
      block.add(lines[i]);
      i++;
      while (i < lines.length && !lines[i].startsWith('=== SEVİYE')) {
        block.add(lines[i]);
        i++;
      }

      // Soru satırını bul
      final String? questionLine = block.firstWhere(
        (l) => l.startsWith('Soru:'),
        orElse: () => '',
      );
      String normalized = '';
      if (questionLine != null && questionLine.isNotEmpty) {
        final String q = questionLine.substring('Soru:'.length).trim();
        normalized = q.toLowerCase();
      }

      if (normalized.isEmpty || !seenQuestions.contains(normalized)) {
        if (normalized.isNotEmpty) seenQuestions.add(normalized);
        output.addAll(block);
        kept++;
      } else {
        removed++;
      }
      continue;
    }

    // Başlıkla başlamayan satırlar (dosya başında olabilecek boşluklar vb.)
    output.add(line);
    i++;
  }

  // Fazla boş satırları normalize et (isteğe bağlı hafif temizlik)
  final List<String> compact = [];
  bool lastEmpty = false;
  for (final String l in output) {
    final bool isEmpty = l.trim().isEmpty;
    if (isEmpty && lastEmpty) {
      continue;
    }
    compact.add(l);
    lastEmpty = isEmpty;
  }

  // Yedek al ve yaz
  final String backupPath = '${path}.bak';
  await File(backupPath).writeAsString(content);
  await file.writeAsString(compact.join('\n'));

  stdout.writeln('Toplam blok: ${kept + removed} | Kalan: $kept | Silinen (tekrar): $removed');
  stdout.writeln('Yedek: $backupPath');
}


