class DemoChatMessage {
  const DemoChatMessage({
    required this.body,
    required this.senderRole,
    required this.sentAt,
  });

  final String body;
  final DemoChatRole senderRole;
  final DateTime sentAt;
}

enum DemoChatRole { applicant, employer }

class DemoConversation {
  const DemoConversation({required this.jobId, required this.messages});

  final String jobId;
  final List<DemoChatMessage> messages;
}
