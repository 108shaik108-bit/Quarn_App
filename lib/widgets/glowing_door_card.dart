import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlowingDoorCard extends StatefulWidget {
  final ValueChanged<String>? onSearch;
  final ValueChanged<bool>? onTabChanged;

  const GlowingDoorCard({
    super.key,
    this.onSearch,
    this.onTabChanged,
  });

  @override
  State<GlowingDoorCard> createState() => _GlowingDoorCardState();
}

class _GlowingDoorCardState extends State<GlowingDoorCard> {
  bool showSurahs = true;

  static const Color green = Color(0xFF07502D);
  static const Color deepGreen = Color(0xFF043D23);
  static const Color gold = Color(0xFFD7AC57);
  static const Color cream = Color(0xFFFFF3DC);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 32;
        final compact = width < 560;
        final cardHeight = compact ? 174.0 : 210.0;

        return Container(
          width: double.infinity,
          height: cardHeight,
          padding: EdgeInsets.all(compact ? 10 : 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gold.withOpacity(0.65)),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: width * (compact ? 0.34 : 0.36),
                child: CustomPaint(
                  painter: GlowingDoorPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
              SizedBox(width: compact ? 8 : 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildTabs(compact),
                    SizedBox(height: compact ? 10 : 14),
                    _buildSearch(compact),
                    if (!compact) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Read  •  Reflect  •  Understand',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: gold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
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
  }

  Widget _buildTabs(bool compact) {
    return Container(
      width: double.infinity,
      height: compact ? 42 : 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: deepGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: gold.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          _buildTab('Surahs', true, compact),
          _buildTab('Juz', false, compact),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSurah, bool compact) {
    final selected = showSurahs == isSurah;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (showSurahs == isSurah) return;
          setState(() => showSurahs = isSurah);
          widget.onTabChanged?.call(isSurah);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? cream : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? green : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 13 : 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(bool compact) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 46 : 54,
      child: TextField(
        onChanged: widget.onSearch,
        style: TextStyle(color: Colors.white, fontSize: compact ? 12 : 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: showSurahs ? 'Search surah by name or number...' : 'Search Juz...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: compact ? 10 : 13,
          ),
          prefixIcon: const Icon(Icons.search, color: gold),
          prefixIconConstraints: const BoxConstraints(minWidth: 42),
          filled: true,
          fillColor: const Color(0xFF064426),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold.withOpacity(0.75)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: gold.withOpacity(0.75)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class GlowingDoorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final doorWidth = size.width * 0.72;
    final left = center - doorWidth / 2;
    final right = center + doorWidth / 2;
    final top = size.height * 0.08;
    final bottom = size.height * 0.88;

    canvas.drawCircle(
      Offset(center, size.height * 0.58),
      size.width * 0.72,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(center, size.height * 0.58),
          size.width * 0.72,
          [
            const Color(0xFFFFE8A3).withOpacity(0.8),
            const Color(0xFFFFC45C).withOpacity(0.22),
            Colors.transparent,
          ],
        ),
    );

    final door = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + doorWidth * 0.34)
      ..quadraticBezierTo(left, top, center, top)
      ..quadraticBezierTo(right, top, right, top + doorWidth * 0.34)
      ..lineTo(right, bottom)
      ..close();

    canvas.drawPath(
      door,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center, top),
          Offset(center, bottom),
          const [Color(0xFFFFF0B8), Color(0xFFFFC65C), Color(0xFF9B5725)],
        ),
    );
    canvas.drawPath(
      door,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final inner = Path()
      ..moveTo(left + 7, bottom)
      ..lineTo(left + 7, top + doorWidth * 0.37)
      ..quadraticBezierTo(left + 7, top + 7, center, top + 7)
      ..quadraticBezierTo(right - 7, top + 7, right - 7, top + doorWidth * 0.37)
      ..lineTo(right - 7, bottom);
    canvas.drawPath(
      inner,
      Paint()
        ..color = const Color(0xFFFFE8A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final stepPaint = Paint()..color = gold;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center, bottom + 4 + i * 5),
            width: doorWidth + 12 + i * 10,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        stepPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
