import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/question_card.dart';
import '../widgets/joker_buttons.dart';
import '../widgets/audience_dialog.dart';
import '../services/audio_service.dart';
import 'prize_ladder_screen.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showPrizeLadder = false;

  @override
  void initState() {
    super.initState();
    // İlk açılışta ödül merdiveni gösterme - doğrudan soru sayfasına git
    
    // Seyirci joker dialog callback'ini ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // İlk açılışta olası "tık" kısa efektlerini önlemek için kısa bir süre bastır
      AudioService().suppressShortEffects(const Duration(milliseconds: 1000));
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.setAudienceDialogCallback(_showAudienceDialog);
      
        // Bekletme müziğini çal
      try {
        print('GameScreen: Önce tüm sesler durduruluyor...');
          // Oyun ekranı açılırken tık sesini tamamen önlemek için bekletme niyeti kapalı durdur
          await AudioService().stopAllSounds(preserveWaitingLoop: false);
        await Future.delayed(const Duration(milliseconds: 100));
        print('GameScreen: Bekletme müziği başlatılıyor...');
        await AudioService().playWaiting(context: context);
        print('GameScreen: Bekletme müziği başarıyla başlatıldı');
      } catch (e) {
        print('GameScreen: Bekletme müziği başlatılamadı: $e');
      }
      
      // İlk soru için süre sistemini başlat
      if (gameProvider.currentQuestion != null) {
        gameProvider.startTimer();
      }
    });
  }

  // Seyirci joker dialog'unu goster
  void _showAudienceDialog(BuildContext context, List<String> options, int correctAnswer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudienceDialog(
        options: options,
        correctAnswer: correctAnswer,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Seyirci joker kullan
  void _useAudienceWithDialog(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentQuestion != null) {
      // Önce useAudience fonksiyonunu çağır (kronometreyi durdurur)
      gameProvider.useAudience();
      
      // Sonra dialog'u göster
      _showAudienceDialog(
        context,
        gameProvider.currentQuestion!.options,
        gameProvider.currentQuestion!.correctAnswer,
      );
    }
  }

  void _showPrizeLadderForNewQuestion() {
    setState(() {
      _showPrizeLadder = true;
    });
    
    // 3 saniye sonra ödül merdivenini kapat
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showPrizeLadder = false;
        });
      }
    });
  }

  void _showCashOutDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a237e),
        title: const Text(
          'Çekil',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Şu anki ödülünüzü çekmek istediğinizden emin misiniz?\n\n${gameProvider.formatMoney(gameProvider.currentPrize)}',
          style: const TextStyle(color: Colors.white, fontSize: 18), // 16'dan 18'e
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Çekil işlemi - oyunu bitir ve ödülü ver
              gameProvider.cashOut();
            },
            child: const Text(
              'Çekil',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              const Color(0xFF050A14), // En koyu lacivert (kenarlar)
              const Color(0xFF0A1428), // Çok koyu lacivert
              const Color(0xFF0D1B2A), // Koyu lacivert
              const Color(0xFF1B263B), // Orta lacivert
              const Color(0xFF2C3E50), // Açık lacivert (merkez)
              const Color(0xFF1B263B), // Orta lacivert
              const Color(0xFF0D1B2A), // Koyu lacivert
              const Color(0xFF0A1428), // Çok koyu lacivert
              const Color(0xFF050A14), // En koyu lacivert (kenarlar)
            ],
            stops: [0.0, 0.1, 0.2, 0.35, 0.5, 0.65, 0.8, 0.9, 1.0],
          ),
        ),
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              if (gameProvider.isGameOver) {
                return _buildGameOverScreen(context, gameProvider);
              }
              
              // Ödül merdiveni gösteriliyorsa
              if (_showPrizeLadder) {
                return PrizeLadderScreen();
              }
              
              return Column(
                children: [
                  // Üst bar
                  _buildTopBar(context, gameProvider),
                  
                  // Ana içerik
                  Expanded(
                    child: Column(
                      children: [
                        // Soru kartı
                        if (gameProvider.currentQuestion != null)
                           Expanded(
                            child: QuestionCard(
                              key: ValueKey(gameProvider.currentQuestion!.question),
                              question: gameProvider.currentQuestion!,
                              selectedAnswer: gameProvider.selectedAnswer,
                              onAnswerSelected: gameProvider.selectAnswer,
                               onAnswerConfirmed: () async {
                                 // Cevabı kontrol et
                                 await gameProvider.checkAnswer();
                                 if (gameProvider.isUntimedMode) {
                                   // Süresiz mod: bekleme yok – doğruysa ödül merdivenini göster ama akışı bekletme
                                   if (!gameProvider.isGameOver && gameProvider.currentLevel > 1) {
                                     setState(() { _showPrizeLadder = true; });
                                     // Akışı bekletmeden kapatmak için zamanlayıcı
                                     Future.delayed(const Duration(milliseconds: 700), () {
                                       if (mounted) {
                                         setState(() { _showPrizeLadder = false; });
                                       }
                                     });
                                   }
                                 } else if (!gameProvider.isGameOver && !gameProvider.isWon) {
                                   // Zamanlı mod: mevcut akış (3 sn)
                                   _showPrizeLadderForNewQuestion();
                                 }
                               },
                              hasUsedFiftyFifty: gameProvider.hasUsedFiftyFifty,
                              isFiftyFiftyActiveForCurrentQuestion: gameProvider.isFiftyFiftyActiveForCurrentQuestion,
                              isPhoneHintActive: gameProvider.isPhoneHintActive,
                              phoneHintTargetIndex: gameProvider.phoneHintTargetIndex,
                              phoneHighlightIndex: gameProvider.phoneHighlightIndex,
                               autoConfirmOnSelect: gameProvider.isUntimedMode,
                            ),
                          )
                        else
                          // Soru yüklenene kadar loading göster
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.amber,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Soru yükleniyor...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Joker butonları
                        JokerButtons(
                          onFiftyFifty: gameProvider.useFiftyFifty,
                          onAudience: () => _useAudienceWithDialog(context),
                          onPhone: gameProvider.usePhone,
                          hasUsedFiftyFifty: gameProvider.hasUsedFiftyFifty,
                          hasUsedAudience: gameProvider.hasUsedAudience,
                          hasUsedPhone: gameProvider.hasUsedPhone,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Üst satır - Para ikonu ve TL butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Para ikonu
              GestureDetector(
                onTap: () {
                  // Çekil fonksiyonu
                  _showCashOutDialog(context, gameProvider);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a237e),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              
              // TL butonu
              GestureDetector(
                onTap: () {
                  // Para ödül merdiveni sayfasını aç
                  // Kısa efekt patlamasını önlemek için kısa efektleri geçici sustur
                  AudioService().suppressShortEffects(const Duration(milliseconds: 400));
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrizeLadderScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a237e),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        offset: const Offset(0, -2),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'TL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Soru sayacı
          Text(
            'Soru ${gameProvider.currentLevel} / 13',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Ödül miktarı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a237e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  offset: const Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  offset: const Offset(0, -3),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              gameProvider.formatMoney(gameProvider.currentPrize),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameProvider gameProvider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a237e),
            Color(0xFF0d47a1),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildAnimatedIcon(gameProvider.isWon),
              const SizedBox(height: 32),
              Text(
                gameProvider.isWon ? 'Tebrikler!' : 'Oyun Bitti',
                style: TextStyle(
                  color: gameProvider.isWon ? Colors.amber : Colors.red,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: gameProvider.isWon ? Colors.amber : Colors.red,
                    width: 2,
                  ),
                ),
                child: Text(
                  gameProvider.isWon 
                    ? '${gameProvider.formatMoney(gameProvider.currentPrize)} kazandınız!'
                    : 'Garantili ödülünüz: ${gameProvider.formatMoney(gameProvider.guaranteedPrize)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AudioService().playButtonClick(context: context);
                    gameProvider.startGame(untimed: gameProvider.isUntimedMode);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.amber.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Tekrar Oyna',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AudioService().playButtonClick(context: context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: const Text(
                    'Ana Sayfa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isWon) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Transform.rotate(
            angle: isWon ? 0 : (0.1 * (1 - value)) * (value % 2 == 0 ? 1 : -1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              child: Icon(
                isWon ? Icons.celebration : Icons.sentiment_dissatisfied,
                size: 80,
                color: isWon ? Colors.amber : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
