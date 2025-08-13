import 'package:flutter/material.dart';
import 'dart:math';
import '../services/audio_service.dart';

class AudienceDialog extends StatefulWidget {
  final List<String> options;
  final int correctAnswer;
  final VoidCallback onClose;

  const AudienceDialog({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.onClose,
  });

  @override
  State<AudienceDialog> createState() => _AudienceDialogState();
}

class _AudienceDialogState extends State<AudienceDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _barAnimationController;
  late Animation<double> _fadeAnimation;
  List<double> _votePercentages = [];
  List<double> _animatedPercentages = [];
  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();
    _initializeDialog();
  }

  Future<void> _initializeDialog() async {
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _barAnimationController = AnimationController(
      duration: const Duration(seconds: 7), // Bekletme sesi süresi kadar
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _generateVotePercentages();
    _animatedPercentages = List.filled(_votePercentages.length, 0.0);
    
    // Dialog hemen açılsın
    _animationController.forward();
    
    // Grafik animasyonunu başlat (bekletme müziği game_screen'de çalıyor)
    if (mounted) {
      _barAnimationController.forward();
    }
    
    // 10 saniye sonra dialog'u kapat
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _generateVotePercentages() {
    final random = Random();
    final correctAnswer = widget.correctAnswer;
    
    // Doğru cevap için 45-80 arası rastgele oran
    double correctPercentage = 45.0 + random.nextDouble() * 35.0; // 45-80 arası
    
    // Kalan oranı diğer şıklar arasında dağıt
    double remainingPercentage = 100.0 - correctPercentage;
    List<double> wrongPercentages = [];
    
    for (int i = 0; i < widget.options.length; i++) {
      if (i != correctAnswer) {
        // Her yanlış şık için 0-15 arası rastgele oran
        double randomPercentage = random.nextDouble() * 15.0;
        wrongPercentages.add(randomPercentage);
      }
    }
    
    // Yanlış şıkların toplamını hesapla
    double totalWrong = wrongPercentages.fold(0.0, (sum, item) => sum + item);
    
    // Yanlış şıkları normalize et (kalan oranı dağıtacak şekilde)
    for (int i = 0; i < wrongPercentages.length; i++) {
      wrongPercentages[i] = (wrongPercentages[i] / totalWrong) * remainingPercentage;
    }
    
    // Final oranları oluştur
    _votePercentages = List.filled(widget.options.length, 0.0);
    int wrongIndex = 0;
    for (int i = 0; i < widget.options.length; i++) {
      if (i == correctAnswer) {
        _votePercentages[i] = correctPercentage;
      } else {
        _votePercentages[i] = wrongPercentages[wrongIndex];
        wrongIndex++;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _barAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: const Color(0xFF1a237e), // Koyu mavi arka plan
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Text(
                'SEYİRCİ OYLAMASI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Yüzde değerleri (üstte)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(widget.options.length, (index) {
                  final percentage = _votePercentages[index];
                  return AnimatedBuilder(
                    animation: CurvedAnimation(
                      parent: _barAnimationController,
                      curve: Curves.easeInOut, // Daha yumuşak animasyon
                    ),
                    builder: (context, child) {
                      final animatedValue = _barAnimationController.value;
                      final animatedPercentage = percentage * animatedValue;
                      return Text(
                        '%${animatedPercentage.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  );
                }),
              ),
              
              const SizedBox(height: 20),
              
              // Animasyonlu bar chart
              Container(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.options.length, (index) {
                    final percentage = _votePercentages[index];
                    final isCorrect = index == widget.correctAnswer;
                    
                    return Column(
                      children: [
                        // Bar chart
                        Expanded(
                          child: AnimatedBuilder(
                            animation: CurvedAnimation(
                              parent: _barAnimationController,
                              curve: Curves.easeInOut, // Daha yumuşak animasyon
                            ),
                            builder: (context, child) {
                              final animatedValue = _barAnimationController.value;
                              final animatedPercentage = percentage * animatedValue;
                              final maxHeight = 160.0;
                              final barHeight = (animatedPercentage / 100) * maxHeight;
                              
                              return Container(
                                width: 40,
                                child: Column(
                                  children: [
                                    // Boşluk (bar'ın yüksekliğine göre)
                                    Expanded(
                                      child: Container(
                                        height: maxHeight - barHeight,
                                      ),
                                    ),
                                    // Bar
                                    Container(
                                      width: 40,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.orange[300]!,
                                            Colors.orange[600]!,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Harf etiketi
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color: isCorrect ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Kalan süre
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final remainingSeconds = (10 * (1 - _animationController.value)).round();
                  return Text(
                    'Kalan süre: $remainingSeconds saniye',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
