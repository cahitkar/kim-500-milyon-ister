import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/questions.dart';
import '../services/audio_service.dart';

class GameProvider extends ChangeNotifier {
  int _currentLevel = 1;
  int _currentPrize = 0;
  int _guaranteedPrize = 0;
  bool _isGameActive = false;
  bool _isGameOver = false;
  bool _isWon = false;
  Question? _currentQuestion;
  int? _selectedAnswer;
  bool _hasUsedFiftyFifty = false;
  bool _hasUsedAudience = false;
  bool _hasUsedPhone = false;
  // Telefon joker animasyon durumu ve hedef/animasyon indexleri
  bool _isPhoneHintActive = false;
  int? _phoneHintTargetIndex;
  int _phoneHighlightIndex = -1;
  Timer? _phoneHintTimer;
  // 50:50 jokeri sadece mevcut soru için aktif mi?
  bool _isFiftyFiftyActiveForCurrentQuestion = false;
  int _highScore = 0;
  AudioService? _audioService;
  // Seyirci joker dialog callback'i
  Function(BuildContext context, List<String> options, int correctAnswer)? _showAudienceDialog;
  // Her seviye için kullanılan soruları takip etmek için
  Map<int, Set<String>> _usedQuestionsByLevel = {};
  
  // Seviye bazlı soru sistemi için
  bool _useLevelBasedQuestions = true; // Seviye bazlı soru sistemi aktif
  
  // Süre yönetimi
  Timer? _timer;
  int _remainingTime = 0;
  bool _isTimeWarning = false;
  bool _isCountdownActive = false;
  bool _isUntimedMode = false; // Süresiz oyun modu

  // Getters
  int get currentLevel => _currentLevel;
  int get currentPrize => _currentPrize;
  int get guaranteedPrize => _guaranteedPrize;
  bool get isGameActive => _isGameActive;
  bool get isGameOver => _isGameOver;
  bool get isWon => _isWon;
  Question? get currentQuestion => _currentQuestion;
  int? get selectedAnswer => _selectedAnswer;
  bool get hasUsedFiftyFifty => _hasUsedFiftyFifty;
  bool get hasUsedAudience => _hasUsedAudience;
  bool get hasUsedPhone => _hasUsedPhone;
  bool get isPhoneHintActive => _isPhoneHintActive;
  int? get phoneHintTargetIndex => _phoneHintTargetIndex;
  int get phoneHighlightIndex => _phoneHighlightIndex;
  bool get isFiftyFiftyActiveForCurrentQuestion => _isFiftyFiftyActiveForCurrentQuestion;
  int get highScore => _highScore;
  
  // Süre getter'ları
  int get remainingTime => _remainingTime;
  bool get isTimeWarning => _isTimeWarning;
  bool get isCountdownActive => _isCountdownActive;
  bool get isUntimedMode => _isUntimedMode;

  // Seyirci joker dialog callback'ini ayarla
  void setAudienceDialogCallback(Function(BuildContext context, List<String> options, int correctAnswer) callback) {
    _showAudienceDialog = callback;
  }

  GameProvider() {
    _loadHighScore();
    _loadUsedQuestions();
    _initializeAudioService();
  }

  // AudioService'i başlat
  Future<void> _initializeAudioService() async {
    try {
      _audioService = AudioService();
      // AudioService'in başlatılmasını bekle (mobil için daha kısa)
      await Future.delayed(const Duration(milliseconds: 2000));
      print('GameProvider: AudioService başarıyla başlatıldı');
    } catch (e) {
      print('GameProvider: AudioService başlatılamadı: $e');
    }
  }

