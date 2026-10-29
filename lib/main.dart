import 'package:flutter/material.dart';
import 'screens/surah_list_screen.dart';

void main() {
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