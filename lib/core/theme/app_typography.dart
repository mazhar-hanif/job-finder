import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 34,
      height: 42 / 34,
      fontWeight: FontWeight.w800,
      fontVariations: [FontVariation.weight(800)],
      letterSpacing: -0.9,
      color: AppColors.ink,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w700,
      fontVariations: [FontVariation.weight(700)],
      letterSpacing: -0.6,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 22,
      height: 30 / 22,
      fontWeight: FontWeight.w700,
      fontVariations: [FontVariation.weight(700)],
      letterSpacing: -0.4,
      color: AppColors.ink,
    ),
    titleLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w700,
      fontVariations: [FontVariation.weight(700)],
      letterSpacing: -0.2,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 15,
      height: 21 / 15,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation.weight(600)],
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 16,
      height: 25 / 16,
      fontWeight: FontWeight.w400,
      fontVariations: [FontVariation.weight(400)],
      color: AppColors.ink2,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 14,
      height: 22 / 14,
      fontWeight: FontWeight.w400,
      fontVariations: [FontVariation.weight(400)],
      color: AppColors.ink2,
    ),
    bodySmall: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation.weight(600)],
      color: AppColors.ink2,
    ),
    labelLarge: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation.weight(600)],
      color: AppColors.ink,
    ),
    labelMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      fontVariations: [FontVariation.weight(500)],
      color: AppColors.muted,
    ),
    labelSmall: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation.weight(600)],
      color: AppColors.muted,
    ),
    displayMedium: TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation.weight(600)],
      color: AppColors.ink,
    ),
  );
}
