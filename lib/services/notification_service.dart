import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
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
  static const int prayerTimeReminderBaseId = 4300;
  static const String _prayerTimeMasterKey = 'prayer_time_reminders_enabled';
  static const Map<String, String> _prayerTimeKeys = {
    'Fajr': 'prayer_time_fajr_enabled',
    'Dhuhr': 'prayer_time_dhuhr_enabled',
    'Asr': 'prayer_time_asr_enabled',
    'Maghrib': 'prayer_time_maghrib_enabled',
    'Isha': 'prayer_time_isha_enabled',
  };
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

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) {
        await _recordOpenedNotification(response);
      }
    }
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


  static Future<bool> arePrayerTimeRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prayerTimeMasterKey) ?? false;
  }

  static Future<bool> isPrayerTimeReminderEnabled(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prayerTimeKeys[prayer];
    if (key == null) return false;
    return prefs.getBool(key) ?? true;
  }

  static Future<bool> requestPrayerTimeReminderPermissions() async {
    if (kIsWeb) return false;
    final notificationsAllowed = await requestPermission();
    if (!notificationsAllowed) {
      throw Exception('Please allow notifications in your device settings.');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final exactAlarm = await Permission.scheduleExactAlarm.request();
      if (!exactAlarm.isGranted) {
        throw Exception('Please allow exact alarms so prayer reminders can arrive at prayer time.');
      }
    }
    return true;
  }

  static Future<void> setPrayerTimeRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prayerTimeMasterKey, enabled);
    try {
      await refreshPrayerTimeReminders();
    } catch (_) {
      if (enabled) {
        await prefs.setBool(_prayerTimeMasterKey, false);
        await refreshPrayerTimeReminders();
      }
      rethrow;
    }
  }

  static Future<void> setPrayerTimeReminderPrayerEnabled(
      String prayer, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prayerTimeKeys[prayer];
    if (key == null) return;
    await prefs.setBool(key, enabled);
    await refreshPrayerTimeReminders();
  }

  /// Schedules exact, sound-independent prayer notifications for the next 7 days.
  /// The rolling window is refreshed whenever the app opens or the location changes.
  static Future<void> refreshPrayerTimeReminders({
    Coordinates? coordinates,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    for (var day = 0; day < 7; day++) {
      for (var prayerIndex = 0; prayerIndex < _prayerTimeKeys.length; prayerIndex++) {
        await _plugin.cancel(prayerTimeReminderBaseId + day * 5 + prayerIndex);
      }
    }
    if (!(prefs.getBool(_prayerTimeMasterKey) ?? false)) return;

    final savedLat = prefs.getDouble('prayer_location_lat');
    final savedLon = prefs.getDouble('prayer_location_lon');
    final location = coordinates ??
        (savedLat != null && savedLon != null
            ? Coordinates(savedLat, savedLon)
            : Coordinates(13.1143, 80.1548));

    final parameters = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.shafi;
    final now = tz.TZDateTime.now(tz.local);
    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_time_reminders',
        'Prayer time reminders',
        channelDescription: 'Normal notifications at each selected prayer time',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final times = PrayerTimes(
        location,
        DateComponents.from(date),
        parameters,
      );
      final timesByPrayer = <String, DateTime>{
        'Fajr': times.fajr,
        'Dhuhr': times.dhuhr,
        'Asr': times.asr,
        'Maghrib': times.maghrib,
        'Isha': times.isha,
      };

      for (var prayerIndex = 0; prayerIndex < prayers.length; prayerIndex++) {
        final prayer = prayers[prayerIndex];
        if (!(prefs.getBool(_prayerTimeKeys[prayer]!) ?? true)) continue;
        final prayerTime = timesByPrayer[prayer]!;
        final scheduled = tz.TZDateTime(
          tz.local,
          prayerTime.year,
          prayerTime.month,
          prayerTime.day,
          prayerTime.hour,
          prayerTime.minute,
          prayerTime.second,
        );
        if (!scheduled.isAfter(now)) continue;

        final id = prayerTimeReminderBaseId + dayOffset * 5 + prayerIndex;
        final body = 'It is time for $prayer prayer.';
        await _plugin.zonedSchedule(
          id,
          '$prayer prayer time',
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: '$prayer prayer time|$body',
        );
      }
    }
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
    try {
      await refreshPrayerTimeReminders();
    } catch (_) {
      // A revoked exact-alarm permission must not prevent the app from opening.
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
