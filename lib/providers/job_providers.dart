import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_config.dart';
import '../data/models/app_notification.dart';
import '../data/models/application.dart';
import '../data/models/company.dart';
import '../data/models/demo_chat.dart';
import '../data/models/job.dart';
import '../data/models/message.dart';
import '../data/repositories/job_repository.dart';
import '../data/repositories/supabase_job_service.dart';

final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => const MockJobRepository(),
);

final supabaseClientProvider = Provider<SupabaseClient?>(
  (ref) => SupabaseConfig.clientOrNull,
);

final supabaseJobServiceProvider = Provider<SupabaseJobService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseJobService(client);
});

final jobCatalogProvider =
    NotifierProvider<JobCatalogNotifier, JobCatalogState>(
      JobCatalogNotifier.new,
    );

class JobCatalogState {
  const JobCatalogState({
    required this.jobs,
    required this.companies,
    this.loading = false,
    this.error,
  });

  final List<Job> jobs;
  final List<Company> companies;
  final bool loading;
  final String? error;
}

class JobCatalogNotifier extends Notifier<JobCatalogState> {
  Timer? _refreshTimer;
  RealtimeChannel? _jobChangesChannel;
  bool _refreshInProgress = false;
  bool _disposed = false;

  @override
  JobCatalogState build() {
    final service = ref.read(supabaseJobServiceProvider);
    if (service != null) {
      ref.onDispose(() {
        _disposed = true;
        _refreshTimer?.cancel();
        final channel = _jobChangesChannel;
        if (channel != null) {
          unawaited(service.client.removeChannel(channel));
        }
      });
      scheduleMicrotask(() {
        if (_disposed) return;
        unawaited(refresh(service));
        _startLiveUpdates(service);
      });
      return const JobCatalogState(jobs: [], companies: [], loading: true);
    }
    final repository = ref.read(jobRepositoryProvider);
    return JobCatalogState(
      jobs: repository.getJobs(),
      companies: repository.getCompanies(),
    );
  }

  Future<void> refresh([SupabaseJobService? service]) async {
    if (_disposed || _refreshInProgress) return;
    final backend = service ?? ref.read(supabaseJobServiceProvider);
    if (backend == null) return;
    _refreshInProgress = true;
    state = JobCatalogState(
      jobs: state.jobs,
      companies: state.companies,
      loading: true,
    );
    try {
      final catalog = await backend.fetchPublishedJobs();
      state = JobCatalogState(jobs: catalog.jobs, companies: catalog.companies);
    } on Exception catch (error) {
      state = JobCatalogState(
        jobs: state.jobs,
        companies: state.companies,
        error: error.toString(),
      );
    } finally {
      _refreshInProgress = false;
    }
  }

  void _startLiveUpdates(SupabaseJobService service) {
    _jobChangesChannel = service.client
        .channel('job-catalog-live')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          callback: (_) => unawaited(refresh(service)),
        )
        .subscribe((status, error) {
          if (_disposed ||
              (status != RealtimeSubscribeStatus.channelError &&
                  status != RealtimeSubscribeStatus.timedOut)) {
            return;
          }
          state = JobCatalogState(
            jobs: state.jobs,
            companies: state.companies,
            error:
                'Live job updates are unavailable; periodic refresh remains '
                'active. ${error ?? ''}',
          );
        });
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(refresh(service)),
    );
  }

  Job createDemoJob({
    required String companyName,
    required String industry,
    required String companyLocation,
    required String title,
    required String location,
    required String employmentType,
    required String description,
    required String workplaceType,
    required int? salaryMin,
    required int? salaryMax,
    required String salaryCurrency,
    required String salaryPeriod,
    required List<String> responsibilities,
    required List<String> requirements,
    required List<String> benefits,
    required List<String> skills,
  }) {
    if (ref.read(supabaseClientProvider) != null) {
      throw StateError('Demo jobs cannot be created while Supabase is active.');
    }
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final companyId = 'demo-company-$timestamp';
    final salary = salaryMin == null
        ? 'Salary not listed'
        : '$salaryCurrency ${salaryMin.toString()}${salaryMax == null ? '' : ' – ${salaryMax.toString()}'} / ${salaryPeriod == 'year' ? 'year' : 'month'}';
    final compactSalary = salaryMin == null
        ? 'Not listed'
        : '$salaryCurrency ${salaryMin.toString()}${salaryMax == null ? '' : ' – ${salaryMax.toString()}'}';
    final job = Job(
      id: 'demo-job-$timestamp',
      title: title.trim(),
      companyId: companyId,
      location: location.trim(),
      isRemote: workplaceType == 'Remote',
      type: employmentType,
      salaryLabel: salary,
      salaryShort: compactSalary,
      postedAgo: 'Just now',
      applicantsLabel: 'Open to applications',
      about: description.trim(),
      responsibilities: responsibilities,
      requirements: requirements,
      benefits: benefits,
      skills: skills,
      workplaceType: workplaceType,
      salaryCurrency: salaryCurrency,
      salaryPeriod: salaryPeriod,
    );
    final company = Company(
      id: companyId,
      name: companyName.trim(),
      tint: 0xFF2F5BFF,
      rating: 0,
      reviewsLabel: 'Demo company',
      industry: industry.trim(),
      size: '',
      location: companyLocation.trim(),
      about: 'Company profile created in the local JobFinder demo.',
      values: const [],
    );
    state = JobCatalogState(
      jobs: [job, ...state.jobs],
      companies: [company, ...state.companies],
    );
    ref.read(demoEmployerJobIdsProvider.notifier).add(job.id);
    return job;
  }
}

