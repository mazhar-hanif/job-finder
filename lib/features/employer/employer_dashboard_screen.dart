import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/router/navigation_helpers.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_tag.dart';
import '../../data/models/application.dart';
import '../../data/models/job.dart';
import '../../data/repositories/supabase_job_service.dart';
import '../../providers/job_providers.dart';

/// Employer job-posting and candidate-review workspace.
class EmployerDashboardScreen extends ConsumerStatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  ConsumerState<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState
    extends ConsumerState<EmployerDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _industryController = TextEditingController();
  final _companyLocationController = TextEditingController();
  final _titleController = TextEditingController();
  final _jobLocationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  String _employmentType = 'Full-time';
  String _workplaceType = 'On-site';
  String _salaryCurrency = 'PKR';
  String _salaryPeriod = 'year';
  bool _loading = false;
  bool _checkingAccess = true;
  bool _hasEmployerAccess = false;
  bool _showPostForm = false;
  String? _selectedJobId;
  String? _error;
  Future<List<Map<String, dynamic>>>? _jobsFuture;
  Future<List<Map<String, dynamic>>>? _applicationsFuture;

  SupabaseJobService? get _service => ref.read(supabaseJobServiceProvider);

  @override
  void initState() {
    super.initState();
    if (_service == null) {
      _checkingAccess = false;
      _hasEmployerAccess = true;
    }
    _loadEmployerData();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _industryController.dispose();
    _companyLocationController.dispose();
    _titleController.dispose();
    _jobLocationController.dispose();
    _descriptionController.dispose();
    _responsibilitiesController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _skillsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    super.dispose();
  }

  void _loadEmployerData() {
    final service = _service;
    if (service == null || service.client.auth.currentUser == null) return;
    _jobsFuture = service.fetchEmployerJobs();
    _applicationsFuture = service.fetchEmployerApplications();
    _checkEmployerRole(service);
  }

  Future<void> _checkEmployerRole(SupabaseJobService service) async {
    try {
      final profile = await service.client
          .from('profiles')
          .select('role')
          .eq('id', service.client.auth.currentUser!.id)
          .single();
      if (mounted) {
        setState(() {
          _hasEmployerAccess = profile['role'] == 'employer';
          _checkingAccess = false;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Could not verify employer access: $error';
          _checkingAccess = false;
        });
      }
    }
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    final service = _service;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (service == null) {
        ref
            .read(jobCatalogProvider.notifier)
            .createDemoJob(
              companyName: _companyController.text,
              industry: _industryController.text,
              companyLocation: _companyLocationController.text,
              title: _titleController.text,
              location: _jobLocationController.text,
              employmentType: _employmentType,
              description: _descriptionController.text,
              workplaceType: _workplaceType,
              salaryMin: _salaryAmount(_salaryMinController.text),
              salaryMax: _salaryAmount(_salaryMaxController.text),
              salaryCurrency: _salaryCurrency,
              salaryPeriod: _salaryPeriod,
              responsibilities: _lineItems(_responsibilitiesController.text),
              requirements: _lineItems(_requirementsController.text),
              benefits: _lineItems(_benefitsController.text),
              skills: _commaItems(_skillsController.text),
            );
        if (!mounted) return;
        _titleController.clear();
        _jobLocationController.clear();
        _descriptionController.clear();
        _responsibilitiesController.clear();
        _requirementsController.clear();
        _benefitsController.clear();
        _skillsController.clear();
        _salaryMinController.clear();
        _salaryMaxController.clear();
        setState(() => _showPostForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo job published and visible in job search.'),
          ),
        );
        return;
      }
      await service.createJob(
        companyName: _companyController.text,
        industry: _industryController.text,
        companyLocation: _companyLocationController.text,
        jobTitle: _titleController.text,
        jobLocation: _jobLocationController.text,
        employmentType: _employmentType,
        description: _descriptionController.text,
        status: 'published',
        workplaceType: _workplaceType,
        salaryMin: _salaryAmount(_salaryMinController.text),
        salaryMax: _salaryAmount(_salaryMaxController.text),
        salaryCurrency: _salaryCurrency,
        salaryPeriod: _salaryPeriod,
        responsibilities: _lineItems(_responsibilitiesController.text),
        requirements: _lineItems(_requirementsController.text),
        benefits: _lineItems(_benefitsController.text),
        skills: _commaItems(_skillsController.text),
      );
      if (!mounted) return;
      _titleController.clear();
      _jobLocationController.clear();
      _descriptionController.clear();
      _responsibilitiesController.clear();
      _requirementsController.clear();
      _benefitsController.clear();
      _skillsController.clear();
      _salaryMinController.clear();
      _salaryMaxController.clear();
      ref.read(jobCatalogProvider.notifier).refresh();
      setState(() {
        _showPostForm = false;
        _jobsFuture = service.fetchEmployerJobs();
        _applicationsFuture = service.fetchEmployerApplications();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job post published.')));
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not publish job: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(String id, String status) async {
    final service = _service;
    if (service == null) {
      final nextStatus = ApplicationStatus.values.firstWhere(
        (value) => value.name == status,
      );
      ref.read(applicationsProvider.notifier).updateStatus(id, nextStatus);
      return;
    }
    try {
      await service.updateApplicationStatus(applicationId: id, status: status);
      setState(() {
        _applicationsFuture = service.fetchEmployerApplications();
      });
    } on Exception catch (error) {
      setState(() => _error = 'Could not update application status: $error');
    }
  }

  Future<void> _openResume(String path) async {
    final service = _service;
    if (service == null) return;
    try {
      final url = await service.createResumeUrl(path);
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        setState(() => _error = 'No app could open the resume link.');
      }
    } on Exception catch (error) {
      setState(() => _error = 'Could not securely open this resume: $error');
    }
  }

  Future<void> _messageApplicant(String applicationId) async {
    final service = _service;
    if (service == null) return;
    try {
      final conversationId = await service.getOrCreateApplicationConversation(
        applicationId,
      );
      if (mounted) context.push('/messages/$conversationId');
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not open applicant chat: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseClientProvider);
    final user = client?.auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.xs,
            AppSpacing.screenGutter,
            AppSpacing.xxl,
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
                    'Employer workspace',
                    style: AppTypography.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (client != null && user == null)
              Column(
                children: [
                  const EmptyState(
                    title: 'Sign in as an employer',
                    message:
                        'Create an employer account or sign in to post roles and review applicants.',
                  ),
                  PrimaryButton(
                    label: 'Sign in or create account',
                    onPressed: () => context.go('/auth'),
                  ),
                ],
              )
            else if (client != null && _checkingAccess)
              const Center(child: CircularProgressIndicator())
            else if (client != null && !_hasEmployerAccess)
              const EmptyState(
                title: 'Employer account required',
                message:
                    'Sign out and create an employer account to post jobs and review applicants.',
              )
            else ...[
              if (client == null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    'Employer demo · Posts and applications stay on this device session. Connect Supabase later to publish for everyone.',
                    style: AppTypography.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              PrimaryButton(
                label: _showPostForm ? 'Cancel new post' : 'Add a job post',
                leading: Icon(
                  _showPostForm ? Icons.close_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _showPostForm = !_showPostForm;
                        _error = null;
                      }),
              ),
              if (_showPostForm) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Create a job post',
                  style: AppTypography.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Give candidates the details they need to decide whether to apply.',
                  style: AppTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _input(
                        _companyController,
                        'Company name',
                        maxLength: 120,
                        validator: (value) =>
                            _required(value, minLength: 2, maxLength: 120),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _companyLocationController,
                        'Company location',
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _industryController,
                        'Company industry (optional)',
                        maxLength: 120,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Role details',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _titleController,
                        'Job title',
                        maxLength: 160,
                        validator: (value) =>
                            _required(value, minLength: 3, maxLength: 160),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _jobLocationController,
                        'Location (city, region or country)',
                        validator: _required,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _workplaceType,
                        decoration: const InputDecoration(
                          labelText: 'Work arrangement',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'On-site',
                            child: Text('On-site'),
                          ),
                          DropdownMenuItem(
                            value: 'Hybrid',
                            child: Text('Hybrid'),
                          ),
                          DropdownMenuItem(
                            value: 'Remote',
                            child: Text('Remote'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _workplaceType = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _employmentType,
                        decoration: const InputDecoration(
                          labelText: 'Employment type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Full-time',
                            child: Text('Full-time'),
                          ),
                          DropdownMenuItem(
                            value: 'Part-time',
                            child: Text('Part-time'),
                          ),
                          DropdownMenuItem(
                            value: 'Contract',
                            child: Text('Contract'),
                          ),
                          DropdownMenuItem(
                            value: 'Temporary',
                            child: Text('Temporary'),
                          ),
                          DropdownMenuItem(
                            value: 'Internship',
                            child: Text('Internship'),
                          ),
                          DropdownMenuItem(
                            value: 'Freelance',
                            child: Text('Freelance'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _employmentType = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Annual or monthly salary (optional)',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Providing a range helps candidates understand the offer.',
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _salaryCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _salaryCurrency = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _salaryPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Pay period',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'year',
                            child: Text('Per year'),
                          ),
                          DropdownMenuItem(
                            value: 'month',
                            child: Text('Per month'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _salaryPeriod = value);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _input(
                              _salaryMinController,
                              'Minimum',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) => _salaryValidator(
                                value,
                                otherValue: _salaryMaxController.text,
                                isMinimum: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _input(
                              _salaryMaxController,
                              'Maximum',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) => _salaryValidator(
                                value,
                                otherValue: _salaryMinController.text,
                                isMinimum: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'What the role involves',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _descriptionController,
                        'Job summary',
                        maxLines: 5,
                        maxLength: 12000,
                        validator: (value) =>
                            _required(value, minLength: 20, maxLength: 12000),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _responsibilitiesController,
                        'Key responsibilities (one per line)',
                        maxLines: 4,
                        maxLength: 4000,
                        validator: (value) => _listValidator(
                          value,
                          minLength: 10,
                          label: 'responsibilities',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _requirementsController,
                        'Requirements / qualifications (one per line)',
                        maxLines: 4,
                        maxLength: 4000,
                        validator: (value) => _listValidator(
                          value,
                          minLength: 10,
                          label: 'requirements',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _skillsController,
                        'Required skills (comma separated)',
                        maxLength: 1000,
                        validator: (value) => _listValidator(
                          value,
                          minLength: 2,
                          label: 'skills',
                          commaSeparated: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _input(
                        _benefitsController,
                        'Benefits (optional, one per line)',
                        maxLines: 3,
                        maxLength: 4000,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: _loading ? 'Publishing...' : 'Publish job',
                          disabled: _loading,
                          onPressed: _loading ? null : _postJob,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.textTheme.bodyMedium!.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text('Your jobs', style: AppTypography.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              _jobs(),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedJobId == null
                          ? 'Applicants'
                          : 'Applicants for selected job',
                      style: AppTypography.textTheme.headlineMedium,
                    ),
                  ),
                  if (_selectedJobId != null)
                    TextButton(
                      onPressed: () => setState(() => _selectedJobId = null),
                      child: const Text('Show all'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _applications(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _jobs() {
    if (_service == null) {
      final catalog = ref.watch(jobCatalogProvider);
      final ownedJobIds = ref.watch(demoEmployerJobIdsProvider);
      final ownJobs = catalog.jobs
          .where((job) => ownedJobIds.contains(job.id))
          .toList();
      if (ownJobs.isEmpty) return const Text('No jobs posted yet.');
      return Column(
        children: [
          for (final job in ownJobs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.work_outline_rounded,
                color: AppColors.brand500,
              ),
              title: Text(
                job.title,
                style: AppTypography.textTheme.titleMedium,
              ),
              subtitle: Text('${job.location} · Published · Local demo'),
              trailing: TextButton(
                onPressed: () => setState(
                  () =>
                      _selectedJobId = _selectedJobId == job.id ? null : job.id,
                ),
                child: Text(
                  _selectedJobId == job.id ? 'Selected' : 'Review applicants',
                ),
              ),
            ),
        ],
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _jobsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorText(snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Text('No jobs posted yet.');
        }
        return Column(
          children: [
            for (final job in snapshot.data!)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  job['title'] as String,
                  style: AppTypography.textTheme.titleMedium,
                ),
                subtitle: Text('${job['location']} · ${job['status']}'),
                trailing: TextButton(
                  onPressed: () => setState(
                    () => _selectedJobId = _selectedJobId == job['id']
                        ? null
                        : job['id'] as String,
                  ),
                  child: Text(
                    _selectedJobId == job['id']
                        ? 'Selected'
                        : 'Review applicants',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _applications() {
    if (_service == null) {
      final ownedJobIds = ref.watch(demoEmployerJobIdsProvider);
      final catalog = ref.watch(jobCatalogProvider);
      final applications = ref
          .watch(applicationsProvider)
          .where(
            (application) =>
                ownedJobIds.contains(application.jobId) &&
                (_selectedJobId == null || application.jobId == _selectedJobId),
          )
          .toList();
      if (applications.isEmpty) {
        return const Text('No applications received yet.');
      }
      return Column(
        children: [
          for (final application in applications)
            _demoApplicationCard(
              application,
              catalog.jobs.firstWhere((job) => job.id == application.jobId),
            ),
        ],
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _applicationsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorText(snapshot.error!);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final applications = snapshot.data!.where((application) {
          if (_selectedJobId == null) return true;
          final job = application['jobs'] as Map<String, dynamic>?;
          return job?['id'] == _selectedJobId;
        }).toList();
        if (applications.isEmpty) {
          return const Text('No applications received yet.');
        }
        return Column(
          children: [
            for (final application in applications)
              _applicationCard(application),
          ],
        );
      },
    );
  }

  Widget _demoApplicationCard(ApplicationModel application, Job job) {
    final status = application.status.name;
    final statusTone = switch (application.status) {
      ApplicationStatus.applied => StatusTagTone.brand,
      ApplicationStatus.interview => StatusTagTone.orange,
      ApplicationStatus.offer => StatusTagTone.success,
      ApplicationStatus.accepted => StatusTagTone.success,
      ApplicationStatus.rejected ||
      ApplicationStatus.withdrawn => StatusTagTone.neutral,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            application.applicantName,
            style: AppTypography.textTheme.titleMedium,
          ),
          if (application.applicantEmail.isNotEmpty)
            Text(
              application.applicantEmail,
              style: AppTypography.textTheme.labelMedium,
            ),
          Text(job.title, style: AppTypography.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          StatusTag(
            label: status == 'accepted'
                ? 'Offer accepted'
                : status[0].toUpperCase() + status.substring(1),
            tone: statusTone,
          ),
          if (application.coverLetter.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              application.coverLetter,
              style: AppTypography.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          if (application.status == ApplicationStatus.interview ||
              application.status == ApplicationStatus.offer ||
              application.status == ApplicationStatus.accepted)
            TextButton.icon(
              onPressed: () => context.push('/messages/demo-${job.id}'),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Message applicant'),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            application.resumeName.isEmpty
                ? 'No resume attached in offline demo.'
                : 'Selected resume: ${application.resumeName} (not uploaded)',
            style: AppTypography.textTheme.labelMedium,
          ),
          if (status == 'offer')
            Text(
              'Offer sent · waiting for the applicant to respond.',
              style: AppTypography.textTheme.labelMedium,
            ),
          if (status == 'accepted')
            Text(
              'Offer accepted · hiring complete.',
              style: AppTypography.textTheme.labelMedium,
            ),
          if (status == 'applied' ||
              status == 'interview' ||
              status == 'offer') ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final nextStatus in switch (status) {
                  'applied' => const ['interview', 'rejected'],
                  'interview' => const ['offer', 'rejected'],
                  _ => const <String>[],
                })
                  AppChip(
                    label:
                        nextStatus[0].toUpperCase() + nextStatus.substring(1),
                    soft: true,
                    onTap: () => _changeStatus(application.jobId, nextStatus),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _applicationCard(Map<String, dynamic> application) {
    final profile = application['profiles'] as Map<String, dynamic>?;
    final job = application['jobs'] as Map<String, dynamic>?;
    final name = (profile?['full_name'] as String?) ?? 'Applicant';
    final status = application['status'] as String;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTypography.textTheme.titleMedium),
          Text(
            job?['title'] as String? ?? 'Job',
            style: AppTypography.textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          StatusTag(
            label: status == 'accepted'
                ? 'Offer accepted'
                : status[0].toUpperCase() + status.substring(1),
          ),
          if ((application['cover_letter'] as String?)?.isNotEmpty ??
              false) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              application['cover_letter'] as String,
              style: AppTypography.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (status == 'interview' ||
                  status == 'offer' ||
                  status == 'accepted')
                TextButton.icon(
                  onPressed: () =>
                      _messageApplicant(application['id'] as String),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message applicant'),
                ),
              AppChip(
                label: 'Resume',
                leading: const Icon(Icons.description_rounded, size: 16),
                onTap: () => _openResume(application['resume_path'] as String),
              ),
              if (status == 'offer')
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Text('Offer sent · awaiting applicant response.'),
                ),
              if (status == 'applied' || status == 'interview')
                for (final nextStatus
                    in status == 'applied'
                        ? const ['interview', 'rejected']
                        : const ['offer', 'rejected'])
                  AppChip(
                    label:
                        nextStatus[0].toUpperCase() + nextStatus.substring(1),
                    soft: true,
                    onTap: () =>
                        _changeStatus(application['id'] as String, nextStatus),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorText(Object error) => Text(
    'Could not load data: $error',
    style: AppTypography.textTheme.bodyMedium!.copyWith(
      color: AppColors.danger,
    ),
  );

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLength,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );

  String? _required(String? value, {int minLength = 1, int? maxLength}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'This field is required.';
    if (trimmed.length < minLength) {
      return 'Enter at least $minLength characters.';
    }
    if (maxLength != null && trimmed.length > maxLength) {
      return 'Use no more than $maxLength characters.';
    }
    return null;
  }

  String? _salaryValidator(
    String? value, {
    required String otherValue,
    required bool isMinimum,
  }) {
    final amount = _salaryAmount(value ?? '');
    final otherAmount = _salaryAmount(otherValue);
    if ((value == null || value.isEmpty) && otherValue.trim().isNotEmpty) {
      return 'Enter both salary amounts.';
    }
    if (value == null || value.isEmpty) return null;
    if (amount == null || amount > 2147483647) {
      return 'Enter a valid salary amount.';
    }
    if (!isMinimum && otherAmount != null && amount < otherAmount) {
      return 'Maximum must be at least the minimum.';
    }
    return null;
  }

  String? _listValidator(
    String? value, {
    required int minLength,
    required String label,
    bool commaSeparated = false,
  }) {
    final items = commaSeparated
        ? _commaItems(value ?? '')
        : _lineItems(value ?? '');
    if (items.isEmpty) return 'Add at least one $label.';
    if (items.any((item) => item.length < minLength)) {
      return 'Each $label entry needs at least $minLength characters.';
    }
    return null;
  }

  List<String> _lineItems(String value) => value
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<String> _commaItems(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  int? _salaryAmount(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }
}
