import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A pill-shaped selectable filter or category.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.active = false,
    this.soft = false,
    this.onTap,
    this.leading,
  });

  final String label;
  final bool active;
  final bool soft;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.brand500
        : soft
        ? AppColors.brand50
        : Colors.white;
    final fg = active ? Colors.white : AppColors.ink2;
    final border = active
        ? null
        : Border.all(color: AppColors.border, width: 1);

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 44,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                    border: border,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.labelLarge!.copyWith(
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
