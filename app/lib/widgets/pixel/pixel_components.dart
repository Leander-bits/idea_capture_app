import 'package:flutter/material.dart';

import '../../theme/pixel_theme.dart';

class PixelSurface extends StatelessWidget {
  const PixelSurface({
    super.key,
    required this.child,
    this.color = PixelColors.card,
    this.borderColor = PixelColors.border,
    this.borderWidth = 1,
    this.shadow = 3,
    this.padding = EdgeInsets.zero,
    this.leftAccent = false,
  });
  final Widget child;
  final Color color, borderColor;
  final double borderWidth, shadow;
  final EdgeInsetsGeometry padding;
  final bool leftAccent;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(color: PixelColors.shadow, offset: Offset(shadow, shadow)),
      ],
    ),
    child: Container(
      decoration: leftAccent
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: PixelColors.purple, width: 2),
              ),
            )
          : null,
      padding: padding,
      child: child,
    ),
  );
}

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = PixelColors.secondary,
    this.borderColor = PixelColors.edge,
    this.padding = const EdgeInsets.all(12),
    this.label,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final Color color, borderColor;
  final EdgeInsetsGeometry padding;
  final String? label;
  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.onPressed != null,
    label: widget.label,
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      transform: Matrix4.translationValues(
        _pressed ? 2 : 0,
        _pressed ? 2 : 0,
        0,
      ),
      child: PixelSurface(
        color: widget.color,
        borderColor: widget.borderColor,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    ),
  );
}

class PixelSectionHeading extends StatelessWidget {
  const PixelSectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 6, height: 12, color: PixelColors.purple),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      ?trailing,
    ],
  );
}
