import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/company_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/status_tag.dart';
import '../../core/widgets/underline_tabs.dart';
import '../../core/widgets/user_avatar.dart';

class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Display', style: AppTypography.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Headline Large',
                style: AppTypography.textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Headline Medium',
                style: AppTypography.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Title Large', style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text('Body Large', style: AppTypography.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              Text('Body Medium', style: AppTypography.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Text('Label Large', style: AppTypography.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: 'Buttons', actionLabel: 'Action'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  PrimaryButton(label: 'Get Started', onPressed: () {}),
                  PrimaryButton(
                    label: 'Small',
                    size: PrimaryButtonSize.small,
                    onPressed: () {},
                  ),
                  OutlineButton(label: 'Outline', onPressed: () {}),
                  SoftButton(label: 'Soft', onPressed: () {}),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSearchBar(hintText: 'Search jobs'),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  const AppChip(label: 'Remote', active: true),
                  const AppChip(label: 'Full-time'),
                  const AppChip(label: 'Soft', soft: true),
                  const StatusTag(label: 'Applied', tone: StatusTagTone.brand),
                  const StatusTag(
                    label: 'Interview',
                    tone: StatusTagTone.orange,
                  ),
                  const StatusTag(label: 'Offer', tone: StatusTagTone.success),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  CompanyLogo(name: 'G', tint: AppColors.brand500, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  CompanyLogo(name: 'M', tint: AppColors.brand700, size: 56),
                  const SizedBox(width: AppSpacing.md),
                  UserAvatar(initials: 'AC', size: 46),
                  const SizedBox(width: AppSpacing.md),
                  const IconCircleButton(
                    icon: Icons.notifications_rounded,
                    semanticLabel: 'Notifications',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              UnderlineTabs(
                tabs: const ['Overview', 'Requirements', 'Benefits'],
                selectedIndex: 1,
                onTap: (_) {},
              ),
              const SizedBox(height: AppSpacing.lg),
              const EmptyState(
                title: 'Nothing here yet',
                message: 'Your saved jobs will appear here.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
