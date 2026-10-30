import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart';
import 'screens/surah_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // lets us load data before app starts
  await Quran.initialize();                  // loads the full Quran into memory
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quran App',
      home: SurahListScreen(),
    );
  }
}