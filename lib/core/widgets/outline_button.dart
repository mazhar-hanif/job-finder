import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A white button with a blue outline.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.size = OutlineButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final OutlineButtonSize size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = size == OutlineButtonSize.small ? 12.0 : 14.0;
    final height = size == OutlineButtonSize.small ? 34.0 : 46.0;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppColors.brand500, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.displayMedium!.copyWith(
                      color: AppColors.brand500,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum OutlineButtonSize { small, medium }
