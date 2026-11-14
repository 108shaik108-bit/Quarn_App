import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_flutter/quran_flutter.dart' hide Surah;
import '../data/surah_data.dart';
import '../services/bookmark_service.dart';
import '../services/app_settings.dart';
import '../services/quran_progress_service.dart';

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
  final ScrollController _scrollController = ScrollController();
  static const int ayahsPerPage = 10;

  @override
  void initState() {
    super.initState();
    currentPage = ((widget.initialAyah - 1) ~/ ayahsPerPage)
        .clamp(0, (widget.surah.ayahs - 1) ~/ ayahsPerPage)
        .toInt();
    _recordCurrentPage();
  }

  void _changePage(int page) {
    setState(() => currentPage = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _recordCurrentPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _recordCurrentPage() async {
    final firstAyah = currentPage * ayahsPerPage + 1;
    final lastAyah = (firstAyah + ayahsPerPage - 1)
        .clamp(1, widget.surah.ayahs)
        .toInt();
    await QuranProgressService.recordReadPage(
      widget.surah.number,
      firstAyah,
      lastAyah,
    );
  }

  Future<void> _toggleAyahBookmark(int ayahNumber) async {
    await BookmarkService.toggle(widget.surah.number, ayahNumber);
    if (mounted) setState(() {});
  }


  void _copyAyahText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  Widget _ayahActionsMenu({
    required int ayahNumber,
    required String arabic,
    required String translation,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Ayah options',
      icon: const Icon(Icons.more_horiz, color: Color(0xFF8B7969)),
      onSelected: (value) {
        if (value == 'arabic') {
          _copyAyahText(arabic, 'Arabic Ayah');
        } else if (value == 'translation') {
          _copyAyahText(translation, 'Translation');
        } else if (value == 'share') {
          _showShareAyahCard(
            ayahNumber: ayahNumber,
            arabic: arabic,
            translation: translation,
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'arabic', child: Text('Copy Arabic')),
        PopupMenuItem(value: 'translation', child: Text('Copy Translation')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 18),
              SizedBox(width: 10),
              Text('Share Ayah Card'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showShareAyahCard({
    required int ayahNumber,
    required String arabic,
    required String translation,
  }) async {
    final cardKey = GlobalKey();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8F0),
        contentPadding: const EdgeInsets.all(16),
        content: RepaintBoundary(
          key: cardKey,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              border: Border.all(color: const Color(0xFFD8B77A), width: 1.4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'THE HOLY QURAN',
                  style: TextStyle(
                    color: Color(0xFF806443),
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Color(0xFF241D18),
                    fontSize: 28,
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: const Color(0xFFE4D4C3)),
                const SizedBox(height: 18),
                Text(
                  translation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF655548),
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  '${widget.surah.nameEnglish} • Ayah $ayahNumber',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9A784D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                final boundary = cardKey.currentContext?.findRenderObject()
                    as RenderRepaintBoundary?;
                if (boundary == null) return;
                final image = await boundary.toImage(pixelRatio: 3);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                if (data == null) return;
                final bytes = data.buffer.asUint8List();
                await SharePlus.instance.share(
                  ShareParams(
                    files: [
                      XFile.fromData(
                        bytes,
                        mimeType: 'image/png',
                        name: 'quran-ayah.png',
                      ),
                    ],
                    text: '${widget.surah.nameEnglish} • Ayah $ayahNumber',
                  ),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Could not create share card.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _pageBookmarkButton(int firstAyahNumber) {
    return FutureBuilder<bool>(
      future: BookmarkService.isBookmarked(
        widget.surah.number,
        firstAyahNumber,
      ),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? false;
        return IconButton(
          tooltip: saved ? 'Remove page bookmark' : 'Save this page',
          onPressed: () => _toggleAyahBookmark(firstAyahNumber),
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: const Color(0xFFC49A45),
          ),
        );
      },
    );
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
    final translationLanguage = AppSettings.language.value;
    final englishVerses = Quran.getSurahVersesAsList(
      surah.number,
      language: translationLanguage,
    );

    final totalPages = (surah.ayahs / ayahsPerPage).ceil();
    final startAyah = currentPage * ayahsPerPage;
    final endAyah = (startAyah + ayahsPerPage) > surah.ayahs
        ? surah.ayahs
        : startAyah + ayahsPerPage;

    const mushafMode = true;
    const mushafPaper = Color(0xFFFFF8F0);
    const mushafInk = Color(0xFF241D18);

    return Scaffold(
      backgroundColor: mushafMode ? mushafPaper : const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: mushafMode ? mushafPaper : const Color(0xFF0A0F0D),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mushafMode ? mushafInk : Colors.white),
        actions: [_pageBookmarkButton(startAyah + 1)],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Page ${currentPage + 1} of $totalPages",
              style: const TextStyle(
                color: Color(0xFF8A857D),
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Ayahs ${startAyah + 1} - $endAyah",
              style: const TextStyle(
                color: Color(0xFF8A857D),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 200 && currentPage < totalPages - 1) {
            _changePage(currentPage + 1);
          } else if (velocity < -200 && currentPage > 0) {
            _changePage(currentPage - 1);
          }
        },
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 0)),
          // ═══ 1. Header: name, number, Arabic, ayah count ═══
          SliverToBoxAdapter(
            child: Column(
              children: [
                Text(
                  surah.nameArabic,
                  style: const TextStyle(
                    color: Color(0xFFD8B77A),
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  surah.nameEnglish,
                  style: const TextStyle(
                    color: Color(0xFFD8B77A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Surah ${surah.number}",
                  style: TextStyle(color: mushafMode ? const Color(0xFF8B7969) : Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  "${surah.ayahs} Ayahs • ${surah.isMakki ? 'makki' : 'madinah'}",
                  style: TextStyle(color: mushafMode ? const Color(0xFF8B7969) : Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 1,
                  color: mushafMode ? const Color(0xFFE4D4C3) : const Color(0xFF1E3A2A),
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
                  color: mushafMode ? const Color(0xFFF0E5D8) : const Color(0xFF111A16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: mushafMode ? const Color(0xFFE4D4C3) : const Color(0xFF22332B)),
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

          // ═══ 4. Bismillah ═══
          if (currentPage == 0 && surah.number != 1 && surah.number != 9)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              margin: EdgeInsets.fromLTRB(mushafMode ? 10 : 16, 0, mushafMode ? 10 : 16, 20),
              padding: EdgeInsets.fromLTRB(
                mushafMode ? 18 : 20,
                mushafMode ? 12 : 20,
                mushafMode ? 18 : 20,
                mushafMode ? 28 : 20,
              ),
              decoration: BoxDecoration(
                color: mushafMode ? mushafPaper : const Color(0xFF111A16),
                borderRadius: BorderRadius.circular(mushafMode ? 2 : 12),
                border: mushafMode ? null : Border.all(color: const Color(0xFF22332B)),
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
                                      fontSize: 27,
                                      height: 2.15,
                                      color: mushafInk,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0),
                                  children: [
                                    TextSpan(
                                        text:
                                            "${arabicVerses[ayahIndex].text} "),
                                    TextSpan(
                                      text: " ۝${_arabicDigits(ayahIndex + 1)}",
                                      style: const TextStyle(
                                          color: Color(0xFFB18A68),
                                          fontSize: 19),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _useAllahTerminology(englishVerses[ayahIndex].text),
                              style: const TextStyle(
                                  color: Color(0xFF655548),
                                  fontSize: 16,
                                  height: 1.8),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _bookmarkButton(ayahIndex + 1),
                                _ayahActionsMenu(
                                  ayahNumber: ayahIndex + 1,
                                  arabic: arabicVerses[ayahIndex].text,
                                  translation: _useAllahTerminology(englishVerses[ayahIndex].text),
                                ),
                              ],
                            ),
                            if (i < endAyah - startAyah - 1) ...[
                              const SizedBox(height: 16),
                              Container(
                                  height: 1, color: const Color(0xFFE4D4C3)),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      }),
                    )
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: RichText(
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                        text: TextSpan(
                          style: const TextStyle(
                            color: mushafInk,
                            fontSize: 27,
                            height: 2.15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                          children: [
                            for (var i = startAyah; i < endAyah; i++) ...[
                              TextSpan(text: '${arabicVerses[i].text} '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleAyahBookmark(i + 1),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Text(
                                          '۝${_arabicDigits(i + 1)}',
                                          style: const TextStyle(
                                            color: Color(0xFFB18A68),
                                            fontSize: 19,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _ayahActionsMenu(
                                      ayahNumber: i + 1,
                                      arabic: arabicVerses[i].text,
                                      translation: _useAllahTerminology(englishVerses[i].text),
                                    ),
                                  ],
                                ),
                              ),
                              const TextSpan(text: ' '),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Previous/Next page controls — available on every page
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _surahNavButton(
                      "‹ Next",
                      currentPage < totalPages - 1,
                      () => _changePage(currentPage + 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _surahNavButton(
                      "Previous ›",
                      currentPage > 0,
                      () => _changePage(currentPage - 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══ 6. Previous/Next Surah — only after the final page ═══
          if (currentPage == totalPages - 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _surahNavButton(
                        "← Next Surah",
                        surah.number < 114,
                        () => _goToSurah(surah.number + 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _surahNavButton(
                        "Previous Surah →",
                        surah.number > 1,
                        () => _goToSurah(surah.number - 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _useAllahTerminology(String translation) {
    return translation.replaceAllMapped(
      RegExp(r"\bGod('s)?\b", caseSensitive: false),
      (match) {
        final original = match.group(0) ?? 'God';
        final suffix = original.toLowerCase().endsWith("'s") ? "'s" : '';
        if (original == original.toUpperCase()) return 'ALLAH$suffix';
        if (original.startsWith('g')) return 'allah$suffix';
        return 'Allah$suffix';
      },
    );
  }

  String _arabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => digits[int.parse(digit)]).join();
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
            color: active ? Colors.white : const Color(0xFF3D3028),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ═══ NEW! Helper: Previous/Next Surah button ═══
  Widget _surahNavButton(String label, bool enabled, VoidCallback onTap) {
    const enabledBackground = Color(0xFFE8E2D5);
    const disabledBackground = Color(0xFFF1EDE5);
    const enabledText = Color(0xFF000000);
    const disabledText = Color(0xFFAAA39A);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? enabledBackground : disabledBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? enabledBackground : disabledBackground,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: enabled ? enabledText : disabledText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
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