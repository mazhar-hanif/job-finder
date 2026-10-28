import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_tag.dart';
import '../../../data/models/company.dart';
import '../../../data/models/job.dart';

/// An expanded employer job post for the home feed.
class JobPostCard extends StatelessWidget {
  const JobPostCard({
    super.key,
    required this.job,
    required this.company,
    required this.saved,
    required this.onSave,
  });

  final Job job;
  final Company company;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2B6B).withValues(alpha: 0.07),
            blurRadius: AppSpacing.shadowBlur,
            offset: const Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogo(
                name: company.name,
                tint: Color(company.tint),
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    Text(
                      '${job.location} · ${job.workplaceType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.labelMedium,
                    ),
                    Text(job.type, style: AppTypography.textTheme.labelMedium),
                  ],
                ),
              ),
              Text(job.postedAgo, style: AppTypography.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(job.title, style: AppTypography.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusTag(label: job.salaryShort, tone: StatusTagTone.success),
              StatusTag(label: job.type, tone: StatusTagTone.neutral),
              StatusTag(label: job.workplaceType, tone: StatusTagTone.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Apply now',
                  size: PrimaryButtonSize.medium,
                  onPressed: () => context.push('/apply/${job.id}'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlineButton(
                  label: saved ? 'Saved' : 'Save',
                  leading: Icon(
                    saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: AppColors.brand500,
                    size: 18,
                  ),
                  onPressed: onSave,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _PostSection(title: 'Job description', content: job.about),
          if (job.responsibilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _BulletSection(
              title: 'Key responsibilities',
              items: job.responsibilities,
            ),
          ],
          if (job.requirements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _BulletSection(title: 'Qualifications', items: job.requirements),
          ],
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/job/${job.id}'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View full job details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostSection extends StatelessWidget {
  const _PostSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTypography.textTheme.titleLarge),
      const SizedBox(height: AppSpacing.xs),
      Text(content, style: AppTypography.textTheme.bodyMedium),
    ],
  );
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTypography.textTheme.titleLarge),
      const SizedBox(height: AppSpacing.xs),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Icon(Icons.circle, size: 5, color: AppColors.ink2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(item, style: AppTypography.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
    ],
  );
}
