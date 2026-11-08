import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_flutter/quran_flutter.dart' hide Surah;

import '../data/surah_data.dart';
import '../services/bookmark_service.dart';
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

  @override
  void initState() {
    super.initState();
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
    final text = 'Daily Ayah
'
        '${surah.nameEnglish} $_surahNumber:$_ayahNumber

'
        '$_arabicText

$_englishText

Quarn App';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ayah copied. You can now share it.')),
    );
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
          Container(
            height: 650,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF26343A),
                  Color(0xFF263B36),
                  Color(0xFF07130F),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: green.withOpacity(0.18),
                  blurRadius: 20,
                  offset: Offset(0, 9),
                ),
              ],
            ),
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
                          Text(
                            'Daily Ayah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'serif',
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '$_surahNumber:$_ayahNumber',
                            style: TextStyle(
                              color: Color(0xFFE4E4E4),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${surah.nameEnglish} • ${surah.nameArabic}',
                            style: TextStyle(
                              color: Color(0xFFD8D8D8),
                              fontSize: 13,
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
                    SizedBox(width: 10),
                    _circleAction(
                      icon: Icons.share_outlined,
                      label: 'Copy to share',
                      onTap: _shareAyah,
                    ),
                  ],
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 3),
                  child: Text(
                    _arabicText,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 2.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    _englishText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.55,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                SizedBox(height: 38),
                SizedBox(
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: _openSurah,
                    icon: Icon(Icons.menu_book_rounded, size: 25),
                    label: Text(
                      'Read in Quran',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.28),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        ],
      ),
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
