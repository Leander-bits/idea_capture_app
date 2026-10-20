import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/pixel_theme.dart';

// Geometry extracted from the Figma inline SVG paths. No raster scaling or filters.
final _icons = <String, Path>{
  'gem': Path()
    ..moveTo(6, 2)
    ..lineTo(18, 2)
    ..lineTo(18, 5)
    ..lineTo(21, 5)
    ..lineTo(21, 14)
    ..lineTo(18, 14)
    ..lineTo(18, 17)
    ..lineTo(15, 17)
    ..lineTo(15, 20)
    ..lineTo(12, 20)
    ..lineTo(12, 23)
    ..lineTo(9, 23)
    ..lineTo(9, 20)
    ..lineTo(6, 20)
    ..lineTo(6, 17)
    ..lineTo(3, 17)
    ..lineTo(3, 5)
    ..lineTo(6, 5)
    ..close(),
  'chest': Path()
    ..moveTo(5, 3)
    ..lineTo(19, 3)
    ..lineTo(19, 6)
    ..lineTo(22, 6)
    ..lineTo(22, 21)
    ..lineTo(2, 21)
    ..lineTo(2, 6)
    ..lineTo(5, 6)
    ..close()
    ..moveTo(2, 10)
    ..lineTo(22, 10)
    ..lineTo(22, 13)
    ..lineTo(2, 13)
    ..close(),
  'sword': Path()
    ..moveTo(17, 1)
    ..lineTo(23, 1)
    ..lineTo(23, 7)
    ..lineTo(20, 7)
    ..lineTo(20, 10)
    ..lineTo(17, 10)
    ..lineTo(17, 13)
    ..lineTo(14, 13)
    ..lineTo(14, 16)
    ..lineTo(17, 16)
    ..lineTo(17, 19)
    ..lineTo(11, 19)
    ..lineTo(11, 16)
    ..lineTo(8, 16)
    ..lineTo(8, 19)
    ..lineTo(5, 19)
    ..lineTo(5, 22)
    ..lineTo(2, 22)
    ..lineTo(2, 19)
    ..lineTo(5, 19)
    ..lineTo(5, 16)
    ..lineTo(8, 16)
    ..lineTo(8, 13)
    ..lineTo(5, 13)
    ..lineTo(5, 10)
    ..lineTo(8, 10)
    ..lineTo(8, 13)
    ..lineTo(11, 13)
    ..lineTo(11, 9)
    ..lineTo(14, 9)
    ..lineTo(14, 6)
    ..lineTo(17, 6)
    ..close(),
  'scroll': Path()
    ..moveTo(4, 2)
    ..lineTo(19, 2)
    ..lineTo(19, 5)
    ..lineTo(22, 5)
    ..lineTo(22, 9)
    ..lineTo(19, 9)
    ..lineTo(19, 5)
    ..lineTo(7, 5)
    ..lineTo(7, 19)
    ..lineTo(19, 19)
    ..lineTo(19, 16)
    ..lineTo(22, 16)
    ..lineTo(22, 22)
    ..lineTo(4, 22)
    ..lineTo(4, 19)
    ..lineTo(1, 19)
    ..lineTo(1, 5)
    ..lineTo(4, 5)
    ..close()
    ..moveTo(10, 8)
    ..lineTo(16, 8)
    ..lineTo(16, 10)
    ..lineTo(10, 10)
    ..close()
    ..moveTo(10, 12)
    ..lineTo(16, 12)
    ..lineTo(16, 14)
    ..lineTo(10, 14)
    ..close(),
  'heart': Path()
    ..moveTo(3, 3)
    ..lineTo(9, 3)
    ..lineTo(9, 6)
    ..lineTo(15, 6)
    ..lineTo(15, 3)
    ..lineTo(21, 3)
    ..lineTo(21, 6)
    ..lineTo(24, 6)
    ..lineTo(24, 15)
    ..lineTo(21, 15)
    ..lineTo(21, 18)
    ..lineTo(18, 18)
    ..lineTo(18, 21)
    ..lineTo(15, 21)
    ..lineTo(15, 24)
    ..lineTo(9, 24)
    ..lineTo(9, 21)
    ..lineTo(6, 21)
    ..lineTo(6, 18)
    ..lineTo(3, 18)
    ..lineTo(3, 15)
    ..lineTo(0, 15)
    ..lineTo(0, 6)
    ..lineTo(3, 6)
    ..close(),
  'crown': Path()
    ..moveTo(1, 4)
    ..lineTo(4, 4)
    ..lineTo(4, 7)
    ..lineTo(7, 7)
    ..lineTo(7, 10)
    ..lineTo(10, 10)
    ..lineTo(10, 3)
    ..lineTo(14, 3)
    ..lineTo(14, 10)
    ..lineTo(17, 10)
    ..lineTo(17, 7)
    ..lineTo(20, 7)
    ..lineTo(20, 4)
    ..lineTo(23, 4)
    ..lineTo(23, 19)
    ..lineTo(1, 19)
    ..close()
    ..moveTo(4, 21)
    ..lineTo(20, 21)
    ..lineTo(20, 24)
    ..lineTo(4, 24)
    ..close(),
};

