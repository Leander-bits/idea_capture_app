import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/pixel_theme.dart';

enum AppDestination { today, capture, tasks }

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
    this.pixel = true,
  });

  final AppDestination selected;
  final bool pixel;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final height = pixel
        ? math.max(62.0, 43 + MediaQuery.textScalerOf(context).scale(10) * 1.5)
        : 62.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pixel ? PixelColors.canvas : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: pixel ? PixelColors.border : const Color(0x0D000000),
            width: pixel ? 2 : 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(
                '今天',
                Icons.light_mode_outlined,
                AppDestination.today,
                height,
              ),
              _item(
                '记录',
                Icons.mic_none_outlined,
                AppDestination.capture,
                height,
              ),
              _item(
                '任务',
                Icons.checklist_outlined,
                AppDestination.tasks,
                height,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    String label,
    IconData icon,
    AppDestination destination,
    double height,
  ) => Semantics(
    selected: selected == destination,
    button: true,
    label: label,
    onTap: () => onSelected(destination),
    excludeSemantics: true,
    child: InkWell(
      key: ValueKey('nav-${destination.name}'),
      onTap: () => onSelected(destination),
      excludeFromSemantics: true,
      child: Container(
        margin: pixel
            ? const EdgeInsets.symmetric(vertical: 6)
            : EdgeInsets.zero,
        decoration: pixel && selected == destination
            ? BoxDecoration(
                color: PixelColors.secondary,
                border: Border.all(color: PixelColors.primary),
                boxShadow: const [
                  BoxShadow(color: PixelColors.shadow, offset: Offset(2, 2)),
                ],
              )
            : null,
        width: 80,
        height: pixel ? height - 12 : height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: selected == destination
                  ? (pixel ? PixelColors.primary : AppColors.primary)
                  : (pixel ? PixelColors.muted : const Color(0xFF939497)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected == destination
                    ? (pixel ? PixelColors.primary : AppColors.primary)
                    : (pixel ? PixelColors.muted : const Color(0xFF939497)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
