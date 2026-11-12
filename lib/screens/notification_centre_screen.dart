import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/adhan_scheduler_service.dart';
import '../services/app_settings.dart';
import '../services/notification_service.dart';

class NotificationCentreScreen extends StatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  State<NotificationCentreScreen> createState() =>
      _NotificationCentreScreenState();
}

class _NotificationCentreScreenState extends State<NotificationCentreScreen> {
  static Color get green =>
      AppSettings.isDark ? const Color(0xFF9BD0AF) : const Color(0xFF07502D);
  static Color get cream =>
      AppSettings.isDark ? const Color(0xFF101814) : const Color(0xFFFFF5E2);
  static Color get card =>
      AppSettings.isDark ? const Color(0xFF1B2922) : const Color(0xFFFFFAEF);
  static Color get gold =>
      AppSettings.isDark ? const Color(0xFFE0B96B) : const Color(0xFFC49A45);

  bool _loading = true;
  bool _masterEnabled = false;
  bool _quranEnabled = false;
  bool _ayahEnabled = false;
  bool _busy = false;
  DateTime _quranTime = DateTime(2000, 1, 1, 20);
  DateTime _ayahTime = DateTime(2000, 1, 1, 9);
  final Map<String, bool> _prayerEnabled = {
    for (final prayer in AdhanSchedulerService.prayerNames) prayer: true,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final master = await AdhanSchedulerService.isRingEnabled();
    final values = <String, bool>{};
    for (final prayer in AdhanSchedulerService.prayerNames) {
      values[prayer] = await AdhanSchedulerService.isPrayerEnabled(prayer);
    }
    final quran = await NotificationService.isQuranEnabled();
    final ayah = await NotificationService.isAyahEnabled();
    final quranTime = await NotificationService.getQuranTime();
    final ayahTime = await NotificationService.getAyahTime();
    if (!mounted) return;
    setState(() {
      _masterEnabled = master;
      _prayerEnabled.addAll(values);
      _quranEnabled = quran;
      _ayahEnabled = ayah;
      _quranTime = quranTime;
      _ayahTime = ayahTime;
      _loading = false;
    });
  }

