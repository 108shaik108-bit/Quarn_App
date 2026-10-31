import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart' hide Surah;
import '../data/surah_data.dart';

class SurahReaderScreen extends StatefulWidget {
  final Surah surah;
  const SurahReaderScreen({super.key, required this.surah});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  int currentPage = 0;
  bool showTranslation = false; // Arabic Only = false
  static const int ayahsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;

    // Load REAL Quran text — Arabic + English
    final arabicVerses = Quran.getSurahVersesAsList(surah.number);
    final englishVerses =
        Quran.getSurahVersesAsList(surah.number, language: QuranLanguage.english);

    final totalPages = (surah.ayahs / ayahsPerPage).ceil();
    final startAyah = currentPage * ayahsPerPage;
    final endAyah = (startAyah + ayahsPerPage) > surah.ayahs
        ? surah.ayahs
        : startAyah + ayahsPerPage;

    // ── FIX 2: Build ONE flowing Arabic text (verses continue like a real Mushaf) ──
    final arabicSpans = <TextSpan>[];
    for (int i = startAyah; i < endAyah; i++) {
      arabicSpans.add(
        TextSpan(
          text: "${arabicVerses[i].text} ",
          style: const TextStyle(color: Colors.white),
        ),
      );
      arabicSpans.add(
        TextSpan(
          text: "﴿${i + 1}﴾ ",
          style: const TextStyle(
            color: Color(0xFF22C55E),
            fontSize: 20,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F0D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          // ── 1. Header ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                Text(
                  surah.nameEnglish,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Surah ${surah.number}",
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 14),
                Text(
                  surah.nameArabic,
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${surah.ayahs} Ayahs • ${surah.isMakki ? 'makki' : 'madinah'}",
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 1,
                  color: const Color(0xFF1E3A2A),
                ),
              ],
            ),
          ),

          // ── 2. Arabic Only / Arabic + Translation toggle ──
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22332B)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toggleButton("Arabic Only", !showTranslation, () {
                      setState(() => showTranslation = false);
                    }),
                    _toggleButton("Arabic + Translation", showTranslation, () {
                      setState(() => showTranslation = true);
                    }),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Pagination bar ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111A16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22332B)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: currentPage > 0
                        ? () => setState(() => currentPage--)
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: currentPage > 0
                              ? const Color(0xFF22C55E)
                              : Colors.grey.shade700,
                          size: 20,
                        ),
                        Text(
                          " Previous",
                          style: TextStyle(
                            color: currentPage > 0
                                ? const Color(0xFF22C55E)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "Page ${currentPage + 1} of $totalPages",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Ayahs ${startAyah + 1} - $endAyah",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: currentPage < totalPages - 1
                        ? () => setState(() => currentPage++)
                        : null,
                    child: Row(
                      children: [
                        Text(
                          "Next ",
                          style: TextStyle(
                            color: currentPage < totalPages - 1
                                ? const Color(0xFF22C55E)
                                : Colors.grey.shade700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: currentPage < totalPages - 1
                              ? const Color(0xFF22C55E)
                              : Colors.grey.shade700,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. Bismillah ──
          if (surah.number != 1 && surah.number != 9)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 28,
                    height: 1.8,
                  ),
                ),
              ),
            ),

          // ── 5. FIX 1+2: ONE flowing page card, text vertically centered ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111A16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22332B)),
              ),
              child: Column(
                children: [
                  // Arabic — flows continuously, verse 2 follows verse 1
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 24,
                          height: 2.2, // comfortable Mushaf line spacing
                        ),
                        children: arabicSpans,
                      ),
                    ),
                  ),
                  // Translation — each verse as its own flowing paragraph below
                  if (showTranslation) ...[
                    const SizedBox(height: 20),
                    Container(height: 1, color: const Color(0xFF1E3A2A)),
                    const SizedBox(height: 20),
                    ...List.generate(endAyah - startAyah, (i) {
                      final ayahIndex = startAyah + i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ayahIndex + 1}. ",
                              style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                englishVerses[ayahIndex].text,
                                style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 15,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF16A34A) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}