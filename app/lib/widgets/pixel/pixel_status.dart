import 'package:flutter/material.dart';

import '../../theme/pixel_theme.dart';
import 'pixel_components.dart';

class PixelBusyDots extends StatefulWidget {
  const PixelBusyDots({super.key});
  @override
  State<PixelBusyDots> createState() => _PixelBusyDotsState();
}

class _PixelBusyDotsState extends State<PixelBusyDots>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
    child: AnimatedBuilder(
      animation: _clock,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 5,
                height: 5,
                color:
                    MediaQuery.disableAnimationsOf(context) ||
                        (_clock.value * 3).floor() == i
                    ? PixelColors.primary
                    : PixelColors.edge,
              ),
            ),
        ],
      ),
    ),
  );
}

class PixelStatusMessage extends StatelessWidget {
  const PixelStatusMessage(
    this.message, {
    super.key,
    this.error = false,
    this.busy = false,
  });
  final String message;
  final bool error, busy;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: PixelSurface(
      shadow: 0,
      borderColor: error ? PixelColors.danger : PixelColors.border,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (busy) ...[const PixelBusyDots(), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: error ? PixelColors.danger : PixelColors.muted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
