

import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class QuranHeader extends StatelessWidget {
  const QuranHeader({super.key, this.onNotificationsTap, this.onSettingsTap});

  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;

  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Rebuild this screen when the app theme changes.
    return Container(
      width: double.infinity,
      height: 310,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Decorative mosque background
          Positioned(
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.16,
              child: Icon(
                Icons.mosque,
                size: 190,
                color: gold,
              ),
            ),
          ),

          // Notification and settings
          Positioned(
            top: 18,
            right: 20,
            child: Row(
              children: [
                _headerButton(Icons.notifications_none, 'Prayer notifications', onNotificationsTap),
                SizedBox(width: 12),
                _headerButton(Icons.settings_outlined, 'App settings', onSettingsTap),
              ],
            ),
          ),

          // Quran title
          Positioned(
            top: 100,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Text(
                  'القرآن الكريم',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 42,
                    color: green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The Holy Quran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    color: green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '✦  A Guidance for All Mankind  ✦',
                  style: TextStyle(
                    fontSize: 15,
                    color: green,
                  ),
                ),
              ],
            ),
          ),

          // Gold decorative divider
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '──────  ✧  ──────',
                style: TextStyle(
                  color: gold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _headerButton(
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Color(0xFFFFF9ED),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.12),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: green, size: 27),
      ),
    );
  }
}
