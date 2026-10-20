import 'package:flutter/material.dart';

import 'pixel_theme.dart';

/// Compatibility names for shared widgets; pixel tokens remain the source of truth.
abstract final class AppColors {
  static const background = PixelColors.background;
  static const text = PixelColors.text;
  static const surface = PixelColors.card;
  static const primary = PixelColors.primary;
  static const secondary = PixelColors.secondary;
  static const muted = PixelColors.muted;
  static const faint = PixelColors.muted;
  static const border = PixelColors.border;
  static const divider = PixelColors.border;
  static const circle = PixelColors.muted;
  static const segmentBackground = PixelColors.mutedSurface;
  static const segmentText = PixelColors.muted;
  static const description = PixelColors.muted;
  static const source = PixelColors.muted;
  static const detailIcon = PixelColors.muted;
  static const detailValue = PixelColors.muted;
  static const detailDivider = PixelColors.muted;
  static const detailCircle = PixelColors.muted;
  static const stepBackground = PixelColors.accent;
  static const stepHeading = PixelColors.muted;
  static const stepDivider = PixelColors.edge;
  static const stepReason = PixelColors.accentText;
  static const destructive = PixelColors.danger;
  static const dialog = PixelColors.card;
  static const captureFooter = PixelColors.muted;
  static const captureCaption = PixelColors.muted;
}

abstract final class AppTheme {
  static const pagePadding = 20.0;
  static const taskRadius = 0.0;
  static ThemeData get light => PixelTheme.dark;
}
