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

  static Color get gold =>
      AppSettings.isDark ? const Color(0xFFE0B96B) : const Color(0xFFFFD875);
  static Color get darkGreen =>
      AppSettings.isDark ? const Color(0xFF0B2117) : const Color(0xFF032F19);
  static Color get cream =>
      AppSettings.isDark ? const Color(0xFF263B2D) : const Color(0xFFFFE3A0);
  static Color get selectedText =>
      AppSettings.isDark ? const Color(0xFF102219) : const Color(0xFF172719);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Column(
      children: [
        Container(
          height: 82,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkGreen, const Color(0xFF062B18), darkGreen],
            ),
            borderRadius: BorderRadius.circular(42),
            border: Border.all(color: gold, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: gold.withOpacity(0.16),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 7,
                offset: const Offset(0, 4),
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
              gradient: LinearGradient(
                colors: [darkGreen, const Color(0xFF062B18), darkGreen],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: gold, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.13),
                  blurRadius: 9,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              onChanged: widget.onSearch,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: selectedTab == 0
                    ? 'Search surah by name or number...'
                    : 'Search Juz...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search_rounded, color: gold, size: 31),
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
              color: darkGreen,
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
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE9AE), Color(0xFFEFC45F)],
                  )
                : null,
            borderRadius: BorderRadius.circular(36),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: gold.withOpacity(0.24),
                      blurRadius: 7,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 27,
                color: selected ? selectedText : gold,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? selectedText : const Color(0xFFFFE5A0),
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
