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
  static Color get green =>
      isDark ? const Color(0xFF241D1A) : const Color(0xFF493326);
  static Color get deepGreen =>
      isDark ? const Color(0xFF17120F) : const Color(0xFF35251D);
  static Color get gold =>
      isDark ? const Color(0xFFE0B96B) : const Color(0xFFD9B65D);
  static Color get cream =>
      isDark ? const Color(0xFFFFE9B0) : const Color(0xFFFFF7E5);
  static Color get ink =>
      isDark ? const Color(0xFF241D1A) : const Color(0xFF493326);

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF293B31), Color(0xFF17231D)]
              : const [
                  Color(0xFFFFF8E8),
                  Color(0xFFF2DDAF),
                  Color(0xFFFFF4D9),
                ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.14),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 74,
            child: Row(
              children: [
                _tab('Surahs', 0, Icons.menu_book_rounded),
                _tabDivider(),
                _tab('Juz', 1, Icons.auto_stories_rounded),
                _tabDivider(),
                _tab('Prayer', 2, Icons.account_balance_rounded),
              ],
            ),
          ),
          if (selectedTab != 2) ...[
            const SizedBox(height: 12),
            Container(
              height: 37,
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.45),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: cream.withOpacity(0.9),
                  width: 1.35,
                ),
              ),
              child: TextField(
                onChanged: widget.onSearch,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: selectedTab == 0
                      ? 'Search surah by name or number...'
                      : 'Search Juz...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.5,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cream,
                    size: 29,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabDivider() => Container(
        width: 1,
        height: 28,
        color: const Color(0xFF493326).withOpacity(0.35),
      );

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
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          decoration: BoxDecoration(
            color: deepGreen.withOpacity(0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? gold : cream.withOpacity(0.75),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: cream),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
