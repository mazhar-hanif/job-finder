import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// JobFinder brand mark and wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.work_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          'JobFinder',
          style: AppTypography.textTheme.titleLarge!.copyWith(
            color: AppColors.brand500,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
