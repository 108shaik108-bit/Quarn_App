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

  static bool get isDark => AppSettings.isDark;
  static Color get gold =>
      isDark ? const Color(0xFFE0B96B) : const Color(0xFFB88732);
  static Color get panel =>
      isDark ? const Color(0xFF29251D) : const Color(0xFFFFF5DF);
  static Color get selectedFill =>
      isDark ? const Color(0xFFE0B96B) : const Color(0xFFF2D28B);
  static Color get textColor =>
      isDark ? const Color(0xFFFFE8B0) : const Color(0xFF543A18);
  static Color get searchText =>
      isDark ? const Color(0xFFFFF1D0) : const Color(0xFF3E3020);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      children: [
        Container(
          height: 82,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(42),
            border: Border.all(color: gold, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.18),
                blurRadius: 11,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _tab('Surahs', 0, Icons.menu_book_rounded),
              _tab('Juz', 1, Icons.auto_stories_rounded),
              _tab('Prayer', 2, Icons.account_balance_rounded),
            ],
          ),
        ),
        if (selectedTab != 2) ...[
          const SizedBox(height: 13),
          Container(
            height: 61,
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: gold, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.12),
                  blurRadius: 9,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              onChanged: widget.onSearch,
              style: TextStyle(color: searchText, fontSize: 15),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: selectedTab == 0
                    ? 'Search Surah by name or number'
                    : 'Search Juz',
                hintStyle: TextStyle(
                  color: searchText.withOpacity(0.72),
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: gold, size: 27),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 9,
            height: 9,
            transform: Matrix4.rotationZ(0.785398),
            decoration: BoxDecoration(
              color: panel,
              border: Border.all(color: gold, width: 1.2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tab(String label, int index, IconData icon) {
    final selected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => selectedTab = index);
          widget.onSearch?.call('');
          widget.onTabChanged?.call(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: gold.withOpacity(0.18),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 25, color: textColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
