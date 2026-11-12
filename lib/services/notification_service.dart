import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_flutter/quran_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/surah_data.dart' as app_data;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int quranReminderId = 4101;
  static const int ayahReminderId = 4102;
  static const String _historyKey = 'notification_open_history';
  static const String _quranEnabledKey = 'daily_quran_enabled';
  static const String _ayahEnabledKey = 'daily_ayah_enabled';
  static const String _quranHourKey = 'daily_quran_hour';
  static const String _quranMinuteKey = 'daily_quran_minute';
  static const String _ayahHourKey = 'daily_ayah_hour';
  static const String _ayahMinuteKey = 'daily_ayah_minute';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    tz_data.initializeTimeZones();
    // The app currently uses Indian prayer locations by default.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _recordOpenedNotification,
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  static Future<void> _recordOpenedNotification(
      NotificationResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? <String>[];
    history.insert(
      0,
      jsonEncode({
        'title': response.payload?.split('|').first ?? 'Quran App',
        'body': response.payload?.split('|').skip(1).join('|') ??
            'You opened a notification.',
        'time': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setStringList(_historyKey, history.take(50).toList());
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_historyKey) ?? <String>[];
    return items.map((item) {
      try {
        return Map<String, dynamic>.from(jsonDecode(item) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  static Future<bool> isQuranEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quranEnabledKey) ?? false;
  }

  static Future<bool> isAyahEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ayahEnabledKey) ?? false;
  }

  static Future<DateTime> getQuranTime() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime(2000, 1, 1,
        prefs.getInt(_quranHourKey) ?? 20, prefs.getInt(_quranMinuteKey) ?? 0);
  }

  static Future<DateTime> getAyahTime() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime(2000, 1, 1,
        prefs.getInt(_ayahHourKey) ?? 9, prefs.getInt(_ayahMinuteKey) ?? 0);
  }

  static Future<void> setQuranReminder(bool enabled, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quranEnabledKey, enabled);
    await prefs.setInt(_quranHourKey, time.hour);
    await prefs.setInt(_quranMinuteKey, time.minute);
    if (!enabled) {
      if (!kIsWeb) await _plugin.cancel(quranReminderId);
      return;
    }
    await _scheduleDaily(
      id: quranReminderId,
      title: 'Time for Quran',
      body: 'Take a moment for your daily Quran reading.',
      time: time,
      payloadTitle: 'Time for Quran',
    );
  }

  static Future<void> setAyahReminder(bool enabled, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ayahEnabledKey, enabled);
    await prefs.setInt(_ayahHourKey, time.hour);
    await prefs.setInt(_ayahMinuteKey, time.minute);

    if (kIsWeb) return;
    for (var offset = 0; offset < 7; offset++) {
      await _plugin.cancel(ayahReminderId + offset);
    }
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var firstDate = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    var firstTime = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!firstTime.isAfter(now)) {
      firstDate = firstDate.add(const Duration(days: 1));
      firstTime = firstTime.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_ayah',
        'Daily Ayah',
        channelDescription: 'A different Quran verse reminder each day',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var offset = 0; offset < 7; offset++) {
      final date = firstDate.add(Duration(days: offset));
      final scheduled = firstTime.add(Duration(days: offset));
      final ayah = _ayahForDate(DateTime(date.year, date.month, date.day));
      final body =
          '${ayah.arabic}  (${ayah.surahName} ${ayah.ayahNumber})';
      await _plugin.zonedSchedule(
        ayahReminderId + offset,
        'Your Daily Ayah',
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'Your Daily Ayah|$body',
      );
    }
  }

  static ({String arabic, String surahName, int ayahNumber}) _ayahForDate(
      DateTime date) {
    final day = date.difference(DateTime(2020, 1, 1)).inDays;
    var index = day % 6236;
    for (final surah in app_data.surahs) {
      if (index < surah.ayahs) {
        final ayahNumber = index + 1;
        final verse = Quran.getVerse(
          surahNumber: surah.number,
          verseNumber: ayahNumber,
        );
        return (
          arabic: verse.text,
          surahName: surah.nameEnglish,
          ayahNumber: ayahNumber,
        );
      }
      index -= surah.ayahs;
    }
    final verse = Quran.getVerse(surahNumber: 1, verseNumber: 1);
    return (arabic: verse.text, surahName: 'Al-Fatihah', ayahNumber: 1);
  }

  static Future<void> refreshEnabledReminders() async {
    if (kIsWeb) return;
    await initialize();
    if (await isQuranEnabled()) {
      await setQuranReminder(true, await getQuranTime());
    }
    if (await isAyahEnabled()) {
      await setAyahReminder(true, await getAyahTime());
    }
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required String payloadTitle,
  }) async {
    if (kIsWeb) return;
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminders',
        'Daily reminders',
        channelDescription: 'Daily Quran and Ayah reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$payloadTitle|$body',
    );
  }
}