final jobsProvider = Provider<List<Job>>(
  (ref) => ref.watch(jobCatalogProvider).jobs,
);

final companiesProvider = Provider<List<Company>>(
  (ref) => ref.watch(jobCatalogProvider).companies,
);

final messagesProvider = Provider<List<Message>>(
  (ref) => ref.watch(jobRepositoryProvider).getMessages(),
);

final notificationsProvider = Provider<List<AppNotification>>(
  (ref) => ref.watch(jobRepositoryProvider).getNotifications(),
);

final savedJobIdsProvider = NotifierProvider<SavedJobsNotifier, Set<String>>(
  SavedJobsNotifier.new,
);

final demoEmployerJobIdsProvider =
    NotifierProvider<DemoEmployerJobsNotifier, Set<String>>(
      DemoEmployerJobsNotifier.new,
    );

final demoConversationsProvider =
    NotifierProvider<DemoConversationsNotifier, Map<String, DemoConversation>>(
      DemoConversationsNotifier.new,
    );

class DemoConversationsNotifier
    extends Notifier<Map<String, DemoConversation>> {
  @override
  Map<String, DemoConversation> build() => {};

  DemoConversation ensure(String jobId) {
    final existing = state[jobId];
    if (existing != null) return existing;
    final conversation = DemoConversation(jobId: jobId, messages: const []);
    state = {...state, jobId: conversation};
    return conversation;
  }

  void send(String jobId, DemoChatRole senderRole, String body) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) return;
    final conversation = ensure(jobId);
    state = {
      ...state,
      jobId: DemoConversation(
        jobId: jobId,
        messages: [
          ...conversation.messages,
          DemoChatMessage(
            body: trimmedBody,
            senderRole: senderRole,
            sentAt: DateTime.now(),
          ),
        ],
      ),
    };
  }
}

class DemoEmployerJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void add(String jobId) => state = {...state, jobId};
}

class SavedJobsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.read(supabaseClientProvider) == null ? {'j1', 'j2', 'j3', 'j4'} : {};

  void toggle(String jobId) {
    final next = {...state};
    if (!next.add(jobId)) next.remove(jobId);
    state = next;
  }
}

final applicationsProvider =
    NotifierProvider<ApplicationsNotifier, List<ApplicationModel>>(
      ApplicationsNotifier.new,
    );

class ApplicationsNotifier extends Notifier<List<ApplicationModel>> {
  @override
  List<ApplicationModel> build() {
    if (ref.read(supabaseClientProvider) != null) return [];
    return ref.read(jobRepositoryProvider).getApplications();
  }

