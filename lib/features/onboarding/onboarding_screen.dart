import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/primary_button.dart';
import 'widgets/brand_mark.dart';
import 'widgets/hero_illustration.dart';

/// First-run welcome screen that introduces the JobFinder experience.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideContent(
      eyebrow: 'Discover',
      title: 'Find work that fits your future.',
      description:
          'Explore job posts by role, skills, location, and work style.',
      icon: Icons.search_rounded,
    ),
    _SlideContent(
      eyebrow: 'Apply',
      title: 'Put your best profile forward.',
      description:
          'Share your experience, attach a resume, and apply with confidence.',
      icon: Icons.description_rounded,
    ),
    _SlideContent(
      eyebrow: 'Stay in control',
      title: 'Follow every application.',
      description:
          'See interview updates, offers, and next steps in one place.',
      icon: Icons.track_changes_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    const BrandMark(),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        'YOUR NEXT OPPORTUNITY STARTS HERE',
                        style: AppTypography.textTheme.labelMedium!.copyWith(
                          color: AppColors.brand600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Find the right job.\nBuild your future.',
                      style: AppTypography.textTheme.displayLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Discover opportunities, connect with top companies, and take the next step in your career.',
                      style: AppTypography.textTheme.bodyLarge!.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: AppSpacing.onboardingSlideHeight,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const PageScrollPhysics(),
                        itemCount: _slides.length + 1,
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: index == 0
                              ? const HeroIllustration()
                              : _OnboardingSlide(content: _slides[index - 1]),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PageDots(
                      currentPage: _currentPage,
                      itemCount: _slides.length + 1,
                      onSelected: (page) => _pageController.animateToPage(
                        page,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Get Started',
                        leading: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => context.push('/auth?mode=signup'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideContent {
  const _SlideContent({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content});

  final _SlideContent content;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: AppColors.brand100),
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: AppSpacing.shadowBlur,
          offset: Offset(0, AppSpacing.shadowOffsetY),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: AppSpacing.onboardingSlideIconContainerSize,
          height: AppSpacing.onboardingSlideIconContainerSize,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.brand100),
          ),
          child: Icon(
            content.icon,
            color: AppColors.brand500,
            size: AppSpacing.onboardingSlideIconSize,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          content.eyebrow.toUpperCase(),
          style: AppTypography.textTheme.labelMedium!.copyWith(
            color: AppColors.brand500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content.title,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content.description,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.bodyMedium!.copyWith(
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.currentPage,
    required this.itemCount,
    required this.onSelected,
  });

  final int currentPage;
  final int itemCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Onboarding page ${currentPage + 1} of $itemCount',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Semantics(
          button: true,
          selected: currentPage == index,
          label: 'Show onboarding page ${index + 1}',
          child: InkResponse(
            onTap: () => onSelected(index),
            radius: AppSpacing.md,
            child: SizedBox(
              width: AppSpacing.onboardingDotHitSize,
              height: AppSpacing.onboardingDotHitSize,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: currentPage == index
                      ? AppSpacing.onboardingActiveDotWidth
                      : AppSpacing.onboardingDotSize,
                  height: AppSpacing.onboardingDotSize,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? AppColors.brand500
                        : AppColors.brand200,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
