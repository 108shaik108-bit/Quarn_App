
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(22),
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
          // Glowing Islamic doorway
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: GlowingDoorPainter(),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Surahs, Juz and search
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF043D23),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _tabButton('Surahs', true),
                      _tabButton('Juz', false),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  onChanged: widget.onSearch,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Surah...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: gold,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF064426),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(
                        color: gold,
                        width: 0.6,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(
                        color: gold.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Read • Reflect • Understand',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String title, bool isSurah) {
    final selected = showSurahs == isSurah;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            showSurahs = isSurah;
          });
          widget.onTabChanged?.call(isSurah);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? cream : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? green : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
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
    final bottom = size.height - 8;

    // Golden light behind the doorway
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

    // Door shape with pointed arch
    final doorPath = Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + doorWidth * 0.35)
      ..quadraticBezierTo(
        left,
        top,
        center,
        top,
      )
      ..quadraticBezierTo(
        right,
        top,
        right,
        top + doorWidth * 0.35,
      )
      ..lineTo(right, bottom)
      ..close();

    // Warm illuminated interior
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

    // Inner doorway shadow
    final inner = doorPath.shift(const Offset(0, 0));
    canvas.drawPath(
      inner,
      Paint()
        ..color = const Color(0xFFFFE6A0).withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Golden arch outline
    canvas.drawPath(
      doorPath,
      Paint()
        ..color = const Color(0xFFE4BB67)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Inner decorative arch
    final innerPath = Path()
      ..moveTo(left + 8, bottom - 2)
      ..lineTo(left + 8, top + doorWidth * 0.38)
      ..quadraticBezierTo(
        left + 8,
        top + 8,
        center,
        top + 8,
      )
      ..quadraticBezierTo(
        right - 8,
        top + 8,
        right - 8,
        top + doorWidth * 0.38,
      )
      ..lineTo(right - 8, bottom - 2);

    canvas.drawPath(
      innerPath,
      Paint()
        ..color = const Color(0xFFFFE8A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Decorative geometric details at the top
    final starPaint = Paint()
      ..color = const Color(0xFF9B682B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(
      Offset(center, top + 25),
      5,
      starPaint,
    );

    canvas.drawLine(
      Offset(center - 10, top + 25),
      Offset(center + 10, top + 25),
      starPaint,
    );

    // Doorway steps
    final stepPaint = Paint()
      ..color = const Color(0xFFD4A452)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final stepWidth = doorWidth + 12 + (i * 10);
      final y = bottom + (i * 6);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center, y),
            width: stepWidth,
            height: 5,
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
