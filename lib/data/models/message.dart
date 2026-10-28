enum MessageKind { recruiter, company }

class Message {
  const Message({
    required this.id,
    required this.name,
    required this.company,
    required this.preview,
    required this.time,
    required this.unread,
    required this.kind,
  });

  final String id;
  final String name;
  final String company;
  final String preview;
  final String time;
  final bool unread;
  final MessageKind kind;
}
