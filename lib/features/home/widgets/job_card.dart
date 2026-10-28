import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../core/widgets/status_tag.dart';
import '../../../data/models/company.dart';
import '../../../data/models/job.dart';

/// A job summary card with save and optional flip-to-preview actions.
class JobCard extends StatefulWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.company,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });

  final Job job;
  final Company company;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> with SingleTickerProviderStateMixin {
  late final AnimationController _flipController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  bool get _isFlipped => _flipController.status == AnimationStatus.completed;

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    child: InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, _) {
          final angle = _flipController.value * math.pi;
          final showBack = _flipController.value >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _backFace(),
                  )
                : _frontFace(),
          );
        },
      ),
    ),
  );

  Widget _frontFace() => _cardSurface(
    key: const ValueKey('job-card-front'),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompanyLogo(
          name: widget.company.name,
          tint: Color(widget.company.tint),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${widget.company.name} · ${widget.job.location} · ${widget.job.workplaceType}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusTag(label: widget.job.type),
                  StatusTag(
                    label: widget.job.salaryShort,
                    tone: StatusTagTone.success,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _iconAction(
              icon: widget.saved
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: widget.saved ? 'Remove saved job' : 'Save job',
              onPressed: widget.onSave,
              color: widget.saved ? AppColors.brand500 : AppColors.muted,
            ),
            _iconAction(
              icon: Icons.flip_rounded,
              label: 'Flip job card',
              onPressed: _toggleFlip,
            ),
            Text(
              widget.job.postedAgo,
              style: AppTypography.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _backFace() => _cardSurface(
    key: const ValueKey('job-card-back'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'About this role',
                style: AppTypography.textTheme.titleMedium,
              ),
            ),
            _iconAction(
              icon: Icons.flip_rounded,
              label: 'Flip job card back',
              onPressed: _toggleFlip,
            ),
          ],
        ),
        Text(
          '${widget.company.name} · ${widget.job.location} · ${widget.job.type}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.textTheme.labelMedium,
        ),
        Text(
          widget.job.about,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusTag(
              label: widget.job.salaryShort,
              tone: StatusTagTone.success,
            ),
            Text(
              'View details',
              style: AppTypography.textTheme.labelLarge!.copyWith(
                color: AppColors.brand500,
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.brand500,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _iconAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = AppColors.ink2,
  }) => Semantics(
    button: true,
    label: label,
    child: SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
      ),
    ),
  );

  Widget _cardSurface({required Key key, required Widget child}) => Container(
    key: key,
    constraints: const BoxConstraints(minHeight: 122),
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1B2B6B).withValues(alpha: 0.07),
          blurRadius: AppSpacing.shadowBlur,
          offset: const Offset(0, AppSpacing.shadowOffsetY),
        ),
      ],
    ),
    child: child,
  );
}
