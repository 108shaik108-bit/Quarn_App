import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_flutter/quran_flutter.dart' hide Surah;

import '../data/surah_data.dart';
import '../services/bookmark_service.dart';
import '../services/quran_progress_service.dart';
import '../services/app_settings.dart';
import 'surah_reader_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

  late final int _surahNumber;
  late final int _ayahNumber;
  late final String _arabicText;
  late final String _englishText;
  bool _isSaved = false;
  final GlobalKey _shareCardKey = GlobalKey();
  late Future<({int surah, int ayah})?> _continueReadingFuture;

  @override
  void initState() {
    super.initState();
    _continueReadingFuture = QuranProgressService.getLastReadLocation();
    _loadDailyAyah();
  }

  void _loadDailyAyah() {
    // One stable verse per calendar day. The verse changes automatically
    // when the device's local date changes.
    final allVerses = <({int surah, int ayah})>[];
    for (final surah in surahs) {
      for (var ayah = 1; ayah <= surah.ayahs; ayah++) {
        allVerses.add((surah: surah.number, ayah: ayah));
      }
    }

    final today = DateTime.now();
    final dayNumber = DateTime(today.year, today.month, today.day)
        .difference(DateTime(2024, 1, 1))
        .inDays;
    final selected = allVerses[dayNumber % allVerses.length];

    _surahNumber = selected.surah;
    _ayahNumber = selected.ayah;
    _arabicText = Quran.getSurahVersesAsList(_surahNumber)[_ayahNumber - 1].text;
    _englishText = Quran.getSurahVersesAsList(
      _surahNumber,
      language: AppSettings.language.value,
    )[_ayahNumber - 1].text;

    _checkBookmark();
  }

  String _arabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => digits[int.parse(digit)]).join();
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

  Future<void> _checkBookmark() async {
    final saved = await BookmarkService.isBookmarked(_surahNumber, _ayahNumber);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _toggleBookmark() async {
    await BookmarkService.toggle(_surahNumber, _ayahNumber);
    if (!mounted) return;
    setState(() => _isSaved = !_isSaved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSaved ? 'Daily Ayah saved to Bookmarks' : 'Bookmark removed'),
      ),
    );
  }

  Future<void> _shareAyah() async {
    final surah = surahs[_surahNumber - 1];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF10251D),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _shareCardKey,
                    child: _buildShareArtwork(surah),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareAyahImage(dialogContext),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share image'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareArtwork(dynamic surah) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 340,
        height: 560,
        decoration: const BoxDecoration(color: Color(0xFF101820)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1100&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF59636A), Color(0xFF18231F), Color(0xFF050A08)],
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0xB8000000), Color(0x16000000), Color(0x65000000)],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD9000000)],
                  stops: [0.28, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 28, 25, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Ayah',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'serif',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '$_surahNumber:$_ayahNumber',
                              style: const TextStyle(
                                color: Color(0xFFE8E8E8),
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${surah.nameEnglish}  •  ${surah.nameArabic}',
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 25),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      _arabicText,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 12)],
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    _useAllahTerminology(_englishText),
                    textAlign: TextAlign.center,
                    textDirection: AppSettings.language.value == 'ur'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'serif',
                      fontSize: 18,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'QUARN APP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAyahImage(BuildContext dialogContext) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: ['daily_ayah.png'],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share image: $error')),
      );
    }
  }

  Future<void> _openContinueReading() async {
    final location = await _continueReadingFuture;
    if (!mounted) return;

    final surahNumber = location?.surah ?? 1;
    final ayahNumber = location?.ayah ?? 1;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surah: surahs[surahNumber - 1],
          initialAyah: ayahNumber,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _continueReadingFuture = QuranProgressService.getLastReadLocation();
    });
  }

  void _openSurah() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surah: surahs[_surahNumber - 1],
          initialAyah: _ayahNumber,
        ),
      ),
    );
  }

  String get _dateLabel {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Rebuild this screen when the app theme changes.
    final surah = surahs[_surahNumber - 1];

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Connect',
          style: TextStyle(
            color: green,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: gold, size: 20),
              SizedBox(width: 8),
              Text(
                _dateLabel,
                style: TextStyle(
                  color: Color(0xFF52735F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _buildDailyAyahCard(surah),
          SizedBox(height: 18),
          Text(
            'A verse to reflect on every day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF52735F),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 20),
          _continueReadingCard(),
        ],
      ),
    );
  }


  Widget _buildDailyAyahCard(dynamic surah) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: AspectRatio(
        aspectRatio: 0.56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1100&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF59636A), Color(0xFF18231F), Color(0xFF050A08)],
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB8000000),
                    Color(0x28000000),
                    Color(0xD9000000),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Ayah',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w800,
                                shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '$_surahNumber:$_ayahNumber  •  ${surah.nameEnglish}',
                              style: const TextStyle(
                                color: Color(0xFFF0E9DD),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _circleAction(
                        icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        label: _isSaved ? 'Remove bookmark' : 'Save ayah',
                        onTap: _toggleBookmark,
                      ),
                      const SizedBox(width: 9),
                      _circleAction(
                        icon: Icons.share_outlined,
                        label: 'Share as WhatsApp Status',
                        onTap: _shareAyah,
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      '$_arabicText  ۝${_arabicDigits(_ayahNumber)}',
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 12)],
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    _useAllahTerminology(_englishText),
                    textAlign: AppSettings.language.value == 'ur'
                        ? TextAlign.right
                        : TextAlign.left,
                    textDirection: AppSettings.language.value == 'ur'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'serif',
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                    ),
                  ),
                  const Spacer(flex: 1),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _openSurah,
                      icon: const Icon(Icons.menu_book_rounded, size: 22),
                      label: const Text(
                        'Read in Quran',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.42),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                          side: BorderSide(color: Colors.white.withOpacity(0.25)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'QUARN APP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueReadingCard() {
    return FutureBuilder<({int surah, int ayah})?>(
      future: _continueReadingFuture,
      builder: (context, snapshot) {
        final location = snapshot.data;
        final surah = location == null ? surahs.first : surahs[location.surah - 1];
        final ayah = location?.ayah ?? 1;
        final hasProgress = location != null;

        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppSettings.isDark ? Color(0xFF1B2922) : Color(0xFFFFFAEF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppSettings.isDark ? Color(0xFF405448) : Color(0xFFF0D8A9),
            ),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.10),
                blurRadius: 9,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppSettings.isDark ? Color(0xFF304638) : Color(0xFFE9EAB4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, color: green, size: 33),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Reading',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: green,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading your progress...'
                          : '${surah.nameEnglish} • Ayah $ayah',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppSettings.isDark ? Color(0xFFB4C7BA) : Color(0xFF52735F),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: snapshot.connectionState == ConnectionState.waiting
                    ? null
                    : _openContinueReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: AppSettings.isDark ? Color(0xFF101814) : Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hasProgress ? 'Resume' : 'Start'),
                    SizedBox(width: 3),
                    Icon(Icons.chevron_right, size: 19),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _circleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.black.withOpacity(0.24),
        shape: CircleBorder(),
        child: InkWell(
          customBorder: CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
