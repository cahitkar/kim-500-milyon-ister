import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/questions.dart';
import '../services/audio_service.dart';
import '../providers/game_provider.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;
  final Future<void> Function() onAnswerConfirmed;
  final bool hasUsedFiftyFifty;
  // Mevcut soru için 50:50 aktif mi (yalnızca bu soruda 2 şık göstermek için)
  final bool? isFiftyFiftyActiveForCurrentQuestion;
  // Telefon joker ipucu bilgisi
  final bool? isPhoneHintActive;
  final int? phoneHintTargetIndex;
  final int? phoneHighlightIndex;
  // Süresiz mod: şık tıklaması otomatik onay kabul edilsin mi?
  final bool autoConfirmOnSelect;

  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    required this.onAnswerConfirmed,
    required this.hasUsedFiftyFifty,
    this.isFiftyFiftyActiveForCurrentQuestion,
    this.isPhoneHintActive,
    this.phoneHintTargetIndex,
    this.phoneHighlightIndex,
    this.autoConfirmOnSelect = false,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  bool _isAnswerConfirmed = false;
  bool _isShowingResult = false;
  bool _isCorrect = false;
  bool _showCorrectAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Soru (küçültme yok, satır sarmalı)
            Container(
              width: double.infinity,
              child: Text(
                widget.question.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: null,
              ),
            ),
           
            const SizedBox(height: 16),
          
            // Şıklar
            ...List.generate(widget.question.options.length, (index) {
              final isSelected = widget.selectedAnswer == index;
              final isCorrect = index == widget.question.correctAnswer;
              final isWrong = widget.selectedAnswer != null && isSelected && !isCorrect;
              final isDisabled = _isOptionDisabled(index);
              // Animasyon sırasında phoneHighlightIndex, sonunda phoneHintTargetIndex kullan
              final isPhoneHighlight = (widget.phoneHighlightIndex != null && widget.phoneHighlightIndex == index) &&
                   !(widget.isPhoneHintActive == true && widget.phoneHintTargetIndex != null && widget.phoneHintTargetIndex == index);
              // Son şıkta kalıcı highlight
              final isPhoneFinalHighlight = widget.isPhoneHintActive == true && 
                   widget.phoneHintTargetIndex != null && widget.phoneHintTargetIndex == index;
              if (isPhoneHighlight) {
                print('QuestionCard: Şık $index telefon highlight ile gösteriliyor');
              }
              if (isPhoneFinalHighlight) {
                print('QuestionCard: Şık $index telefon final highlight ile gösteriliyor');
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isDisabled ? null : () async {
                      try {
                        // Bekletmeyi durdururken loop niyetini koru ve kısa efekt patlamasını önle
                        final audio = AudioService();
                        audio.suppressShortEffects(const Duration(milliseconds: 250));
                        await audio.stopAllSounds(preserveWaitingLoop: false);
                        print('QuestionCard: Bekletme müziği durduruldu');
                        
                        // Buton tıklama sesini çal
                        await audio.playButtonClick();
                      } catch (e) {
                        print('Ses işlemleri yapılamadı: $e');
                      }
                      // Seçimi bildir
                      widget.onAnswerSelected(index);
                      // Süresiz modda otomatik onay
                      if (widget.autoConfirmOnSelect) {
                        final isCorrect = index == widget.question.correctAnswer;
                        setState(() {
                          _isAnswerConfirmed = true;
                          _isCorrect = isCorrect;
                          _isShowingResult = true; // Sonucu hemen göster
                        });
                        
                        // Yanlışsa doğru cevabı 2 sn, doğruysa 1 sn yeşil highlight ile göster
                        if (!isCorrect) {
                          print('QuestionCard: Yanlış cevap tıklandı, doğru cevap gösterilecek');
                          print('QuestionCard: Doğru cevap index: ${widget.question.correctAnswer}');
                          setState(() { 
                            _showCorrectAnswer = true; 
                          });
                          print('QuestionCard: _showCorrectAnswer true yapıldı');
                          await Future.delayed(const Duration(seconds: 2));
                          setState(() { 
                            _showCorrectAnswer = false; 
                          });
                          print('QuestionCard: Doğru cevap gösterimi tamamlandı');
                        } else {
                          setState(() { 
                            _showCorrectAnswer = true; 
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          setState(() { 
                            _showCorrectAnswer = false; 
                          });
                        }
                        await widget.onAnswerConfirmed();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _getOptionGradientColor1(isSelected, isCorrect, isWrong, isDisabled, isPhoneHighlight, isPhoneFinalHighlight),
                            _getOptionGradientColor2(isSelected, isCorrect, isWrong, isDisabled, isPhoneHighlight, isPhoneFinalHighlight),
                            _getOptionGradientColor3(isSelected, isCorrect, isWrong, isDisabled, isPhoneHighlight, isPhoneFinalHighlight),
                            _getOptionGradientColor4(isSelected, isCorrect, isWrong, isDisabled, isPhoneHighlight, isPhoneFinalHighlight),
                          ],
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ),
                        border: Border.all(
                          color: _getOptionBorderColor(isSelected, isCorrect, isWrong, isPhoneHighlight, isPhoneFinalHighlight, isDisabled),
                          width: _getOptionBorderWidth(isSelected, isCorrect, isWrong, isPhoneHighlight, isPhoneFinalHighlight),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: (isPhoneHighlight || isPhoneFinalHighlight) ? [
                          BoxShadow(
                            color: Colors.blue.shade300.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          // Şık harfi
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  color: isDisabled ? Colors.grey : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18, // 16'dan 18'e
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Şık metni (küçültme yok, satır sarmalı)
                          Expanded(
                            child: Text(
                              widget.question.options[index],
                              style: TextStyle(
                                color: isDisabled ? Colors.grey : Colors.white,
                                fontSize: 18, // 16'dan 18'e
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              maxLines: null,
                            ),
                          ),
                          // Seçim işareti (sadece animasyon sırasında)
                          if (_isShowingResult && isSelected)
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            
            // Cevap onay butonu
            if (!widget.autoConfirmOnSelect && widget.selectedAnswer != null)
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isAnswerConfirmed ? null : () async {
                    // Cevabın doğru olup olmadığını kontrol et
                    _isCorrect = widget.selectedAnswer == widget.question.correctAnswer;
                    
                    // Önce sadece onaylandığını göster, sonucu gösterme
                    setState(() {
                      _isAnswerConfirmed = true;
                      _isShowingResult = false; // Henüz sonucu gösterme
                    });
                    
                    // Buton tıklama sesi (hızlı)
                    try {
                      print('QuestionCard: Buton tıklama sesi çalınacak');
                      final audioService = AudioService();
                      audioService.suppressShortEffects(const Duration(milliseconds: 250));
                      await audioService.playButtonClick();
                      print('QuestionCard: Buton tıklama sesi başarıyla çalındı');
                    } catch (e) {
                      print('QuestionCard: Buton tıklama sesi çalınamadı: $e');
                    }
                    
                    // Gerilim müziğini hemen çal (hızlı)
                    try {
                      print('QuestionCard: Gerilim müziği çalınacak');
                      final audioService = AudioService();
                      await audioService.playTension();
                      print('QuestionCard: Gerilim müziği başarıyla çalındı');
                    } catch (e) {
                      print('QuestionCard: Gerilim müziği çalınamadı: $e');
                    }
                    
                    // 10 saniye bekle (gerilim müziği için)
                    await Future.delayed(const Duration(seconds: 10));
                    
                                         // 7 saniye sonra sonucu göster
                     setState(() {
                       _isShowingResult = true;
                     });
                     
                     // Yanlış cevap verildiyse doğru cevabı 2 saniye göster
                     if (!_isCorrect) {
                       print('QuestionCard: Yanlış cevap verildi, doğru cevap gösterilecek');
                       print('QuestionCard: Doğru cevap index: ${widget.question.correctAnswer}');
                       setState(() {
                         _showCorrectAnswer = true;
                       });
                       print('QuestionCard: _showCorrectAnswer true yapıldı');
                       
                       await Future.delayed(const Duration(seconds: 2));
                       
                       setState(() {
                         _showCorrectAnswer = false;
                       });
                       print('QuestionCard: Doğru cevap gösterimi tamamlandı');
                     }
                     
                     // Oyun sonucunu kontrol et
                     await widget.onAnswerConfirmed();
                   },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                                         child: Text(
                       _getButtonText(),
                       style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: _getButtonTextColor(),
                         fontSize: 18,
                       ),
                       textAlign: TextAlign.center,
                     ),
                  ),
                ),
              ),
              
              // Süre göstergesi (onay butonunun altında)
              Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  if (gameProvider.remainingTime <= 0) return const SizedBox.shrink();
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          color: gameProvider.isTimeWarning 
                            ? Colors.red
                            : gameProvider.isCountdownActive
                              ? Colors.orange
                              : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          gameProvider.getFormattedTime(),
                          style: TextStyle(
                            color: gameProvider.isTimeWarning 
                              ? Colors.red
                              : gameProvider.isCountdownActive
                                ? Colors.orange
                                : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getOptionColor(bool isSelected, bool isCorrect, bool isWrong, bool isDisabled) {
    if (isDisabled) {
      return Colors.grey.withOpacity(0.3);
    }
    // Animasyon sırasında doğru/yanlış renkleri göster
    if (_isShowingResult) {
      if (isCorrect) {
        return Colors.green.withOpacity(0.3);
      }
      if (isWrong) {
        return Colors.red.withOpacity(0.3);
      }
    }
    // Sadece seçildiğinde amber renk göster
    if (isSelected) {
      return Colors.amber.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  Color _getAnimatedBorderColor(bool isSelected, bool isCorrect, bool isWrong) {
    // Animasyon sırasında renk değişimi
    if (_isShowingResult) {
      if (isCorrect) {
        return Colors.green;
      }
      if (isWrong) {
        return Colors.red;
      }
    }
    // Sadece seçildiğinde amber border göster
    if (isSelected) {
      return Colors.amber;
    }
    return Colors.white.withOpacity(0.3);
  }

  // Eski sınır rengi hesaplama artık kullanılmıyor (telefon highlight ile değişti)

  Color _getOptionLetterColor(bool isSelected, bool isCorrect, bool isWrong) {
    // Animasyon sırasında doğru/yanlış renkleri göster
    if (_isShowingResult) {
      if (isCorrect) {
        return Colors.green;
      }
      if (isWrong) {
        return Colors.red;
      }
    }
    // Sadece seçildiğinde amber renk göster
    if (isSelected) {
      return Colors.amber;
    }
    return Colors.white.withOpacity(0.3);
  }

  Color _getOptionLetterTextColor(bool isSelected, bool isCorrect, bool isWrong) {
    // Animasyon sırasında doğru/yanlış renkleri göster
    if (_isShowingResult) {
      if (isCorrect || isWrong) {
        return Colors.white;
      }
    }
    // Sadece seçildiğinde siyah renk göster
    if (isSelected) {
      return Colors.black;
    }
    return Colors.white;
  }

  // Seçenek arka plan rengini belirle
  Color _getOptionBackgroundColor(bool isSelected, bool isCorrect, bool isWrong, bool isDisabled, bool isPhoneHighlight, bool isPhoneFinalHighlight) {
    // Pasif şık için yarı saydam gri
    if (isDisabled) {
      return Colors.grey.withOpacity(0.3);
    }
    
    // Telefon joker final highlight efekti (animasyon bittikten sonra)
    if (isPhoneFinalHighlight) {
      return Colors.blue.shade400.withOpacity(0.5); // Kalıcı mavi
    }
    
    // Telefon joker animasyon highlight efekti (dolaşan ışık)
    if (isPhoneHighlight) {
      return Colors.blue.shade400.withOpacity(0.5); // Dolaşan mavi
    }
    
    // Yanlış cevap verildiyse ve doğru cevap gösteriliyorsa
    if (_showCorrectAnswer && isCorrect) {
      print('QuestionCard: Doğru cevap yeşil arka plan ile gösteriliyor - _showCorrectAnswer: $_showCorrectAnswer, isCorrect: $isCorrect');
      return Colors.green.withOpacity(0.2);
    }
    // Seçilen cevap
    if (isSelected) {
      return Colors.amber.withOpacity(0.2);
    }
    return const Color(0xFF1a237e);
  }

  // Seçenek çerçeve rengini belirle
  Color _getOptionBorderColor(bool isSelected, bool isCorrect, bool isWrong, bool isPhoneHighlight, bool isPhoneFinalHighlight, bool isDisabled) {
    // Pasif şık için yarı saydam gri border
    if (isDisabled) {
      return Colors.grey.withOpacity(0.5);
    }
    
    // Telefon joker final highlight efekti (animasyon bittikten sonra)
    if (isPhoneFinalHighlight) {
      return Colors.blue.shade300; // Kalıcı mavi border
    }
    
    // Telefon joker animasyon highlight efekti (dolaşan ışık)
    if (isPhoneHighlight) {
      return Colors.blue.shade300; // Dolaşan mavi border
    }
    
    // Yanlış cevap verildiyse ve doğru cevap gösteriliyorsa
    if (_showCorrectAnswer && isCorrect) {
      print('QuestionCard: Doğru cevap yeşil çerçeve ile gösteriliyor - _showCorrectAnswer: $_showCorrectAnswer, isCorrect: $isCorrect');
      return Colors.green;
    }
    // Seçilen cevap
    if (isSelected) {
      return Colors.amber.withOpacity(0.7);
    }
    return Colors.grey.shade400;
  }

  // Seçenek çerçeve kalınlığını belirle
  double _getOptionBorderWidth(bool isSelected, bool isCorrect, bool isWrong, bool isPhoneHighlight, bool isPhoneFinalHighlight) {
    // Telefon joker final highlight efekti (animasyon bittikten sonra)
    if (isPhoneFinalHighlight) {
      return 6; // Kalıcı border
    }
    
    // Telefon joker animasyon highlight efekti (dolaşan ışık)
    if (isPhoneHighlight) {
      return 6; // Dolaşan border
    }
    
    // Yanlış cevap verildiyse ve doğru cevap gösteriliyorsa
    if (_showCorrectAnswer && isCorrect) {
      return 4;
    }
    // Seçilen cevap
    if (isSelected) {
      return 4;
    }
    return 2;
  }

   bool _shouldShowOption(int index) {
     final isActive = widget.isFiftyFiftyActiveForCurrentQuestion ?? widget.hasUsedFiftyFifty;
     print('QuestionCard: _shouldShowOption($index) - isActive: $isActive, hasUsedFiftyFifty: ${widget.hasUsedFiftyFifty}, isFiftyFiftyActiveForCurrentQuestion: ${widget.isFiftyFiftyActiveForCurrentQuestion}');
     
     if (!isActive) {
       print('QuestionCard: 50:50 aktif değil, tüm şıklar gösteriliyor');
       return true;
     }
     
     // 50:50 joker kullanıldığında sadece doğru cevap ve bir yanlış cevap göster
     if (index == widget.question.correctAnswer) {
       print('QuestionCard: Doğru cevap gösteriliyor: $index');
       return true;
     }
     
     // İlk yanlış cevabı göster (doğru cevap değilse)
     for (int i = 0; i < widget.question.options.length; i++) {
       if (i != widget.question.correctAnswer) {
         final shouldShow = index == i;
         print('QuestionCard: Şık $index gösteriliyor: $shouldShow');
         return shouldShow;
       }
     }
     
     print('QuestionCard: Şık $index gizleniyor');
     return false;
   }

   // Şık pasif mi kontrol et
   bool _isOptionDisabled(int index) {
     // Yanlış cevap seçildiyse ve doğru cevap gösteriliyorsa, doğru cevap pasif olmasın
     if (_showCorrectAnswer && index == widget.question.correctAnswer) {
       return false;
     }
     
     // Oyuncu cevap seçtiyse, seçmediği şıklar pasif olsun
     if (widget.selectedAnswer != null) {
       // Seçilen şık pasif olmasın
       if (index == widget.selectedAnswer) {
         return false;
       }
       // Diğer şıklar pasif olsun
       return true;
     }
     
     // 50:50 joker için şık pasif mi kontrol et
     final isActive = widget.isFiftyFiftyActiveForCurrentQuestion ?? widget.hasUsedFiftyFifty;
     if (!isActive) return false;
     
     // Doğru cevap her zaman aktif
     if (index == widget.question.correctAnswer) return false;
     
     // İlk yanlış cevap aktif, diğerleri pasif
     for (int i = 0; i < widget.question.options.length; i++) {
       if (i != widget.question.correctAnswer) {
         return index != i; // İlk yanlış cevap değilse pasif
       }
     }
     
     return false;
   }

   // Buton rengini belirle
   Color _getButtonColor() {
     if (_isShowingResult) {
       return _isCorrect ? const Color(0xFF00FF00) : Colors.red; // Fosforlu yeşil
     }
     if (_isAnswerConfirmed) {
       return Colors.amber;
     }
     return Colors.amber;
   }

   // Buton metnini belirle
   String _getButtonText() {
     if (_isShowingResult) {
       return _isCorrect ? 'DOĞRU!' : 'YANLIŞ!';
     }
     if (_isAnswerConfirmed) {
       return 'ONAYLANDI';
     }
     return 'ONAYLA';
   }

   // Buton metni rengini belirle
   Color _getButtonTextColor() {
     if (_isShowingResult) {
       return _isCorrect ? Colors.white : Colors.white; // Fosforlu yeşil arka plan için beyaz metin
     }
     if (_isAnswerConfirmed) {
       return Colors.white; // ONAYLANDI için beyaz metin
     }
     return Colors.white; // ONAYLA için beyaz metin
   }

   // Gradyan renk metodları
   Color _getOptionGradientColor1(bool isSelected, bool isCorrect, bool isWrong, bool isDisabled, bool isPhoneHighlight, bool isPhoneFinalHighlight) {
     if (isDisabled) return Colors.grey.withOpacity(0.1);
     if (isPhoneFinalHighlight) return Colors.blue.shade900;
     if (isPhoneHighlight) return Colors.blue.shade900;
     if (_showCorrectAnswer && isCorrect) {
       print('QuestionCard: Doğru cevap yeşil gösteriliyor - _showCorrectAnswer: $_showCorrectAnswer, isCorrect: $isCorrect, index: ${widget.question.options.indexOf(widget.question.options[0])}');
       return Colors.green.shade900;
     }
     if (isSelected && _isShowingResult) {
       // Seçilen şık doğruysa yeşil, yanlışsa kırmızı
       return _isCorrect ? Colors.green.shade900 : Colors.red.shade900;
     }
     if (isSelected) return Colors.amber.shade900;
     return const Color(0xFF0A1428); // Çok koyu lacivert üst
   }

   Color _getOptionGradientColor2(bool isSelected, bool isCorrect, bool isWrong, bool isDisabled, bool isPhoneHighlight, bool isPhoneFinalHighlight) {
     if (isDisabled) return Colors.grey.withOpacity(0.2);
     if (isPhoneFinalHighlight) return Colors.blue.shade700;
     if (isPhoneHighlight) return Colors.blue.shade700;
     if (_showCorrectAnswer && isCorrect) return Colors.green.shade700;
     if (isSelected && _isShowingResult) {
       // Seçilen şık doğruysa yeşil, yanlışsa kırmızı
       return _isCorrect ? Colors.green.shade700 : Colors.red.shade700;
     }
     if (isSelected) return Colors.amber.shade700;
     return const Color(0xFF0D1B2A); // Koyu lacivert orta üst
   }

   Color _getOptionGradientColor3(bool isSelected, bool isCorrect, bool isWrong, bool isDisabled, bool isPhoneHighlight, bool isPhoneFinalHighlight) {
     if (isDisabled) return Colors.grey.withOpacity(0.3);
     if (isPhoneFinalHighlight) return Colors.blue.shade500;
     if (isPhoneHighlight) return Colors.blue.shade500;
     if (_showCorrectAnswer && isCorrect) return Colors.green.shade500;
     if (isSelected && _isShowingResult) {
       // Seçilen şık doğruysa yeşil, yanlışsa kırmızı
       return _isCorrect ? Colors.green.shade500 : Colors.red.shade500;
     }
     if (isSelected) return Colors.amber.shade500;
     return const Color(0xFF1B263B); // Orta lacivert orta alt
   }

   Color _getOptionGradientColor4(bool isSelected, bool isCorrect, bool isWrong, bool isDisabled, bool isPhoneHighlight, bool isPhoneFinalHighlight) {
     if (isDisabled) return Colors.grey.withOpacity(0.4);
     if (isPhoneFinalHighlight) return Colors.blue.shade300;
     if (isPhoneHighlight) return Colors.blue.shade300;
     if (_showCorrectAnswer && isCorrect) return Colors.green.shade300;
     if (isSelected && _isShowingResult) {
       // Seçilen şık doğruysa yeşil, yanlışsa kırmızı
       return _isCorrect ? Colors.green.shade300 : Colors.red.shade300;
     }
     if (isSelected) return Colors.amber.shade300;
     return const Color(0xFF2C3E50); // Açık lacivert alt
   }
 }
