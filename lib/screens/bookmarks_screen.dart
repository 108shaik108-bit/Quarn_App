import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart' hide Surah;

import '../data/surah_data.dart';
import '../services/bookmark_service.dart';
import '../services/app_settings.dart';
import 'surah_reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get cardCream => AppSettings.isDark ? Color(0xFF1B2922) : Color(0xFFFFFAEF);
  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

  late Future<List<QuranBookmark>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _bookmarksFuture = BookmarkService.getBookmarks();
  }

  Future<void> _remove(QuranBookmark bookmark) async {
    await BookmarkService.remove(bookmark);
    if (!mounted) return;
    setState(_refresh);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bookmark removed')),
    );
  }

  Future<void> _openBookmark(QuranBookmark bookmark) async {
    final surah = surahs[bookmark.surahNumber - 1];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surah: surah,
          initialAyah: bookmark.ayahNumber,
        ),
      ),
    );
    if (!mounted) return;
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Rebuild this screen when the app theme changes.
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          'My Bookmarks',
          style: TextStyle(color: green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cream,
        elevation: 0,
        iconTheme: IconThemeData(color: green),
      ),
      body: FutureBuilder<List<QuranBookmark>>(
        future: _bookmarksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: green),
            );
          }

          final bookmarks = snapshot.data ?? [];
          if (bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        color: Color(0xFFE9EAB4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bookmark_outline_rounded,
                        color: green,
                        size: 48,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'No bookmarks yet',
                      style: TextStyle(
                        color: green,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Open any Surah and tap the bookmark icon beside an Ayah to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF52735F), height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              final surah = surahs[bookmark.surahNumber - 1];
              final arabic = Quran.getSurahVersesAsList(bookmark.surahNumber);
              final english = Quran.getSurahVersesAsList(
                bookmark.surahNumber,
                language: AppSettings.language.value,
              );
              final ayahIndex = bookmark.ayahNumber - 1;

              return Material(
                color: cardCream,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openBookmark(bookmark),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Color(0xFFF0D8A9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFE9EAB4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${surah.nameEnglish} • Ayah ${bookmark.ayahNumber}',
                                style: TextStyle(
                                  color: green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              tooltip: 'Remove bookmark',
                              onPressed: () => _remove(bookmark),
                              icon: Icon(
                                Icons.bookmark_remove_rounded,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          arabic[ayahIndex].text,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: green,
                            fontSize: 23,
                            height: 1.8,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          english[ayahIndex].text,
                          style: TextStyle(
                            color: Color(0xFF52735F),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Tap to open Ayah',
                            style: TextStyle(
                              color: gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