  // Oyunu başlat
  void startGame({bool untimed = false}) {
    _currentPrize = 0;
    _guaranteedPrize = 0;
    _isGameActive = true;
    _isGameOver = false;
    _isWon = false;
    _isUntimedMode = untimed;
    _selectedAnswer = null;
    _hasUsedFiftyFifty = false;
    _hasUsedAudience = false;
    _hasUsedPhone = false;
    _isFiftyFiftyActiveForCurrentQuestion = false;
    _isPhoneHintActive = false;
    _phoneHintTargetIndex = null;
    _phoneHighlightIndex = -1;
    _phoneHintTimer?.cancel();
    
    // 1. seviyeden başla
    _currentLevel = 1;
    
    // Süre yönetimini sıfırla
    _timer?.cancel();
    _remainingTime = 0;
    _isTimeWarning = false;
    _isCountdownActive = false;
    
    // Soru yükleme işlemini güvenli hale getir
    try {
      _loadQuestion();
      // Eğer soru yüklenemezse varsayılan bir soru ata
      if (_currentQuestion == null) {
        _currentQuestion = GameData.questions.first;
        _currentLevel = 1;
      } else {
        // İlk sorunun seviyesini kullan
        _currentLevel = _currentQuestion!.level;
      }
    } catch (e) {
      // Hata durumunda varsayılan soru kullan
      _currentQuestion = GameData.questions.first;
      _currentLevel = 1;
    }
    
    notifyListeners();
  }

  // Soru yükle
  void _loadQuestion() {
    try {
      if (_useLevelBasedQuestions) {
        // Seviye bazlı soru sistemi kullan
        _currentQuestion = GameData.getUnusedRandomQuestionForLevel(_currentLevel, _getUsedQuestionsForLevel(_currentLevel));
        
        // Eğer bu seviye için soru yoksa, oyunu bitir
        if (_currentQuestion == null) {
          _isGameOver = true;
          _isGameActive = false;
          _saveHighScore(_guaranteedPrize);
          notifyListeners();
          return;
        }
        
        // Kullanılan soruyu kaydet
        if (_currentQuestion != null) {
          _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
          _saveUsedQuestions();
        }
        
        print('GameProvider: Yeni soru yüklendi, seviye: $_currentLevel');
      } else {
        // Eski sistem - seviye bazlı rastgele soru
        _currentQuestion = GameData.getUnusedRandomQuestionForLevel(_currentLevel, _getUsedQuestionsForLevel(_currentLevel));
        
        // Kullanılan soruyu kaydet
        if (_currentQuestion != null) {
          _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
          _saveUsedQuestions();
        }
      }
      
      _selectedAnswer = null;
      // Yeni soruda 4 seçenek geri gelsin (50:50 jokeri sıfırla)
      _isFiftyFiftyActiveForCurrentQuestion = false;
      // Telefon joker ipucu sıfırlansın
      _isPhoneHintActive = false;
      _phoneHintTargetIndex = null;
      _phoneHighlightIndex = -1;
      _phoneHintTimer?.cancel();
      
      // Süresiz modda süre başlatma; değilse başlat
      if (!_isUntimedMode) {
        startTimer();
      }
    } catch (e) {
      // Hata durumunda varsayılan soru kullan
      _currentQuestion = GameData.questions.first;
      _selectedAnswer = null;
      _isFiftyFiftyActiveForCurrentQuestion = false;
      _isPhoneHintActive = false;
      _phoneHintTargetIndex = null;
      _phoneHighlightIndex = -1;
      _phoneHintTimer?.cancel();
      
      if (!_isUntimedMode) {
        startTimer();
      }
    }
  }

  // Cevap seç
  void selectAnswer(int answerIndex) {
    _selectedAnswer = answerIndex;
    
    // Zamanlı modda tercih yapınca kronometreyi durdur
    if (!_isUntimedMode) {
      stopTimer();
    }
    
    notifyListeners();
  }

