import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
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

class _ConnectScreenState extends State<ConnectScreen> with WidgetsBindingObserver {
  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

  late int _surahNumber;
  late int _ayahNumber;
  late String _arabicText;
  late String _englishText;
  late DateTime _loadedDailyDate;
  Timer? _dailyRefreshTimer;
  bool _isSaved = false;
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDailyAyah();
    _scheduleDailyRefresh();
  }

  @override
  void dispose() {
    _dailyRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDailyAyahIfNeeded();
    }
  }

  void _scheduleDailyRefresh() {
    _dailyRefreshTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _dailyRefreshTimer = Timer(
      nextMidnight.difference(now) + const Duration(seconds: 1),
      _refreshDailyAyahIfNeeded,
    );
  }

  void _refreshDailyAyahIfNeeded() {
    if (!mounted) return;

    final now = DateTime.now();
    final loadedDate = DateTime(
      _loadedDailyDate.year,
      _loadedDailyDate.month,
      _loadedDailyDate.day,
    );
    final currentDate = DateTime(now.year, now.month, now.day);

    if (currentDate != loadedDate) {
      setState(_loadDailyAyah);
    }
    _scheduleDailyRefresh();
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
    _loadedDailyDate = DateTime(today.year, today.month, today.day);
    _isSaved = false;
    final dayNumber = _loadedDailyDate.difference(DateTime(2024, 1, 1)).inDays;
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
            _buildDailyBackground(),
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
        ],
      ),
    );
  }


  int get _dailyBackgroundIndex {
    final dayNumber = DateTime(
      _loadedDailyDate.year,
      _loadedDailyDate.month,
      _loadedDailyDate.day,
    ).difference(DateTime(2024, 1, 1)).inDays;
    return dayNumber % 30;
  }

  Widget _buildDailyBackground() {
    return CustomPaint(
      painter: _IslamicDailyBackgroundPainter(_dailyBackgroundIndex),
      child: const SizedBox.expand(),
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
            _buildDailyBackground(),
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


/// A lightweight, locally-rendered collection of 30 premium Islamic-inspired
/// backgrounds. The same date always selects the same design on every device.
class _IslamicDailyBackgroundPainter extends CustomPainter {
  _IslamicDailyBackgroundPainter(this.index);

  final int index;

  static const List<List<Color>> _palettes = [
    [Color(0xFF142D2A), Color(0xFF071714), Color(0xFF020908)],
    [Color(0xFF49301F), Color(0xFF21150F), Color(0xFF090604)],
    [Color(0xFF263B58), Color(0xFF111D32), Color(0xFF050A13)],
    [Color(0xFF5A3B2B), Color(0xFF2A1C18), Color(0xFF0C0807)],
    [Color(0xFF344B3A), Color(0xFF17251D), Color(0xFF070D0A)],
    [Color(0xFF3E315B), Color(0xFF1D1730), Color(0xFF080610)],
    [Color(0xFF5A4526), Color(0xFF2B2113), Color(0xFF0D0905)],
    [Color(0xFF1D4650), Color(0xFF0D252B), Color(0xFF030B0D)],
    [Color(0xFF593A42), Color(0xFF281A22), Color(0xFF0B070A)],
    [Color(0xFF405044), Color(0xFF1D281F), Color(0xFF080C09)],
    [Color(0xFF55412F), Color(0xFF292016), Color(0xFF0A0805)],
    [Color(0xFF263C4A), Color(0xFF101F2A), Color(0xFF04080D)],
    [Color(0xFF51402B), Color(0xFF261E15), Color(0xFF0B0805)],
    [Color(0xFF24413C), Color(0xFF10231F), Color(0xFF040B09)],
    [Color(0xFF49354D), Color(0xFF211728), Color(0xFF09060C)],
    [Color(0xFF4C3A2A), Color(0xFF241B14), Color(0xFF090705)],
    [Color(0xFF30475A), Color(0xFF152432), Color(0xFF050A10)],
    [Color(0xFF4C4930), Color(0xFF242316), Color(0xFF090A06)],
    [Color(0xFF3C4B45), Color(0xFF1B2521), Color(0xFF070B09)],
    [Color(0xFF5A3B25), Color(0xFF2A1B11), Color(0xFF0B0704)],
    [Color(0xFF293B5A), Color(0xFF121D32), Color(0xFF050811)],
    [Color(0xFF4D3440), Color(0xFF241821), Color(0xFF09060A)],
    [Color(0xFF385044), Color(0xFF192820), Color(0xFF070C09)],
    [Color(0xFF594A35), Color(0xFF2A2419), Color(0xFF0B0906)],
    [Color(0xFF24434B), Color(0xFF102329), Color(0xFF040A0C)],
    [Color(0xFF51402F), Color(0xFF261E17), Color(0xFF0A0806)],
    [Color(0xFF3E3A5A), Color(0xFF1D1A32), Color(0xFF080710)],
    [Color(0xFF405044), Color(0xFF1C281F), Color(0xFF070C09)],
    [Color(0xFF58402D), Color(0xFF291E15), Color(0xFF0A0705)],
    [Color(0xFF29464A), Color(0xFF122529), Color(0xFF050A0B)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final palette = _palettes[index % _palettes.length];
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );

    final goldPaint = Paint()
      ..color = const Color(0xFFD6B36A).withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final softPaint = Paint()
      ..color = const Color(0xFFF4E4C1).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Large ornamental arches and rings create a quiet mosque-inspired depth.
    final center = Offset(size.width * (0.18 + (index % 5) * 0.16), size.height * 0.32);
    for (var ring = 0; ring < 7; ring++) {
      final radius = size.width * (0.13 + ring * 0.075);
      canvas.drawCircle(center, radius, ring.isEven ? goldPaint : softPaint);
    }

    // Repeating diamond geometry, offset per day for 30 distinct compositions.
    final spacing = size.width / 5.2;
    final offset = (index % 4) * spacing / 4;
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        final c = Offset(x + offset, y + offset);
        final path = Path()
          ..moveTo(c.dx, c.dy - spacing * 0.42)
          ..lineTo(c.dx + spacing * 0.42, c.dy)
          ..lineTo(c.dx, c.dy + spacing * 0.42)
          ..lineTo(c.dx - spacing * 0.42, c.dy)
          ..close();
        canvas.drawPath(path, softPaint);
        canvas.drawCircle(c, spacing * 0.12, goldPaint);
      }
    }

    // A subtle dark veil keeps Quran text legible over every composition.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x52000000), Color(0x18000000), Color(0xD9000000)],
          stops: [0, 0.42, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _IslamicDailyBackgroundPainter oldDelegate) =>
      oldDelegate.index != index;
}
