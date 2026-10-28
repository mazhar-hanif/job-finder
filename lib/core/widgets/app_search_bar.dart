import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A themed search field or read-only search entry point.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.hintText = 'Search',
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.trailing,
    this.dark = false,
  });

  final String hintText;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final Widget? trailing;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final radius = dark ? AppSpacing.radiusPill : 18.0;
    final foreground = dark ? AppColors.ink : AppColors.brand500;
    final hintColor = AppColors.placeholder;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: dark ? AppColors.brand100 : AppColors.border,
              width: dark ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: AppSpacing.shadowBlur,
                offset: const Offset(0, AppSpacing.shadowOffsetY),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.brand500, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  textInputAction: TextInputAction.search,
                  cursorColor: AppColors.brand500,
                  onTap: onTap,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: dark
                      ? AppTypography.textTheme.bodyMedium!.copyWith(
                          color: foreground,
                        )
                      : null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: AppTypography.textTheme.bodyMedium!.copyWith(
                      color: hintColor,
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                IconTheme(
                  data: IconThemeData(
                    color: dark ? AppColors.muted : AppColors.brand500,
                    size: 20,
                  ),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