  // Cevabı kontrol et
  Future<void> checkAnswer() async {
    if (_selectedAnswer == null || _currentQuestion == null) return;

    // Süreyi durdur
    stopTimer();

    bool isCorrect = _selectedAnswer == _currentQuestion!.correctAnswer;

    if (isCorrect) {
      _currentPrize = _currentQuestion!.prize;
      _guaranteedPrize = _currentPrize;
      
      // Alkış sesi çal (süresiz modda bekleme yok)
      try {
        print('GameProvider: Alkış sesi çalınacak');
        if (_audioService != null) {
          await _audioService!.playLevelUp();
          print('GameProvider: Alkış sesi çalındı');
        }
      } catch (e) {
        print('GameProvider: Alkış sesi çalınamadı: $e');
      }
      
      // Süresiz modda bekleme yapma, zamanlı modda 5 sn bekle
      if (!_isUntimedMode) {
        await Future.delayed(const Duration(seconds: 5));
      }
      
      if (_useLevelBasedQuestions) {
        // Seviye bazlı soru sisteminde seviye artırma
        // Kullanılan soruyu kaydet
        if (_currentQuestion != null) {
          _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
          _saveUsedQuestions();
          print('GameProvider: Soru kaydedildi, seviye: $_currentLevel');
        }
        
        // Seviye 13'e ulaştıysa oyunu kazan
        if (_currentLevel == 13) {
          _isWon = true;
          _isGameOver = true;
          _isGameActive = false;
          _saveHighScore(_currentPrize);
          // Oyun kazanma sesi
          try {
            if (_audioService != null) {
              _audioService!.playLevelUp();
            }
          } catch (e) {
            print('Oyun kazanma sesi çalınamadı: $e');
          }
        } else {
          // Seviyeyi artır ve sonraki soruyu yükle
          _currentLevel++;
          _loadQuestion();
        }
      } else {
        // Eski sistem - seviye bazlı
        if (_currentLevel == 13) {
          _isWon = true;
          _isGameOver = true;
          _isGameActive = false;
          _saveHighScore(_currentPrize);
          // Oyun kazanma sesi
          try {
            if (_audioService != null) {
              _audioService!.playLevelUp();
            }
          } catch (e) {
            print('Oyun kazanma sesi çalınamadı: $e');
          }
        } else {
          _currentLevel++;
          _loadQuestion();
        }
      }
    } else {
      // Yanlış cevap sesi çal (3 saniye)
      try {
        print('GameProvider: Yanlış cevap sesi çalınacak');
        if (_audioService != null) {
          await _audioService!.playWrongAnswer();
          print('GameProvider: Yanlış cevap sesi çalındı');
        }
      } catch (e) {
        print('GameProvider: Yanlış cevap sesi çalınamadı: $e');
      }
      
      // Doğru cevabın gösterilmesi için 2 saniye daha bekle
      await Future.delayed(const Duration(seconds: 2));
      
      // Yanlış cevap verildiğinde de kullanılan soruyu kaydet
      if (_currentQuestion != null) {
        _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
        _saveUsedQuestions();
      }
      
      _isGameOver = true;
      _isGameActive = false;
      _saveHighScore(_guaranteedPrize);
      
      // Oyun bitti sesi (3 saniye)
      try {
        print('GameProvider: Oyun bitti sesi çalınacak');
        if (_audioService != null) {
          await _audioService!.playGameOver();
          print('GameProvider: Oyun bitti sesi çalındı');
        }
      } catch (e) {
        print('GameProvider: Oyun bitti sesi çalınamadı: $e');
      }
      
      // 3 saniye daha bekle
      await Future.delayed(const Duration(seconds: 3));
    }

    notifyListeners();
  }

  // 50:50 joker kullan
  Future<void> useFiftyFifty() async {
    if (_hasUsedFiftyFifty || _currentQuestion == null) return;
    
    _hasUsedFiftyFifty = true;
    _isFiftyFiftyActiveForCurrentQuestion = true; // Sadece bu soru için uygula
    
    // Jokere tıklayınca kronometreyi durdur
    stopTimer();
    
    try {
      print('GameProvider: 50:50 joker kullanılıyor');
      if (_audioService != null) {
        // Önce diğer sesleri durdur
        await _audioService!.stopAllSounds();
        await _audioService!.playJoker();
        print('GameProvider: 50:50 joker sesi çalındı');
      } else {
        print('GameProvider: AudioService null, joker sesi çalınamadı');
      }
    } catch (e) {
      print('Joker sesi çalınamadı: $e');
    }
    notifyListeners();
  }

