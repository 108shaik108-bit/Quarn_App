import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuranBookmark {
  final int surahNumber;
  final int ayahNumber;

  const QuranBookmark({
    required this.surahNumber,
    required this.ayahNumber,
  });

  String get id => '$surahNumber:$ayahNumber';

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
      };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
    );
  }
}

class BookmarkService {
  static const String _storageKey = 'quran_ayah_bookmarks';

  static Future<List<QuranBookmark>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null || saved.isEmpty) return [];

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;
      return decoded
          .map((item) => QuranBookmark.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((item) =>
        item.surahNumber == surahNumber && item.ayahNumber == ayahNumber);
  }

  static Future<void> toggle(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    final exists = bookmarks.any((item) =>
        item.surahNumber == surahNumber && item.ayahNumber == ayahNumber);

    if (exists) {
      bookmarks.removeWhere((item) =>
          item.surahNumber == surahNumber && item.ayahNumber == ayahNumber);
    } else {
      bookmarks.add(QuranBookmark(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      ));
    }

    await prefs.setString(
      _storageKey,
      jsonEncode(bookmarks.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> remove(QuranBookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((item) => item.id == bookmark.id);
    await prefs.setString(
      _storageKey,
      jsonEncode(bookmarks.map((item) => item.toJson()).toList()),
    );
  }
}
