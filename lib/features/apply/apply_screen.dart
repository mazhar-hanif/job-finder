import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/widgets/company_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/soft_button.dart';
import '../../core/widgets/status_tag.dart';
import '../../providers/job_providers.dart';

/// Application form for a selected job.
class ApplyScreen extends ConsumerStatefulWidget {
  const ApplyScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _applicantNameController = TextEditingController(text: 'Alex Carter');
  final _applicantEmailController = TextEditingController(
    text: 'alex.carter@email.com',
  );
  final _coverLetterController = TextEditingController();
  String _resumeName = 'No resume selected';
  PlatformFile? _selectedResume;
  Uint8List? _resumeBytes;
  bool _submitted = false;
  bool _submitting = false;
  bool _demoSubmission = false;
  String? _submitError;

  @override
  void dispose() {
    _applicantNameController.dispose();
    _applicantEmailController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final size = await file.length();
      if (!mounted) return;
      if (size == null) {
        setState(
          () => _submitError = 'Could not read the selected resume file.',
        );
        return;
      }
      if (size > 10 * 1024 * 1024) {
        setState(() => _submitError = 'Resume files must be 10 MB or smaller.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(() => _submitError = 'The selected resume file is empty.');
        return;
      }
      setState(() {
        _selectedResume = file;
        _resumeBytes = bytes;
        _resumeName = file.name;
        _submitError = null;
      });
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _submitError = 'Could not read resume: $error');
      }
    }
  }

  Future<void> _submitApplication(String jobId) async {
    final service = ref.read(supabaseJobServiceProvider);
    if (service == null) {
      final applicantName = _applicantNameController.text.trim();
      final applicantEmail = _applicantEmailController.text.trim();
      if (applicantName.length < 2) {
        setState(() => _submitError = 'Enter your name to apply.');
        return;
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(applicantEmail)) {
        setState(() => _submitError = 'Enter a valid email to apply.');
        return;
      }
      ref
          .read(applicationsProvider.notifier)
          .apply(
            jobId,
            applicantName: applicantName,
            applicantEmail: applicantEmail,
            coverLetter: _coverLetterController.text,
            resumeName: _selectedResume?.name ?? '',
          );
      setState(() {
        _demoSubmission = true;
        _submitted = true;
      });
      return;
    }
    if (service.client.auth.currentUser == null) {
      setState(() => _submitError = 'Sign in to submit your application.');
      return;
    }
    final resume = _selectedResume;
    final resumeBytes = _resumeBytes;
    if (resume == null || resumeBytes == null) {
      setState(() => _submitError = 'Choose your resume before applying.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final profile = await service.client
          .from('profiles')
          .select('role')
          .eq('id', service.client.auth.currentUser!.id)
          .single();
      if (profile['role'] != 'applicant') {
        setState(
          () => _submitError =
              'Applications can only be submitted from job seeker accounts.',
        );
        return;
      }
      await service.submitApplication(
        jobId: jobId,
        fileName: resume.name,
        fileBytes: resumeBytes,
        coverLetter: _coverLetterController.text,
      );
      ref.read(applicationsProvider.notifier).apply(jobId);
      setState(() => _submitted = true);
    } on Exception catch (error) {
      setState(() => _submitError = 'Could not submit application: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobsProvider);
    final companies = ref.watch(companiesProvider);
    final catalog = ref.watch(jobCatalogProvider);
    final matchingJobs = jobs.where((item) => item.id == widget.jobId);
    if (matchingJobs.isEmpty) {
      final isConfigured = ref.watch(supabaseClientProvider) != null;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenGutter),
              child: EmptyState(
                title: catalog.loading ? 'Loading job...' : 'Job unavailable',
                message: catalog.loading
                    ? 'Please wait while we load the job details.'
                    : catalog.error != null
                    ? 'We could not load this job: ${catalog.error}'
                    : 'This job may have been closed or removed. Browse jobs to find another opportunity.',
                action: catalog.loading
                    ? const CircularProgressIndicator()
                    : PrimaryButton(
                        label: catalog.error != null && isConfigured
                            ? 'Try again'
                            : 'Browse jobs',
                        onPressed: catalog.error != null && isConfigured
                            ? () => ref
                                  .read(jobCatalogProvider.notifier)
                                  .refresh()
                            : () => context.go('/home'),
                      ),
              ),
            ),
          ),
        ),
      );
    }
    final job = matchingJobs.first;
    final matchingCompanies = companies.where(
      (item) => item.id == job.companyId,
    );
    if (matchingCompanies.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenGutter),
              child: EmptyState(
                title: 'Company unavailable',
                message:
                    'We could not load the company details for this job. Please try again.',
                action: PrimaryButton(
                  label: 'Try again',
                  onPressed: () =>
                      ref.read(jobCatalogProvider.notifier).refresh(),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final company = matchingCompanies.first;

    if (_submitted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _demoSubmission
                        ? 'Demo application recorded'
                        : 'Application sent',
                    style: AppTypography.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _demoSubmission
                        ? 'Saved locally and visible in the Employer demo on this device. Connect Supabase to send applications online.'
                        : 'Your application for ${job.title} is on its way. Good luck!',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodyLarge!.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Track application',
                      onPressed: () => context.go('/applications'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SoftButton(
                      label: 'Back to home',
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.xs,
            AppSpacing.screenGutter,
            AppSpacing.lg,
          ),
          children: [
            Row(
              children: [
                IconCircleButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  onPressed: () => goBackOrHome(context),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Apply for Job',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (ref.watch(supabaseClientProvider) == null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Demo application · Your details will appear in the local Employer demo on this device. No data is sent online.',
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (ref.watch(supabaseClientProvider) == null) ...[
              Text(
                'Your details',
                style: AppTypography.textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _applicantNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _applicantEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            Container(
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
              child: Row(
                children: [
                  CompanyLogo(
                    name: company.name,
                    tint: Color(company.tint),
                    size: 54,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: AppTypography.textTheme.titleLarge,
                        ),
                        Text(
                          '${company.name} · ${job.location}',
                          style: AppTypography.textTheme.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            StatusTag(
                              label: job.salaryLabel,
                              tone: StatusTagTone.success,
                            ),
                            StatusTag(label: job.type),
                            StatusTag(
                              label: job.workplaceType,
                              tone: StatusTagTone.neutral,
                            ),
                            StatusTag(
                              label: job.postedAgo,
                              tone: StatusTagTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Your resume', style: AppTypography.textTheme.headlineMedium),
            if (ref.watch(supabaseClientProvider) != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Upload a PDF, DOC, or DOCX file (maximum 10 MB). It is stored privately.',
                style: AppTypography.textTheme.labelMedium,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Offline demo only: a selected file is not uploaded or shared with the employer.',
                style: AppTypography.textTheme.labelMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.brand500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resumeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        Text(
                          _selectedResume == null
                              ? 'Select a resume to apply'
                              : 'Ready to submit',
                          style: AppTypography.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Change resume',
                    onPressed: _pickResume,
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.brand500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlineButton(
                label: 'Upload new resume',
                leading: const Icon(
                  Icons.upload_file_rounded,
                  color: AppColors.brand500,
                  size: 18,
                ),
                onPressed: _pickResume,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cover letter (optional)',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                ),
                Text(
                  '${_coverLetterController.text.length}/500',
                  style: AppTypography.textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _coverLetterController,
              maxLength: 500,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Share a few words about why you are a great fit...',
                counterText: '',
                alignLabelWithHint: true,
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _submitError!,
                style: AppTypography.textTheme.bodyMedium!.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.sm,
            AppSpacing.screenGutter,
            AppSpacing.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _submitting
                  ? 'Submitting...'
                  : ref.watch(supabaseClientProvider)?.auth.currentUser ==
                            null &&
                        ref.watch(supabaseClientProvider) != null
                  ? 'Sign in to apply'
                  : 'Submit Application',
              disabled: _submitting,
              onPressed: _submitting
                  ? null
                  : ref.watch(supabaseClientProvider)?.auth.currentUser ==
                            null &&
                        ref.watch(supabaseClientProvider) != null
                  ? () => context.go(
                      Uri(
                        path: '/auth',
                        queryParameters: {'next': '/apply/${job.id}'},
                      ).toString(),
                    )
                  : () => _submitApplication(job.id),
            ),
          ),
        ),
      ),
    );
  }
}
