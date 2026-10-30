import 'package:flutter/material.dart';
import '../data/surah_data.dart';
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
    // Filter surahs by search
    final filtered = surahs.where((s) {
      final q = searchQuery.toLowerCase();
      return s.nameEnglish.toLowerCase().contains(q) ||
          s.nameArabic.contains(searchQuery) ||
          "${s.number}".contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D), // dark background
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

          // ── 4. Grid of surahs ──
          if (showSurahs)
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400, // 2 columns on phones, more on wide screens
                mainAxisExtent: 90,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _surahCard(filtered[index]),
                childCount: filtered.length,
              ),
            )
          else
            // Juz tab — simple list of 30 juz (full data comes later)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111A16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22332B)),
                  ),
                  child: Text(
                    "Juz ${index + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                childCount: 30,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // Green pill tab button
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

  // Dark surah card matching the website
  Widget _surahCard(Surah s) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SurahReaderScreen(surah: s)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111A16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF22332B)),
        ),
        child: Row(
          children: [
            // Number box
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
            // English name + info
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
            // Arabic name
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
}