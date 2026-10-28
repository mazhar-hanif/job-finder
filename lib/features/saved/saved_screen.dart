import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/job_providers.dart';
import '../home/widgets/job_card.dart';

/// List of saved jobs with quick category filters.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider);
    final companies = ref.watch(companiesProvider);
    final savedIds = ref.watch(savedJobIdsProvider);
    final savedJobs = jobs.where((job) => savedIds.contains(job.id)).toList();
    final remoteCount = savedJobs.where((job) => job.isRemote).length;
    final fullTimeCount = savedJobs
        .where((job) => job.type == 'Full-time')
        .length;
    final visible = switch (_filter) {
      1 => savedJobs.where((job) => job.isRemote).toList(),
      2 => savedJobs.where((job) => job.type == 'Full-time').toList(),
      _ => savedJobs,
    };

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
          Text('Saved Jobs', style: AppTypography.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                AppChip(
                  label: 'All (${savedJobs.length})',
                  active: _filter == 0,
                  onTap: () => setState(() => _filter = 0),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: 'Remote ($remoteCount)',
                  active: _filter == 1,
                  onTap: () => setState(() => _filter = 1),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: 'Full-time ($fullTimeCount)',
                  active: _filter == 2,
                  onTap: () => setState(() => _filter = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            EmptyState(
              title: 'No saved jobs',
              message: 'Save jobs you like and come back to them anytime.',
              action: TextButton(
                onPressed: () => context.push('/search'),
                child: const Text('Browse jobs'),
              ),
            )
          else
            for (final job in visible)
              JobCard(
                job: job,
                company: companies.firstWhere(
                  (item) => item.id == job.companyId,
                ),
                saved: true,
                onTap: () => context.push('/job/${job.id}'),
                onSave: () =>
                    ref.read(savedJobIdsProvider.notifier).toggle(job.id),
              ),
        ],
      ),
    );
  }
}
