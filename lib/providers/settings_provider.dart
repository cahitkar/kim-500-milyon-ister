import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showTimer = true;
  bool _showHints = true;
  String _difficulty = 'normal';
  bool _autoSave = true;
  bool _showStatistics = true;
  String _language = 'tr';

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get showTimer => _showTimer;
  bool get showHints => _showHints;
  String get difficulty => _difficulty;
  bool get autoSave => _autoSave;
  bool get showStatistics => _showStatistics;
  String get language => _language;

  // Setters
  set soundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  set vibrationEnabled(bool value) {
    _vibrationEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  set showTimer(bool value) {
    _showTimer = value;
    _saveSettings();
    notifyListeners();
  }

  set showHints(bool value) {
    _showHints = value;
    _saveSettings();
    notifyListeners();
  }

  set difficulty(String value) {
    _difficulty = value;
    _saveSettings();
    notifyListeners();
  }

  set autoSave(bool value) {
    _autoSave = value;
    _saveSettings();
    notifyListeners();
  }

  set showStatistics(bool value) {
    _showStatistics = value;
    _saveSettings();
    notifyListeners();
  }

  set language(String value) {
    _language = value;
    _saveSettings();
    notifyListeners();
  }

  // Ayarları kaydet
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setBool('showTimer', _showTimer);
    await prefs.setBool('showHints', _showHints);
    await prefs.setString('difficulty', _difficulty);
    await prefs.setBool('autoSave', _autoSave);
    await prefs.setBool('showStatistics', _showStatistics);
    await prefs.setString('language', _language);
  }

  // Ayarları yükle
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _showTimer = prefs.getBool('showTimer') ?? true;
    _showHints = prefs.getBool('showHints') ?? true;
    _difficulty = prefs.getString('difficulty') ?? 'normal';
    _autoSave = prefs.getBool('autoSave') ?? true;
    _showStatistics = prefs.getBool('showStatistics') ?? true;
    _language = prefs.getString('language') ?? 'tr';
    notifyListeners();
  }

  // Ayarları sıfırla
  Future<void> resetSettings() async {
    _soundEnabled = true;
    _vibrationEnabled = true;
    _showTimer = true;
    _showHints = true;
    _difficulty = 'normal';
    _autoSave = true;
    _showStatistics = true;
    _language = 'tr';
    await _saveSettings();
    notifyListeners();
  }
}
