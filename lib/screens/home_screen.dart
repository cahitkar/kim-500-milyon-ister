import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Seçilen modu işaretlemek için: 'classic' veya 'untimed'
  String _selectedMode = '';
  @override
  void initState() {
    super.initState();
    // Ana sayfa açıldığında giriş müziğini çal
    _playIntroMusic();
  }

  Future<void> _playIntroMusic() async {
    try {
      print('HomeScreen: Önce tüm sesler durdurulacak');
      final audioService = AudioService();
      
      // Önce tüm sesleri durdur
      await audioService.stopAllSounds();
      
      // Kısa bir bekleme
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('HomeScreen: Giriş müziği çalınacak');
      await audioService.playIntro();
      print('HomeScreen: Giriş müziği başarıyla çalındı');
    } catch (e) {
      print('HomeScreen: Giriş müziği çalınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A), // En koyu mavi (sol üst)
              Color(0xFF1B263B), // Orta koyu mavi
              Color(0xFF2C3E50), // Orta mavi (merkez)
              Color(0xFF1B263B), // Orta koyu mavi
              Color(0xFF0D1B2A), // En koyu mavi (sağ alt)
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Click sesi çal
                        AudioService().playButtonClick(context: context);
                        // Ayarlar ekranına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Click sesi çal
                        AudioService().playButtonClick(context: context);
                        _showRules(context);
                      },
                      icon: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'i',
                            style: TextStyle(
                              color: Color(0xFF1a237e),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Başlık: MOD SEÇİN
              const Text(
                'MOD SEÇİN',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Oyun modu başlığı (tıklanabilir - oyunu başlat)
              GestureDetector(
                onTap: () async {
                  try {
                    // Oyun başlangıcında tık sesi olmasın
                    final audio = AudioService();
                    audio.suppressShortEffects(const Duration(milliseconds: 600));
                    await audio.stopAllSounds(preserveWaitingLoop: false);

                    final gameProvider = Provider.of<GameProvider>(context, listen: false);
                    // Seçimi yeşil göstermek için state'i güncelle
                    if (mounted) {
                      setState(() { _selectedMode = 'classic'; });
                    }
                    gameProvider.startGame();

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Oyun başlatılırken bir hata oluştu. Lütfen tekrar deneyin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Klasik',
                  style: TextStyle(
                    color: _selectedMode == 'classic' ? Colors.green : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              // Süresiz modu başlığı (tıklanabilir - süresiz oyun başlat)
              GestureDetector(
                onTap: () async {
                  try {
                    final audio = AudioService();
                    audio.suppressShortEffects(const Duration(milliseconds: 600));
                    await audio.stopAllSounds(preserveWaitingLoop: false);

                    final gameProvider = Provider.of<GameProvider>(context, listen: false);
                    // Seçimi yeşil göstermek için state'i güncelle
                    if (mounted) {
                      setState(() { _selectedMode = 'untimed'; });
                    }
                    gameProvider.startGame(untimed: true);

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const GameScreen()),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Oyun başlatılırken bir hata oluştu. Lütfen tekrar deneyin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Süresiz',
                  style: TextStyle(
                    color: _selectedMode == 'untimed' ? Colors.green : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Ana oyun detayları kutusu
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF34495E), // Açık mavi (kenarlar)
                      const Color(0xFF1a237e), // Koyu mavi (merkez)
                      const Color(0xFF34495E), // Açık mavi (kenarlar)
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade400, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade400.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Ödül gösterimi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber,
                            Colors.amber.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Text(
                        '5.000.000 TL',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Oyun açıklaması
                    const Text(
                      '13 SORU - 3 JOKER HAKKI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20, // 18'den 20'ye
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Joker ikonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildJokerIcon('1/2', Icons.horizontal_split),
                        _buildJokerIcon('', Icons.bar_chart),
                        _buildJokerIcon('', Icons.person_outline),
                        _buildJokerIcon('', Icons.home),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // İstatistik kutuları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0D1B2A), // Koyu gece mavisi (sol üst)
                              const Color(0xFF2C3E50), // Açık gece mavisi (merkez - parlak)
                              const Color(0xFF0D1B2A), // Koyu gece mavisi (sağ alt)
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade400,
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade400.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'OYUNLAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14, // 12'den 14'e
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22, // 20'den 22'ye
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3E2723), // Koyu kahve (sol üst)
                              const Color(0xFF5D4037), // Açık kahve (merkez - parlak)
                              const Color(0xFF3E2723), // Koyu kahve (sağ alt)
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber,
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ZAFERLER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14, // 12'den 14'e
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Consumer<GameProvider>(
                              builder: (context, gameProvider, child) {
                                return Text(
                                  gameProvider.highScore > 0 ? '1' : '0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26, // 24'ten 26'ya
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // "Oyunu başlat" butonu kaldırıldı
              
              const Spacer(),
              
              // Alt navigasyon barı
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavIcon(Icons.home, 'Ana Sayfa'),
                    _buildClickableNavIcon(Icons.shop, 'Mağaza', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StoreScreen()),
                      );
                    }),
                    _buildNavIcon(Icons.close, ''),
                    _buildClickableNavIcon(Icons.pie_chart, 'İstatistik', () => _showStatistics(context)),
                    _buildClickableNavIcon(Icons.people, 'Liderler', () => _showLeaderboard(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJokerIcon(String text, IconData icon) {
    // Ana sayfa ikonu için özel stil
    bool isHomeIcon = icon == Icons.home;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isHomeIcon ? Colors.amber : Colors.blue.shade400, 
          width: isHomeIcon ? 3 : 2
        ),
        boxShadow: [
          BoxShadow(
            color: isHomeIcon ? Colors.amber.withOpacity(0.4) : Colors.blue.shade400.withOpacity(0.2),
            blurRadius: isHomeIcon ? 8 : 6,
            spreadRadius: isHomeIcon ? 2 : 1,
          ),
        ],
      ),
      child: Center(
        child: text.isNotEmpty
            ? Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : Icon(
                icon,
                color: isHomeIcon ? Colors.amber : Colors.white,
                size: isHomeIcon ? 28 : 24,
              ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12, // 10'dan 12'ye
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClickableNavIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        AudioService().playButtonClick(context: context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a237e),
        title: const Text(
          'Oyun Kuralları',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '• 13 seviyeden oluşan bilgi yarışması\n'
                '• Her seviyede 4 şıklı soru\n'
                '• Doğru cevap verince bir sonraki seviyeye geç\n'
                '• Yanlış cevap verince oyun biter\n'
                '• 3 joker hakkın var:\n'
                '  - 50:50: İki yanlış şıkkı ele\n'
                '  - Seyirci: Seyircinin oyu\n'
                '  - Telefon: Bir arkadaşını ara\n'
                '• Garantili ödüller:\n'
                '  - 5. seviye: 16.000 TL\n'
                '  - 10. seviye: 500.000 TL\n'
                '  - 13. seviye: 5.000.000 TL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18, // 16'dan 18'e
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Click sesi çal
              AudioService().playButtonClick(context: context);
              Navigator.pop(context);
            },
            child: const Text(
              'Anladım',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a237e),
        title: const Text(
          'İstatistikler',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem('Toplam Oyun', '1'),
                  _buildStatItem('Kazanılan Oyun', gameProvider.highScore > 0 ? '1' : '0'),
                  _buildStatItem('En Yüksek Ödül', gameProvider.formatMoney(gameProvider.highScore)),
                  _buildStatItem('Başarı Oranı', gameProvider.highScore > 0 ? '%100' : '%0'),
                  _buildStatItem('Ortalama Süre', '2 dakika'),
                  _buildStatItem('En Çok Kullanılan Joker', '50:50'),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService().playButtonClick(context: context);
              Navigator.pop(context);
            },
            child: const Text(
              'Kapat',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a237e),
        title: const Text(
          'Lider Tablosu',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLeaderItem(1, 'Ahmet Yılmaz', '5.000.000 TL', true),
              _buildLeaderItem(2, 'Fatma Demir', '500.000 TL', false),
              _buildLeaderItem(3, 'Mehmet Kaya', '16.000 TL', false),
              _buildLeaderItem(4, 'Ayşe Özkan', '16.000 TL', false),
              _buildLeaderItem(5, 'Ali Veli', '16.000 TL', false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService().playButtonClick(context: context);
              Navigator.pop(context);
            },
            child: const Text(
              'Kapat',
              style: TextStyle(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderItem(int rank, String name, String prize, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.amber.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentUser ? Colors.amber : Colors.grey.shade600,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rank == 1 ? Colors.amber : Colors.grey.shade600,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rank == 1 ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isCurrentUser ? Colors.amber : Colors.white,
                fontSize: 16,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            prize,
            style: TextStyle(
              color: isCurrentUser ? Colors.amber : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
