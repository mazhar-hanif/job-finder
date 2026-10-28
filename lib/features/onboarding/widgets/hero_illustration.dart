import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Decorative, code-drawn illustration for the onboarding screen.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 8,
            right: 8,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.brand100.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Expanded(child: _SkylineBlock(height: 90)),
                  Expanded(child: _SkylineBlock(height: 120)),
                  Expanded(child: _SkylineBlock(height: 75)),
                  Expanded(child: _SkylineBlock(height: 108)),
                  Expanded(child: _SkylineBlock(height: 68)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 30,
            right: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Container(
                      height: 40 + i * 22,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: i == 2
                          ? const Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: AppColors.ink,
                                  child: Icon(
                                    Icons.directions_walk_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 50,
            bottom: 155,
            child: Icon(
              Icons.flag_rounded,
              color: AppColors.brand700,
              size: 24,
            ),
          ),
          const Positioned(
            top: 18,
            left: 0,
            child: _FloatingChip(
              icon: Icons.trending_up_rounded,
              label: '2.4k new jobs',
              tone: AppColors.brand500,
            ),
          ),
          const Positioned(
            top: 64,
            right: 0,
            child: _FloatingChip(
              icon: Icons.auto_awesome_rounded,
              label: '98% match',
              tone: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkylineBlock extends StatelessWidget {
  const _SkylineBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
    decoration: BoxDecoration(
      color: AppColors.brand200.withValues(alpha: 0.7),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    ),
  );
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1B2B6B).withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: tone, size: 16),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.textTheme.labelMedium),
      ],
    ),
  );
}
