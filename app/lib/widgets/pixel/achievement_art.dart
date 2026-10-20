import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../theme/pixel_theme.dart';

/// Original 16-unit pixel artwork; rectangles remain crisp at every app size.
/// No font glyphs, smoothing, network assets or reference changes are needed.
class AchievementArt extends StatelessWidget {
  const AchievementArt({
    super.key,
    required this.type,
    this.size = 48,
    this.collected = true,
  });
  final AchievementType type;
  final double size;
  final bool collected;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${type.label}像素成就',
    child: Opacity(
      opacity: collected ? 1 : .35,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _AchievementPainter(type.id)),
      ),
    ),
  );
}

class _AchievementPainter extends CustomPainter {
  const _AchievementPainter(this.id);
  final String id;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 16, size.height / 16);
    void r(double x, double y, double w, double h, Color color) =>
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          Paint()
            ..color = color
            ..isAntiAlias = false,
        );
    void block(double x, double y, double w, double h, Color color) {
      r(x + 1, y + 1, w, h, PixelColors.shadow);
      r(x, y, w, h, PixelColors.edge);
      if (w > 2 && h > 2) r(x + 1, y + 1, w - 2, h - 2, color);
    }

    const green = PixelColors.primary,
        gold = PixelColors.gold,
        pink = PixelColors.pink,
        purple = PixelColors.purple;
    switch (id) {
      case 'code':
        block(2, 2, 12, 9, purple);
        r(3, 3, 10, 6, PixelColors.sky);
        r(5, 5, 1, 1, green);
        r(4, 6, 1, 1, green);
        r(5, 7, 1, 1, green);
        r(10, 5, 1, 1, green);
        r(11, 6, 1, 1, green);
        r(10, 7, 1, 1, green);
        r(1, 12, 14, 2, gold);
        r(4, 12, 8, 1, PixelColors.edge);
      case 'cooking':
        r(4, 2, 1, 2, gold);
        r(7, 1, 1, 3, gold);
        r(10, 2, 1, 2, gold);
        block(2, 6, 11, 7, purple);
        r(1, 6, 13, 2, gold);
        r(14, 7, 2, 2, green);
        r(4, 9, 6, 2, pink);
      case 'travel':
        block(3, 4, 10, 10, purple);
        r(6, 1, 4, 1, gold);
        r(5, 2, 1, 3, gold);
        r(10, 2, 1, 3, gold);
        r(5, 6, 1, 7, gold);
        r(10, 6, 1, 7, gold);
        r(4, 14, 2, 1, green);
        r(10, 14, 2, 1, green);
      case 'swimming':
        block(9, 2, 4, 4, gold);
        r(3, 5, 7, 2, pink);
        r(2, 4, 2, 2, pink);
        r(1, 9, 4, 2, purple);
        r(5, 10, 4, 2, purple);
        r(9, 9, 5, 2, purple);
        r(2, 13, 4, 2, green);
        r(6, 12, 4, 2, green);
        r(10, 13, 4, 2, green);
      case 'fitness':
        block(1, 4, 4, 8, purple);
        block(11, 4, 4, 8, purple);
        r(5, 7, 6, 2, gold);
        r(2, 5, 2, 6, green);
        r(12, 5, 2, 6, green);
      case 'photo':
        r(4, 2, 4, 3, gold);
        block(1, 4, 14, 9, purple);
        r(2, 5, 3, 2, gold);
        r(6, 6, 6, 5, PixelColors.shadow);
        r(7, 7, 4, 3, green);
        r(8, 7, 1, 1, PixelColors.text);
      case 'dining':
        r(1, 2, 1, 5, gold);
        r(3, 2, 1, 5, gold);
        r(1, 6, 3, 2, gold);
        r(2, 8, 1, 6, gold);
        block(5, 3, 8, 10, purple);
        r(7, 5, 4, 6, pink);
        r(14, 2, 1, 12, gold);
      case 'makeup':
        r(6, 1, 4, 1, pink);
        r(5, 2, 5, 5, pink);
        r(6, 3, 1, 2, PixelColors.text);
        r(4, 7, 8, 2, gold);
        block(4, 9, 8, 6, purple);
        r(6, 10, 4, 3, pink);
      case 'life':
        r(7, 1, 2, 2, pink);
        r(5, 3, 6, 2, gold);
        r(3, 5, 10, 2, gold);
        block(4, 7, 8, 7, purple);
        r(7, 9, 2, 5, green);
        r(5, 8, 1, 2, pink);
      case 'fun':
        block(1, 5, 14, 7, purple);
        r(3, 7, 1, 4, green);
        r(2, 8, 3, 1, green);
        r(10, 7, 2, 2, pink);
        r(12, 9, 2, 2, gold);
        r(5, 4, 6, 1, gold);
      case 'sport':
        r(3, 2, 4, 5, purple);
        r(5, 5, 4, 4, purple);
        r(9, 8, 4, 2, pink);
        block(2, 10, 12, 4, green);
        r(3, 11, 9, 1, gold);
      case 'work':
        r(5, 2, 6, 1, gold);
        r(4, 3, 1, 3, gold);
        r(11, 3, 1, 3, gold);
        block(1, 5, 14, 9, purple);
        r(2, 8, 12, 1, gold);
        r(7, 8, 2, 3, green);
      case 'social':
        block(1, 2, 10, 7, purple);
        r(3, 9, 2, 2, purple);
        r(3, 5, 1, 1, gold);
        r(6, 5, 1, 1, gold);
        block(7, 8, 8, 5, pink);
        r(12, 13, 2, 2, pink);
        r(9, 10, 4, 1, green);
      default:
        r(4, 1, 3, 5, purple);
        r(9, 1, 3, 5, pink);
        block(3, 5, 10, 9, gold);
        r(7, 7, 2, 2, green);
        r(5, 9, 6, 2, green);
        r(6, 11, 1, 2, green);
        r(9, 11, 1, 2, green);
    }
  }

  @override
  bool shouldRepaint(_AchievementPainter old) => old.id != id;
}
