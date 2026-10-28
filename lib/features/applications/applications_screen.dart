import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/company_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/status_tag.dart';
import '../../data/models/application.dart';
import '../../data/models/company.dart';
import '../../data/models/job.dart';
import '../../providers/job_providers.dart';
import '../../data/repositories/supabase_job_service.dart';

/// Tracks submitted applications and their current status.
class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  ApplicationStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseJobServiceProvider);
    final currentUser = service?.client.auth.currentUser;
    if (service != null && currentUser != null) {
      return _BackendApplicationsScreen(service: service);
    }
    if (service != null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenGutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                title: 'Sign in to track applications',
                message:
                    'Applications you submit will be stored in your account.',
              ),
              TextButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Sign in or create account'),
              ),
            ],
          ),
        ),
      );
    }

    final applications = ref.watch(applicationsProvider);
    final jobs = ref.watch(jobsProvider);
    final companies = ref.watch(companiesProvider);
    final visible = _filter == null
        ? applications
        : applications.where((item) => item.status == _filter).toList();
    final interviews = applications
        .where((item) => item.status == ApplicationStatus.interview)
        .length;
    final offers = applications
        .where(
          (item) =>
              item.status == ApplicationStatus.offer ||
              item.status == ApplicationStatus.accepted,
        )
        .length;

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.lg,
          AppSpacing.screenGutter,
          AppSpacing.xxl,
        ),
        children: [
          const _ApplicationsHeader(
            title: 'My applications',
            subtitle: 'Track every opportunity, all in one place.',
            demo: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ApplicationOverview(
            total: applications.length,
            interviews: interviews,
            offers: offers,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Application activity',
            style: AppTypography.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                AppChip(
                  label: 'All (${applications.length})',
                  active: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final status in ApplicationStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: AppChip(
                      label:
                          '${_statusLabel(status)} (${applications.where((item) => item.status == status).length})',
                      active: _filter == status,
                      onTap: () => setState(() => _filter = status),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            const EmptyState(
              title: 'No applications yet',
              message: 'When you apply for a role, you can track it here.',
            )
          else
            for (final application in visible)
              _ApplicationCard(
                application: application,
                job: jobs.firstWhere((job) => job.id == application.jobId),
                company: companies.firstWhere(
                  (company) =>
                      company.id ==
                      jobs
                          .firstWhere((job) => job.id == application.jobId)
                          .companyId,
                ),
              ),
        ],
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) => switch (status) {
  ApplicationStatus.applied => 'Applied',
  ApplicationStatus.interview => 'Interview',
  ApplicationStatus.offer => 'Offer',
  ApplicationStatus.accepted => 'Offer accepted',
  ApplicationStatus.rejected => 'Rejected',
  ApplicationStatus.withdrawn => 'Withdrawn',
};

String _backendStatusLabel(String status) => switch (status) {
  'accepted' => 'Offer accepted',
  'applied' => 'Applied',
  'interview' => 'Interview',
  'offer' => 'Offer',
  'rejected' => 'Rejected',
  'withdrawn' => 'Withdrawn',
  _ => status,
};

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({
    required this.application,
    required this.job,
    required this.company,
  });

  final ApplicationModel application;
  final Job job;
  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = switch (application.status) {
      ApplicationStatus.applied => StatusTagTone.brand,
      ApplicationStatus.interview => StatusTagTone.orange,
      ApplicationStatus.offer => StatusTagTone.success,
      ApplicationStatus.accepted => StatusTagTone.success,
      ApplicationStatus.rejected ||
      ApplicationStatus.withdrawn => StatusTagTone.neutral,
    };
    final label = _statusLabel(application.status);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: () => context.push('/job/${job.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
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
                children: [
                  CompanyLogo(
                    name: company.name,
                    tint: Color(company.tint),
                    size: 48,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: AppTypography.textTheme.labelMedium,
                        ),
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  StatusTag(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Applied · ${application.appliedAgo}',
                style: AppTypography.textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusProgress(status: application.status),
              const SizedBox(height: AppSpacing.xs),
              if (application.status == ApplicationStatus.interview ||
                  application.status == ApplicationStatus.offer ||
                  application.status == ApplicationStatus.accepted)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      ref
                          .read(demoConversationsProvider.notifier)
                          .ensure(job.id);
                      context.push('/messages/demo-${job.id}');
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message employer (local demo)'),
                  ),
                ),
              if (application.status == ApplicationStatus.offer)
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    AppChip(
                      label: 'Accept offer',
                      active: true,
                      onTap: () => ref
                          .read(applicationsProvider.notifier)
                          .updateStatus(job.id, ApplicationStatus.accepted),
                    ),
                    AppChip(
                      label: 'Decline offer',
                      onTap: () => ref
                          .read(applicationsProvider.notifier)
                          .updateStatus(job.id, ApplicationStatus.rejected),
                    ),
                  ],
                ),
              if (application.status == ApplicationStatus.applied ||
                  application.status == ApplicationStatus.interview ||
                  application.status == ApplicationStatus.offer)
                TextButton(
                  onPressed: () => ref
                      .read(applicationsProvider.notifier)
                      .updateStatus(job.id, ApplicationStatus.withdrawn),
                  child: const Text('Withdraw application'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackendApplicationsScreen extends StatefulWidget {
  const _BackendApplicationsScreen({required this.service});

  final SupabaseJobService service;

  @override
  State<_BackendApplicationsScreen> createState() =>
      _BackendApplicationsScreenState();
}

class _BackendApplicationsScreenState
    extends State<_BackendApplicationsScreen> {
  late Future<List<Map<String, dynamic>>> _applications;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _applications = widget.service.fetchApplicantApplications();
  }

  void _refresh() {
    setState(() {
      _applications = widget.service.fetchApplicantApplications();
    });
  }

  Future<void> _messageEmployer(String applicationId) async {
    try {
      final conversationId = await widget.service
          .getOrCreateApplicationConversation(applicationId);
      if (mounted) context.push('/messages/$conversationId');
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open employer chat: $error')),
        );
      }
    }
  }

  Future<void> _respondToOffer(
    String applicationId, {
    required bool accept,
  }) async {
    try {
      await widget.service.respondToOffer(
        applicationId: applicationId,
        accept: accept,
      );
      _refresh();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Could not accept offer: $error'
                  : 'Could not decline offer: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _withdrawApplication(String applicationId) async {
    try {
      await widget.service.withdrawApplication(applicationId);
      _refresh();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not withdraw application: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.lg,
          AppSpacing.screenGutter,
          AppSpacing.xxl,
        ),
        children: [
          _ApplicationsHeader(
            title: 'My applications',
            subtitle: 'Track every opportunity, all in one place.',
            onRefresh: _refresh,
          ),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _applications,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Could not load applications: ${snapshot.error}',
                  style: AppTypography.textTheme.bodyMedium!.copyWith(
                    color: AppColors.danger,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data!;
              final statuses = [
                'all',
                'applied',
                'interview',
                'offer',
                'accepted',
                'rejected',
                'withdrawn',
              ];
              final visible = _filter == 'all'
                  ? all
                  : all.where((item) => item['status'] == _filter).toList();
              final interviews = all
                  .where((item) => item['status'] == 'interview')
                  .length;
              final offers = all
                  .where(
                    (item) =>
                        item['status'] == 'offer' ||
                        item['status'] == 'accepted',
                  )
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ApplicationOverview(
                    total: all.length,
                    interviews: interviews,
                    offers: offers,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Application activity',
                    style: AppTypography.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (final status in statuses)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.xs,
                            ),
                            child: AppChip(
                              label:
                                  '${status[0].toUpperCase()}${status.substring(1)} '
                                  '(${status == 'all' ? all.length : all.where((item) => item['status'] == status).length})',
                              active: _filter == status,
                              onTap: () => setState(() => _filter = status),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (visible.isEmpty)
                    const EmptyState(
                      title: 'No applications yet',
                      message:
                          'When you apply for a role, you can track it here.',
                    )
                  else
                    for (final application in visible)
                      _backendApplicationCard(application),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _backendApplicationCard(Map<String, dynamic> application) {
    final job = application['jobs'] as Map<String, dynamic>?;
    final company = job?['companies'] as Map<String, dynamic>?;
    final status = application['status'] as String;
    final tone = switch (status) {
      'offer' => StatusTagTone.success,
      'accepted' => StatusTagTone.success,
      'interview' => StatusTagTone.orange,
      'rejected' || 'withdrawn' => StatusTagTone.neutral,
      _ => StatusTagTone.brand,
    };
    final progressStatus = switch (status) {
      'interview' => ApplicationStatus.interview,
      'offer' => ApplicationStatus.offer,
      'accepted' => ApplicationStatus.accepted,
      'rejected' => ApplicationStatus.rejected,
      'withdrawn' => ApplicationStatus.withdrawn,
      _ => ApplicationStatus.applied,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company?['name'] as String? ?? 'Company',
                      style: AppTypography.textTheme.labelMedium,
                    ),
                    Text(
                      job?['title'] as String? ?? 'Job',
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    Text(
                      'Submitted ${application['created_at']}',
                      style: AppTypography.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              StatusTag(label: _backendStatusLabel(status), tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusProgress(status: progressStatus),
          if (status == 'interview' ||
              status == 'offer' ||
              status == 'accepted') ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _messageEmployer(application['id'] as String),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Message employer'),
              ),
            ),
          ],
          if (status == 'offer') ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You have an offer. Accept it to confirm, or decline it.',
              style: AppTypography.textTheme.bodyMedium,
            ),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                AppChip(
                  label: 'Accept offer',
                  active: true,
                  onTap: () => _respondToOffer(
                    application['id'] as String,
                    accept: true,
                  ),
                ),
                AppChip(
                  label: 'Decline offer',
                  onTap: () => _respondToOffer(
                    application['id'] as String,
                    accept: false,
                  ),
                ),
              ],
            ),
          ],
          if (status == 'applied' || status == 'interview' || status == 'offer')
            TextButton(
              onPressed: () =>
                  _withdrawApplication(application['id'] as String),
              child: const Text('Withdraw application'),
            ),
        ],
      ),
    );
  }
}

