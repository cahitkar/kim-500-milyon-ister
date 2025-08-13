import 'dart:io';
import 'dart:math';

void main() async {
  final file = File('../assets/data/veri.txt');
  final content = await file.readAsString();
  
  print('Mevcut cevap dağılımı:');
  print('=' * 30);
  analyzeDistribution(content);
  
  print('\nCevap dağılımını dengeleme...');
  final balancedContent = balanceAnswers(content);
  
  // Yedek dosya oluştur
  final backupFile = File('../assets/data/veri.txt.backup');
  if (!await backupFile.exists()) {
    await backupFile.writeAsString(content);
    print('Yedek dosya oluşturuldu: veri.txt.backup');
  }
  
  // Dengelenmiş içeriği yaz
  await file.writeAsString(balancedContent);
  
  print('Cevap dağılımı dengelendi!');
  
  print('\nYeni cevap dağılımı:');
  print('=' * 30);
  analyzeDistribution(balancedContent);
}

void analyzeDistribution(String content) {
  final lines = content.split('\n');
  final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith('Doğru Cevap:')) {
      final correctAnswer = line.replaceFirst('Doğru Cevap:', '').trim();
      
      // Doğru cevabın hangi şıkta olduğunu bul
      for (int j = i - 4; j < i; j++) {
        if (j >= 0 && j < lines.length) {
          final optionLine = lines[j].trim();
          if (optionLine.startsWith('1)') || 
              optionLine.startsWith('2)') || 
              optionLine.startsWith('3)') || 
              optionLine.startsWith('4)')) {
            if (optionLine.contains(correctAnswer)) {
              final optionNumber = int.parse(optionLine[0]);
              distribution[optionNumber] = (distribution[optionNumber] ?? 0) + 1;
              break;
            }
          }
        }
      }
    }
  }
  
  final total = distribution.values.reduce((a, b) => a + b);
  print('Toplam soru sayısı: $total');
  print('\nCevap dağılımı:');
  
  for (int i = 1; i <= 4; i++) {
    final count = distribution[i] ?? 0;
    final percentage = total > 0 ? (count / total * 100) : 0;
    print('Şık $i: $count soru (${percentage.toStringAsFixed(1)}%)');
  }
}

String balanceAnswers(String content) {
  final sections = content.split('===');
  final random = Random();
  final balancedContent = StringBuffer();
  
  for (final section in sections) {
    if (section.trim().isEmpty) continue;
    
    final lines = section.trim().split('\n');
    if (lines.isEmpty) continue;
    
    // Seviye başlığını ekle
    if (lines[0].contains('SEVİYE')) {
      balancedContent.writeln('===${lines[0]}');
      lines.removeAt(0);
    }
    
    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        i++;
        continue;
      }
      
      // Soru satırı
      if (!line.startsWith('1)') && 
          !line.startsWith('2)') && 
          !line.startsWith('3)') && 
          !line.startsWith('4)') && 
          !line.startsWith('Doğru Cevap:')) {
        
        balancedContent.writeln(line);
        i++;
        
        // Şıkları topla
        final options = <String>[];
        String correctAnswer = '';
        
        while (i < lines.length && 
               (lines[i].trim().startsWith('1)') || 
                lines[i].trim().startsWith('2)') || 
                lines[i].trim().startsWith('3)') || 
                lines[i].trim().startsWith('4)'))) {
          options.add(lines[i].trim());
          i++;
        }
        
        // Doğru cevabı bul
        if (i < lines.length && lines[i].trim().startsWith('Doğru Cevap:')) {
          correctAnswer = lines[i].trim();
          i++;
        }
        
        if (options.isNotEmpty && correctAnswer.isNotEmpty) {
          // Doğru cevabın hangi şıkta olduğunu bul
          int correctIndex = -1;
          final correctText = correctAnswer.replaceFirst('Doğru Cevap:', '').trim();
          
          for (int j = 0; j < options.length; j++) {
            if (options[j].contains(correctText)) {
              correctIndex = j;
              break;
            }
          }
          
          if (correctIndex != -1) {
            // Şıkları karıştır
            final shuffledOptions = List<String>.from(options);
            for (int j = shuffledOptions.length - 1; j > 0; j--) {
              final k = random.nextInt(j + 1);
              final temp = shuffledOptions[j];
              shuffledOptions[j] = shuffledOptions[k];
              shuffledOptions[k] = temp;
            }
            
            // Yeni şıkları yaz
            for (int j = 0; j < shuffledOptions.length; j++) {
              final optionText = shuffledOptions[j].substring(2); // "1)" kısmını çıkar
              balancedContent.writeln('${j + 1})$optionText');
            }
            
            // Yeni doğru cevabı yaz
            balancedContent.writeln('Doğru Cevap: $correctText');
          } else {
            // Orijinal şıkları yaz
            for (final option in options) {
              balancedContent.writeln(option);
            }
            balancedContent.writeln(correctAnswer);
          }
        } else {
          // Orijinal şıkları yaz
          for (final option in options) {
            balancedContent.writeln(option);
          }
          if (correctAnswer.isNotEmpty) {
            balancedContent.writeln(correctAnswer);
          }
        }
      } else {
        i++;
      }
    }
    
    balancedContent.writeln();
  }
  
  return balancedContent.toString();
}
