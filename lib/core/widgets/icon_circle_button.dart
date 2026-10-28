import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular icon action with optional glass styling and badge.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.glass = false,
    this.badge = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool glass;
  final bool badge;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fillColor = glass
        ? AppColors.surface.withValues(alpha: 0.92)
        : AppColors.surface;

    return Semantics(
      button: true,
      label: semanticLabel ?? 'Action button',
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Material(
                color: fillColor,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onPressed,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: glass
                          ? null
                          : Border.all(color: AppColors.border, width: 1),
                      boxShadow: glass
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(
                                  0xFF1B2B6B,
                                ).withValues(alpha: 0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: AppColors.ink2, size: 20),
                  ),
                ),
              ),
            ),
          ),
          if (badge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.brand500,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
