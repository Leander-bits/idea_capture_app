import 'package:flutter/material.dart';

/// Verified final CSS tokens from the pixel Figma export.
abstract final class PixelColors {
  static const background = Color(0xFF141325);
  static const text = Color(0xFFF1EDFF);
  static const card = Color(0xFF222039);
  static const primary = Color(0xFFC6F779);
  static const onPrimary = Color(0xFF18251C);
  static const secondary = Color(0xFF323E2B);
  static const mutedSurface = Color(0xFF2B2842);
  static const muted = Color(0xFFAAA4C4);
  static const accent = Color(0xFF302544);
  static const accentText = Color(0xFFDDC9FF);
  static const border = Color(0xFF45405F);
  static const edge = Color(0xFF706187);
  static const shadow = Color(0xFF090914);
  static const canvas = Color(0xFF0D0C18);
  static const sky = Color(0xFF201B39);
  static const purple = Color(0xFFB995F2);
  static const pink = Color(0xFFF29EBE);
  static const gold = Color(0xFFF5CE7D);
  static const highlight = Color(0xFF9983BB);
  static const mountain = Color(0xFF3E305A);
  static const mountainNear = Color(0xFF635080);
  static const danger = Color(0xFFFF9CAE);
}

abstract final class PixelTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PixelColors.background,
    colorScheme: const ColorScheme.dark(
      primary: PixelColors.primary,
      onPrimary: PixelColors.onPrimary,
      surface: PixelColors.card,
      onSurface: PixelColors.text,
      secondary: PixelColors.purple,
      error: PixelColors.danger,
    ),
    fontFamilyFallback: const [
      'PingFang SC',
      'Hiragino Sans GB',
      'Microsoft YaHei',
      'Noto Sans CJK SC',
      'Noto Sans SC',
    ],
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: PixelColors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: PixelColors.text,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: PixelColors.text),
      bodySmall: TextStyle(fontSize: 13, color: PixelColors.muted),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: PixelColors.card,
      contentTextStyle: TextStyle(color: PixelColors.text, fontSize: 13),
      actionTextColor: PixelColors.primary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: PixelColors.purple),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(),
      side: const BorderSide(color: PixelColors.edge, width: 2),
      checkColor: const WidgetStatePropertyAll(PixelColors.onPrimary),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: PixelColors.card,
      hintStyle: TextStyle(color: PixelColors.muted),
      labelStyle: TextStyle(color: PixelColors.muted),
      helperStyle: TextStyle(color: PixelColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.primary),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: const TextStyle(color: PixelColors.text, fontSize: 12),
      decoration: BoxDecoration(
        color: PixelColors.card,
        border: Border.all(color: PixelColors.edge),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PixelColors.card,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: PixelColors.purple),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: const RoundedRectangleBorder()),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PixelColors.primary,
        shape: const RoundedRectangleBorder(),
      ),
    ),
  );
}
