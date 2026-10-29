import 'package:flutter/material.dart';
import '../data/surah_data.dart';

class SurahReaderScreen extends StatelessWidget {
  final Surah surah;
  const SurahReaderScreen({super.key, required this.surah});

  // Temporary sample text for Al-Fatihah
  // Later we will load the FULL Quran from a JSON file
  static const Map<String, String> fatihah = {
    "1": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ|In the name of Allah, the Most Gracious, the Most Merciful",
    "2": "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ|All praise is due to Allah, Lord of the worlds",
    "3": "الرَّحْمَٰنِ الرَّحِيمِ|The Most Gracious, the Most Merciful",
    "4": "مَالِكِ يَوْمِ الدِّينِ|Master of the Day of Judgment",
    "5": "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ|You alone we worship, and You alone we ask for help",
    "6": "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ|Guide us along the Straight Path",
    "7": "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ|The path of those You have blessed",
  };

  @override
  Widget build(BuildContext context) {
    final entries = fatihah.entries.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        elevation: 0,
        title: Text(surah.nameEnglish),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final parts = entries[index].value.split("|");
          final arabic = parts[0];
          final translation = parts[1];

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
                // Ayah number badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFD4AF37),
                    child: Text(
                      entries[index].key,
                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Arabic text — right aligned, like real Mushaf
                Text(
                  arabic,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 2.0, // line spacing for beautiful reading
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Translation
                Text(
                  translation,
                  textAlign: TextAlign.left,
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