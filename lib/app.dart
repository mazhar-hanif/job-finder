import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';

/// Root Material application for JobFinder.
class JobFinderApp extends StatelessWidget {
  const JobFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JobFinder',
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) => ColoredBox(
        color: AppColors.bg,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
