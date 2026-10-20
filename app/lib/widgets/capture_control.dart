import 'package:flutter/material.dart';

import '../theme/pixel_theme.dart';

class CaptureControl extends StatelessWidget {
  const CaptureControl({
    super.key,
    required this.listening,
    required this.active,
    required this.onPressed,
  });

  final bool listening;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 110,
    height: 110,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -24,
          right: -25,
          child: _Spark(color: PixelColors.gold),
        ),
        Positioned(
          bottom: 2,
          left: -30,
          child: _Spark(color: PixelColors.pink),
        ),
        Positioned.fill(
          left: -10,
          right: -10,
          top: -10,
          bottom: -10,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: PixelColors.border),
              ),
            ),
          ),
        ),
        if (listening)
          Positioned(
            top: -6,
            bottom: -6,
            left: -6,
            right: -6,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: PixelColors.primary, width: 2),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: _RecordingPulse(
            listening: listening,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: PixelColors.shadow, offset: Offset(6, 6)),
                ],
              ),
              child: Material(
                color: PixelColors.accent,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  side: BorderSide(color: PixelColors.purple, width: 3),
                ),
                child: Semantics(
                  label: listening
                      ? '结束录音'
                      : active
                      ? '再记一个想法'
                      : '开始录音',
                  button: true,
                  enabled: onPressed != null,
                  onTap: onPressed,
                  excludeSemantics: true,
                  child: InkWell(
                    key: const ValueKey('capture-control'),
                    customBorder: const RoundedRectangleBorder(),
                    onTap: onPressed,
                    child: Center(
                      child: listening
                          ? Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: PixelColors.purple,
                              ),
                            )
                          : const Icon(
                              Icons.mic_none_outlined,
                              size: 39,
                              color: PixelColors.purple,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Spark extends StatelessWidget {
  const _Spark({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          Positioned(
            left: 5,
            child: Container(width: 8, height: 18, color: color),
          ),
          Positioned(
            top: 5,
            child: Container(width: 18, height: 8, color: color),
          ),
        ],
      ),
    ),
  );
}

class _RecordingPulse extends StatefulWidget {
  const _RecordingPulse({required this.child, required this.listening});
  final Widget child;
  final bool listening;
  @override
  State<_RecordingPulse> createState() => _RecordingPulseState();
}

class _RecordingPulseState extends State<_RecordingPulse>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_RecordingPulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.listening && !MediaQuery.disableAnimationsOf(context)) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, child) =>
        Opacity(opacity: 1 - _pulse.value * .5, child: child),
    child: widget.child,
  );
}
