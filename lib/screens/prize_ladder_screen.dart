import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class PrizeLadderScreen extends StatefulWidget {
  final int durationSeconds;
  const PrizeLadderScreen({super.key, this.durationSeconds = 3});

  @override
  State<PrizeLadderScreen> createState() => _PrizeLadderScreenState();
}

class _PrizeLadderScreenState extends State<PrizeLadderScreen> {
  @override
  void initState() {
    super.initState();
    // Belirtilen süre > 0 ise otomatik olarak oyun sayfasına dön
    if (widget.durationSeconds > 0) {
      Future.delayed(Duration(seconds: widget.durationSeconds), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF2C3E50),
              Color(0xFF34495E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const GameScreen()),
                        );
                      },
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close,
                            color: Color(0xFF0D1B2A),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Para tablosu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22, // 20'den 22'ye
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 40), // Dengeleme için
                  ],
                ),
              ),
              
              // Ödül merdiveni - tüm satırları tek ekrana sığdır
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Consumer<GameProvider>(
                    builder: (context, gameProvider, child) {
                      final items = List.generate(13, (i) => 13 - i);
                      return Column(
                        children: items.map((level) {
                          final prize = _getPrizeForLevel(level);
                          final isCurrentLevel = level == gameProvider.currentLevel;
                          final isGuaranteed = _isGuaranteedLevel(level);
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: isCurrentLevel
                                      ? [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                          Colors.orange.shade700,
                                        ]
                                      : (level <= 6
                                          ? [
                                              Colors.green.shade400,
                                              Colors.green.shade600,
                                              Colors.green.shade700,
                                            ]
                                          : [
                                              const Color(0xFF1a237e),
                                              const Color(0xFF0d47a1),
                                              const Color(0xFF01579b),
                                            ]),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrentLevel ? Colors.orange.shade300 : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCurrentLevel
                                        ? Colors.orange.withOpacity(0.25)
                                        : (level <= 6
                                            ? Colors.green.withOpacity(0.15)
                                            : const Color(0xFF1a237e).withOpacity(0.15)),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Seviye numarası (daha kompakt)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isCurrentLevel
                                            ? [Colors.white, Colors.grey.shade100]
                                            : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrentLevel ? Colors.orange.shade300 : Colors.grey.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        child: Text(
                                          level.toString(),
                                          style: TextStyle(
                                            color: isCurrentLevel ? Colors.orange : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Ödül miktarı (FittedBox ile ölçeklenir)
                                  Expanded(
                                    child: FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        gameProvider.formatMoney(prize),
                                        style: TextStyle(
                                          color: isCurrentLevel
                                              ? Colors.white
                                              : (isGuaranteed ? Colors.yellow : Colors.white),
                                          fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Garantili işareti (daha kompakt)
                                  if (isGuaranteed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.yellow.shade300, Colors.yellow.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.yellow.shade700, width: 1.5),
                                      ),
                                      child: const Text(
                                        'G',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              
              // Alt bilgi kısmı kaldırıldı
            ],
          ),
        ),
      ),
    );
  }

  int _getPrizeForLevel(int level) {
    switch (level) {
      case 1: return 5000;
      case 2: return 10000;
      case 3: return 30000;
      case 4: return 90000;
      case 5: return 200000;
      case 6: return 400000;
      case 7: return 600000;
      case 8: return 800000;
      case 9: return 1000000;
      case 10: return 1500000;
      case 11: return 2000000;
      case 12: return 3000000;
      case 13: return 5000000;
      default: return 0;
    }
  }

  bool _isGuaranteedLevel(int level) {
    return level == 5 || level == 10 || level == 13;
  }

  // Para formatlamayı GameProvider'daki formatMoney ile yapıyoruz
}
