import 'package:flutter/material.dart';
import '../data/surah_data.dart';
import '../data/surah_meanings.dart';
import '../data/juz_data.dart';
import 'surah_reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String searchQuery = "";
  bool showSurahs = true; // Surahs tab = true, Juz tab = false

  @override
  Widget build(BuildContext context) {
    final q = searchQuery.toLowerCase();

    // Filter surahs by search
    final filteredSurahs = surahs.where((s) {
      return s.nameEnglish.toLowerCase().contains(q) ||
          s.nameArabic.contains(searchQuery) ||
          "${s.number}".contains(q);
    }).toList();

    // Filter juz cards (a juz matches if any surah inside matches the search)
    final filteredJuzNumbers = List.generate(30, (i) => i + 1).where((juz) {
      if (q.isEmpty) return true;
      return juzSurahs[juz - 1].any((num) {
        final s = surahs[num - 1];
        return s.nameEnglish.toLowerCase().contains(q) ||
            s.nameArabic.contains(searchQuery) ||
            "$num".contains(q);
      });
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      body: CustomScrollView(
        slivers: [
          // ── 1. Green gradient hero header ──
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0E5C2F), Color(0xFF16A34A), Color(0xFF22C55E)],
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    "القرآن الكريم",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "The Holy Quran",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "A Guidance for All Mankind",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Surahs / Juz toggle ──
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF22332B)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabButton("Surahs", showSurahs, () {
                      setState(() => showSurahs = true);
                    }),
                    _tabButton("Juz", !showSurahs, () {
                      setState(() => showSurahs = false);
                    }),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Search bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search surah by name or number...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF111A16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF22332B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF22332B)),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Surah grid OR Juz cards ──
          if (showSurahs)
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisExtent: 90,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _surahCard(filteredSurahs[index]),
                childCount: filteredSurahs.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _juzCard(filteredJuzNumbers[index]),
                childCount: filteredJuzNumbers.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Green pill tab button ──
  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF16A34A) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Surah card (Surahs tab) ──
  Widget _surahCard(Surah s) {
    return GestureDetector(
      onTap: () => _openSurah(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111A16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF22332B)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2E1F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${s.number}",
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.nameEnglish,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${s.ayahs} Ayahs • ${s.isMakki ? 'Makki' : 'Madani'}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              s.nameArabic,
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BIG Juz card: "Juz N" + "Read Juz" + surah mini-chips ──
  Widget _juzCard(int juzNumber) {
    final surahNumbers = juzSurahs[juzNumber - 1];
    // 2 chips per row: screen width - page margins - card padding - chip spacing
    final chipWidth = (MediaQuery.of(context).size.width - 32 - 32 - 8) / 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF22332B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: "Juz N" ...... "Read Juz"
          Row(
            children: [
              Text(
                "Juz $juzNumber",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openSurah(surahs[surahNumbers.first - 1]),
                child: const Text(
                  "Read Juz",
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Mini surah chips in 2-column wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: surahNumbers.map((num) {
              final s = surahs[num - 1];
              return GestureDetector(
                onTap: () => _openSurah(s),
                child: Container(
                  width: chipWidth,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1411),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1C2B24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2E1F),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          "$num",
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.nameEnglish,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              meanings[num - 1],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        s.nameArabic,
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _openSurah(Surah s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SurahReaderScreen(surah: s)),
    );
  }
}