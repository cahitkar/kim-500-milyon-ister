import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../services/audio_service.dart';

class JokerButtons extends StatelessWidget {
  final VoidCallback onFiftyFifty;
  final VoidCallback onAudience;
  final VoidCallback onPhone;
  final bool hasUsedFiftyFifty;
  final bool hasUsedAudience;
  final bool hasUsedPhone;

  const JokerButtons({
    super.key,
    required this.onFiftyFifty,
    required this.onAudience,
    required this.onPhone,
    required this.hasUsedFiftyFifty,
    required this.hasUsedAudience,
    required this.hasUsedPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildJokerButton(
            '1/2',
            Icons.horizontal_split,
            onFiftyFifty,
            hasUsedFiftyFifty,
            context,
          ),
          _buildJokerButton(
            '',
            Icons.bar_chart,
            onAudience,
            hasUsedAudience,
            context,
          ),
          _buildJokerButton(
            '',
            Icons.person_outline,
            onPhone,
            hasUsedPhone,
            context,
          ),
          _buildJokerButton(
            '',
            Icons.home,
            () {
              // Ana sayfaya dön
              AudioService().playButtonClick(context: context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            false,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildJokerButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    bool isUsed,
    BuildContext context,
  ) {
    // Ana sayfa ikonu için özel stil
    bool isHomeIcon = icon == Icons.home;
    
    // Joker türünü belirle
    bool isAudienceJoker = icon == Icons.bar_chart;
    bool isFiftyFiftyJoker = icon == Icons.horizontal_split;
    bool isPhoneJoker = icon == Icons.person_outline;
    
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: isHomeIcon ? Colors.transparent : (isUsed ? Colors.grey.shade700 : const Color(0xFF1a237e)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHomeIcon ? Colors.blue.shade400 : (isUsed ? Colors.grey.shade500 : Colors.grey.shade400),
          width: isHomeIcon ? 2 : 2,
        ),
        boxShadow: isHomeIcon ? [
          BoxShadow(
            color: Colors.blue.shade400.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : isUsed ? [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUsed ? null : () {
            // Ana sayfa ikonu değilse ses çal
            if (icon != Icons.home) {
              AudioService().playJoker(context: context);
            }
            onPressed();
          },
          borderRadius: BorderRadius.circular(20),
          child: Tooltip(
            message: isUsed ? 'Bu joker zaten kullanıldı' : _getJokerTooltip(icon),
            child: Center(
              child: text.isNotEmpty
                  ? Text(
                      text,
                      style: TextStyle(
                        color: isUsed ? Colors.grey.shade400 : Colors.white,
                        fontSize: 18, // 16'dan 18'e
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(
                      icon,
                      color: isUsed ? Colors.grey.shade400 : (isHomeIcon ? Colors.blue.shade400 : Colors.white),
                      size: isHomeIcon ? 24 : 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _getJokerTooltip(IconData icon) {
    switch (icon) {
      case Icons.horizontal_split:
        return '50:50 - İki yanlış şıkkı ele';
      case Icons.bar_chart:
        return 'Seyirci - Seyircinin oyu';
      case Icons.person_outline:
        return 'Telefon - Bir arkadaşını ara';
      case Icons.home:
        return 'Ana Sayfa';
      default:
        return 'Joker';
    }
  }
}
