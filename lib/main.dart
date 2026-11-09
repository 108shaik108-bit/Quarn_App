import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart';

import 'screens/surah_list_screen.dart';
import 'services/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Alarm.init();
  }
  await Quran.initialize();
  await AppSettings.load();
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Quarn App',
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF07502D),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFF5E2),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFFF5E2),
              foregroundColor: Color(0xFF07502D),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF07502D),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF101814),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF101814),
              foregroundColor: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: const SurahListScreen(),
        );
      },
    );
  }
}
