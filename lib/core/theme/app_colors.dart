import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color brand50 = Color(0xFFEEF3FF);
  static const Color brand100 = Color(0xFFDDE7FF);
  static const Color brand200 = Color(0xFFBDD0FF);
  static const Color brand300 = Color(0xFF8FADFF);
  static const Color brand400 = Color(0xFF5C83FF);
  static const Color brand500 = Color(0xFF2F5BFF);
  static const Color brand600 = Color(0xFF2347E6);
  static const Color brand700 = Color(0xFF1A37B8);

  static const Color ink = Color(0xFF0B1633);
  static const Color ink2 = Color(0xFF3A4668);
  static const Color muted = Color(0xFF7C88A6);
  static const Color placeholder = Color(0xFFA3ADC4);
  static const Color bg = Color(0xFFF6F8FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE6EBF6);
  static const Color divider = Color(0xFFEEF1F8);
  static const Color cardShadow = Color(0x121B2B6B);
  static const Color success = Color(0xFF0E9F6E);
  static const Color successBg = Color(0xFFE6F7F0);
  static const Color warn = Color(0xFFC2410C);
  static const Color warnBg = Color(0xFFFFEEDD);
  static const Color danger = Color(0xFFE5484D);
  static const Color gold = Color(0xFFF5B544);
  static const Color goldBg = Color(0xFFFFF6E2);
  static const Color homeHeaderBackground = brand600;
  static const Color homeHeaderForeground = surface;
  static const Color homeHeaderBorder = brand400;
  static const Color homeHeaderHint = brand100;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4D7DFF), Color(0xFF2347E6)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3F7FF), Color(0xFFDCE7FF)],
  );

  static const LinearGradient onboardingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFE9F0FF)],
  );

  static const LinearGradient companyCoverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF13214D), Color(0xFF2F5BFF)],
  );

  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8FADFF), Color(0xFF2F5BFF)],
  );
}
