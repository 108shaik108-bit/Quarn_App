import 'package:flutter/foundation.dart';
import 'package:adhan/adhan.dart';
import 'package:alarm/alarm.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schedules a rolling 7-day set of prayer alarms.
///
/// Ringing is deliberately disabled until the user enables it in Prayer settings.
class AdhanSchedulerService {
  static const String _masterKey = 'adhan_ring_enabled';
  static const String _scheduledIdsKey = 'adhan_scheduled_alarm_ids';
  static const int _daysToSchedule = 7;

  static const List<String> prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  static const Map<String, String> _prayerKeys = {
    'Fajr': 'adhan_prayer_fajr_enabled',
    'Dhuhr': 'adhan_prayer_dhuhr_enabled',
    'Asr': 'adhan_prayer_asr_enabled',
    'Maghrib': 'adhan_prayer_maghrib_enabled',
    'Isha': 'adhan_prayer_isha_enabled',
  };

  static Future<void> requestPermissions() async {
    if (kIsWeb) {
      throw UnsupportedError('Automatic Adhan alarms are available on Android and iOS, not Chrome.');
    }
    final notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted) {
      throw Exception('Allow notifications to use Adhan alerts.');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      if (!exactAlarmStatus.isGranted) {
        throw Exception('Allow exact alarms so Adhan can ring at prayer time.');
      }
    }
  }

  static Future<bool> isRingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_masterKey) ?? false;
  }

  static Future<void> setRingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_masterKey, enabled);
  }

  static Future<bool> isPrayerEnabled(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prayerKeys[prayer];
    if (key == null) return false;
    return prefs.getBool(key) ?? true;
  }

  static Future<void> setPrayerEnabled(String prayer, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prayerKeys[prayer];
    if (key != null) await prefs.setBool(key, enabled);
  }

  static Future<void> cancelScheduled() async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_scheduledIdsKey) ?? <String>[];
    for (final value in ids) {
      final id = int.tryParse(value);
      if (id != null) {
        try {
          await Alarm.stop(id);
        } catch (_) {
          // An alarm may already have fired or been removed by the OS.
        }
      }
    }
    await prefs.remove(_scheduledIdsKey);
  }

  static Future<void> refresh({
    required Coordinates coordinates,
  }) async {
    if (kIsWeb) return;
    await cancelScheduled();
    if (!await isRingEnabled()) return;

    final enabledPrayers = <String>[];
    for (final prayer in prayerNames) {
      if (await isPrayerEnabled(prayer)) enabledPrayers.add(prayer);
    }
    if (enabledPrayers.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final scheduledIds = <String>[];
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.shafi;

    final now = DateTime.now();
    for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day + dayOffset);
      final times = PrayerTimes(
        coordinates,
        DateComponents.from(date),
        params,
      );

      final timesByPrayer = <String, DateTime>{
        'Fajr': times.fajr,
        'Dhuhr': times.dhuhr,
        'Asr': times.asr,
        'Maghrib': times.maghrib,
        'Isha': times.isha,
      };

      for (var index = 0; index < prayerNames.length; index++) {
        final prayer = prayerNames[index];
        if (!enabledPrayers.contains(prayer)) continue;

        final prayerTime = timesByPrayer[prayer]!;
        if (!prayerTime.isAfter(now.add(const Duration(seconds: 10)))) {
          continue;
        }

        final dayNumber = DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(2020, 1, 1))
            .inDays;
        final id = 200000000 + (dayNumber * 10) + index;
        final audioAsset = prayer == 'Fajr'
            ? 'assets/audio/adhan_fajr.mp3'
            : 'assets/audio/adhan_other_prayers.mp3';

        await Alarm.set(
          alarmSettings: AlarmSettings(
            id: id,
            dateTime: prayerTime,
            assetAudioPath: audioAsset,
            loopAudio: false,
            vibrate: false,
            volumeSettings: const VolumeSettings.fixed(
              volume: null,
              volumeEnforced: false,
            ),
            warningNotificationOnKill: defaultTargetPlatform == TargetPlatform.iOS,
            androidFullScreenIntent: false,
            androidStopAlarmOnTermination: false,
            notificationSettings: NotificationSettings(
              title: '$prayer prayer time',
              body: 'It is time for $prayer. Tap Stop to end the Adhan.',
              stopButton: 'Stop Adhan',
            ),
          ),
        );
        scheduledIds.add(id.toString());
        await prefs.setStringList(_scheduledIdsKey, scheduledIds);
      }
    }

    await prefs.setStringList(_scheduledIdsKey, scheduledIds);
  }
}
