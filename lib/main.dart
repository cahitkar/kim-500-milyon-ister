import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'data/txt_loader.dart';
import 'data/questions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TXT'den soruları yükle
  try {
    final loaded = await TxtQuestionLoader.loadFromAssets('assets/data/veri.txt');
    GameData.externalQuestions = loaded;
    // Konsola kısa özet yaz
    // ignore: avoid_print
    print('TXT yüklendi: ${loaded.length} soru');
  } catch (e) {
    // ignore: avoid_print
    print('TXT yüklenemedi: $e');
  }
  runApp(const Kim500MilyonIsterApp());
}

class Kim500MilyonIsterApp extends StatelessWidget {
  const Kim500MilyonIsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final settings = SettingsProvider();
            settings.loadSettings();
            return settings;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Kim 500 Milyon İster',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
