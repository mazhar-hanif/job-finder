import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/section_header.dart';
import '../../providers/job_providers.dart';
import '../home/widgets/job_card.dart';

/// Search and filter job listings.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _locationController = TextEditingController();
  String _query = '';
  String _locationQuery = '';
  String? _employmentType;
  bool _remoteOnly = false;
  bool _fullTimeOnly = false;
  final List<String> _recentQueries = [
    'Frontend developer',
    'Product designer',
    'Remote UX designer',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider);
    final companies = ref.watch(companiesProvider);
    final catalog = ref.watch(jobCatalogProvider);
    final saved = ref.watch(savedJobIdsProvider);
    final filtered = jobs.where((job) {
      final company = companies.firstWhere((item) => item.id == job.companyId);
      final searchableText = [
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
      final matchesQuery =
          _query.isEmpty ||
          searchableText.contains(_query.trim().toLowerCase());
      final matchesLocation =
          _locationQuery.isEmpty ||
          job.location.toLowerCase().contains(_locationQuery.toLowerCase());
      return matchesQuery &&
          matchesLocation &&
          (!_remoteOnly || job.isRemote) &&
          (!_fullTimeOnly || job.type == 'Full-time') &&
          (_employmentType == null || job.type == _employmentType);
    }).toList();
    final showingResults =
        _query.isNotEmpty ||
        _locationQuery.isNotEmpty ||
        _remoteOnly ||
        _fullTimeOnly ||
        _employmentType != null;
    final activeFilterCount = [
      if (_locationQuery.isNotEmpty) true,
      if (_remoteOnly) true,
      if (_fullTimeOnly) true,
      if (_employmentType != null) true,
    ].length;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Find your next role',
                  style: AppTypography.textTheme.headlineLarge,
                ),
              ),
              if (ref.watch(supabaseClientProvider) != null)
                IconCircleButton(
                  icon: Icons.refresh_rounded,
                  semanticLabel: 'Refresh jobs',
                  onPressed: () =>
                      ref.read(jobCatalogProvider.notifier).refresh(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Search thousands of opportunities and find the right fit.',
            style: AppTypography.textTheme.bodyMedium!.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSearchBar(
            controller: _controller,
            hintText: 'Job title, keyword, or company',
            onChanged: (value) => setState(() => _query = value.trim()),
            onSubmitted: _recordSearch,
            trailing: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _LocationCard(
            location: _locationQuery.isEmpty ? 'Worldwide' : _locationQuery,
            onTap: _editLocation,
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                AppChip(
                  label: 'Remote',
                  active: _remoteOnly,
                  onTap: () => setState(() {
                    _remoteOnly = !_remoteOnly;
                  }),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppChip(
                  label: 'Full-time',
                  active: _fullTimeOnly,
                  onTap: () => setState(() {
                    _fullTimeOnly = !_fullTimeOnly;
                    if (_fullTimeOnly) _employmentType = null;
                  }),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconCircleButton(
                  icon: Icons.tune_rounded,
                  semanticLabel: 'More job filters',
                  badge: activeFilterCount > 0,
                  onPressed: _showMoreFilters,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (catalog.loading) const LinearProgressIndicator(),
          if (catalog.error != null)
            Text(
              'Could not load live jobs: ${catalog.error}',
              style: AppTypography.textTheme.bodyMedium!.copyWith(
                color: AppColors.danger,
              ),
            ),
          if (showingResults) ...[
            Row(
              children: [
                Expanded(
                  child: SectionHeader(
                    title: '${filtered.length} matching job posts',
                  ),
                ),
                if (_query.isNotEmpty ||
                    _locationQuery.isNotEmpty ||
                    _remoteOnly ||
                    _fullTimeOnly ||
                    _employmentType != null)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear all'),
                  ),
              ],
            ),
            if (activeFilterCount > 0 || _query.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (_locationQuery.isNotEmpty)
                    AppChip(
                      label: _locationQuery,
                      soft: true,
                      leading: const Icon(Icons.location_on_rounded, size: 16),
                    ),
                  if (_remoteOnly)
                    const AppChip(
                      label: 'Remote',
                      soft: true,
                      leading: Icon(Icons.public_rounded, size: 16),
                    ),
                  if (_employmentType != null)
                    AppChip(label: _employmentType!, soft: true),
                ],
              ),
            ],
          ],
          if (showingResults) ...[
            const SizedBox(height: AppSpacing.md),
            if (catalog.loading && filtered.isEmpty)
              const Center(child: CircularProgressIndicator()),
            if (filtered.isEmpty && !catalog.loading)
              const EmptyState(
                title: 'No matching job posts',
                message: 'Try a different title, skill, company, or location.',
              )
            else if (filtered.isNotEmpty)
              for (final job in filtered)
                JobCard(
                  job: job,
                  company: companies.firstWhere(
                    (item) => item.id == job.companyId,
                  ),
                  saved: saved.contains(job.id),
                  onTap: () => context.push('/job/${job.id}'),
                  onSave: () =>
                      ref.read(savedJobIdsProvider.notifier).toggle(job.id),
                ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Popular Searches',
                        style: AppTypography.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Explore roles people are searching for',
                        style: AppTypography.textTheme.bodyMedium!.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 15,
                        color: AppColors.warn,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'TRENDING',
                        style: AppTypography.textTheme.labelSmall!.copyWith(
                          color: AppColors.warn,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - AppSpacing.xs) / 2;
                const popularRoles = [
                  ('Software Engineer', Icons.code_rounded),
                  ('Product Designer', Icons.draw_rounded),
                  ('Data Scientist', Icons.query_stats_rounded),
                  ('UI/UX Designer', Icons.design_services_rounded),
                  ('Marketing', Icons.campaign_rounded),
                  ('Sales', Icons.handshake_rounded),
                ];
                return Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final role in popularRoles)
                      SizedBox(
                        width: tileWidth,
                        child: _PopularSearchTile(
                          title: role.$1,
                          icon: role.$2,
                          onTap: () {
                            _controller.text = role.$1;
                            _recordSearch(role.$1);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Recent Searches',
              style: AppTypography.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _RecentSearches(
              entries: _recentQueries,
              onSelect: (value) {
                _controller.text = value;
                _recordSearch(value);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _recordSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() {
      _query = query;
      _recentQueries.remove(query);
      _recentQueries.insert(0, query);
      if (_recentQueries.length > 5) _recentQueries.removeLast();
    });
  }

  void _clearFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _locationQuery = '';
      _remoteOnly = false;
      _fullTimeOnly = false;
      _employmentType = null;
    });
  }

  Future<void> _editLocation() async {
    _locationController.text = _locationQuery;
    final location = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a location'),
        content: TextField(
          controller: _locationController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
          decoration: const InputDecoration(
            labelText: 'City, region, or Remote',
            hintText: 'e.g. New York or Remote',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Worldwide'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_locationController.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (location != null && mounted) {
      setState(() => _locationQuery = location);
    }
  }

  Future<void> _showMoreFilters() async {
    var selectedType = _employmentType;
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              AppSpacing.sm,
              AppSpacing.screenGutter,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More filters',
                  style: AppTypography.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Employment type',
                  style: AppTypography.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final option in const [
                      ('Any', null),
                      ('Full-time', 'Full-time'),
                      ('Part-time', 'Part-time'),
                      ('Contract', 'Contract'),
                    ])
                      AppChip(
                        label: option.$1,
                        active: selectedType == option.$2,
                        onTap: () =>
                            setSheetState(() => selectedType = option.$2),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(selectedType ?? ''),
                    child: const Text('Show matching jobs'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && type != null) {
      setState(() {
        _employmentType = type.isEmpty ? null : type;
        _fullTimeOnly = false;
      });
    }
  }
}

class _PopularSearchTile extends StatelessWidget {
  const _PopularSearchTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B2B6B).withValues(alpha: 0.05),
              blurRadius: AppSpacing.shadowBlur,
              offset: const Offset(0, AppSpacing.xs),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, color: AppColors.brand500, size: 17),
                ),
                const Spacer(),
                const Icon(
                  Icons.north_east_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    ),
  );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.onTap});

  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.brand500,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location', style: AppTypography.textTheme.labelMedium),
                  Text(location, style: AppTypography.textTheme.titleMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.entries, required this.onSelect});

  final List<String> entries;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Column(
      children: [
        for (final entry in entries)
          Material(
            color: AppColors.surface,
            child: InkWell(
              onTap: () => onSelect(entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.muted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        entry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