  void apply(
    String jobId, {
    String applicantName = 'Job seeker',
    String applicantEmail = '',
    String coverLetter = '',
    String resumeName = '',
  }) {
    if (state.any((application) => application.jobId == jobId)) return;
    state = [
      ApplicationModel(
        jobId: jobId,
        status: ApplicationStatus.applied,
        appliedAgo: 'Just now',
        applicantName: applicantName,
        applicantEmail: applicantEmail,
        coverLetter: coverLetter.trim(),
        resumeName: resumeName,
      ),
      ...state,
    ];
  }

  void updateStatus(String jobId, ApplicationStatus status) {
    final index = state.indexWhere((item) => item.jobId == jobId);
    if (index < 0 || !_canTransitionDemoStatus(state[index].status, status)) {
      return;
    }
    state = [
      for (final application in state)
        if (application.jobId == jobId)
          ApplicationModel(
            jobId: application.jobId,
            status: status,
            appliedAgo: application.appliedAgo,
            applicantName: application.applicantName,
            applicantEmail: application.applicantEmail,
            coverLetter: application.coverLetter,
            resumeName: application.resumeName,
          )
        else
          application,
    ];
  }

  bool _canTransitionDemoStatus(
    ApplicationStatus current,
    ApplicationStatus next,
  ) => switch ((current, next)) {
    (ApplicationStatus.applied, ApplicationStatus.interview) ||
    (ApplicationStatus.applied, ApplicationStatus.rejected) ||
    (ApplicationStatus.interview, ApplicationStatus.offer) ||
    (ApplicationStatus.interview, ApplicationStatus.rejected) ||
    (ApplicationStatus.offer, ApplicationStatus.accepted) ||
    (ApplicationStatus.offer, ApplicationStatus.rejected) ||
    (ApplicationStatus.applied, ApplicationStatus.withdrawn) ||
    (ApplicationStatus.interview, ApplicationStatus.withdrawn) ||
    (ApplicationStatus.offer, ApplicationStatus.withdrawn) => true,
    _ => false,
  };
}

final followingCompanyIdsProvider =
    NotifierProvider<FollowingCompaniesNotifier, Set<String>>(
      FollowingCompaniesNotifier.new,
    );

final profileDetailsProvider =
    NotifierProvider<ProfileDetailsNotifier, ProfileDetails>(
      ProfileDetailsNotifier.new,
    );

class ProfileDetails {
  const ProfileDetails({
    this.fullName = 'Alex Carter',
    this.headline = '',
    this.phone = '',
    this.location = '',
    this.skills = const [],
    this.experienceSummary = '',
    this.yearsExperience = '',
    this.preferredJobTypes = const [],
    this.avatarPath,
    this.avatarUrl,
    this.avatarBytes,
  });

  final String fullName;
  final String headline;
  final String phone;
  final String location;
  final List<String> skills;
  final String experienceSummary;
  final String yearsExperience;
  final List<String> preferredJobTypes;
  final String? avatarPath;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
}

class ProfileDetailsNotifier extends Notifier<ProfileDetails> {
  @override
  ProfileDetails build() => const ProfileDetails();

  void update({
    String? fullName,
    String? headline,
    String? phone,
    String? location,
    List<String>? skills,
    String? experienceSummary,
    String? yearsExperience,
    List<String>? preferredJobTypes,
    String? avatarPath,
    String? avatarUrl,
    Uint8List? avatarBytes,
  }) {
    state = ProfileDetails(
      fullName: fullName ?? state.fullName,
      headline: headline ?? state.headline,
      phone: phone ?? state.phone,
      location: location ?? state.location,
      skills: skills ?? state.skills,
      experienceSummary: experienceSummary ?? state.experienceSummary,
      yearsExperience: yearsExperience ?? state.yearsExperience,
      preferredJobTypes: preferredJobTypes ?? state.preferredJobTypes,
      avatarPath: avatarPath ?? state.avatarPath,
      avatarUrl: avatarUrl ?? state.avatarUrl,
      avatarBytes: avatarBytes ?? state.avatarBytes,
    );
  }
}

class FollowingCompaniesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String companyId) {
    final next = {...state};
    if (!next.add(companyId)) next.remove(companyId);
    state = next;
  }
}

final applicationCountsProvider = Provider<Map<ApplicationStatus, int>>((ref) {
  final applications = ref.watch(applicationsProvider);
  return {
    for (final status in ApplicationStatus.values)
      status: applications.where((item) => item.status == status).length,
  };
});
