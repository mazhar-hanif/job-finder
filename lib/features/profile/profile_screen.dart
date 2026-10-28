import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/navigation_helpers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/outline_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_tag.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/application.dart';
import '../../providers/job_providers.dart';

/// User profile overview and account settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _role;
  String? _profileError;
  Future<List<Map<String, dynamic>>>? _applicationsFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final service = ref.read(supabaseJobServiceProvider);
    final user = service?.client.auth.currentUser;
    if (service == null) {
      _role = 'applicant';
      return;
    }
    if (user == null) return;
    _applicationsFuture = service.fetchApplicantApplications();
    try {
      final profile = await service.fetchMyProfile();
      final avatarPath = profile['avatar_path'] as String?;
      final avatarUrl = avatarPath == null || avatarPath.isEmpty
          ? null
          : await service.createAvatarUrl(avatarPath);
      ref
          .read(profileDetailsProvider.notifier)
          .update(
            fullName: (profile['full_name'] as String?) ?? '',
            headline: (profile['headline'] as String?) ?? '',
            phone: (profile['phone'] as String?) ?? '',
            location: (profile['location'] as String?) ?? '',
            skills: (profile['skills'] as List<dynamic>? ?? const [])
                .cast<String>(),
            experienceSummary: (profile['experience_summary'] as String?) ?? '',
            yearsExperience:
                (profile['years_experience'] as int?)?.toString() ?? '',
            preferredJobTypes:
                (profile['preferred_job_types'] as List<dynamic>? ?? const [])
                    .cast<String>(),
            avatarPath: avatarPath,
            avatarUrl: avatarUrl,
          );
      if (mounted) {
        setState(() {
          _role = profile['role'] as String?;
          _profileError = null;
        });
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _profileError = '$error');
    }
  }

  ImageProvider? _profileImage(ProfileDetails profile) {
    final bytes = profile.avatarBytes;
    if (bytes != null) return MemoryImage(bytes);
    final url = profile.avatarUrl;
    return url == null ? null : NetworkImage(url);
  }

  Future<void> _pickProfilePhoto() async {
    final client = ref.read(supabaseClientProvider);
    if (client != null && client.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to add a profile photo.')),
      );
      return;
    }
    try {
      final selection = await FilePicker.pickFiles(type: FileType.image);
      if (selection.isEmpty || !mounted) return;
      final file = selection.first;
      final extension = file.extension?.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        throw const FormatException('Choose a JPG, PNG, or WebP image.');
      }
      final fileSize = await file.length();
      if (fileSize != null && fileSize > 5 * 1024 * 1024) {
        throw const FormatException('Profile photos must be 5 MB or smaller.');
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        throw const FormatException('Could not read the selected image.');
      }
      if (bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Profile photos must be 5 MB or smaller.');
      }
      final service = ref.read(supabaseJobServiceProvider);
      if (service == null) {
        ref.read(profileDetailsProvider.notifier).update(avatarBytes: bytes);
      } else {
        final path = await service.uploadProfileAvatar(
          fileName: file.name,
          bytes: bytes,
        );
        final url = await service.createAvatarUrl(path);
        ref
            .read(profileDetailsProvider.notifier)
            .update(avatarPath: path, avatarUrl: url, avatarBytes: bytes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service == null
                  ? 'Profile photo updated for this demo session.'
                  : 'Profile photo updated.',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile photo: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(applicationsProvider);
    final client = ref.watch(supabaseClientProvider);
    final user = client?.auth.currentUser;
    final profile = ref.watch(profileDetailsProvider);
    final displayName = user == null
        ? (client == null ? profile.fullName : 'Guest')
        : _role == null
        ? (user.userMetadata?['full_name'] as String? ?? 'Loading profile…')
        : (profile.fullName.isEmpty ? 'Your name' : profile.fullName);
    final email =
        user?.email ??
        (client == null
            ? 'alex.carter@email.com'
            : 'Sign in to manage your account');
    final role = _role;
    final interviews = applications
        .where((item) => item.status.name == 'interview')
        .length;
    final offers = applications
        .where(
          (item) =>
              item.status == ApplicationStatus.offer ||
              item.status == ApplicationStatus.accepted,
        )
        .length;

    return Scaffold(
      body: SafeArea(
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
                IconCircleButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  onPressed: () => goBackOrHome(context),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'My profile',
                  style: AppTypography.textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      initials: _initials(displayName),
                      size: AppSpacing.profileAvatarSize,
                      imageProvider: _profileImage(profile),
                    ),
                    Positioned(
                      right: -AppSpacing.xs,
                      bottom: -AppSpacing.md,
                      child: Semantics(
                        button: true,
                        label: 'Choose profile photo',
                        child: Tooltip(
                          message: 'Choose profile photo',
                          child: Material(
                            color: Colors.transparent,
                            child: InkResponse(
                              onTap: _pickProfilePhoto,
                              radius: AppSpacing.profileAvatarActionSize / 2,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: AppSpacing.profileAvatarActionSize,
                                height: AppSpacing.profileAvatarActionSize,
                                child: Center(
                                  child: Container(
                                    width: AppSpacing
                                        .profileAvatarActionVisualSize,
                                    height: AppSpacing
                                        .profileAvatarActionVisualSize,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.surface,
                                        width: AppSpacing
                                            .profileAvatarActionBorderWidth,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.cardShadow,
                                          blurRadius: AppSpacing.shadowBlur,
                                          offset: Offset(
                                            0,
                                            AppSpacing.shadowOffsetY / 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: AppColors.surface,
                                      size: AppSpacing
                                          .profileAvatarActionIconSize,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.textTheme.headlineMedium,
                      ),
                      Text(email, style: AppTypography.textTheme.labelMedium),
                      if (client == null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        const StatusTag(label: 'Demo profile'),
                      ],
                    ],
                  ),
                ),
                if (user != null || client == null)
                  IconCircleButton(
                    icon: Icons.edit_rounded,
                    semanticLabel: 'Edit personal information',
                    onPressed: () => _editPersonalInformation(
                      initialName: displayName == 'Guest' ? '' : displayName,
                      email: email,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileOverviewCard(profile: profile),
            const SizedBox(height: AppSpacing.xl),
            if (client == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: OutlineButton(
                  label: 'Employer workspace',
                  leading: const Icon(
                    Icons.business_center_rounded,
                    color: AppColors.brand500,
                  ),
                  onPressed: () => context.go('/employer'),
                ),
              ),
            if (role == 'employer') ...[
              ListTile(
                leading: const Icon(Icons.business_center_rounded),
                title: const Text('Employer workspace'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go('/employer'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (client != null && user == null)
              PrimaryButton(
                label: 'Sign in or create account',
                onPressed: () => context.go('/auth'),
              )
            else if (client != null && user != null && role == 'applicant')
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _applicationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Could not load your application stats: ${snapshot.error}',
                      style: AppTypography.textTheme.bodyMedium!.copyWith(
                        color: AppColors.danger,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final records = snapshot.data!;
                  return _StatsCard(
                    applied: records.length,
                    interviews: records
                        .where((item) => item['status'] == 'interview')
                        .length,
                    offers: records
                        .where(
                          (item) =>
                              item['status'] == 'offer' ||
                              item['status'] == 'accepted',
                        )
                        .length,
                  );
                },
              )
            else if (client == null)
              _StatsCard(
                applied: applications.length,
                interviews: interviews,
                offers: offers,
              ),
            if (client == null || user != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _MenuCard(
                rows: [
                  _MenuRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    subtitle: profile.location.isEmpty
                        ? 'Add your title, location, and contact details'
                        : '${profile.headline.isEmpty ? 'Profile details' : profile.headline} · ${profile.location}',
                    onTap: () => _editPersonalInformation(
                      initialName: displayName,
                      email: email,
                    ),
                  ),
                  if (role != 'employer') ...[
                    _MenuRow(
                      icon: Icons.description_rounded,
                      title: 'My Resume',
                      subtitle: 'View resumes attached to your applications',
                      onTap: _showResumes,
                    ),
                    _MenuRow(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Skills & Experience',
                      subtitle: profile.skills.isEmpty
                          ? 'Add skills, experience, and career history'
                          : '${profile.skills.length} skills · ${profile.yearsExperience.isEmpty ? 'Experience summary' : '${profile.yearsExperience} years experience'}',
                      onTap: _editSkillsAndExperience,
                    ),
                    _MenuRow(
                      icon: Icons.tune_rounded,
                      title: 'Career Preferences',
                      subtitle: profile.preferredJobTypes.isEmpty
                          ? 'Choose preferred job types'
                          : profile.preferredJobTypes.join(', '),
                      onTap: _editCareerPreferences,
                    ),
                  ],
                  _MenuRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ],
            if (_profileError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Could not load profile: $_profileError',
                style: AppTypography.textTheme.bodyMedium!.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () async {
                try {
                  if (client != null && user != null) {
                    await client.auth.signOut();
                  }
                  if (context.mounted) {
                    context.go(client == null ? '/onboarding' : '/auth');
                  }
                } on Exception catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not sign out: $error')),
                    );
                  }
                }
              },
              icon: Icon(
                client != null && user == null
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                color: client != null && user == null
                    ? AppColors.brand500
                    : AppColors.danger,
              ),
              label: Text(
                client != null && user == null ? 'Sign in' : 'Log out',
                style: AppTypography.textTheme.labelLarge!.copyWith(
                  color: client != null && user == null
                      ? AppColors.brand500
                      : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPersonalInformation({
    required String initialName,
    required String email,
  }) async {
    final profile = ref.read(profileDetailsProvider);
    var editedName = initialName;
    var headline = profile.headline;
    var phone = profile.phone;
    var location = profile.location;
    var invalidName = false;
    final result = await showDialog<(String, String, String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Personal information'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: initialName,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => editedName = value,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  errorText: invalidName
                      ? 'Enter at least 2 characters.'
                      : null,
                ),
              ),
              TextFormField(
                initialValue: profile.headline,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => headline = value,
                decoration: const InputDecoration(
                  labelText: 'Professional title',
                  hintText: 'e.g. Product Designer',
                ),
              ),
              TextFormField(
                initialValue: profile.phone,
                maxLength: 30,
                keyboardType: TextInputType.phone,
                onChanged: (value) => phone = value,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: 'Add a contact number',
                ),
              ),
              TextFormField(
                initialValue: profile.location,
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => location = value,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'City, country',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Email: $email'),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Email changes require account verification.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = editedName.trim();
                if (value.length < 2) {
                  setDialogState(() => invalidName = true);
                  return;
                }
                Navigator.pop(dialogContext, (
                  value,
                  headline.trim(),
                  phone.trim(),
                  location.trim(),
                ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    await _saveProfile(
      fullName: result.$1,
      headline: result.$2,
      phone: result.$3,
      location: result.$4,
      skills: profile.skills,
      experienceSummary: profile.experienceSummary,
      yearsExperience: profile.yearsExperience,
      preferredJobTypes: profile.preferredJobTypes,
    );
  }

  Future<void> _editSkillsAndExperience() async {
    final profile = ref.read(profileDetailsProvider);
    var skillsText = profile.skills.join(', ');
    var experienceText = profile.experienceSummary;
    var yearsText = profile.yearsExperience;
    var invalidYears = false;
    final result = await showDialog<(List<String>, String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Skills & experience'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: skillsText,
                maxLength: 1000,
                onChanged: (value) => skillsText = value,
                decoration: const InputDecoration(
                  labelText: 'Skills',
                  hintText: 'Flutter, Dart, Communication',
                  helperText: 'Separate each skill with a comma.',
                ),
              ),
              TextFormField(
                initialValue: yearsText,
                maxLength: 2,
                keyboardType: TextInputType.number,
                onChanged: (value) => yearsText = value,
                decoration: InputDecoration(
                  labelText: 'Years of experience',
                  hintText: '0',
                  errorText: invalidYears
                      ? 'Enter a number from 0 to 80.'
                      : null,
                ),
              ),
              TextFormField(
                initialValue: experienceText,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => experienceText = value,
                decoration: const InputDecoration(
                  labelText: 'Experience summary',
                  hintText: 'Share your roles, achievements, and strengths.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final years = yearsText.trim();
                final parsedYears = int.tryParse(years);
                if (years.isNotEmpty &&
                    (parsedYears == null ||
                        parsedYears < 0 ||
                        parsedYears > 80)) {
                  setDialogState(() => invalidYears = true);
                  return;
                }
                Navigator.pop(dialogContext, (
                  _commaItems(skillsText),
                  experienceText.trim(),
                  years,
                ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    await _saveProfile(
      fullName: profile.fullName,
      headline: profile.headline,
      phone: profile.phone,
      location: profile.location,
      skills: result.$1,
      experienceSummary: result.$2,
      yearsExperience: result.$3,
      preferredJobTypes: profile.preferredJobTypes,
    );
  }

  Future<void> _editCareerPreferences() async {
    final profile = ref.read(profileDetailsProvider);
    final choices = <String>{...profile.preferredJobTypes};
    const options = [
      'Full-time',
      'Part-time',
      'Contract',
      'Temporary',
      'Internship',
      'Freelance',
    ];
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Career preferences'),
          content: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option),
                  selected: choices.contains(option),
                  onSelected: (value) => setDialogState(() {
                    if (value) {
                      choices.add(option);
                    } else {
                      choices.remove(option);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, choices.toList()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _saveProfile(
      fullName: profile.fullName,
      headline: profile.headline,
      phone: profile.phone,
      location: profile.location,
      skills: profile.skills,
      experienceSummary: profile.experienceSummary,
      yearsExperience: profile.yearsExperience,
      preferredJobTypes: selected,
    );
  }

  Future<void> _saveProfile({
    required String fullName,
    required String headline,
    required String phone,
    required String location,
    required List<String> skills,
    required String experienceSummary,
    required String yearsExperience,
    required List<String> preferredJobTypes,
  }) async {
    final service = ref.read(supabaseJobServiceProvider);
    try {
      if (service != null && service.client.auth.currentUser != null) {
        await service.updateMyProfile(
          fullName: fullName,
          headline: headline,
          phone: phone,
          location: location,
          skills: skills,
          experienceSummary: experienceSummary,
          yearsExperience: yearsExperience,
          preferredJobTypes: preferredJobTypes,
        );
      }
      ref
          .read(profileDetailsProvider.notifier)
          .update(
            fullName: fullName,
            headline: headline,
            phone: phone,
            location: location,
            skills: skills,
            experienceSummary: experienceSummary,
            yearsExperience: yearsExperience,
            preferredJobTypes: preferredJobTypes,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service == null
                  ? 'Profile updated for this demo session.'
                  : 'Profile updated.',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile: $error')),
        );
      }
    }
  }

  Future<void> _showResumes() async {
    final service = ref.read(supabaseJobServiceProvider);
    if (service == null) {
      final resumes = ref
          .read(applicationsProvider)
          .where((application) => application.resumeName.isNotEmpty)
          .toList();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('My resumes'),
          content: resumes.isEmpty
              ? const Text(
                  'No resume selected yet. Attach a PDF, DOC, or DOCX when you apply for a job.',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final application in resumes)
                      _ResumeRecordCard(
                        title: application.resumeName,
                        subtitle: 'Attached to a demo application',
                        localOnly: true,
                      ),
                    if (resumes.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Demo files stay on this device and are not shared.',
                          style: AppTypography.textTheme.labelMedium,
                        ),
                      ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (resumes.isEmpty)
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
                child: const Text('Browse jobs'),
              ),
          ],
        ),
      );
      return;
    }
    try {
      final resumes = await service.fetchMyResumes();
      if (!mounted) return;
      if (resumes.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('My resumes'),
            content: const Text(
              'Your resumes appear here after you attach one to a job application.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
                child: const Text('Browse jobs'),
              ),
            ],
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('My resumes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${resumes.length} resume${resumes.length == 1 ? '' : 's'} '
                  'attached to your applications',
                  style: AppTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final resume in resumes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _ResumeRecordCard(
                      title:
                          ((resume['jobs'] as Map<String, dynamic>?)?['title']
                              as String?) ??
                          'Job application resume',
                      subtitle:
                          'Added ${(resume['created_at'] as String?)?.split('T').first ?? 'date unavailable'}',
                      onOpen: () =>
                          _openResume(resume['resume_path'] as String),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load resumes: $error')),
        );
      }
    }
  }

  Future<void> _openResume(String path) async {
    final service = ref.read(supabaseJobServiceProvider);
    if (service == null) return;
    try {
      final url = await service.createResumeUrl(path);
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app could open this resume.')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open resume: $error')),
        );
      }
    }
  }

  List<String> _commaItems(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'JF';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ResumeRecordCard extends StatelessWidget {
  const _ResumeRecordCard({
    required this.title,
    required this.subtitle,
    this.onOpen,
    this.localOnly = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onOpen;
  final bool localOnly;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
            Icons.description_rounded,
            color: AppColors.brand500,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.titleMedium,
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.labelMedium,
              ),
              if (localOnly) ...[
                const SizedBox(height: AppSpacing.xxs),
                const StatusTag(label: 'Demo only'),
              ],
            ],
          ),
        ),
        if (onOpen != null)
          IconButton(
            tooltip: 'Open resume',
            onPressed: onOpen,
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.brand500,
            ),
          ),
      ],
    ),
  );
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      boxShadow: const [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: AppSpacing.shadowBlur,
          offset: Offset(0, AppSpacing.shadowOffsetY),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile highlights', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          profile.headline.isEmpty
              ? 'Add a professional title to introduce yourself.'
              : profile.headline,
          style: AppTypography.textTheme.bodyMedium,
        ),
        if (profile.location.isNotEmpty || profile.phone.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (profile.location.isNotEmpty)
                _ProfileDetail(
                  icon: Icons.location_on_rounded,
                  label: profile.location,
                ),
              if (profile.phone.isNotEmpty)
                _ProfileDetail(icon: Icons.phone_rounded, label: profile.phone),
            ],
          ),
        ],
        if (profile.skills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final skill in profile.skills.take(6))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    skill,
                    style: AppTypography.textTheme.labelMedium!.copyWith(
                      color: AppColors.brand600,
                    ),
                  ),
                ),
              if (profile.skills.length > 6)
                Text(
                  '+${profile.skills.length - 6} more',
                  style: AppTypography.textTheme.labelMedium,
                ),
            ],
          ),
        ],
        if (profile.experienceSummary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.experienceSummary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.bodyMedium,
          ),
        ],
      ],
    ),
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: AppSpacing.profileDetailIconSize,
        color: AppColors.muted,
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(child: Text(label, style: AppTypography.textTheme.labelMedium)),
    ],
  );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.applied,
    required this.interviews,
    required this.offers,
  });

  final int applied;
  final int interviews;
  final int offers;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Row(
      children: [
        _Stat(label: 'Jobs Applied', count: applied),
        const _VerticalDivider(),
        _Stat(label: 'Interviews', count: interviews),
        const _VerticalDivider(),
        _Stat(label: 'Offers', count: offers),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          '$count',
          style: AppTypography.textTheme.headlineMedium!.copyWith(
            color: AppColors.brand500,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.textTheme.labelMedium,
        ),
      ],
    ),
  );
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 38, width: 1, color: AppColors.divider);
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.rows});

  final List<_MenuRow> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Material(
            color: AppColors.surface,
            child: InkWell(
              onTap: rows[index].onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brand50,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Icon(
                        rows[index].icon,
                        color: AppColors.brand500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rows[index].title,
                            style: AppTypography.textTheme.titleMedium,
                          ),
                          if (rows[index].subtitle != null)
                            Text(
                              rows[index].subtitle!,
                              style: AppTypography.textTheme.labelMedium,
                            ),
                        ],
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
          if (index != rows.length - 1)
            const Divider(height: 1, indent: 68, endIndent: AppSpacing.md),
        ],
      ],
    ),
  );
}

class _MenuRow {
  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
}
