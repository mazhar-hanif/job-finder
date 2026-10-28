import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/app_notification.dart';
import '../../providers/job_providers.dart';

/// Displays job, recruiter, and application notifications.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.md,
            AppSpacing.screenGutter,
            AppSpacing.xxl,
          ),
          children: [
            Text('Notifications', style: AppTypography.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            if (notifications.isEmpty)
              const EmptyState(
                title: 'You’re all caught up',
                message: 'Job and application updates will appear here.',
              )
            else ...[
              Text('Recent', style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              for (final notification in notifications)
                _NotificationCard(notification: notification),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (notification.kind) {
      AppNotificationKind.application => (
        Icons.assignment_turned_in_rounded,
        AppColors.success,
      ),
      AppNotificationKind.recruiter => (
        Icons.mark_chat_unread_rounded,
        AppColors.brand500,
      ),
      AppNotificationKind.recommendation => (
        Icons.work_history_rounded,
        AppColors.warn,
      ),
    };
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () {
          switch (notification.kind) {
            case AppNotificationKind.application:
              context.push('/applications');
            case AppNotificationKind.recruiter:
              context.push('/messages');
            case AppNotificationKind.recommendation:
              context.push('/search');
          }
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.textTheme.titleMedium,
                          ),
                        ),
                        if (notification.unread)
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: AppColors.brand500,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      notification.message,
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.time,
                      style: AppTypography.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
