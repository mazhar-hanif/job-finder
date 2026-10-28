enum AppNotificationKind { application, recruiter, recommendation }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.kind,
    required this.unread,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final AppNotificationKind kind;
  final bool unread;
}
