class Job {
  const Job({
    required this.id,
    required this.title,
    required this.companyId,
    required this.location,
    required this.isRemote,
    required this.type,
    required this.salaryLabel,
    required this.salaryShort,
    required this.postedAgo,
    required this.applicantsLabel,
    required this.about,
    required this.responsibilities,
    required this.requirements,
    required this.benefits,
    required this.skills,
    this.workplaceType = 'On-site',
    this.salaryCurrency = 'PKR',
    this.salaryPeriod = 'year',
  });

  final String id;
  final String title;
  final String companyId;
  final String location;
  final bool isRemote;
  final String type;
  final String salaryLabel;
  final String salaryShort;
  final String postedAgo;
  final String applicantsLabel;
  final String about;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> benefits;
  final List<String> skills;
  final String workplaceType;
  final String salaryCurrency;
  final String salaryPeriod;
}
