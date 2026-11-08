import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart' hide Surah;
import '../data/surah_data.dart';
import '../services/bookmark_service.dart';

class SurahReaderScreen extends StatefulWidget {
  final Surah surah;
  final int initialAyah;
  const SurahReaderScreen({
    super.key,
    required this.surah,
    this.initialAyah = 1,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  int currentPage = 0;
  bool showTranslation = false; // Arabic Only = false
  static const int ayahsPerPage = 10;

  @override
  void initState() {
    super.initState();
    currentPage = ((widget.initialAyah - 1) ~/ ayahsPerPage)
        .clamp(0, (widget.surah.ayahs - 1) ~/ ayahsPerPage)
        .toInt();
  }

  Future<void> _toggleAyahBookmark(int ayahNumber) async {
    await BookmarkService.toggle(widget.surah.number, ayahNumber);
    if (mounted) setState(() {});
  }

  Widget _bookmarkButton(int ayahNumber) {
    return FutureBuilder<bool>(
      future: BookmarkService.isBookmarked(widget.surah.number, ayahNumber),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? false;
        return IconButton(
          tooltip: saved ? 'Remove bookmark' : 'Bookmark this Ayah',
          visualDensity: VisualDensity.compact,
          onPressed: () => _toggleAyahBookmark(ayahNumber),
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: const Color(0xFFC49A45),
          ),
        );
      },
    );
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F0D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          // ═══ 1. Header: name, number, Arabic, ayah count ═══
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

          // ═══ 2. Arabic Only / Arabic + Translation toggle ═══
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

          // ═══ 3. Top pagination bar ═══
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
                        Icon(Icons.chevron_left,
                            size: 20,
                            color: currentPage > 0
                                ? const Color(0xFF22C55E)
                                : Colors.grey.shade700),
                        Text(" Previous",
                            style: TextStyle(
                                color: currentPage > 0
                                    ? const Color(0xFF22C55E)
                                    : Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text("Page ${currentPage + 1} of $totalPages",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("Ayahs ${startAyah + 1} - $endAyah",
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  GestureDetector(
                    onTap: currentPage < totalPages - 1
                        ? () => setState(() => currentPage++)
                        : null,
                    child: Row(
                      children: [
                        Text("Next ",
                            style: TextStyle(
                                color: currentPage < totalPages - 1
                                    ? const Color(0xFF22C55E)
                                    : Colors.grey.shade700)),
                        Icon(Icons.chevron_right,
                            size: 20,
                            color: currentPage < totalPages - 1
                                ? const Color(0xFF22C55E)
                                : Colors.grey.shade700),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══ 4. Bismillah ═══
          if (surah.number != 1 && surah.number != 9)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF22C55E), fontSize: 28, height: 1.8),
                ),
              ),
            ),

          // ═══ 5. The Quran page card ═══
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111A16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22332B)),
              ),
              child: showTranslation
                  ? Column(
                      children:
                          List.generate(endAyah - startAyah, (i) {
                        final ayahIndex = startAyah + i;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 24,
                                      height: 2.0,
                                      color: Colors.white),
                                  children: [
                                    TextSpan(
                                        text:
                                            "${arabicVerses[ayahIndex].text} "),
                                    TextSpan(
                                      text: "﴿${ayahIndex + 1}﴾",
                                      style: const TextStyle(
                                          color: Color(0xFF22C55E),
                                          fontSize: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              englishVerses[ayahIndex].text,
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 15,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _bookmarkButton(ayahIndex + 1),
                            ),
                            if (i < endAyah - startAyah - 1) ...[
                              const SizedBox(height: 16),
                              Container(
                                  height: 1, color: const Color(0xFF1E3A2A)),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      }),
                    )
                  : Column(
                      children: List.generate(endAyah - startAyah, (i) {
                        final ayahIndex = startAyah + i;
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      '${arabicVerses[ayahIndex].text} ﴿${ayahIndex + 1}﴾',
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                _bookmarkButton(ayahIndex + 1),
                              ],
                            ),
                            if (i < endAyah - startAyah - 1)
                              const Divider(color: Color(0xFF1E3A2A)),
                          ],
                        );
                      }),
                    ),
            ),
          ),

          // ═══ 6. NEW! Page pills + Previous/Next Surah ═══
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                children: [
                  // Numbered pills row
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111A16),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF22332B)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: currentPage > 0
                              ? () => setState(() => currentPage--)
                              : null,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                Icon(Icons.chevron_left,
                                    size: 18,
                                    color: currentPage > 0
                                        ? const Color(0xFF22C55E)
                                        : Colors.grey.shade700),
                                Text(" Previous",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: currentPage > 0
                                            ? const Color(0xFF22C55E)
                                            : Colors.grey.shade700)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(totalPages, (i) {
                                final active = i == currentPage;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => currentPage = i),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF1A2620),
                                      borderRadius:
                                          BorderRadius.circular(7),
                                      border: Border.all(
                                          color: const Color(0xFF22332B)),
                                    ),
                                    child: Text(
                                      "${i + 1}",
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: 13,
                                        fontWeight: active
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: currentPage < totalPages - 1
                              ? () => setState(() => currentPage++)
                              : null,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                Text("Next ",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: currentPage < totalPages - 1
                                            ? const Color(0xFF22C55E)
                                            : Colors.grey.shade700)),
                                Icon(Icons.chevron_right,
                                    size: 18,
                                    color: currentPage < totalPages - 1
                                        ? const Color(0xFF22C55E)
                                        : Colors.grey.shade700),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Previous Surah / Next Surah buttons
                  Row(
                    children: [
                      Expanded(
                        child: _surahNavButton(
                          "← Previous Surah",
                          surah.number > 1,
                          () => _goToSurah(surah.number - 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _surahNavButton(
                          "Next Surah →",
                          surah.number < 114,
                          () => _goToSurah(surah.number + 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // ═══ Helper: toggle pill button ═══
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

  // ═══ NEW! Helper: Previous/Next Surah button ═══
  Widget _surahNavButton(String label, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF111A16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFF22C55E) : const Color(0xFF22332B),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? const Color(0xFF22C55E) : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ═══ NEW! Jump to another surah ═══
  void _goToSurah(int number) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SurahReaderScreen(surah: surahs[number - 1]),
      ),
    );
  }
}