import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand500,
        brightness: Brightness.light,
        primary: AppColors.brand500,
        secondary: AppColors.brand500,
        surface: AppColors.surface,
      ),
      textTheme: AppTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerColor: AppColors.divider,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      iconTheme: const IconThemeData(color: AppColors.ink2),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.brand500,
        selectionColor: AppColors.brand100,
        selectionHandleColor: AppColors.brand500,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.brand500, width: 1.2),
          borderRadius: BorderRadius.circular(18),
        ),
        hintStyle: AppTypography.textTheme.bodyMedium!.copyWith(
          color: AppColors.placeholder,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand500,
          foregroundColor: AppColors.surface,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTypography.textTheme.bodyMedium!.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
