import '../mock/mock_data.dart';
import '../models/app_notification.dart';
import '../models/application.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/message.dart';

abstract interface class JobRepository {
  List<Job> getJobs();
  List<Company> getCompanies();
  List<ApplicationModel> getApplications();
  List<Message> getMessages();
  List<AppNotification> getNotifications();
}

class MockJobRepository implements JobRepository {
  const MockJobRepository();

  @override
  List<Job> getJobs() => MockData.jobs;

  @override
  List<Company> getCompanies() => MockData.companies;

  @override
  List<ApplicationModel> getApplications() => MockData.applications;

  @override
  List<Message> getMessages() => MockData.messages;

  @override
  List<AppNotification> getNotifications() => MockData.notifications;
}
