import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';

/// Promotional card linking to personalized job recommendations.
class AiMatchCard extends StatelessWidget {
  const AiMatchCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        border: Border.all(color: AppColors.brand100),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Smart Job Match',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Compare your skills and goals with available job posts.',
                  style: AppTypography.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Try Now',
                  size: PrimaryButtonSize.small,
                  trailing: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _MatchTarget(),
        ],
      ),
    );
  }
}

class _MatchTarget extends StatelessWidget {
  const _MatchTarget();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    height: 100,
    child: Stack(
      alignment: Alignment.center,
      children: [
        for (final size in [82.0, 62.0, 42.0, 22.0])
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand300, width: 1.5),
            ),
          ),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.track_changes_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
        const Positioned(
          right: 3,
          top: 6,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gold,
            size: 20,
          ),
        ),
      ],
    ),
  );
}
