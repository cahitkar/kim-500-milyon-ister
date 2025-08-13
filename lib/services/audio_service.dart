import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  AudioService._internal() {
    _initializeAudioPlayer();
  }

  // Tek AudioPlayer kullan
  late AudioPlayer _audioPlayer;
  bool _isMuted = false;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _keepWaitingLoop = false; // bekletme.mp3 sürekli çalsın mı?
  DateTime? _lastEffectPlayedAt; // kısa efektler için tekrar engelleme
  String? _lastEffectFileName;
  DateTime? _shortEffectsSuppressedUntil; // geçici olarak kısa efektleri sustur
  String? _currentSoundFile; // o an çalan dosya

  // Ses dosyaları için sabitler
  static const String _correctAnswerSound = 'correct.mp3';
  static const String _wrongAnswerSound = 'wrong.mp3';
  static const String _levelUpSound = 'applause.mp3';
  static const String _gameOverSound = 'warning.mp3';
  static const String _jokerSound = 'button_click.mp3';
  static const String _buttonClickSound = 'button_click.mp3';
  static const String _thinkingSound = 'thinking.mp3';
  static const String _tensionSound = 'tension.mp3';
  static const String _waitingSound = 'bekletme.mp3';
  static const String _phoneSound = 'telefon.mp3';
  static const String _countdownSound = 'gerisay.mp3';
  static const String _warningSound = 'warning.mp3';
  static const String _introSound = 'giris.mp3';

  // AudioPlayer'ı başlat
  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      
      // Mobil platformlar için ek ayarlar
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.setVolume(0.8); // Ses seviyesini artır
        
        // Ses durumu dinleyicisi ekle
        _audioPlayer.onPlayerStateChanged.listen((state) async {
          _isPlaying = state == PlayerState.playing;
          print('Ses durumu değişti: $state');
          // Sadece gerçekten bekletme müziği çalıyorsa ve beklenmedik şekilde durduysa tekrar başlat
          if ((_keepWaitingLoop) && (_currentSoundFile == _waitingSound) && (state == PlayerState.stopped || state == PlayerState.completed)) {
            try {
              print('Bekleme müziği yeniden başlatılıyor (auto-loop)');
              await _audioPlayer.setReleaseMode(ReleaseMode.loop);
              await _audioPlayer.setVolume(0.7);
              await _audioPlayer.play(AssetSource('sounds/$_waitingSound'));
              _currentSoundFile = _waitingSound;
            } catch (e) {
              print('Bekleme müziği auto-loop başlatılamadı: $e');
            }
          }
        });
      }
      
      _isInitialized = true;
      final platform = kIsWeb ? 'Web' : Platform.operatingSystem;
      print('AudioService başarıyla başlatıldı (Platform: $platform)');
    } catch (e) {
      print('AudioService başlatılamadı: $e');
    }
  }

  // Ayarlardan ses açık mı?
  Future<bool> isSoundEnabled({BuildContext? context}) async {
    try {
      if (context != null) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        return settings.soundEnabled;
      }
    } catch (_) {}
    try {
      // Context yoksa SharedPreferences üzerinden oku
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('soundEnabled') ?? true;
    } catch (_) {
      return true;
    }
  }

  // Ses çalma yardımcı fonksiyonu
  Future<void> _playSound(String soundFile, double volume, {BuildContext? context}) async {
    // Kısa efektler (tıklama/joker) için hızlı tekrarı engelle
    final now = DateTime.now();
    final isShortEffect = soundFile == _buttonClickSound || soundFile == _jokerSound;
    // Geçici susturma penceresi
    if (isShortEffect && _shortEffectsSuppressedUntil != null && now.isBefore(_shortEffectsSuppressedUntil!)) {
      final remain = _shortEffectsSuppressedUntil!.difference(now).inMilliseconds;
      print('Kısa efektler geçici olarak susturuldu ($remain ms kaldı): $soundFile atlandı');
      return;
    }
    if (isShortEffect && _lastEffectFileName == soundFile && _lastEffectPlayedAt != null) {
      final ms = now.difference(_lastEffectPlayedAt!).inMilliseconds;
      if (ms < 500) { // bir tık daha toleranslı debounce
        print('Aynı kısa efekt çok hızlı tetiklendi ($soundFile, ${ms}ms) – atlanıyor');
        return;
      }
    }

    // Ayarlardan ses durumunu kontrol et
    bool shouldPlay = true;
    if (context != null) {
      try {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        shouldPlay = settings.soundEnabled;
      } catch (e) {
        print('Ayarlar kontrol edilemedi: $e');
        shouldPlay = true; // Hata durumunda sesi çal
      }
    }
    
    if (_isMuted || !shouldPlay) {
      print('Ses kapalı, $soundFile çalınmayacak');
      return;
    }
    
    if (!_isInitialized) {
      print('AudioService henüz başlatılmadı, bekleniyor...');
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    try {
      final platform = kIsWeb ? 'Web' : Platform.operatingSystem;
      print('$soundFile çalınıyor... (Platform: $platform)');
      
      // Eğer başka bir ses çalıyorsa durdur
      if (_isPlaying) {
        await _audioPlayer.stop();
        // Gecikmeyi kaldır - anında çal
      }
      
      // Gecikmeleri kaldır - anında çal
      
      // Ses seviyesini ayarla
      await _audioPlayer.setVolume(volume);
      
      // Ses dosyasını çal
      _currentSoundFile = soundFile;
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
      
      print('$soundFile başarıyla çalındı');
      if (isShortEffect) {
        _lastEffectFileName = soundFile;
        _lastEffectPlayedAt = now;
      }
    } catch (e) {
      print('$soundFile çalınamadı: $e');
      
      // Hata durumunda tekrar dene (mobil için daha fazla deneme)
      // Ses efektleri kapalıysa beklemeleri minimuma indir
      final soundOn = await isSoundEnabled(context: context);
      final retryDelay = soundOn ? const Duration(milliseconds: 300) : const Duration(milliseconds: 100);
      final maxRetries = soundOn ? 3 : 1;
      for (int i = 0; i < maxRetries; i++) {
        try {
          await Future.delayed(retryDelay);
          await _audioPlayer.stop();
          await _audioPlayer.setVolume(volume);
          _currentSoundFile = soundFile;
          await _audioPlayer.play(AssetSource('sounds/$soundFile'));
          print('$soundFile ${i + 2}. denemede başarıyla çalındı');
          if (isShortEffect) {
            _lastEffectFileName = soundFile;
            _lastEffectPlayedAt = now;
          }
          break;
        } catch (e2) {
          print('$soundFile ${i + 2}. denemede de çalınamadı: $e2');
          if (i == 2) {
            print('$soundFile hiç çalınamadı, atlanıyor...');
          }
        }
      }
    }
  }

  // Belirtilen süre boyunca kısa efektleri (tıklama/joker) sustur
  void suppressShortEffects(Duration duration) {
    final until = DateTime.now().add(duration);
    _shortEffectsSuppressedUntil = until;
    print('Kısa efektler ${duration.inMilliseconds}ms için susturuldu');
  }

  // Gerilim sesi (cevap onaylandığında)
  Future<void> playTension({BuildContext? context}) async {
    print('Gerilim sesi çalınacak...');
    await _playSound(_tensionSound, 0.8, context: context);
  }

  // Seviye atlama sesi (alkış)
  Future<void> playLevelUp({BuildContext? context}) async {
    print('Alkış sesi çalınacak...');
    // Alkıştan önce bekleme döngüsünü kapat ve tüm sesleri durdur
    _keepWaitingLoop = false;
    await stopAllSounds(preserveWaitingLoop: false);
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _playSound(_levelUpSound, 0.8, context: context);
  }

  // Yanlış cevap sesi
  Future<void> playWrongAnswer({BuildContext? context}) async {
    print('Yanlış cevap sesi çalınacak...');
    await _playSound(_wrongAnswerSound, 0.9, context: context);
  }

  // Oyun bitti sesi
  Future<void> playGameOver({BuildContext? context}) async {
    print('Oyun bitti sesi çalınacak...');
    await _playSound(_gameOverSound, 0.8, context: context);
  }

  // Joker kullanma sesi (mobil için özel)
  Future<void> playJoker({BuildContext? context}) async {
    print('Joker sesi çalınacak...');
    await _playSound(_jokerSound, 0.8, context: context);
  }

  // Buton tıklama sesi (mobil için özel)
  Future<void> playButtonClick({BuildContext? context}) async {
    print('Buton tıklama sesi çalınacak...');
    await _playSound(_buttonClickSound, 0.6, context: context);
  }

  // Telefon joker sesi: 7 saniye çal ve durdur
  Future<void> playPhone({Duration duration = const Duration(seconds: 7), BuildContext? context}) async {
    print('Telefon (arkadaş) sesi çalınacak...');
    try {
      print('AudioService: telefon.mp3 dosyası çalınıyor...');
      await _playSound(_phoneSound, 0.8, context: context);
      print('AudioService: telefon.mp3 başarıyla başlatıldı');
      
      // Belirtilen süre kadar bekle, sonra durdur
      print('AudioService: $duration süre bekleniyor...');
      await Future.delayed(duration);
      await _audioPlayer.stop();
      _isPlaying = false;
      print('Telefon sesi durduruldu');
    } catch (e) {
      print('Telefon sesi başlatılamadı: $e');
    }
  }

  // Geri sayım sesi
  Future<void> playCountdown({BuildContext? context}) async {
    print('Geri sayım sesi çalınacak...');
    await _playSound(_countdownSound, 0.8, context: context);
  }

  // Uyarı sesi
  Future<void> playWarning({BuildContext? context}) async {
    print('Uyarı sesi çalınacak...');
    await _playSound(_warningSound, 0.8, context: context);
  }

  // Giriş müziği
  Future<void> playIntro({BuildContext? context}) async {
    print('Giriş müziği çalınacak...');
    await _playSound(_introSound, 0.8, context: context);
  }

  // Bekletme müziği
  Future<void> playWaiting({BuildContext? context}) async {
    print('Bekletme müziği çalınacak...');
    try {
      // Bekletme müziği loop olarak çalsın
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _keepWaitingLoop = true;
    } catch (e) {
      print('ReleaseMode.loop ayarlanamadı: $e');
    }
    await _playSound(_waitingSound, 0.7, context: context);
  }

  // Eski metodlar (geriye uyumluluk için)
  Future<void> playCorrectAnswer({BuildContext? context}) async {
    await playLevelUp(context: context);
  }

  Future<void> playThinking() async {
    // Artık kullanılmıyor
    print('Düşünme sesi artık kullanılmıyor');
  }

  // Ses açma/kapama
  void toggleMute() {
    try {
      _isMuted = !_isMuted;
      print('Ses durumu: ${_isMuted ? "Kapalı" : "Açık"}');
    } catch (e) {
      print('toggleMute hatası: $e');
      _isMuted = false;
    }
  }

  // Ayarlara senkronize sessize alma/açma
  Future<void> setMuted(bool muted) async {
    try {
      _isMuted = muted;
      print('Ses durumu ayarlardan değiştirildi: ${_isMuted ? "Kapalı" : "Açık"}');
      if (_isMuted) {
        _keepWaitingLoop = false;
        await stopAllSounds(preserveWaitingLoop: false);
      }
    } catch (e) {
      print('setMuted hatası: $e');
    }
  }

  bool get isMuted {
    try {
      return _isMuted;
    } catch (e) {
      print('isMuted getter hatası: $e');
      return false;
    }
  }

  // Ses seviyesini ayarlama
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      print('Ses seviyesi ayarlandı: $volume');
    } catch (e) {
      print('Ses seviyesi ayarlanamadı: $e');
    }
  }

  // Tüm sesleri durdur
  // preserveWaitingLoop: true ise mevcut bekleme döngüsü niyeti korunur ve
  // kısa sesler bittikten sonra bekletme müziği otomatik geri dönebilir.
  Future<void> stopAllSounds({bool preserveWaitingLoop = true}) async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentSoundFile = null;
      // Varsayılan moda geri dön
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      } catch (e) {
        print('ReleaseMode.stop ayarlanamadı: $e');
      }
      // Bekleme döngüsü niyetini koru (özellikle GameScreen arka plan müziğinin geri dönmesi için)
      if (!preserveWaitingLoop) {
        _keepWaitingLoop = false;
      }
      print('Tüm sesler durduruldu');
    } catch (e) {
      print('Sesler durdurulamadı: $e');
    }
  }

  // Temizlik
  void dispose() {
    try {
      _audioPlayer.dispose();
      print('AudioService temizlendi');
    } catch (e) {
      print('AudioService temizlenirken hata: $e');
    }
  }
}

