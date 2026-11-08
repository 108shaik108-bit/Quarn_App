
import 'package:flutter/material.dart';

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

  static const Color green = Color(0xFF07502D);
  static const Color darkGreen = Color(0xFF064426);
  static const Color cream = Color(0xFFFFF5E2);
  static const Color gold = Color(0xFFD7AC57);

  @override
  Widget build(BuildContext context) {
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
            offset: const Offset(0, 4),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 55,
            child: TextField(
              onChanged: widget.onSearch,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: selectedTab == 0
                    ? 'Search surah by name or number...'
                    : selectedTab == 1
                        ? 'Search Juz...'
                        : 'Prayer times coming soon...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: darkGreen,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: cream, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: gold, width: 1.5),
                ),
              ),
            ),
          ),
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
          duration: const Duration(milliseconds: 180),
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