class _ArtPath {
  _ArtPath(this.role, this.path);
  final String role;
  final Path path;
}

final _scene = <_ArtPath>[
  _ArtPath(
    'pixel-star',
    Path()
      ..moveTo(20, 14)
      ..lineTo(23, 14)
      ..lineTo(23, 17)
      ..lineTo(20, 17)
      ..close()
      ..moveTo(57, 34)
      ..lineTo(59, 34)
      ..lineTo(59, 36)
      ..lineTo(57, 36)
      ..close()
      ..moveTo(112, 12)
      ..lineTo(115, 12)
      ..lineTo(115, 15)
      ..lineTo(112, 15)
      ..close()
      ..moveTo(155, 29)
      ..lineTo(157, 29)
      ..lineTo(157, 31)
      ..lineTo(155, 31)
      ..close()
      ..moveTo(206, 12)
      ..lineTo(209, 12)
      ..lineTo(209, 15)
      ..lineTo(206, 15)
      ..close()
      ..moveTo(290, 32)
      ..lineTo(293, 32)
      ..lineTo(293, 35)
      ..lineTo(290, 35)
      ..close()
      ..moveTo(176, 54)
      ..lineTo(178, 54)
      ..lineTo(178, 56)
      ..lineTo(176, 56)
      ..close()
      ..moveTo(85, 54)
      ..lineTo(87, 54)
      ..lineTo(87, 56)
      ..lineTo(85, 56)
      ..close(),
  ),
  _ArtPath(
    'pixel-moon',
    Path()
      ..moveTo(246, 12)
      ..lineTo(266, 12)
      ..lineTo(266, 16)
      ..lineTo(274, 16)
      ..lineTo(274, 24)
      ..lineTo(278, 24)
      ..lineTo(278, 40)
      ..lineTo(274, 40)
      ..lineTo(274, 48)
      ..lineTo(266, 48)
      ..lineTo(266, 52)
      ..lineTo(246, 52)
      ..lineTo(246, 48)
      ..lineTo(238, 48)
      ..lineTo(238, 40)
      ..lineTo(234, 40)
      ..lineTo(234, 24)
      ..lineTo(238, 24)
      ..lineTo(238, 16)
      ..lineTo(246, 16)
      ..close(),
  ),
  _ArtPath(
    'pixel-moon-shade',
    Path()
      ..moveTo(246, 16)
      ..lineTo(254, 16)
      ..lineTo(254, 24)
      ..lineTo(246, 24)
      ..close()
      ..moveTo(264, 32)
      ..lineTo(272, 32)
      ..lineTo(272, 40)
      ..lineTo(264, 40)
      ..close()
      ..moveTo(242, 36)
      ..lineTo(246, 36)
      ..lineTo(246, 40)
      ..lineTo(242, 40)
      ..close(),
  ),
  _ArtPath(
    'pixel-mountain',
    Path()
      ..moveTo(0, 74)
      ..lineTo(20, 74)
      ..lineTo(20, 62)
      ..lineTo(36, 62)
      ..lineTo(36, 50)
      ..lineTo(56, 50)
      ..lineTo(56, 38)
      ..lineTo(72, 38)
      ..lineTo(72, 50)
      ..lineTo(88, 50)
      ..lineTo(88, 62)
      ..lineTo(108, 62)
      ..lineTo(108, 74)
      ..lineTo(128, 74)
      ..lineTo(128, 84)
      ..lineTo(158, 84)
      ..lineTo(158, 68)
      ..lineTo(178, 68)
      ..lineTo(178, 56)
      ..lineTo(196, 56)
      ..lineTo(196, 44)
      ..lineTo(216, 44)
      ..lineTo(216, 56)
      ..lineTo(232, 56)
      ..lineTo(232, 68)
      ..lineTo(252, 68)
      ..lineTo(252, 80)
      ..lineTo(276, 80)
      ..lineTo(276, 68)
      ..lineTo(296, 68)
      ..lineTo(296, 56)
      ..lineTo(314, 56)
      ..lineTo(314, 68)
      ..lineTo(336, 68)
      ..lineTo(336, 104)
      ..lineTo(0, 104)
      ..close(),
  ),
  _ArtPath(
    'pixel-mountain-near',
    Path()
      ..moveTo(0, 90)
      ..lineTo(38, 90)
      ..lineTo(38, 78)
      ..lineTo(60, 78)
      ..lineTo(60, 66)
      ..lineTo(80, 66)
      ..lineTo(80, 78)
      ..lineTo(102, 78)
      ..lineTo(102, 90)
      ..lineTo(140, 90)
      ..lineTo(140, 82)
      ..lineTo(166, 82)
      ..lineTo(166, 70)
      ..lineTo(186, 70)
      ..lineTo(186, 82)
      ..lineTo(210, 82)
      ..lineTo(210, 92)
      ..lineTo(250, 92)
      ..lineTo(250, 82)
      ..lineTo(270, 82)
      ..lineTo(270, 72)
      ..lineTo(290, 72)
      ..lineTo(290, 82)
      ..lineTo(320, 82)
      ..lineTo(320, 104)
      ..lineTo(0, 104)
      ..close(),
  ),
  _ArtPath(
    'pixel-ground',
    Path()
      ..moveTo(0, 98)
      ..lineTo(320, 98)
      ..lineTo(320, 104)
      ..lineTo(0, 104)
      ..close(),
  ),
  _ArtPath(
    'pixel-grass',
    Path()
      ..moveTo(0, 96)
      ..lineTo(80, 96)
      ..lineTo(80, 100)
      ..lineTo(0, 100)
      ..close()
      ..moveTo(112, 96)
      ..lineTo(170, 96)
      ..lineTo(170, 100)
      ..lineTo(112, 100)
      ..close()
      ..moveTo(228, 96)
      ..lineTo(320, 96)
      ..lineTo(320, 100)
      ..lineTo(228, 100)
      ..close(),
  ),
  _ArtPath(
    'pixel-castle',
    Path()
      ..moveTo(28, 60)
      ..lineTo(36, 60)
      ..lineTo(36, 68)
      ..lineTo(44, 68)
      ..lineTo(44, 60)
      ..lineTo(52, 60)
      ..lineTo(52, 68)
      ..lineTo(60, 68)
      ..lineTo(60, 60)
      ..lineTo(68, 60)
      ..lineTo(68, 96)
      ..lineTo(28, 96)
      ..close()
      ..moveTo(34, 40)
      ..lineTo(42, 40)
      ..lineTo(42, 48)
      ..lineTo(50, 48)
      ..lineTo(50, 40)
      ..lineTo(58, 40)
      ..lineTo(58, 60)
      ..lineTo(34, 60)
      ..close(),
  ),
  _ArtPath(
    'pixel-face',
    Path()
      ..moveTo(42, 80)
      ..lineTo(54, 80)
      ..lineTo(54, 96)
      ..lineTo(42, 96)
      ..close()
      ..moveTo(40, 54)
      ..lineTo(44, 54)
      ..lineTo(44, 60)
      ..lineTo(40, 60)
      ..close()
      ..moveTo(52, 54)
      ..lineTo(56, 54)
      ..lineTo(56, 60)
      ..lineTo(52, 60)
      ..close(),
  ),
  _ArtPath(
    'adventure-trail',
    Path()
      ..moveTo(76, 94)
      ..lineTo(100, 94)
      ..lineTo(100, 96)
      ..lineTo(76, 96)
      ..close()
      ..moveTo(118, 94)
      ..lineTo(142, 94)
      ..lineTo(142, 96)
      ..lineTo(118, 96)
      ..close()
      ..moveTo(160, 94)
      ..lineTo(184, 94)
      ..lineTo(184, 96)
      ..lineTo(160, 96)
      ..close()
      ..moveTo(202, 94)
      ..lineTo(226, 94)
      ..lineTo(226, 96)
      ..lineTo(202, 96)
      ..close(),
  ),
  _ArtPath(
    'pixel-moon',
    Path()
      ..moveTo(262, 70)
      ..lineTo(266, 70)
      ..lineTo(266, 76)
      ..lineTo(262, 76)
      ..close()
      ..moveTo(276, 68)
      ..lineTo(280, 68)
      ..lineTo(280, 76)
      ..lineTo(276, 76)
      ..close()
      ..moveTo(270, 62)
      ..lineTo(273, 62)
      ..lineTo(273, 67)
      ..lineTo(270, 67)
      ..close(),
  ),
  _ArtPath(
    'pixel-character',
    Path()
      ..moveTo(264, 76)
      ..lineTo(278, 76)
      ..lineTo(278, 80)
      ..lineTo(264, 80)
      ..close(),
  ),
  _ArtPath(
    'pixel-moon',
    Path()
      ..moveTo(254, 86)
      ..lineTo(286, 86)
      ..lineTo(286, 96)
      ..lineTo(254, 96)
      ..close(),
  ),
  _ArtPath(
    'pixel-face',
    Path()
      ..moveTo(254, 86)
      ..lineTo(286, 86)
      ..lineTo(286, 89)
      ..lineTo(254, 89)
      ..close()
      ..moveTo(267, 87)
      ..lineTo(273, 87)
      ..lineTo(273, 93)
      ..lineTo(267, 93)
      ..close(),
  ),
  _ArtPath(
    'pixel-moon',
    Path()
      ..moveTo(258, 80)
      ..lineTo(282, 80)
      ..lineTo(282, 84)
      ..lineTo(286, 84)
      ..lineTo(286, 87)
      ..lineTo(254, 87)
      ..lineTo(254, 84)
      ..lineTo(258, 84)
      ..close(),
  ),
  _ArtPath(
    'pixel-moon-shade',
    Path()
      ..moveTo(258, 81)
      ..lineTo(282, 81)
      ..lineTo(282, 83)
      ..lineTo(258, 83)
      ..close(),
  ),
  _ArtPath(
    'pixel-character-shadow',
    Path()
      ..moveTo(141, 92)
      ..lineTo(167, 92)
      ..lineTo(167, 96)
      ..lineTo(141, 96)
      ..close(),
  ),
  _ArtPath(
    'pixel-character',
    Path()
      ..moveTo(148, 67)
      ..lineTo(160, 67)
      ..lineTo(160, 71)
      ..lineTo(164, 71)
      ..lineTo(164, 83)
      ..lineTo(160, 83)
      ..lineTo(160, 91)
      ..lineTo(156, 91)
      ..lineTo(156, 83)
      ..lineTo(152, 83)
      ..lineTo(152, 91)
      ..lineTo(148, 91)
      ..lineTo(148, 79)
      ..lineTo(144, 79)
      ..lineTo(144, 71)
      ..lineTo(148, 71)
      ..close(),
  ),
  _ArtPath(
    'pixel-face',
    Path()
      ..moveTo(152, 71)
      ..lineTo(160, 71)
      ..lineTo(160, 75)
      ..lineTo(152, 75)
      ..close(),
  ),
  _ArtPath(
    'pixel-sword',
    Path()
      ..moveTo(170, 69)
      ..lineTo(174, 69)
      ..lineTo(174, 87)
      ..lineTo(170, 87)
      ..close()
      ..moveTo(166, 81)
      ..lineTo(178, 81)
      ..lineTo(178, 85)
      ..lineTo(166, 85)
      ..close(),
  ),
];

