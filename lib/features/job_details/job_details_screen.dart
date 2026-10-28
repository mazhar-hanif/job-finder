import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/company_logo.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/underline_tabs.dart';
import '../../data/models/job.dart';
import '../../providers/job_providers.dart';

/// Detailed view of a job listing and its application actions.
class JobDetailsScreen extends ConsumerStatefulWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider);
    final job = jobs.firstWhere((item) => item.id == widget.jobId);
    final company = ref
        .watch(companiesProvider)
        .firstWhere((item) => item.id == job.companyId);
    final isSaved = ref.watch(savedJobIdsProvider).contains(job.id);
    final isApplied = ref
        .watch(applicationsProvider)
        .any((item) => item.jobId == job.id);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.xs,
                AppSpacing.screenGutter,
                AppSpacing.xxl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      IconCircleButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        onPressed: () => goBackOrHome(context),
                      ),
                      const Spacer(),
                      IconCircleButton(
                        icon: Icons.share_rounded,
                        semanticLabel: 'Share job',
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: 'JobFinder job: ${job.title}'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconCircleButton(
                        icon: isSaved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        semanticLabel: isSaved ? 'Unsave job' : 'Save job',
                        onPressed: () => ref
                            .read(savedJobIdsProvider.notifier)
                            .toggle(job.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  InkWell(
                    onTap: () => context.push('/company/${company.id}'),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Row(
                      children: [
                        CompanyLogo(
                          name: company.name,
                          tint: Color(company.tint),
                          size: 52,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: AppTypography.textTheme.titleLarge,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.gold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Expanded(
                                    child: Text(
                                      '${company.rating} (${company.reviewsLabel})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTypography.textTheme.labelMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    job.title,
                    style: AppTypography.textTheme.headlineLarge!.copyWith(
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _MetaRow(
                    icon: job.isRemote
                        ? Icons.public_rounded
                        : Icons.location_on_rounded,
                    label: job.location,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(
                    icon: job.workplaceType == 'Remote'
                        ? Icons.home_work_rounded
                        : Icons.apartment_rounded,
                    label: job.workplaceType,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(icon: Icons.work_outline_rounded, label: job.type),
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(
                    icon: Icons.payments_outlined,
                    label: job.salaryLabel,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(
                    icon: Icons.access_time_rounded,
                    label: 'Posted ${job.postedAgo} · ${job.applicantsLabel}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PrimaryButton(
                          label: isApplied ? 'Applied' : 'Apply Now',
                          leading: isApplied
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                          disabled: isApplied,
                          onPressed: isApplied
                              ? null
                              : () => context.push('/apply/${job.id}'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: isSaved
                            ? SoftButton(
                                label: 'Saved',
                                leading: const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.brand600,
                                  size: 17,
                                ),
                                onPressed: () => ref
                                    .read(savedJobIdsProvider.notifier)
                                    .toggle(job.id),
                              )
                            : OutlineButton(
                                label: 'Save',
                                leading: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppColors.brand500,
                                  size: 17,
                                ),
                                onPressed: () => ref
                                    .read(savedJobIdsProvider.notifier)
                                    .toggle(job.id),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  UnderlineTabs(
                    tabs: const [
                      'Overview',
                      'Requirements',
                      'Benefits',
                      'Company',
                    ],
                    selectedIndex: _tab,
                    onTap: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _DetailsContent(
                      key: ValueKey(_tab),
                      tab: _tab,
                      job: job,
                      companyAbout: company.about,
                      companyId: company.id,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.color = AppColors.ink2,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          label,
          style: AppTypography.textTheme.bodyMedium!.copyWith(color: color),
        ),
      ),
    ],
  );
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    super.key,
    required this.tab,
    required this.job,
    required this.companyAbout,
    required this.companyId,
  });

  final int tab;
  final Job job;
  final String companyAbout;
  final String companyId;

  @override
  Widget build(BuildContext context) {
    if (tab == 1) {
      return _BulletSection(title: 'Requirements', items: job.requirements);
    }
    if (tab == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Benefits', style: AppTypography.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          for (final benefit in job.benefits)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppTypography.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (tab == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About the company',
            style: AppTypography.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(companyAbout, style: AppTypography.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          SoftButton(
            label: 'View company profile',
            trailing: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.brand600,
              size: 18,
            ),
            onPressed: () => context.push('/company/$companyId'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About the job', style: AppTypography.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(job.about, style: AppTypography.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        _BulletSection(
          title: 'Key responsibilities',
          items: job.responsibilities,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Skills', style: AppTypography.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: job.skills
              .map((skill) => AppChip(label: skill, soft: true))
              .toList(),
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTypography.textTheme.headlineMedium),
      const SizedBox(height: AppSpacing.sm),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Icon(Icons.circle, size: 7, color: AppColors.brand500),
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
