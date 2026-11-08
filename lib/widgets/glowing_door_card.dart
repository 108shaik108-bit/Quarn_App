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

  static const green = Color(0xFF07502D);
  static const gold = Color(0xFFD7AC57);
  static const cream = Color(0xFFFFF3DC);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final doorHeight = compact ? 148.0 : 184.0;

        return Container(
          padding: EdgeInsets.all(compact ? 10 : 14),
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gold.withOpacity(0.55), width: 1),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: compact ? 4 : 5,
                child: SizedBox(
                  height: doorHeight,
                  child: CustomPaint(
                    painter: GlowingDoorPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 14),
              Expanded(
                flex: compact ? 6 : 7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabSelector(compact),
                    SizedBox(height: compact ? 10 : 14),
                    _searchField(compact),
                    if (!compact) ...[
                      const SizedBox(height: 9),
                      const Text(
                        'Read  •  Reflect  •  Understand',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: gold,
                          fontSize: 10,
                          letterSpacing: 0.4,
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

  Widget _tabSelector(bool compact) {
    return Container(
      height: compact ? 40 : 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF043D23),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: gold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          _tabButton('Surahs', true, compact),
          _tabButton('Juz', false, compact),
        ],
      ),
    );
  }

  Widget _tabButton(String title, bool isSurah, bool compact) {
    final selected = showSurahs == isSurah;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
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
              borderRadius: BorderRadius.circular(25),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? green : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField(bool compact) {
    return SizedBox(
      height: compact ? 46 : 54,
      child: TextField(
        onChanged: widget.onSearch,
        style: TextStyle(color: Colors.white, fontSize: compact ? 12 : 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: showSurahs ? 'Search Surah...' : 'Search Juz...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.68),
            fontSize: compact ? 10 : 12,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: gold,
            size: compact ? 19 : 21,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 40,
          ),
          filled: true,
          fillColor: const Color(0xFF064426),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: gold.withOpacity(0.65)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: gold.withOpacity(0.65)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: gold, width: 1.4),
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
    final top = 18.0;
    final bottom = size.height - 20;

    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center, size.height * 0.57),
        size.width * 0.75,
        [
          const Color(0xFFFFE8A3).withOpacity(0.65),
          const Color(0xFFFFC45C).withOpacity(0.18),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(
      Offset(center, size.height * 0.57),
      size.width * 0.75,
      glowPaint,
    );

    final doorPath = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + doorWidth * 0.35)
      ..quadraticBezierTo(left, top, center, top)
      ..quadraticBezierTo(right, top, right, top + doorWidth * 0.35)
      ..lineTo(right, bottom)
      ..close();

    canvas.drawPath(
      doorPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center, top),
          Offset(center, bottom),
          const [
            Color(0xFFFFF1BF),
            Color(0xFFFFC65C),
            Color(0xFF9B5725),
          ],
        ),
    );

    canvas.drawPath(
      doorPath,
      Paint()
        ..color = const Color(0xFFE4BB67)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final innerPath = Path()
      ..moveTo(left + 8, bottom - 2)
      ..lineTo(left + 8, top + doorWidth * 0.38)
      ..quadraticBezierTo(left + 8, top + 8, center, top + 8)
      ..quadraticBezierTo(right - 8, top + 8, right - 8, top + doorWidth * 0.38)
      ..lineTo(right - 8, bottom - 2);

    canvas.drawPath(
      innerPath,
      Paint()
        ..color = const Color(0xFFFFE8A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final starPaint = Paint()
      ..color = const Color(0xFF9B682B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(center, top + 25), 5, starPaint);
    canvas.drawLine(
      Offset(center - 10, top + 25),
      Offset(center + 10, top + 25),
      starPaint,
    );

    final stepPaint = Paint()..color = const Color(0xFFD4A452);
    for (int i = 0; i < 3; i++) {
      final stepWidth = doorWidth + 12 + (i * 10);
      final y = bottom + 3 + (i * 5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center, y),
            width: stepWidth,
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
