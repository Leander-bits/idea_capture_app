import 'package:flutter/material.dart';

import '../../theme/pixel_theme.dart';

/// Geometry and stepped motion from the Capture SVG and CSS reference.
class PixelCaptureScene extends StatefulWidget {
  const PixelCaptureScene({super.key, required this.listening});
  final bool listening;
  @override
  State<PixelCaptureScene> createState() => _PixelCaptureSceneState();
}

class _PixelCaptureSceneState extends State<PixelCaptureScene>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
      _clock.value = 0;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: 104,
      decoration: BoxDecoration(
        color: PixelColors.sky,
        border: Border.all(color: PixelColors.border),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _clock,
          builder: (_, _) => CustomPaint(
            painter: _ScenePainter(
              MediaQuery.disableAnimationsOf(context) ? 0 : _clock.value * 24,
              widget.listening,
              MediaQuery.disableAnimationsOf(context),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
}

class _Part {
  _Part(this.path, this.color, this.motion, this.index);
  final Path path;
  final Color color;
  final String motion;
  final int index;
}

final _parts = <_Part>[
  _Part(
    Path()
      ..moveTo(0, 24)
      ..lineTo(320, 24)
      ..lineTo(320, 25)
      ..lineTo(0, 25)
      ..close()
      ..moveTo(0, 48)
      ..lineTo(320, 48)
      ..lineTo(320, 49)
      ..lineTo(0, 49)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(320, 72)
      ..lineTo(320, 73)
      ..lineTo(0, 73)
      ..close()
      ..moveTo(32, 0)
      ..lineTo(33, 0)
      ..lineTo(33, 104)
      ..lineTo(32, 104)
      ..close()
      ..moveTo(64, 0)
      ..lineTo(65, 0)
      ..lineTo(65, 104)
      ..lineTo(64, 104)
      ..close()
      ..moveTo(96, 0)
      ..lineTo(97, 0)
      ..lineTo(97, 104)
      ..lineTo(96, 104)
      ..close()
      ..moveTo(128, 0)
      ..lineTo(129, 0)
      ..lineTo(129, 104)
      ..lineTo(128, 104)
      ..close()
      ..moveTo(160, 0)
      ..lineTo(161, 0)
      ..lineTo(161, 104)
      ..lineTo(160, 104)
      ..close()
      ..moveTo(192, 0)
      ..lineTo(193, 0)
      ..lineTo(193, 104)
      ..lineTo(192, 104)
      ..close()
      ..moveTo(224, 0)
      ..lineTo(225, 0)
      ..lineTo(225, 104)
      ..lineTo(224, 104)
      ..close()
      ..moveTo(256, 0)
      ..lineTo(257, 0)
      ..lineTo(257, 104)
      ..lineTo(256, 104)
      ..close()
      ..moveTo(288, 0)
      ..lineTo(289, 0)
      ..lineTo(289, 104)
      ..lineTo(288, 104)
      ..close(),
    PixelColors.mountain.withValues(alpha: .3),
    '',
    0,
  ),
  _Part(
    Path()
      ..moveTo(38, 18)
      ..lineTo(42, 18)
      ..lineTo(42, 14)
      ..lineTo(46, 14)
      ..lineTo(46, 18)
      ..lineTo(50, 18)
      ..lineTo(50, 22)
      ..lineTo(46, 22)
      ..lineTo(46, 26)
      ..lineTo(42, 26)
      ..lineTo(42, 22)
      ..lineTo(38, 22)
      ..close()
      ..moveTo(275, 20)
      ..lineTo(279, 20)
      ..lineTo(279, 16)
      ..lineTo(283, 16)
      ..lineTo(283, 20)
      ..lineTo(287, 20)
      ..lineTo(287, 24)
      ..lineTo(283, 24)
      ..lineTo(283, 28)
      ..lineTo(279, 28)
      ..lineTo(279, 24)
      ..lineTo(275, 24)
      ..close()
      ..moveTo(93, 8)
      ..lineTo(96, 8)
      ..lineTo(96, 11)
      ..lineTo(93, 11)
      ..close()
      ..moveTo(224, 12)
      ..lineTo(227, 12)
      ..lineTo(227, 15)
      ..lineTo(224, 15)
      ..close(),
    PixelColors.gold,
    'spark',
    0,
  ),
  _Part(
    Path()
      ..moveTo(58, 35)
      ..lineTo(82, 35)
      ..lineTo(82, 63)
      ..lineTo(58, 63)
      ..close(),
    PixelColors.pink,
    'note',
    0,
  ),
  _Part(
    Path()
      ..moveTo(63, 41)
      ..lineTo(77, 41)
      ..lineTo(77, 44)
      ..lineTo(63, 44)
      ..close()
      ..moveTo(63, 48)
      ..lineTo(73, 48)
      ..lineTo(73, 51)
      ..lineTo(63, 51)
      ..close(),
    PixelColors.shadow,
    'note',
    1,
  ),
  _Part(
    Path()
      ..moveTo(236, 40)
      ..lineTo(262, 40)
      ..lineTo(262, 64)
      ..lineTo(236, 64)
      ..close(),
    PixelColors.pink,
    'right',
    0,
  ),
  _Part(
    Path()
      ..moveTo(241, 46)
      ..lineTo(257, 46)
      ..lineTo(257, 49)
      ..lineTo(241, 49)
      ..close()
      ..moveTo(241, 53)
      ..lineTo(252, 53)
      ..lineTo(252, 56)
      ..lineTo(241, 56)
      ..close(),
    PixelColors.shadow,
    'right',
    1,
  ),
  _Part(
    Path()
      ..moveTo(92, 46)
      ..lineTo(96, 46)
      ..lineTo(96, 50)
      ..lineTo(92, 50)
      ..close(),
    PixelColors.highlight,
    'signal',
    0,
  ),
  _Part(
    Path()
      ..moveTo(104, 46)
      ..lineTo(108, 46)
      ..lineTo(108, 50)
      ..lineTo(104, 50)
      ..close(),
    PixelColors.highlight,
    'signal',
    1,
  ),
  _Part(
    Path()
      ..moveTo(116, 46)
      ..lineTo(120, 46)
      ..lineTo(120, 50)
      ..lineTo(116, 50)
      ..close(),
    PixelColors.highlight,
    'signal',
    2,
  ),
  _Part(
    Path()
      ..moveTo(217, 46)
      ..lineTo(221, 46)
      ..lineTo(221, 50)
      ..lineTo(217, 50)
      ..close(),
    PixelColors.highlight,
    'signal',
    3,
  ),
  _Part(
    Path()
      ..moveTo(205, 46)
      ..lineTo(209, 46)
      ..lineTo(209, 50)
      ..lineTo(205, 50)
      ..close(),
    PixelColors.highlight,
    'signal',
    4,
  ),
  _Part(
    Path()
      ..moveTo(158, 20)
      ..lineTo(162, 20)
      ..lineTo(162, 34)
      ..lineTo(158, 34)
      ..close()
      ..moveTo(154, 14)
      ..lineTo(166, 14)
      ..lineTo(166, 22)
      ..lineTo(154, 22)
      ..close(),
    PixelColors.primary,
    'spark',
    1,
  ),
  _Part(
    Path()
      ..moveTo(134, 32)
      ..lineTo(186, 32)
      ..lineTo(186, 36)
      ..lineTo(192, 36)
      ..lineTo(192, 74)
      ..lineTo(186, 74)
      ..lineTo(186, 78)
      ..lineTo(134, 78)
      ..lineTo(134, 74)
      ..lineTo(128, 74)
      ..lineTo(128, 36)
      ..lineTo(134, 36)
      ..close(),
    PixelColors.purple,
    '',
    1,
  ),
  _Part(
    Path()
      ..moveTo(136, 40)
      ..lineTo(184, 40)
      ..lineTo(184, 64)
      ..lineTo(136, 64)
      ..close(),
    PixelColors.shadow,
    '',
    2,
  ),
  _Part(
    Path()
      ..moveTo(143, 49)
      ..lineTo(146, 49)
      ..lineTo(146, 55)
      ..lineTo(143, 55)
      ..close(),
    PixelColors.primary,
    'wave',
    0,
  ),
  _Part(
    Path()
      ..moveTo(149, 45)
      ..lineTo(152, 45)
      ..lineTo(152, 59)
      ..lineTo(149, 59)
      ..close(),
    PixelColors.primary,
    'wave',
    1,
  ),
  _Part(
    Path()
      ..moveTo(155, 42)
      ..lineTo(158, 42)
      ..lineTo(158, 62)
      ..lineTo(155, 62)
      ..close(),
    PixelColors.primary,
    'wave',
    2,
  ),
  _Part(
    Path()
      ..moveTo(161, 47)
      ..lineTo(164, 47)
      ..lineTo(164, 57)
      ..lineTo(161, 57)
      ..close(),
    PixelColors.primary,
    'wave',
    3,
  ),
  _Part(
    Path()
      ..moveTo(167, 44)
      ..lineTo(170, 44)
      ..lineTo(170, 60)
      ..lineTo(167, 60)
      ..close(),
    PixelColors.primary,
    'wave',
    4,
  ),
  _Part(
    Path()
      ..moveTo(173, 49)
      ..lineTo(176, 49)
      ..lineTo(176, 55)
      ..lineTo(173, 55)
      ..close(),
    PixelColors.primary,
    'wave',
    5,
  ),
  _Part(
    Path()
      ..moveTo(140, 69)
      ..lineTo(144, 69)
      ..lineTo(144, 73)
      ..lineTo(140, 73)
      ..close()
      ..moveTo(148, 69)
      ..lineTo(152, 69)
      ..lineTo(152, 73)
      ..lineTo(148, 73)
      ..close()
      ..moveTo(170, 69)
      ..lineTo(180, 69)
      ..lineTo(180, 73)
      ..lineTo(170, 73)
      ..close(),
    PixelColors.gold,
    '',
    3,
  ),
  _Part(
    Path()
      ..moveTo(114, 80)
      ..lineTo(206, 80)
      ..lineTo(206, 86)
      ..lineTo(114, 86)
      ..close()
      ..moveTo(120, 86)
      ..lineTo(126, 86)
      ..lineTo(126, 98)
      ..lineTo(120, 98)
      ..close()
      ..moveTo(194, 86)
      ..lineTo(200, 86)
      ..lineTo(200, 98)
      ..lineTo(194, 98)
      ..close(),
    PixelColors.mountainNear,
    '',
    4,
  ),
  _Part(
    Path()
      ..moveTo(62, 79)
      ..lineTo(90, 79)
      ..lineTo(90, 84)
      ..lineTo(62, 84)
      ..close()
      ..moveTo(58, 86)
      ..lineTo(90, 86)
      ..lineTo(90, 91)
      ..lineTo(58, 91)
      ..close()
      ..moveTo(242, 77)
      ..lineTo(264, 77)
      ..lineTo(264, 81)
      ..lineTo(272, 81)
      ..lineTo(272, 95)
      ..lineTo(234, 95)
      ..lineTo(234, 81)
      ..lineTo(242, 81)
      ..close(),
    PixelColors.highlight,
    '',
    5,
  ),
  _Part(
    Path()
      ..moveTo(249, 84)
      ..lineTo(258, 84)
      ..lineTo(258, 87)
      ..lineTo(249, 87)
      ..close(),
    PixelColors.highlight,
    '',
    6,
  ),
  _Part(
    Path()
      ..moveTo(0, 98)
      ..lineTo(320, 98)
      ..lineTo(320, 104)
      ..lineTo(0, 104)
      ..close(),
    PixelColors.shadow,
    '',
    7,
  ),
];

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.time, this.listening, this.reduced);
  final double time;
  final bool listening, reduced;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / 320).clamp(0.0, size.height / 104);
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 104 * scale) / 2,
    );
    canvas.scale(scale);
    final beat = listening ? 0.8 : 1.6;
    for (final part in _parts) {
      canvas.save();
      var alpha = 1.0;
      if (!reduced) {
        if (part.motion == 'note' || part.motion == 'right') {
          final phase = ((time + (part.motion == 'right' ? 1.5 : 0)) % 3) / 3;
          final step = (phase * 6).floor() / 6;
          canvas.translate(0, -4 * (step < .5 ? step * 2 : (1 - step) * 2));
        } else if (part.motion == 'spark') {
          alpha = ((time % 3) / 3 * 3).floor() == 1 ? 0.45 : 1;
        } else if (part.motion == 'signal' || part.motion == 'wave') {
          final phase = ((time + (part.index % 3) * .3) % beat) / beat;
          final step = (phase * 4).floor();
          if (part.motion == 'signal') {
            alpha = step == 2 ? 1 : .2;
          } else {
            final wave = switch (step) {
              1 => 1.0,
              2 => .7,
              _ => .5,
            };
            canvas.translate(0, 52);
            canvas.scale(1, wave);
            canvas.translate(0, -52);
          }
        }
      }
      canvas.drawPath(
        part.path,
        Paint()
          ..isAntiAlias = false
          ..color = part.color.withValues(alpha: part.color.a * alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      time != old.time || listening != old.listening || reduced != old.reduced;
}
