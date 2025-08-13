import 'dart:io';

/// Removes duplicate Question(...) blocks in lib/data/questions.dart
/// based on identical question: "..." text (case-insensitive, trimmed).
Future<void> main(List<String> args) async {
  final String path = args.isNotEmpty ? args[0] : 'lib/data/questions.dart';
  final File file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Bulunamadı: $path');
    exit(1);
  }

  final List<String> lines = await file.readAsLines();
  final List<String> output = [];

  final Set<String> seenQuestions = <String>{};
  int removed = 0;
  int kept = 0;

  bool inBlock = false;
  int parenBalance = 0;
  final List<String> blockLines = [];

  String? pendingQuestionText;

  String normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  void flushBlock() {
    if (blockLines.isEmpty) return;
    final String qTextNorm = pendingQuestionText == null ? '' : normalize(pendingQuestionText!);
    if (qTextNorm.isNotEmpty && !seenQuestions.contains(qTextNorm)) {
      seenQuestions.add(qTextNorm);
      output.addAll(blockLines);
      kept++;
    } else {
      removed++;
    }
    blockLines.clear();
    pendingQuestionText = null;
  }

  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    if (!inBlock) {
      if (line.contains('Question(')) {
        inBlock = true;
        parenBalance = 0;
        blockLines.clear();
        pendingQuestionText = null;
        // fallthrough: treat this line as part of block
      } else {
        output.add(line);
        continue;
      }
    }

    if (inBlock) {
      blockLines.add(line);
      // Extract question text if present
      final qMatch = RegExp(r'question:\s*"([^"]+)"').firstMatch(line);
      if (qMatch != null) {
        pendingQuestionText = qMatch.group(1);
      }

      // Update parentheses balance to detect end of Question(...),
      // parentheses only, ignore braces.
      for (int c = 0; c < line.length; c++) {
        final ch = line.codeUnitAt(c);
        if (ch == 40) {
          parenBalance++;
        } else if (ch == 41) {
          parenBalance--;
        }
      }
      // End of a Question(...) block is when balance returns to 0 and line contains '),' or '),'
      if (parenBalance <= 0) {
        inBlock = false;
        flushBlock();
      }
    }
  }

  // Safety: if file ended in block, flush
  if (inBlock) {
    flushBlock();
  }

  final String backupPath = '$path.bak';
  await File(backupPath).writeAsString(lines.join('\n'));
  await file.writeAsString(output.join('\n'));
  stdout.writeln('Tamamlandı: Kalan blok=$kept, Silinen tekrar=$removed');
  stdout.writeln('Yedek: $backupPath');
}


