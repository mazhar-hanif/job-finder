import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/company.dart';
import '../../data/models/job.dart';
import '../../providers/job_providers.dart';
import 'widgets/ai_match_card.dart';
import 'widgets/home_match_widgets.dart';
import 'widgets/job_card.dart';
import 'widgets/job_post_card.dart';

/// Home tab featuring personalized job recommendations.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _recommendedPageController = PageController(viewportFraction: 0.92);
  String _query = '';
  HomeMatchPreferences? _aiPreferences;

  @override
  void dispose() {
    _searchController.dispose();
    _recommendedPageController.dispose();
    super.dispose();
  }

  Future<void> _openAiMatchPreferences() async {
    final profile = ref.read(profileDetailsProvider);
    var role = profile.headline;
    var skills = profile.skills.join(', ');
    var location = profile.location;
    var employmentType = profile.preferredJobTypes.firstWhere(
      (type) => const {
        'Full-time',
        'Part-time',
        'Contract',
        'Internship',
        'Freelance',
      }.contains(type),
      orElse: () => '',
    );
    var remoteOnly = false;
    final preferences = await showDialog<HomeMatchPreferences>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Personalize your job match'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add as much or as little as you like. We compare your choices '
                'with current job posts. Matching uses listing details only '
                'and does not call a third-party AI service.',
                style: AppTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: role,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => role = value,
                decoration: const InputDecoration(
                  labelText: 'Role or job title',
                  hintText: 'e.g. Flutter developer',
                ),
              ),
              TextFormField(
                initialValue: skills,
                maxLength: 500,
                onChanged: (value) => skills = value,
                decoration: const InputDecoration(
                  labelText: 'Skills or keywords',
                  hintText: 'Flutter, design, customer support',
                  helperText: 'Separate multiple skills with commas.',
                ),
              ),
              TextFormField(
                initialValue: location,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => location = value,
                decoration: const InputDecoration(
                  labelText: 'Preferred location',
                  hintText: 'City, region, or country',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: employmentType,
                decoration: const InputDecoration(labelText: 'Work type'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Any work type')),
                  DropdownMenuItem(
                    value: 'Full-time',
                    child: Text('Full-time'),
                  ),
                  DropdownMenuItem(
                    value: 'Part-time',
                    child: Text('Part-time'),
                  ),
                  DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                  DropdownMenuItem(
                    value: 'Internship',
                    child: Text('Internship'),
                  ),
                  DropdownMenuItem(
                    value: 'Freelance',
                    child: Text('Freelance'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => employmentType = value ?? ''),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remote jobs only'),
                value: remoteOnly,
                onChanged: (value) => setDialogState(() => remoteOnly = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                dialogContext,
                HomeMatchPreferences(
                  role: role.trim(),
                  skills: _splitTerms(skills),
                  location: location.trim(),
                  employmentType: employmentType,
                  remoteOnly: remoteOnly,
                ),
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Find matches'),
            ),
          ],
        ),
      ),
    );
    if (preferences == null || !mounted) return;
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _query = '';
      _aiPreferences = preferences;
    });
  }

  List<Job> _rankMatches(
    List<Job> jobs,
    List<Company> companies,
    ProfileDetails profile,
    HomeMatchPreferences preferences,
  ) {
    final roleTerms = _splitTerms(preferences.role);
    final skills = {
      ...preferences.skills.map((skill) => skill.toLowerCase()),
      ...profile.skills.map((skill) => skill.toLowerCase()),
    };
    final role = preferences.role.trim().toLowerCase();
    final location = preferences.location.trim().toLowerCase();
    final type = preferences.employmentType.toLowerCase();
    final hasKeywords = roleTerms.isNotEmpty || skills.isNotEmpty;
    final scored = <({Job job, int score})>[];

    for (final job in jobs) {
      if (preferences.remoteOnly && !job.isRemote) continue;
      if (type.isNotEmpty && job.type.toLowerCase() != type) continue;
      final company = companies.firstWhere((item) => item.id == job.companyId);
      final searchable = _searchableContent(job, companies);
      if (location.isNotEmpty &&
          !'${job.location} ${job.workplaceType} ${company.location}'
              .toLowerCase()
              .contains(location)) {
        continue;
      }

      var score = 0;
      for (final skill in skills) {
        if (skill.isNotEmpty && searchable.contains(skill)) score += 3;
      }
      for (final term in roleTerms) {
        if (job.title.toLowerCase().contains(term)) {
          score += 4;
        } else if (searchable.contains(term)) {
          score += 1;
        }
      }

      if (profile.preferredJobTypes.any(
        (preferred) => preferred.toLowerCase() == job.type.toLowerCase(),
      )) {
        score += 2;
      }
      if (location.isNotEmpty) score += 3;
      if (type.isNotEmpty || preferences.remoteOnly) score += 1;
      if (role.isEmpty && skills.isEmpty && location.isEmpty && type.isEmpty) {
        score = 1;
      }
      if (!hasKeywords || score > 0) scored.add((job: job, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((entry) => entry.job).toList();
  }

  String _searchableContent(Job job, List<Company> companies) {
    final company = companies.firstWhere((item) => item.id == job.companyId);
    return [
      job.title,
      job.location,
      job.type,
      job.workplaceType,
      job.about,
      job.salaryLabel,
      job.salaryShort,
      company.name,
      company.industry,
      company.location,
      company.about,
      ...job.skills,
      ...job.responsibilities,
      ...job.requirements,
      ...job.benefits,
    ].join(' ').toLowerCase();
  }

  List<String> _splitTerms(String text) => text
      .toLowerCase()
      .split(RegExp(r'[,;\s]+'))
      .map((term) => term.trim())
      .where((term) => term.length > 1)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final jobs = ref.watch(jobsProvider);
    final companies = ref.watch(companiesProvider);
    final catalog = ref.watch(jobCatalogProvider);
    final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
    final profile = ref.watch(profileDetailsProvider);
    final userName =
        user?.userMetadata?['full_name'] as String? ?? profile.fullName;
    final ImageProvider? profileImage = profile.avatarBytes != null
        ? MemoryImage(profile.avatarBytes!)
        : profile.avatarUrl != null
        ? NetworkImage(profile.avatarUrl!)
        : null;
    final initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final savedIds = ref.watch(savedJobIdsProvider);
    final recommendedJobs = jobs;
    final normalizedQuery = _query.toLowerCase();
    final visibleJobs = jobs.where((job) {
      return normalizedQuery.isEmpty ||
          _searchableContent(job, companies).contains(normalizedQuery);
    }).toList();
    final isSearching = normalizedQuery.isNotEmpty;
    final aiMatches = _aiPreferences == null
        ? <Job>[]
        : _rankMatches(visibleJobs, companies, profile, _aiPreferences!);
    final postedJobs = isSearching || _aiPreferences != null
        ? visibleJobs
        : jobs;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: AppSpacing.homeToolbarHeight,
        titleSpacing: AppSpacing.screenGutter,
        backgroundColor: AppColors.homeHeaderBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Tooltip(
              message: 'Open profile',
              child: Semantics(
                button: true,
                label: 'Open profile',
                excludeSemantics: true,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.push('/profile'),
                    child: UserAvatar(
                      initials: initials.isEmpty ? 'AC' : initials,
                      size: 46,
                      imageProvider: profileImage,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppSearchBar(
                hintText: 'Search jobs, skills, companies',
                dark: true,
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                onSubmitted: (value) {
                  setState(() => _query = value.trim());
                  FocusScope.of(context).unfocus();
                },
                trailing: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.homeHeaderForeground,
                        ),
                      ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: () => context.push('/messages'),
            icon: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.homeHeaderForeground,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.md,
            AppSpacing.screenGutter,
            AppSpacing.xxl,
          ),
          children: [
            if (ref.watch(supabaseClientProvider) == null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: 'Hiring? Post a job',
                  leading: const Icon(
                    Icons.add_business_rounded,
                    color: AppColors.brand500,
                  ),
                  onPressed: () => context.go('/employer'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (catalog.loading) const LinearProgressIndicator(),
            if (catalog.error != null)
              Text(
                'Could not load live jobs: ${catalog.error}',
                style: AppTypography.textTheme.bodyMedium!.copyWith(
                  color: AppColors.danger,
                ),
              ),
            if (isSearching) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title:
                    'Results for "$_query" · ${postedJobs.length} '
                    'job${postedJobs.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: AppSpacing.md),
              if (postedJobs.isEmpty && !catalog.loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No matching job posts',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Try another job title, skill, company, or location.',
                          textAlign: TextAlign.center,
                          style: AppTypography.textTheme.bodyMedium!.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final job in postedJobs)
                JobPostCard(
                  job: job,
                  company: companies.firstWhere(
                    (company) => company.id == job.companyId,
                  ),
                  saved: savedIds.contains(job.id),
                  onSave: () =>
                      ref.read(savedJobIdsProvider.notifier).toggle(job.id),
                ),
            ] else if (_aiPreferences != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: '${aiMatches.length} matched job posts',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _aiPreferences = null),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Matched against role, skills, location, work type, '
                  'and the full job post.',
                  style: AppTypography.textTheme.labelMedium,
                ),
              ),
              if (aiMatches.isEmpty)
                const NoAiMatches()
              else
                for (final job in aiMatches)
                  JobPostCard(
                    job: job,
                    company: companies.firstWhere(
                      (company) => company.id == job.companyId,
                    ),
                    saved: savedIds.contains(job.id),
                    onSave: () =>
                        ref.read(savedJobIdsProvider.notifier).toggle(job.id),
                  ),
            ] else ...[
              AiMatchCard(onPressed: _openAiMatchPreferences),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(
                    child: SectionHeader(title: 'Recommended for you'),
                  ),
                  if (ref.watch(supabaseClientProvider) != null)
                    IconCircleButton(
                      icon: Icons.refresh_rounded,
                      semanticLabel: 'Refresh recommended jobs',
                      onPressed: () =>
                          ref.read(jobCatalogProvider.notifier).refresh(),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (recommendedJobs.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Swipe cards or use the arrows',
                      style: AppTypography.textTheme.labelMedium!.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              if (recommendedJobs.isNotEmpty)
                SizedBox(
                  height: AppSpacing.recommendedJobCardHeight,
                  child: PageView.builder(
                    controller: _recommendedPageController,
                    physics: const PageScrollPhysics(),
                    itemCount: recommendedJobs.length,
                    itemBuilder: (context, index) {
                      final job = recommendedJobs[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.sm,
                          bottom: AppSpacing.xs,
                        ),
                        child: JobCard(
                          job: job,
                          company: companies.firstWhere(
                            (company) => company.id == job.companyId,
                          ),
                          saved: savedIds.contains(job.id),
                          onTap: () => context.push('/job/${job.id}'),
                          onSave: () => ref
                              .read(savedJobIdsProvider.notifier)
                              .toggle(job.id),
                        ),
                      );
                    },
                  ),
                ),
              if (recommendedJobs.length > 1)
                RecommendedPageIndicator(
                  controller: _recommendedPageController,
                  itemCount: recommendedJobs.length,
                ),
            ],
            if (!isSearching &&
                jobs.isEmpty &&
                !catalog.loading &&
                catalog.error == null) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'No jobs are available right now',
                  style: AppTypography.textTheme.labelMedium!.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
            if (!isSearching && postedJobs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Latest job posts'),
              const SizedBox(height: AppSpacing.md),
              for (final job in postedJobs)
                JobPostCard(
                  job: job,
                  company: companies.firstWhere(
                    (company) => company.id == job.companyId,
                  ),
                  saved: savedIds.contains(job.id),
                  onSave: () =>
                      ref.read(savedJobIdsProvider.notifier).toggle(job.id),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
