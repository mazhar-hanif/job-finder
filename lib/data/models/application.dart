enum ApplicationStatus {
  applied,
  interview,
  offer,
  accepted,
  rejected,
  withdrawn,
}

class ApplicationModel {
  const ApplicationModel({
    required this.jobId,
    required this.status,
    required this.appliedAgo,
    this.applicantName = 'Job seeker',
    this.applicantEmail = '',
    this.coverLetter = '',
    this.resumeName = '',
  });

  final String jobId;
  final ApplicationStatus status;
  final String appliedAgo;
  final String applicantName;
  final String applicantEmail;
  final String coverLetter;
  final String resumeName;
}
