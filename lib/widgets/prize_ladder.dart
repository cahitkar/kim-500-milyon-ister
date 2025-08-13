import 'package:flutter/material.dart';

class PrizeLadder extends StatelessWidget {
  final int currentLevel;
  final int currentPrize;

  const PrizeLadder({
    super.key,
    required this.currentLevel,
    required this.currentPrize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
                     FittedBox(
             fit: BoxFit.scaleDown,
             child: Text(
               'ÖDÜL MERDİVENİ',
               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                 color: Colors.amber,
                 fontWeight: FontWeight.bold,
                 fontSize: 22, // Mevcut boyuttan 2px artırıyorum
               ),
             ),
           ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 13,
              reverse: true,
              itemBuilder: (context, index) {
                final level = 13 - index;
                final prize = _getPrizeForLevel(level);
                final isCurrentLevel = level == currentLevel;
                final isGuaranteed = _isGuaranteedLevel(level);
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4), // 2'den 4'e çıkardım
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  height: 50, // Yüksekliği artırdım
                  decoration: BoxDecoration(
                    color: isCurrentLevel 
                      ? Colors.amber.withOpacity(0.3)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isCurrentLevel 
                      ? Border.all(color: Colors.amber, width: 4) // 2'den 4'e çıkardım
                      : null,
                  ),
                  child: Row(
                    children: [
                      // Seviye numarası
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isCurrentLevel 
                            ? Colors.amber 
                            : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            level.toString(),
                            style: TextStyle(
                              color: isCurrentLevel ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // 12'den 14'e
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                                             // Ödül miktarı
                       Expanded(
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           child: Text(
                             _formatMoney(prize),
                             style: TextStyle(
                               color: isCurrentLevel 
                                 ? Colors.amber 
                                 : Colors.white,
                               fontWeight: isCurrentLevel 
                                 ? FontWeight.bold 
                                 : FontWeight.normal,
                               fontSize: isCurrentLevel ? 16 : 14, // 14'ten 16'ya, 12'den 14'e
                             ),
                           ),
                         ),
                       ),
                      // Garantili işareti
                      if (isGuaranteed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // 10'dan 12'ye
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getPrizeForLevel(int level) {
    switch (level) {
      case 1: return 5000;
      case 2: return 7500;
      case 3: return 15000;
      case 4: return 30000;
      case 5: return 45000;
      case 6: return 60000;
      case 7: return 80000;
      case 8: return 100000;
      case 9: return 120000;
      case 10: return 150000;
      case 11: return 200000;
      case 12: return 300000;
      case 13: return 5000000;
      default: return 0;
    }
  }

  bool _isGuaranteedLevel(int level) {
    return level == 5 || level == 10 || level == 13;
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return amount.toString();
    }
  }
}
