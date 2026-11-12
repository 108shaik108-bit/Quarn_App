import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/adhan_scheduler_service.dart';
import '../services/app_settings.dart';

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
    if (!mounted) return;
    setState(() {
      _masterEnabled = master;
      _prayerEnabled.addAll(values);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not schedule Adhan: $error')),
          );
        }
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
                            Text('Manage your Adhan alerts in one place.',
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: gold.withOpacity(0.45)),
                  ),
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
                              : 'Turn on to schedule prayer-time Adhan alarms',
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
                _sectionTitle('MORE REMINDERS'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: gold.withOpacity(0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _comingSoonRow(Icons.menu_book_rounded, 'Daily Quran reminder',
                          'Choose a time to build a daily reading habit'),
                      Divider(color: gold.withOpacity(0.3)),
                      _comingSoonRow(Icons.auto_awesome_rounded, 'Daily Ayah',
                          'A daily verse notification'),
                      Divider(color: gold.withOpacity(0.3)),
                      _comingSoonRow(Icons.format_quote_rounded, 'Daily Hadith',
                          'A daily Hadith notification'),
                      Divider(color: gold.withOpacity(0.3)),
                      _comingSoonRow(Icons.history_rounded, 'Notification history',
                          'Review alerts delivered by the app'),
                      const SizedBox(height: 10),
                      Text(
                        'These reminder types are not active yet. Only Adhan alerts can currently be scheduled.',
                        style: TextStyle(
                            color: green.withOpacity(0.75), fontSize: 12),
                      ),
                    ],
                  ),
                ),
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

  Widget _comingSoonRow(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: gold, size: 23),
            const SizedBox(width: 12),
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
            Icon(Icons.lock_clock_outlined,
                color: green.withOpacity(0.45), size: 18),
          ],
        ),
      );
}