  // Seyirci joker kullan
  Future<void> useAudience() async {
    if (_hasUsedAudience || _currentQuestion == null) return;
    
    _hasUsedAudience = true;
    
    // Jokere tıklayınca kronometreyi durdur
    stopTimer();
    
    try {
      print('GameProvider: Seyirci joker kullaniliyor');
      if (_audioService != null) {
        // Önce diğer sesleri durdur
        await _audioService!.stopAllSounds();
        await _audioService!.playJoker();
        print('GameProvider: Seyirci joker sesi calindi');
      } else {
        print('GameProvider: AudioService null, joker sesi calinamadi');
      }
      
      // Seyirci joker dialog'unu goster
      if (_showAudienceDialog != null) {
        // Context'i game_screen.dart'tan alacağız
        print('GameProvider: Seyirci joker dialog callback ayarlandi');
      } else {
        print('GameProvider: Seyirci joker dialog callback ayarlanmamis');
      }
    } catch (e) {
      print('Joker sesi calinamadi: $e');
    }
    notifyListeners();
  }

  // Context'i almak icin yardimci fonksiyon - artık kullanılmıyor
  BuildContext? _getCurrentContext() {
    return null;
  }

  // Çekil fonksiyonu
  void cashOut() {
    // Çekil sırasında da kullanılan soruyu kaydet
    if (_currentQuestion != null) {
      _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
      _saveUsedQuestions();
    }
    
    _isGameOver = true;
    _isGameActive = false;
    _saveHighScore(_currentPrize);
    notifyListeners();
  }

  // Telefon joker kullan
  Future<void> usePhone() async {
    if (_hasUsedPhone || _currentQuestion == null) return;
    
    _hasUsedPhone = true;
    
    // Jokere tıklayınca kronometreyi durdur
    stopTimer();
    
    try {
      print('GameProvider: Telefon joker kullanılıyor');
      
      // Hedef index belirle (%75 doğru, %25 rastgele yanlış)
      final correct = _currentQuestion!.correctAnswer;
      final rand = DateTime.now().millisecondsSinceEpoch % 100;
      print('GameProvider: Rastgele değer: $rand, Doğru cevap: $correct');
      
      if (rand < 75) {
        _phoneHintTargetIndex = correct;
        print('GameProvider: Doğru cevap seçildi: $_phoneHintTargetIndex');
      } else {
        // Yanlışlardan rastgele seç
        final wrongs = List<int>.generate(_currentQuestion!.options.length, (i) => i)
            .where((i) => i != correct)
            .toList();
        if (wrongs.isNotEmpty) {
          final pick = wrongs[(DateTime.now().microsecondsSinceEpoch) % wrongs.length];
          _phoneHintTargetIndex = pick;
          print('GameProvider: Yanlış cevap seçildi: $_phoneHintTargetIndex');
        } else {
          _phoneHintTargetIndex = correct;
          print('GameProvider: Doğru cevap seçildi (fallback): $_phoneHintTargetIndex');
        }
      }
      
      // Animasyonu başlat (sıralı highlight)
      _isPhoneHintActive = false; // Animasyon sırasında false
      _phoneHighlightIndex = 0; // Başlangıçta A şıkkı seçili
      print('GameProvider: Animasyon başlatılıyor, hedef: $_phoneHintTargetIndex');
      
      // Timer ile sıralı animasyon (A -> B -> C -> D -> A -> B -> C -> D...)
      _phoneHintTimer?.cancel();
      _phoneHintTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
        if (_currentQuestion == null) return;
        final total = _currentQuestion!.options.length;
        _phoneHighlightIndex = (_phoneHighlightIndex + 1) % total;
        print('GameProvider: Mavi ışık şık ${String.fromCharCode(65 + _phoneHighlightIndex)} üzerinde');
        notifyListeners();
      });
      notifyListeners();
      
