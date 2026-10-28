import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A compact, color-coded status label.
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    this.tone = StatusTagTone.brand,
  });

  final String label;
  final StatusTagTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: colors.foreground,
        ),
      ),
    );
  }

  _TagColors _toneColors(StatusTagTone tone) {
    switch (tone) {
      case StatusTagTone.brand:
        return _TagColors(AppColors.brand50, AppColors.brand600);
      case StatusTagTone.success:
        return _TagColors(AppColors.successBg, AppColors.success);
      case StatusTagTone.orange:
        return _TagColors(AppColors.warnBg, AppColors.warn);
      case StatusTagTone.neutral:
        return _TagColors(AppColors.divider, AppColors.ink2);
    }
  }
}

enum StatusTagTone { brand, success, orange, neutral }

class _TagColors {
  const _TagColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
