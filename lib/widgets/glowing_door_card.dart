

import 'package:flutter/material.dart';
import '../services/app_settings.dart';

class GlowingDoorCard extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final ValueChanged<int>? onTabChanged;

  const GlowingDoorCard({
    super.key,
    this.onSearch,
    this.onTabChanged,
  });

  @override
  State<GlowingDoorCard> createState() => _GlowingDoorCardState();
}

class _GlowingDoorCardState extends State<GlowingDoorCard> {
  int selectedTab = 0;

  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get darkGreen => AppSettings.isDark ? Color(0xFF0B2117) : Color(0xFF064426);
  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Rebuild this screen when the app theme changes.
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: gold.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.18),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: gold.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                _tab('Surahs', 0),
                _tab('Juz', 1),
                _tab('Prayer', 2),
              ],
            ),
          ),
          if (selectedTab != 2) ...[
            SizedBox(height: 12),
            SizedBox(
              height: 55,
              child: TextField(
                onChanged: widget.onSearch,
                style: TextStyle(color: Colors.white, fontSize: 15),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: selectedTab == 0
                      ? 'Search surah by name or number...'
                      : 'Search Juz...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: darkGreen,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: cream, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: gold, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
          widget.onSearch?.call('');
          widget.onTabChanged?.call(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cream : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? green : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
