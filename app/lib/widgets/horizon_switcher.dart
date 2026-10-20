import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

class HorizonSwitcher extends StatelessWidget {
  const HorizonSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TaskHorizon selected;
  final ValueChanged<TaskHorizon> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.segmentBackground,
      borderRadius: BorderRadius.zero,
    ),
    child: Row(
      children: [
        for (final horizon in TaskHorizon.values)
          Expanded(
            child: Semantics(
              selected: selected == horizon,
              button: true,
              child: Material(
                color: selected == horizon
                    ? AppColors.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.zero,
                elevation: selected == horizon ? 1 : 0,
                shadowColor: const Color(0x18000000),
                child: InkWell(
                  key: ValueKey('segment-${horizon.name}'),
                  onTap: () => onSelected(horizon),
                  borderRadius: BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      switch (horizon) {
                        TaskHorizon.today => '今天',
                        TaskHorizon.recently => '近期',
                        TaskHorizon.later => '以后',
                      },
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected == horizon
                            ? AppColors.text
                            : AppColors.segmentText,
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
