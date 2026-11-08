

import '../services/app_settings.dart';import 'package:flutter/material.dart';

class QuranHeader extends StatelessWidget {
  const QuranHeader({super.key});

  static const Color cream = Color(0xFFFFF3DC);
  static const Color green = Color(0xFF07502D);
  static const Color gold = Color(0xFFC49A45);

  @override
  Widget build(BuildContext context) {
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
                _headerButton(Icons.notifications_none),
                const SizedBox(width: 12),
                _headerButton(Icons.settings_outlined),
              ],
            ),
          ),

          // Quran title
          const Positioned(
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

  static Widget _headerButton(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: green,
        size: 27,
      ),
    );
  }
}
