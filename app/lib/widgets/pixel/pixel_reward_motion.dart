import 'package:flutter/material.dart';

import '../../theme/pixel_theme.dart';

class PixelCompletionMotion extends StatefulWidget {
  const PixelCompletionMotion({super.key, required this.child});
  final Widget child;
  @override
  State<PixelCompletionMotion> createState() => _PixelCompletionMotionState();
}

class _PixelCompletionMotionState extends State<PixelCompletionMotion>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2700),
  );
  bool _reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _motion.stop();
    } else if (_motion.value == 0) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    builder: (context, child) {
      final elapsed = _motion.value * 2700;
      final t = _reduced
          ? 1.0
          : ((elapsed / 350).clamp(0.0, 1.0) * 5).ceil() / 5;
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -12 * (1 - t)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              if (!_reduced)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _RewardSparks(elapsed)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
    child: widget.child,
  );
}

class _RewardSparks extends CustomPainter {
  _RewardSparks(this.elapsed);
  final double elapsed;
  static const _points = [
    Offset(.05, .15),
    Offset(.15, .9),
    Offset(.27, 0),
    Offset(.37, 1),
    Offset(.48, .05),
    Offset(.58, 1),
    Offset(.7, 0),
    Offset(.82, 1),
    Offset(.94, .1),
    Offset(1, .6),
    Offset(0, .65),
    Offset(.65, 1),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _points.length; i++) {
      final time = elapsed - (i % 4) * 100;
      if (time < 0 || time >= 2400) continue;
      final t = ((time % 1200) / 1200 * 8).floor() / 8;
      final opacity = t < .75 ? 1.0 : (1 - t) * 4;
      final p = _points[i];
      canvas.drawRect(
        Rect.fromLTWH(p.dx * size.width, p.dy * size.height - 18 * t, 5, 5),
        Paint()
          ..isAntiAlias = false
          ..color = [
            PixelColors.primary,
            PixelColors.gold,
            PixelColors.pink,
          ][i % 3].withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_RewardSparks old) => old.elapsed != elapsed;
}