      // Telefon sesi 7 sn çalsın (animasyon ile aynı anda başlar)
      if (_audioService != null) {
        print('GameProvider: Telefon sesi başlatılıyor...');
        try {
          // Önce diğer sesleri durdur
          await _audioService!.stopAllSounds();
          // Animasyon ile aynı anda ses çalmaya başla
          _audioService!.playPhone(duration: const Duration(seconds: 7));
          print('GameProvider: Telefon sesi başarıyla başlatıldı');
        } catch (e) {
          print('GameProvider: Telefon sesi çalınamadı: $e');
        }
      } else {
        print('GameProvider: AudioService null, telefon sesi çalınamadı');
      }
      
      // 7 saniye bekle (telefon sesi ve animasyon için)
      await Future.delayed(const Duration(seconds: 7));
      
      // Animasyonu durdur ve hedefte sabitle
      _phoneHintTimer?.cancel();
      if (_phoneHintTargetIndex != null) {
        _phoneHighlightIndex = _phoneHintTargetIndex!;
        print('GameProvider: Animasyon durduruldu, hedef şık: ${String.fromCharCode(65 + _phoneHighlightIndex)}');
      }
      _isPhoneHintActive = true; // Kalıcı highlight
      print('GameProvider: Telefon joker tamamlandı, isPhoneHintActive: $_isPhoneHintActive');
      notifyListeners();
    } catch (e) {
      print('Joker sesi çalınamadı: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _phoneHintTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // Oyunu bitir (çekil)
  void quitGame() {
    // Oyunu bırakırken de kullanılan soruyu kaydet
    if (_currentQuestion != null) {
      _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
      _saveUsedQuestions();
    }
    
    _isGameOver = true;
    _isGameActive = false;
    _saveHighScore(_guaranteedPrize);
    notifyListeners();
  }

  // Yüksek skoru kaydet
  Future<void> _saveHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', _highScore);
    }
  }

  // Yüksek skoru yükle
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt('highScore') ?? 0;
    notifyListeners();
  }

  // Para formatını Türkçe sistemine göre formatla
  String formatMoney(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Milyon TL';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} Bin TL';
    } else {
      return '$amount TL';
    }
  }

  // Seviye için garantili ödülü hesapla
  int getGuaranteedPrizeForLevel(int level) {
    switch (level) {
      case 5:
        return 200000;
      case 10:
        return 1500000;
      case 13:
        return 5000000;
      default:
        return 0;
    }
  }

  // Süre yönetimi fonksiyonları
  void startTimer() {
    if (_isUntimedMode) {
      _remainingTime = 0;
      _isTimeWarning = false;
      _isCountdownActive = false;
      _timer?.cancel();
      return;
    }
    _timer?.cancel();
    
    // Seviyeye göre süre belirle
    if (_currentLevel <= 2) {
      _remainingTime = 15; // 1. ve 2. sorular: 15 saniye
    } else if (_currentLevel <= 7) {
      _remainingTime = 45; // 3., 4., 5., 6. ve 7. sorular: 45 saniye
    } else {
      // 8. sorudan itibaren süre kısıtlaması yok
      _remainingTime = 0;
      return;
    }
    
    _isTimeWarning = false;
    _isCountdownActive = false;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        
        // Son 4 saniye için geri sayım (sadece bir kez)
        if (_remainingTime <= 4 && _remainingTime > 0 && !_isCountdownActive) {
          _isCountdownActive = true;
          _playCountdownSound();
        }
        
        // Süre bitti
        if (_remainingTime <= 0) {
          _timeUp();
        }
        
        notifyListeners();
      }
    });
  }

  void _playCountdownSound() async {
    try {
      if (_audioService != null) {
        await _audioService!.playCountdown();
        print('GameProvider: Geri sayım sesi çalındı');
      }
    } catch (e) {
      print('GameProvider: Geri sayım sesi çalınamadı: $e');
    }
  }

  void _timeUp() async {
    _timer?.cancel();
    _isTimeWarning = true;
    
    // Uyarı sesi çal
    try {
      if (_audioService != null) {
        await _audioService!.playWarning();
        print('GameProvider: Uyarı sesi çalındı');
      }
    } catch (e) {
      print('GameProvider: Uyarı sesi çalınamadı: $e');
    }
    
    // 3 saniye bekle
    await Future.delayed(const Duration(seconds: 3));
    
    // Bitiş müziği çal
    try {
      if (_audioService != null) {
        await _audioService!.playGameOver();
        print('GameProvider: Bitiş müziği çalındı');
      }
    } catch (e) {
      print('GameProvider: Bitiş müziği çalınamadı: $e');
    }
    
    // Süre bittiğinde de kullanılan soruyu kaydet
    if (_currentQuestion != null) {
      _addUsedQuestionForLevel(_currentLevel, _currentQuestion!.question);
      _saveUsedQuestions();
    }
    
    // Oyunu bitir
    _isGameOver = true;
    _isGameActive = false;
    _saveHighScore(_guaranteedPrize);
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _remainingTime = 0;
    _isTimeWarning = false;
    _isCountdownActive = false;
  }

  String getFormattedTime() {
    if (_remainingTime <= 0) return '00:00';
    int minutes = _remainingTime ~/ 60;
    int seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Seviye bazlı soru yönetimi metodları
  Set<String> _getUsedQuestionsForLevel(int level) {
    return _usedQuestionsByLevel[level] ?? {};
  }

  void _addUsedQuestionForLevel(int level, String question) {
    if (!_usedQuestionsByLevel.containsKey(level)) {
      _usedQuestionsByLevel[level] = {};
    }
    _usedQuestionsByLevel[level]!.add(question);
  }

  // Kullanılan soruları kalıcı olarak kaydet (seviye bazlı)
  Future<void> _saveUsedQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Her seviye için kullanılan soruları JSON formatında kaydet
      final Map<String, List<String>> levelQuestionsMap = {};
      _usedQuestionsByLevel.forEach((level, questions) {
        levelQuestionsMap[level.toString()] = questions.toList();
      });
      
      // JSON string'e çevir
      final jsonString = levelQuestionsMap.toString();
      await prefs.setString('usedQuestionsByLevel', jsonString);
      print('GameProvider: Seviye bazlı kullanılan sorular kaydedildi');
    } catch (e) {
      print('GameProvider: Seviye bazlı kullanılan sorular kaydedilemedi: $e');
    }
  }

  // Kullanılan soruları kalıcı olarak yükle (seviye bazlı)
  Future<void> _loadUsedQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('usedQuestionsByLevel');
      
      if (jsonString != null) {
        // JSON string'i parse et (basit implementasyon)
        _usedQuestionsByLevel = {};
        // Bu basit bir implementasyon, gerçek uygulamada JSON parsing kullanılmalı
        print('GameProvider: Seviye bazlı kullanılan sorular yüklendi');
      } else {
        _usedQuestionsByLevel = {};
      }
    } catch (e) {
      print('GameProvider: Seviye bazlı kullanılan sorular yüklenemedi: $e');
      _usedQuestionsByLevel = {};
    }
  }

  // Tüm kullanılan soruları sıfırla (yeni oyun için)
  Future<void> resetUsedQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('usedQuestionsByLevel');
      _usedQuestionsByLevel.clear();
      print('GameProvider: Seviye bazlı kullanılan sorular sıfırlandı');
      notifyListeners();
    } catch (e) {
      print('GameProvider: Seviye bazlı kullanılan sorular sıfırlanamadı: $e');
    }
  }
}
