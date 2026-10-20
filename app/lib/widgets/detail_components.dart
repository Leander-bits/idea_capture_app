import 'package:flutter/material.dart';

import '../theme/pixel_theme.dart';
import 'pixel/pixel_components.dart';

class DetailMetadataRow extends StatelessWidget {
  const DetailMetadataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.divider = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final bool divider;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Row(
      children: [
        Icon(icon, size: 17, color: PixelColors.purple),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15)
                .copyWith(right: 16),
            decoration: BoxDecoration(
              border: divider
                  ? const Border(bottom: BorderSide(color: PixelColors.border))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.tight,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            valueColor ??
                            (highlight
                                ? PixelColors.primary
                                : PixelColors.muted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class NextStepCard extends StatelessWidget {
  const NextStepCard({super.key, this.step, this.reason});

  final String? step;
  final String? reason;

  @override
  Widget build(BuildContext context) => PixelSurface(
    padding: const EdgeInsets.all(16),
    color: PixelColors.accent,
    borderColor: PixelColors.edge,
    shadow: 4,
    leftAccent: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (step != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.north_east,
                  size: 18,
                  color: PixelColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 24 / 14,
                    color: PixelColors.accentText,
                  ),
                ),
              ),
            ],
          ),
        if (reason != null)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: step == null ? 0 : 12),
            padding: EdgeInsets.only(top: step == null ? 0 : 12),
            decoration: BoxDecoration(
              border: step == null
                  ? null
                  : const Border(top: BorderSide(color: PixelColors.border)),
            ),
            child: Text(
              reason!,
              style: const TextStyle(
                fontSize: 11,
                height: 1.6,
                color: PixelColors.muted,
              ),
            ),
          ),
      ],
    ),
  );
}

class DetailAction extends StatelessWidget {
  const DetailAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => PixelButton(
    onPressed: onPressed,
    color: PixelColors.card,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: destructive ? PixelColors.danger : PixelColors.primary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: destructive ? FontWeight.w400 : FontWeight.w500,
              color: destructive ? PixelColors.danger : PixelColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
