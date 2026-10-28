import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Preferences used to rank the available job posts.
class HomeMatchPreferences {
  const HomeMatchPreferences({
    required this.role,
    required this.skills,
    required this.location,
    required this.employmentType,
    required this.remoteOnly,
  });

  final String role;
  final List<String> skills;
  final String location;
  final String employmentType;
  final bool remoteOnly;
}

/// Empty state shown when no available jobs satisfy the selected criteria.
class NoAiMatches extends StatelessWidget {
  const NoAiMatches({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.manage_search_rounded,
          size: 36,
          color: AppColors.brand500,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No close matches yet',
          style: AppTypography.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Try broader skills or remove the location and work-type filters.',
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodyMedium!.copyWith(
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

/// Page controls and position indicator for the recommended jobs carousel.
class RecommendedPageIndicator extends StatefulWidget {
  const RecommendedPageIndicator({
    super.key,
    required this.controller,
    required this.itemCount,
  });

  final PageController controller;
  final int itemCount;

  @override
  State<RecommendedPageIndicator> createState() =>
      _RecommendedPageIndicatorState();
}

class _RecommendedPageIndicatorState extends State<RecommendedPageIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePageChange);
  }

  @override
  void didUpdateWidget(covariant RecommendedPageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handlePageChange);
      widget.controller.addListener(_handlePageChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePageChange);
    super.dispose();
  }

  void _handlePageChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = widget.itemCount - 1;
    final page = widget.controller.hasClients && widget.controller.page != null
        ? widget.controller.page!.round().clamp(0, lastPage)
        : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous recommended job',
            onPressed: page == 0
                ? null
                : () => widget.controller.previousPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  ),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            '${page + 1} / ${widget.itemCount}',
            style: AppTypography.textTheme.labelMedium,
          ),
          IconButton(
            tooltip: 'Next recommended job',
            onPressed: page >= lastPage
                ? null
                : () => widget.controller.nextPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  ),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
