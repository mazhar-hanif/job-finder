import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/company_logo.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/soft_button.dart';
import '../../providers/job_providers.dart';

/// Company profile with culture highlights and follow action.
class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref
        .watch(companiesProvider)
        .firstWhere((item) => item.id == companyId);
    final isFollowing = ref
        .watch(followingCompanyIdsProvider)
        .contains(company.id);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 180 + MediaQuery.paddingOf(context).top,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.companyCoverGradient,
                      ),
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 150,
                          color: Color(0x22FFFFFF),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
                    left: AppSpacing.screenGutter,
                    child: IconCircleButton(
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: 'Back',
                      glass: true,
                      onPressed: () => goBackOrHome(context),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
                    right: AppSpacing.screenGutter,
                    child: IconCircleButton(
                      icon: Icons.more_horiz_rounded,
                      semanticLabel: 'More company options',
                      glass: true,
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    bottom: -32,
                    left: AppSpacing.screenGutter,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: CompanyLogo(
                        name: company.name,
                        tint: Color(company.tint),
                        size: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: AppTypography.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 17,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${company.rating} (${company.reviewsLabel})',
                        style: AppTypography.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${company.industry} · ${company.size} · ${company.location}',
                    style: AppTypography.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 78,
                    child: Row(
                      children: [
                        for (final icon in const [
                          Icons.meeting_room_rounded,
                          Icons.groups_rounded,
                          Icons.lightbulb_rounded,
                          Icons.workspaces_rounded,
                        ])
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brand50,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: AppColors.brand400,
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'About us',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    company.about,
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Company values',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (final value in company.values)
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.brand50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _companyValueIcon(value.icon),
                                  color: AppColors.brand500,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                value.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: isFollowing
                        ? SoftButton(
                            label: 'Following',
                            leading: const Icon(
                              Icons.check_rounded,
                              color: AppColors.brand600,
                              size: 18,
                            ),
                            onPressed: () => ref
                                .read(followingCompanyIdsProvider.notifier)
                                .toggle(company.id),
                          )
                        : OutlineButton(
                            label: 'Follow',
                            onPressed: () => ref
                                .read(followingCompanyIdsProvider.notifier)
                                .toggle(company.id),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _companyValueIcon(String name) => switch (name) {
  'spark' => Icons.auto_awesome_rounded,
  'people' || 'groups' => Icons.groups_rounded,
  'trending_up' => Icons.trending_up_rounded,
  'flag' => Icons.flag_rounded,
  'favorite' => Icons.favorite_rounded,
  'school' => Icons.school_rounded,
  'rocket_launch' => Icons.rocket_launch_rounded,
  'support_agent' => Icons.support_agent_rounded,
  'lightbulb' => Icons.lightbulb_rounded,
  'speed' => Icons.speed_rounded,
  'check_circle' => Icons.check_circle_rounded,
  'palette' => Icons.palette_rounded,
  'music_note' => Icons.music_note_rounded,
  'stadia_controller' => Icons.sports_esports_rounded,
  'brush' => Icons.brush_rounded,
  'shield' => Icons.shield_rounded,
  'accessibility_new' => Icons.accessibility_new_rounded,
  'verified' => Icons.verified_rounded,
  _ => Icons.business_rounded,
};
