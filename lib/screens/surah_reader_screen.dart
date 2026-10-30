import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart'
hide Surah;   // ← add "hide Surah"
import '../data/surah_data.dart';

class SurahReaderScreen extends StatelessWidget {
  final Surah surah;
  const SurahReaderScreen({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    // Load REAL Quran text — Arabic + English, works offline!
    final arabicVerses = Quran.getSurahVersesAsList(surah.number);
    final englishVerses =
        Quran.getSurahVersesAsList(surah.number, language: QuranLanguage.english);

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        elevation: 0,
        title: Text("${surah.nameEnglish} • ${surah.nameArabic}"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: arabicVerses.length,
        itemBuilder: (context, index) {
          final arabic = arabicVerses[index].text;
          final english = englishVerses[index].text;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14532D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFD4AF37),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  arabic,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 26, height: 2.0, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  english,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFD4AF37),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}