class PixelIcon extends StatelessWidget {
  const PixelIcon(
    this.kind, {
    super.key,
    this.size = 24,
    this.color = PixelColors.purple,
  });
  final String kind;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(kind, color)),
    ),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.kind, this.color);
  final String kind;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      _icons[kind] ?? _icons['scroll']!,
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
    if (kind == 'chest') {
      canvas.drawRect(
        const Rect.fromLTWH(10, 9, 4, 7),
        Paint()..color = PixelColors.shadow,
      );
    } else if (kind == 'gem') {
      canvas.drawRect(
        const Rect.fromLTWH(7, 5, 5, 3),
        Paint()..color = PixelColors.highlight,
      );
      canvas.drawRect(
        const Rect.fromLTWH(5, 8, 3, 5),
        Paint()..color = PixelColors.highlight,
      );
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.kind != kind || old.color != color;
}

class PixelAdventureScene extends StatefulWidget {
  const PixelAdventureScene({
    super.key,
    required this.completedCount,
    this.opened = false,
  });
  final int completedCount;
  final bool opened;
  @override
  State<PixelAdventureScene> createState() => _PixelAdventureSceneState();
}

class _PixelAdventureSceneState extends State<PixelAdventureScene>
    with TickerProviderStateMixin {
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final _step = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final _chest = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
    value: widget.opened ? 1 : 0,
  );
  double _from = -106;
  bool _reduced = false;
  // Four verified source positions: start and three energy steps.
  static double _position(int count) => -106 + 62.0 * count.clamp(0, 3);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _idle.stop();
      _step.value = 1;
      _chest.value = widget.opened ? 1 : 0;
    } else {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(PixelAdventureScene old) {
    super.didUpdateWidget(old);
    if (old.opened != widget.opened) {
      if (_reduced || !widget.opened) {
        _chest.value = widget.opened ? 1 : 0;
      } else {
        _chest.forward(from: 0);
      }
    }
    if (old.completedCount != widget.completedCount) {
      final oldTarget = _position(old.completedCount);
      final progress = (_step.value * 12).floor() / 12;
      _from = _step.isAnimating
          ? _from + (oldTarget - _from) * progress
          : oldTarget;
      if (_reduced) {
        _step.value = 1;
      } else {
        _step.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _step.dispose();
    _chest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 110,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _step, _chest]),
        builder: (context, _) => CustomPaint(
          painter: _ScenePainter(
            completedCount: widget.completedCount,
            opened: widget.opened,
            chestElapsed: _chest.value * 1800,
            phase: _reduced ? 0 : _idle.value,
            elapsed: _step.value * 750,
            from: _from,
            moving: _step.isAnimating,
            reduced: _reduced,
          ),
        ),
      ),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.completedCount,
    required this.opened,
    required this.chestElapsed,
    required this.phase,
    required this.elapsed,
    required this.from,
    required this.moving,
    required this.reduced,
  });
  final int completedCount;
  final bool opened;
  final double chestElapsed;
  final double phase, elapsed, from;
  final bool moving, reduced;
  double _steps(double value, int count) =>
      (value.clamp(0.0, 1.0) * count).floor() / count;
  @override
  void paint(Canvas canvas, Size size) {
    // Match the SVG viewport; mountain geometry extends beyond the viewBox.
    canvas.clipRect(Offset.zero & size, doAntiAlias: false);
    canvas.drawRect(Offset.zero & size, Paint()..color = PixelColors.sky);
    final scale = math.min(size.width / 320, size.height / 104);
    canvas.translate((size.width - 320 * scale) / 2, size.height - 104 * scale);
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, 320, 104), doAntiAlias: false);
    final x = moving
        ? from +
              (_PixelAdventureSceneState._position(completedCount) - from) *
                  _steps(elapsed / 750, 12)
        : _PixelAdventureSceneState._position(completedCount);
    for (var i = 0; i < _scene.length; i++) {
      final art = _scene[i];
      canvas.save();
      var opacity = 1.0;
      if (i == 0 && !reduced) opacity = phase < .5 ? 1 : .45;
      // Match the source's delayed, stepped lid and treasure animations.
      if (i == 10 || i == 11) {
        final rise = opened ? _steps((chestElapsed - 1100) / 650, 6) : 0.0;
        if (rise == 0) {
          canvas.restore();
          continue;
        }
        opacity = rise;
        canvas.translate(0, 8 - 11 * rise);
      }
      if (i == 14 || i == 15) {
        final lid = opened ? _steps((chestElapsed - 800) / 550, 5) : 0.0;
        canvas.translate(286, 88 - 3 * lid);
        canvas.rotate(55 * math.pi / 180 * lid);
        canvas.translate(-286, -88);
      }
      if (i >= 16) {
        canvas.translate(x, 0);
        if (i > 16 && !reduced) {
          final bounce = moving && elapsed < 750
              ? (elapsed % 150 < 75 ? 0.0 : -3.0)
              : ((phase * 3000) % 1800 < 900 ? 0.0 : -1.0);
          canvas.translate(0, bounce);
        }
      }
      final color = switch (art.role) {
        'pixel-star' || 'pixel-castle' => PixelColors.highlight,
        'pixel-moon' || 'pixel-sword' || 'adventure-trail' => PixelColors.gold,
        'pixel-moon-shade' => PixelColors.pink,
        'pixel-mountain' => PixelColors.mountain,
        'pixel-mountain-near' => PixelColors.mountainNear,
        'pixel-grass' => PixelColors.purple,
        'pixel-character' => PixelColors.primary,
        _ => PixelColors.shadow,
      };
      if (art.role == 'adventure-trail') opacity *= .45;
      canvas.drawPath(
        art.path,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..isAntiAlias = false,
      );
      canvas.restore();
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 102, 320, 2),
      Paint()..color = PixelColors.mountainNear,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.opened != opened ||
      old.chestElapsed != chestElapsed ||
      completedCount != old.completedCount ||
      phase != old.phase ||
      elapsed != old.elapsed ||
      reduced != old.reduced;
}
