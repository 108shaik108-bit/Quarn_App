import 'package:shared_preferences/shared_preferences.dart';

import '../data/surah_data.dart';

class QuranProgressService {
  static const String _readAyahsKey = 'quran_read_ayahs';
  static const String _streakKey = 'quran_reading_streak';
  static const String _lastReadDateKey = 'quran_last_read_date';
  static const String _lastSurahKey = 'quran_last_surah';
  static const String _lastAyahKey = 'quran_last_ayah';

  static int get totalAyahs =>
      surahs.fold<int>(0, (sum, surah) => sum + surah.ayahs);

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<void> recordReadPage(
    int surahNumber,
    int firstAyah,
    int lastAyah,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(_readAyahsKey)?.toSet() ?? <String>{};

    for (var ayah = firstAyah; ayah <= lastAyah; ayah++) {
      read.add('$surahNumber:$ayah');
    }
    await prefs.setStringList(_readAyahsKey, read.toList());
    await prefs.setInt(_lastSurahKey, surahNumber);
    await prefs.setInt(_lastAyahKey, firstAyah);

    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastKey = prefs.getString(_lastReadDateKey);

    if (lastKey != todayKey) {
      final yesterday = _dateKey(today.subtract(const Duration(days: 1)));
      final previousStreak = prefs.getInt(_streakKey) ?? 0;
      final nextStreak = lastKey == yesterday ? previousStreak + 1 : 1;
      await prefs.setInt(_streakKey, nextStreak);
      await prefs.setString(_lastReadDateKey, todayKey);
    }
  }


  static Future<({int surah, int ayah})?> getLastReadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final surahNumber = prefs.getInt(_lastSurahKey);
    final ayahNumber = prefs.getInt(_lastAyahKey);

    if (surahNumber == null ||
        ayahNumber == null ||
        surahNumber < 1 ||
        surahNumber > surahs.length) {
      return null;
    }

    final maxAyah = surahs[surahNumber - 1].ayahs;
    return (surah: surahNumber, ayah: ayahNumber.clamp(1, maxAyah).toInt());
  }

  static Future<int> getReadAyahCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readAyahsKey)?.toSet().length ?? 0;
  }

  static Future<int> getReadingStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_streakKey) ?? 0;
    final lastKey = prefs.getString(_lastReadDateKey);
    if (lastKey == null || lastKey != _dateKey(DateTime.now())) {
      return 0;
    }
    return streak;
  }
}