  Future<Coordinates> _savedCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('prayer_location_lat');
    final lon = prefs.getDouble('prayer_location_lon');
    if (lat != null && lon != null) return Coordinates(lat, lon);
    return Coordinates(13.1143, 80.1548);
  }

  Future<void> _toggleMaster(bool enabled) async {
    if (enabled) {
      try {
        await AdhanSchedulerService.requestPermissions();
      } catch (error) {
        if (!mounted) return;
        _message(error.toString().replaceFirst('Exception: ', ''));
        return;
      }
    }

    await AdhanSchedulerService.setRingEnabled(enabled);
    if (enabled) {
      try {
        await AdhanSchedulerService.refresh(
          coordinates: await _savedCoordinates(),
        );
      } catch (error) {
        await AdhanSchedulerService.setRingEnabled(false);
        if (mounted) _message('Could not schedule Adhan: $error');
        return;
      }
    } else {
      await AdhanSchedulerService.cancelScheduled();
    }

    if (mounted) setState(() => _masterEnabled = enabled);
  }

  Future<void> _togglePrayer(String prayer, bool enabled) async {
    await AdhanSchedulerService.setPrayerEnabled(prayer, enabled);
    if (_masterEnabled) {
      await AdhanSchedulerService.refresh(
        coordinates: await _savedCoordinates(),
      );
    }
    if (mounted) setState(() => _prayerEnabled[prayer] = enabled);
  }

  Future<void> _toggleDailyReminder({
    required bool enabled,
    required bool isAyah,
    DateTime? selectedTime,
  }) async {
    if (kIsWeb) {
      _message('Scheduled notifications are available in the Android and iOS app. Please test this on your phone.');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (enabled) {
        final permitted = await NotificationService.requestPermission();
        if (!permitted) {
          throw Exception('Please allow notifications in your device settings.');
        }
      }
      final time = selectedTime ?? (isAyah ? _ayahTime : _quranTime);
      if (isAyah) {
        await NotificationService.setAyahReminder(enabled, time);
      } else {
        await NotificationService.setQuranReminder(enabled, time);
      }
      if (!mounted) return;
      setState(() {
        if (isAyah) {
          _ayahEnabled = enabled;
          _ayahTime = time;
        } else {
          _quranEnabled = enabled;
          _quranTime = time;
        }
      });
      _message(enabled ? 'Daily reminder scheduled.' : 'Daily reminder turned off.');
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseTime({required bool isAyah}) async {
    final current = isAyah ? _ayahTime : _quranTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: isAyah ? 'Daily Ayah reminder time' : 'Daily Quran reminder time',
    );
    if (picked == null) return;
    final selected = DateTime(2000, 1, 1, picked.hour, picked.minute);
    await _toggleDailyReminder(
      enabled: isAyah ? _ayahEnabled : _quranEnabled,
      isAyah: isAyah,
      selectedTime: selected,
    );
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), duration: const Duration(seconds: 2)),
    );
  }

  String _formatTime(DateTime value) =>
      TimeOfDay(hour: value.hour, minute: value.minute).format(context);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: green,
        elevation: 0,
        title: Text('Notification Centre',
            style: TextStyle(color: green, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppSettings.isDark
                          ? [const Color(0xFF203B2D), const Color(0xFF14251C)]
                          : [const Color(0xFF07502D), const Color(0xFF0D6840)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gold.withOpacity(0.65)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Color(0xFFE9D19A), size: 30),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Stay connected to your prayers',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Manage your prayer alerts and daily reminders.',
                                style: TextStyle(
                                    color: Color(0xFFE9D19A), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle('PRAYER NOTIFICATIONS'),
                _panel(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: green,
                        secondary: Icon(Icons.volume_up_rounded, color: green),
                        title: Text('Adhan alerts',
                            style: TextStyle(
                                color: green, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _masterEnabled
                              ? 'Adhan alarms are enabled'
                              : 'Schedule Adhan at each selected prayer time',
                          style: TextStyle(color: green.withOpacity(0.72), fontSize: 12),
                        ),
                        value: _masterEnabled,
                        onChanged: _toggleMaster,
                      ),
                      if (_masterEnabled) ...[
                        Divider(color: gold.withOpacity(0.35)),
                        for (final prayer in AdhanSchedulerService.prayerNames)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: green,
                            title: Text(prayer,
                                style: TextStyle(
                                    color: green, fontWeight: FontWeight.w600)),
                            value: _prayerEnabled[prayer] ?? true,
                            onChanged: (value) => _togglePrayer(prayer, value),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle('DAILY REMINDERS'),
                _panel(
                  child: Column(
                    children: [
                      _reminderTile(
                        icon: Icons.menu_book_rounded,
                        title: 'Daily Quran reminder',
                        subtitle: 'A gentle reminder to read the Quran',
                        enabled: _quranEnabled,
                        time: _quranTime,
                        onChanged: (value) => _toggleDailyReminder(
                            enabled: value, isAyah: false),
                        onTimeTap: () => _chooseTime(isAyah: false),
                      ),
                      Divider(color: gold.withOpacity(0.3)),
                      _reminderTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Daily Ayah',
                        subtitle: 'Receive a Quran verse reminder each day',
                        enabled: _ayahEnabled,
                        time: _ayahTime,
                        onChanged: (value) => _toggleDailyReminder(
                            enabled: value, isAyah: true),
                        onTimeTap: () => _chooseTime(isAyah: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle('ACTIVITY'),
                _panel(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.history_rounded, color: gold, size: 25),
                    title: Text('Notification history',
                        style: TextStyle(
                            color: green, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'See notifications you have opened',
                      style: TextStyle(color: green.withOpacity(0.7), fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: green),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const NotificationHistoryScreen()),
                    ),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Reminder scheduling requires the Android or iOS app. The controls can be tested on your phone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: green.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _sectionTitle(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(value,
            style: TextStyle(
                color: green,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold)),
      );

  Widget _panel({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gold.withOpacity(0.45)),
        ),
        child: child,
      );

  Widget _reminderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required DateTime time,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: gold, size: 23),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: green, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: green.withOpacity(0.7), fontSize: 11)),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: _busy ? null : onChanged, activeColor: green),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _busy ? null : onTimeTap,
            icon: Icon(Icons.schedule_rounded, size: 17, color: green),
            label: Text(_formatTime(time),
                style: TextStyle(color: green, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final green = AppSettings.isDark
        ? const Color(0xFF9BD0AF)
        : const Color(0xFF07502D);
    final cream = AppSettings.isDark
        ? const Color(0xFF101814)
        : const Color(0xFFFFF5E2);
    final card = AppSettings.isDark
        ? const Color(0xFF1B2922)
        : const Color(0xFFFFFAEF);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: green,
        elevation: 0,
        title: Text('Notification history',
            style: TextStyle(color: green, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: NotificationService.getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: green));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        color: green.withOpacity(0.5), size: 48),
                    const SizedBox(height: 12),
                    Text('No notification activity yet',
                        style: TextStyle(
                            color: green, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Text(
                      'Notifications you open from your device tray will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: green.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final date = DateTime.tryParse(item['time']?.toString() ?? '');
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_active_outlined, color: green),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']?.toString() ?? 'Notification',
                              style: TextStyle(
                                  color: green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item['body']?.toString() ?? '',
                              style: TextStyle(color: green)),
                          if (date != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              MaterialLocalizations.of(context)
                                  .formatFullDate(date.toLocal()),
                              style: TextStyle(
                                  color: green.withOpacity(0.65), fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
