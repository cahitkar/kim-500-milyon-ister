import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF2C3E50),
              Color(0xFF1B263B),
              Color(0xFF0D1B2A),
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
                  children: [
                    IconButton(
                      onPressed: () {
                        AudioService().playButtonClick(context: context);
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Ayarlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSection(
                          'Ses ve Titreşim',
                          [
                            _buildSwitchTile(
                              'Ses Efektleri',
                              'Oyun seslerini aç/kapat',
                              Icons.volume_up,
                              settings.soundEnabled,
                              (value) async {
                                final audio = AudioService();
                                await audio.setMuted(!value);
                                settings.soundEnabled = value;
                              },
                              context,
                            ),
                            _buildSwitchTile(
                              'Titreşim',
                              'Telefon titreşimini aç/kapat',
                              Icons.vibration,
                              settings.vibrationEnabled,
                              (value) => settings.vibrationEnabled = value,
                              context,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildSection(
                          'Oyun Ayarları',
                          [
                            _buildSwitchTile(
                              'Zamanlayıcı',
                              'Soru süresini göster',
                              Icons.timer,
                              settings.showTimer,
                              (value) => settings.showTimer = value,
                              context,
                            ),
                            _buildSwitchTile(
                              'İpuçları',
                              'Joker ipuçlarını göster',
                              Icons.lightbulb,
                              settings.showHints,
                              (value) => settings.showHints = value,
                              context,
                            ),
                            _buildDropdownTile(
                              'Zorluk Seviyesi',
                              'Oyun zorluğunu seç',
                              Icons.speed,
                              settings.difficulty,
                              ['kolay', 'normal', 'zor'],
                              (value) => settings.difficulty = value,
                              context,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildSection(
                          'Genel Ayarlar',
                          [
                            _buildSwitchTile(
                              'Otomatik Kaydet',
                              'Oyun ilerlemesini otomatik kaydet',
                              Icons.save,
                              settings.autoSave,
                              (value) => settings.autoSave = value,
                              context,
                            ),
                            _buildSwitchTile(
                              'İstatistikler',
                              'Oyun istatistiklerini göster',
                              Icons.bar_chart,
                              settings.showStatistics,
                              (value) => settings.showStatistics = value,
                              context,
                            ),
                            _buildDropdownTile(
                              'Dil',
                              'Uygulama dilini seç',
                              Icons.language,
                              settings.language,
                              ['tr', 'en'],
                              (value) => settings.language = value,
                              context,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Kullanılan soruları sıfırla butonu
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              AudioService().playButtonClick(context: context);
                              _showResetQuestionsDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Kullanılan Soruları Sıfırla',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Ayarları sıfırla butonu
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              AudioService().playButtonClick(context: context);
                              _showResetDialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Ayarları Sıfırla',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade400.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    BuildContext context,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          AudioService().playButtonClick(context: context);
          onChanged(newValue);
        },
        activeColor: Colors.amber,
        activeTrackColor: Colors.amber.withOpacity(0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String) onChanged,
    BuildContext context,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      trailing: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return DropdownButton<String>(
            value: value,
            onChanged: (newValue) {
              if (newValue != null) {
                AudioService().playButtonClick(context: context);
                onChanged(newValue);
              }
            },
            dropdownColor: const Color(0xFF1a237e),
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  _getDisplayText(option),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _getDisplayText(String value) {
    switch (value) {
      case 'kolay':
        return 'Kolay';
      case 'normal':
        return 'Normal';
      case 'zor':
        return 'Zor';
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      default:
        return value;
    }
  }

  void _showResetQuestionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a237e),
        title: const Text(
          'Kullanılan Soruları Sıfırla',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tüm kullanılan sorular sıfırlanacak. Yeni oyun başlattığınızda tüm sorular tekrar sorulabilir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService().playButtonClick();
              Navigator.pop(context);
            },
            child: const Text(
              'İptal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              AudioService().playButtonClick();
              final gameProvider = Provider.of<GameProvider>(context, listen: false);
              await gameProvider.resetUsedQuestions();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kullanılan sorular sıfırlandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Sıfırla',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a237e),
        title: const Text(
          'Ayarları Sıfırla',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tüm ayarlar varsayılan değerlerine sıfırlanacak. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioService().playButtonClick();
              Navigator.pop(context);
            },
            child: const Text(
              'İptal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              AudioService().playButtonClick();
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              await settings.resetSettings();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ayarlar sıfırlandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Sıfırla',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
