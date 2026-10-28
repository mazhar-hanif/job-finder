import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company.dart';
import '../models/job.dart';

class JobCatalog {
  const JobCatalog({required this.jobs, required this.companies});

  final List<Job> jobs;
  final List<Company> companies;
}

class SupabaseJobService {
  const SupabaseJobService(this.client);

  final SupabaseClient client;

  Future<JobCatalog> fetchPublishedJobs() async {
    final rows = await client
        .from('jobs')
        .select('*, companies(*)')
        .eq('status', 'published')
        .order('created_at', ascending: false);
    final jobs = <Job>[];
    final companies = <String, Company>{};

    for (final row in rows) {
      final companyData = row['companies'] as Map<String, dynamic>;
      final company = _companyFromRow(companyData);
      companies[company.id] = company;
      jobs.add(_jobFromRow(row, company.id));
    }

    return JobCatalog(jobs: jobs, companies: companies.values.toList());
  }

  Future<List<Map<String, dynamic>>> fetchApplicantApplications() async {
    return client
        .from('applications')
        .select('id, status, created_at, jobs(title, companies(name))')
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> fetchMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to load your profile.');
    }
    return client
        .from('profiles')
        .select(
          'full_name, role, headline, phone, location, skills, '
          'experience_summary, years_experience, preferred_job_types, avatar_path',
        )
        .eq('id', user.id)
        .single();
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String headline,
    required String phone,
    required String location,
    required List<String> skills,
    required String experienceSummary,
    required String yearsExperience,
    required List<String> preferredJobTypes,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to update your profile.');
    }
    await client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'headline': headline.trim(),
          'phone': phone.trim(),
          'location': location.trim(),
          'skills': skills,
          'experience_summary': experienceSummary.trim(),
          'years_experience': int.tryParse(yearsExperience),
          'preferred_job_types': preferredJobTypes,
        })
        .eq('id', user.id);
  }

  Future<String> uploadProfileAvatar({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in to upload a profile photo.');
    }
    final extension = fileName.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      throw const FormatException('Choose a JPG, PNG, or WebP image.');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException(
        'Profile photos must be non-empty and 5 MB or smaller.',
      );
    }
    final previousAvatarPath =
        (await client
                .from('profiles')
                .select('avatar_path')
                .eq('id', user.id)
                .single())['avatar_path']
            as String?;
    final path =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: switch (extension) {
              'jpg' || 'jpeg' => 'image/jpeg',
              'png' => 'image/png',
              'webp' => 'image/webp',
              _ => throw const FormatException(
                'Choose a JPG, PNG, or WebP image.',
              ),
            },
          ),
        );
    try {
      await client
          .from('profiles')
          .update({'avatar_path': path})
          .eq('id', user.id);
    } on Exception catch (error, stackTrace) {
      try {
        await client.storage.from('avatars').remove([path]);
      } on Exception catch (cleanupError) {
        throw StateError(
          'Profile update failed ($error); avatar cleanup failed '
          '($cleanupError).',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (previousAvatarPath != null && previousAvatarPath != path) {
      try {
        await client.storage.from('avatars').remove([previousAvatarPath]);
      } on Exception catch (error) {
        throw StateError(
          'Profile photo was updated, but the previous photo could not be '
          'removed: $error',
        );
      }
    }
    return path;
  }

  Future<String> createAvatarUrl(String path) async {
    final url = await client.storage
        .from('avatars')
        .createSignedUrl(path, 3600);
    return url;
  }

  Future<List<Map<String, dynamic>>> fetchMyResumes() async {
    return client
        .from('applications')
        .select('id, resume_path, created_at, jobs(title)')
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchEmployerApplications() async {
    return client
        .from('applications')
        .select(
          'id, status, cover_letter, resume_path, created_at, '
          'profiles!applications_applicant_id_fkey(full_name), '
          'jobs!inner(id, title, company_id)',
        )
        .order('created_at', ascending: false);
  }

  Future<void> respondToOffer({
    required String applicationId,
    required bool accept,
  }) async {
    await client.rpc(
      accept ? 'accept_application_offer' : 'decline_application_offer',
      params: {'p_application_id': applicationId},
    );
  }

  Future<void> withdrawApplication(String applicationId) async {
    await client.rpc(
      'withdraw_application',
      params: {'p_application_id': applicationId},
    );
  }

  Future<List<Map<String, dynamic>>> fetchMyConversations() async {
    final rows = await client.rpc('get_my_conversations');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> getOrCreateApplicationConversation(
    String applicationId,
  ) async {
    final conversationId = await client.rpc(
      'get_or_create_application_conversation',
      params: {'p_application_id': applicationId},
    );
    if (conversationId is! String || conversationId.isEmpty) {
      throw const FormatException(
        'The server did not return a conversation identifier.',
      );
    }
    return conversationId;
  }

  Stream<List<Map<String, dynamic>>> streamConversationMessages(
    String conversationId,
  ) => client
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at');

  Future<void> markConversationRead(String conversationId) async {
    await client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }

  Future<void> sendConversationMessage({
    required String conversationId,
    required String body,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in before sending a message.');
    }
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty || trimmedBody.length > 4000) {
      throw const FormatException(
        'Messages must contain between 1 and 4000 characters.',
      );
    }
    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'body': trimmedBody,
    });
  }

  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in as an employer to view your jobs.');
    }
    return client
        .from('jobs')
        .select(
          'id, title, location, status, created_at, companies!inner(owner_id)',
        )
        .eq('companies.owner_id', user.id)
        .order('created_at', ascending: false);
  }

  Future<String> submitApplication({
    required String jobId,
    required String fileName,
    required Uint8List fileBytes,
    required String coverLetter,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in before submitting an application.');
    }
    if (fileBytes.isEmpty) {
      throw const FormatException('The selected resume file is empty.');
    }

    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => throw const FormatException('Choose a PDF, DOC, or DOCX resume.'),
    };
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '${user.id}/$jobId/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await client.storage
        .from('resumes')
        .uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    try {
      await client.from('applications').insert({
        'job_id': jobId,
        'applicant_id': user.id,
        'resume_path': path,
        'cover_letter': coverLetter.trim(),
      });
    } on Exception catch (error, stackTrace) {
      try {
        await client.storage.from('resumes').remove([path]);
      } on Exception catch (cleanupError) {
        throw StateError(
          'Application submission failed ($error); resume cleanup failed '
          '($cleanupError).',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return path;
  }

  Future<void> createJob({
    required String companyName,
    required String industry,
    required String companyLocation,
    required String jobTitle,
    required String jobLocation,
    required String employmentType,
    required String description,
    required String status,
    required String workplaceType,
    required int? salaryMin,
    required int? salaryMax,
    required String salaryCurrency,
    required String salaryPeriod,
    required List<String> responsibilities,
    required List<String> requirements,
    required List<String> benefits,
    required List<String> skills,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in as an employer to post a job.');
    }

    final companies = await client
        .from('companies')
        .select('id')
        .eq('owner_id', user.id)
        .order('created_at')
        .limit(1);
    final companyId = companies.isEmpty
        ? (await client
              .from('companies')
              .insert({
                'owner_id': user.id,
                'name': companyName.trim(),
                'industry': industry.trim(),
                'location': companyLocation.trim(),
              })
              .select('id')
              .single())['id']
        : companies.first['id'];

    await client.from('jobs').insert({
      'company_id': companyId,
      'title': jobTitle.trim(),
      'location': jobLocation.trim(),
      'employment_type': employmentType,
      'description': description.trim(),
      'status': status,
      'workplace_type': workplaceType,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'salary_period': salaryPeriod,
      'responsibilities': responsibilities,
      'requirements': requirements,
      'benefits': benefits,
      'skills': skills,
    });
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await client.rpc(
      'set_application_status',
      params: {'p_application_id': applicationId, 'p_status': status},
    );
  }

  Future<Uri> createResumeUrl(String path) async {
    final url = await client.storage.from('resumes').createSignedUrl(path, 60);
    return Uri.parse(url);
  }

  static Company _companyFromRow(Map<String, dynamic> row) => Company(
    id: row['id'] as String,
    name: row['name'] as String,
    tint: 0xFF2F5BFF,
    rating: 0,
    reviewsLabel: 'New company',
    industry: row['industry'] as String? ?? '',
    size: '',
    location: row['location'] as String? ?? '',
    about: '',
    values: const [],
  );

  static Job _jobFromRow(Map<String, dynamic> row, String companyId) {
    final salaryMin = row['salary_min'] as int?;
    final salaryMax = row['salary_max'] as int?;
    final salary = [
      if (salaryMin != null)
        '${row['salary_currency'] as String? ?? 'PKR'} $salaryMin',
      if (salaryMax != null) '$salaryMax',
    ].join(' - ');
    final currency = row['salary_currency'] as String? ?? 'PKR';
    final period = row['salary_period'] as String? ?? 'year';
    final workplaceType = row['workplace_type'] as String? ?? 'On-site';
    final responsibilities =
        (row['responsibilities'] as List<dynamic>?)?.cast<String>() ??
        const <String>[];
    final requirements =
        (row['requirements'] as List<dynamic>?)?.cast<String>() ??
        const <String>[];
    final benefits =
        (row['benefits'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
    final skills =
        (row['skills'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
    return Job(
      id: row['id'] as String,
      title: row['title'] as String,
      companyId: companyId,
      location: row['location'] as String,
      isRemote: workplaceType == 'Remote',
      type: row['employment_type'] as String,
      salaryLabel: salary.isEmpty
          ? 'Salary not listed'
          : '$salary / ${period == 'year' ? 'year' : 'month'}',
      salaryShort: salary.isEmpty ? 'Not listed' : salary,
      postedAgo: 'New',
      applicantsLabel: 'Open to applications',
      about: row['description'] as String,
      responsibilities: responsibilities,
      requirements: requirements,
      benefits: benefits,
      skills: skills,
      workplaceType: workplaceType,
      salaryCurrency: currency,
      salaryPeriod: period,
    );
  }
}