class _ApplicationsHeader extends StatelessWidget {
  const _ApplicationsHeader({
    required this.title,
    required this.subtitle,
    this.demo = false,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool demo;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle,
              style: AppTypography.textTheme.bodyMedium!.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
      if (onRefresh != null)
        IconCircleButton(
          icon: Icons.refresh_rounded,
          semanticLabel: 'Refresh applications',
          onPressed: onRefresh,
        ),
      if (demo)
        const StatusTag(label: 'Local demo', tone: StatusTagTone.neutral),
    ],
  );
}

class _ApplicationOverview extends StatelessWidget {
  const _ApplicationOverview({
    required this.total,
    required this.interviews,
    required this.offers,
  });

  final int total;
  final int interviews;
  final int offers;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _OverviewTile(
          label: 'Total',
          value: total,
          icon: Icons.work_outline_rounded,
          color: AppColors.brand500,
          background: AppColors.brand50,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: _OverviewTile(
          label: 'Interviews',
          value: interviews,
          icon: Icons.calendar_month_rounded,
          color: AppColors.warn,
          background: AppColors.warnBg,
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: _OverviewTile(
          label: 'Offers',
          value: offers,
          icon: Icons.celebration_rounded,
          color: AppColors.success,
          background: AppColors.successBg,
        ),
      ),
    ],
  );
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            Text('$value', style: AppTypography.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.textTheme.labelMedium,
        ),
      ],
    ),
  );
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final isClosed =
        status == ApplicationStatus.rejected ||
        status == ApplicationStatus.withdrawn;
    final activeStep = switch (status) {
      ApplicationStatus.applied => 0,
      ApplicationStatus.interview => 1,
      ApplicationStatus.offer || ApplicationStatus.accepted => 2,
      ApplicationStatus.rejected || ApplicationStatus.withdrawn => 0,
    };
    if (isClosed) {
      return Text(
        status == ApplicationStatus.rejected
            ? 'This application is closed.'
            : 'You withdrew this application.',
        style: AppTypography.textTheme.labelMedium!.copyWith(
          color: AppColors.muted,
        ),
      );
    }
    final labels = [
      'Applied',
      'Interview',
      status == ApplicationStatus.accepted ? 'Accepted' : 'Offer',
    ];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                color: index <= activeStep
                    ? AppColors.brand300
                    : AppColors.divider,
              ),
            ),
          _ProgressStep(
            label: labels[index],
            active: index <= activeStep,
            current: index == activeStep,
          ),
        ],
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.label,
    required this.active,
    required this.current,
  });

  final String label;
  final bool active;
  final bool current;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: active ? AppColors.brand500 : AppColors.divider,
          shape: BoxShape.circle,
          border: current
              ? Border.all(color: AppColors.brand100, width: 4)
              : null,
        ),
        child: active && !current
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : null,
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        label,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: active ? AppColors.brand600 : AppColors.muted,
        ),
      ),
    ],
  );
}
