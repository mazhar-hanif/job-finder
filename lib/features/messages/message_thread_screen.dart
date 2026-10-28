import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/application.dart';
import '../../data/models/demo_chat.dart';
import '../../data/repositories/supabase_job_service.dart';
import '../../providers/job_providers.dart';

/// A local demo conversation with a recruiter or company contact.
class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({super.key, required this.messageId});

  final String messageId;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseJobServiceProvider);
    if (service != null &&
        service.client.auth.currentUser != null &&
        widget.messageId.length > 20) {
      return _SupabaseMessageThread(
        key: ValueKey(widget.messageId),
        service: service,
        conversationId: widget.messageId,
      );
    }

    final messages = ref.watch(messagesProvider);
    final messageIndex = messages.indexWhere(
      (message) => message.id == widget.messageId,
    );
    if (messageIndex < 0) {
      final jobId = widget.messageId.startsWith('demo-')
          ? widget.messageId.substring('demo-'.length)
          : null;
      if (jobId != null) {
        final jobs = ref.watch(jobsProvider);
        final matchingJobs = jobs.where((job) => job.id == jobId);
        if (matchingJobs.isNotEmpty) {
          final job = matchingJobs.first;
          final companies = ref.watch(companiesProvider);
          final matchingCompanies = companies.where(
            (company) => company.id == job.companyId,
          );
          if (matchingCompanies.isNotEmpty) {
            return _DemoMessageThread(
              conversationKey: widget.messageId,
              title: matchingCompanies.first.name,
              subtitle: job.title,
              initialMessage: '',
            );
          }
        }
      }
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Conversation unavailable'))),
      );
    }
    final message = messages[messageIndex];
    return _DemoMessageThread(
      conversationKey: widget.messageId,
      title: message.name,
      subtitle: message.company,
      initialMessage: message.preview,
    );
  }
}

class _DemoMessageThread extends ConsumerStatefulWidget {
  const _DemoMessageThread({
    required this.conversationKey,
    required this.title,
    required this.subtitle,
    required this.initialMessage,
  });

  final String conversationKey;
  final String title;
  final String subtitle;
  final String initialMessage;

  @override
  ConsumerState<_DemoMessageThread> createState() => _DemoMessageThreadState();
}

class _DemoMessageThreadState extends ConsumerState<_DemoMessageThread> {
  final _controller = TextEditingController();
  DemoChatRole _role = DemoChatRole.applicant;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applications = ref.watch(applicationsProvider);
    final demoJobId = widget.conversationKey.startsWith('demo-')
        ? widget.conversationKey.substring('demo-'.length)
        : null;
    final matchingApplications = demoJobId == null
        ? const <ApplicationModel>[]
        : applications.where((item) => item.jobId == demoJobId).toList();
    final linkedApplication = matchingApplications.isEmpty
        ? null
        : matchingApplications.first;
    final chatAllowed =
        linkedApplication == null ||
        linkedApplication.status == ApplicationStatus.interview ||
        linkedApplication.status == ApplicationStatus.offer ||
        linkedApplication.status == ApplicationStatus.accepted;
    final conversation = ref.watch(
      demoConversationsProvider,
    )[widget.conversationKey];
    final initialMessage = widget.initialMessage.trim();
    final visibleMessages = [
      if (initialMessage.isNotEmpty) (initialMessage, DemoChatRole.employer),
      for (final item in conversation?.messages ?? const <DemoChatMessage>[])
        (item.body, item.senderRole),
    ];
    final initials = widget.title
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppSpacing.screenGutter,
        title: Row(
          children: [
            IconCircleButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            UserAvatar(initials: initials, size: 42),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.titleMedium,
                  ),
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: chatAllowed ? AppColors.goldBg : AppColors.warnBg,
              child: Text(
                chatAllowed
                    ? 'Local demo chat · Messages stay on this device. Connect Supabase for real account-to-account chat.'
                    : 'Messaging becomes available when the employer moves your application to interview.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.labelSmall!.copyWith(
                  color: chatAllowed ? AppColors.warn : AppColors.danger,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: SegmentedButton<DemoChatRole>(
                segments: const [
                  ButtonSegment(
                    value: DemoChatRole.applicant,
                    label: Text('Applicant'),
                  ),
                  ButtonSegment(
                    value: DemoChatRole.employer,
                    label: Text('Employer'),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (selection) =>
                    setState(() => _role = selection.first),
              ),
            ),
            Expanded(
              child: visibleMessages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'Start the conversation by sending a message.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        for (final item in visibleMessages.reversed)
                          _MessageBubble(
                            text: item.$1,
                            outgoing: item.$2 == _role,
                          ),
                      ],
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: chatAllowed,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 4000,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Write a message',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      tooltip: 'Send reply',
                      onPressed: chatAllowed ? _send : null,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.brand500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    ref
        .read(demoConversationsProvider.notifier)
        .send(widget.conversationKey, _role, body);
    _controller.clear();
  }
}

class _SupabaseMessageThread extends StatefulWidget {
  const _SupabaseMessageThread({
    super.key,
    required this.service,
    required this.conversationId,
  });

  final SupabaseJobService service;
  final String conversationId;

  @override
  State<_SupabaseMessageThread> createState() => _SupabaseMessageThreadState();
}

class _SupabaseMessageThreadState extends State<_SupabaseMessageThread> {
  final _controller = TextEditingController();
  late final Future<List<Map<String, dynamic>>> _conversations;
  late final Stream<List<Map<String, dynamic>>> _messages;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversations = widget.service.fetchMyConversations();
    _messages = widget.service.streamConversationMessages(
      widget.conversationId,
    );
    unawaited(_markRead());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await widget.service.markConversationRead(widget.conversationId);
    } on Exception catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not mark messages as read: $error');
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _conversations,
    builder: (context, conversationSnapshot) {
      if (conversationSnapshot.hasError) {
        return _errorScaffold(
          'Could not load conversation: ${conversationSnapshot.error}',
        );
      }
      if (!conversationSnapshot.hasData) {
        return const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        );
      }

      final conversations = conversationSnapshot.data!;
      final matching = conversations.where(
        (item) => item['conversation_id'] == widget.conversationId,
      );
      if (matching.isEmpty) {
        return _errorScaffold(
          'This conversation is unavailable or your account cannot access it.',
        );
      }
      final conversation = matching.first;
      final currentUserId = widget.service.client.auth.currentUser!.id;
      final isApplicant = conversation['applicant_id'] == currentUserId;
      final name = isApplicant
          ? conversation['company_name'] as String? ?? 'Employer'
          : conversation['applicant_name'] as String? ?? 'Applicant';
      final subtitle =
          conversation['job_title'] as String? ?? 'Job application';
      final initials = name
          .split(' ')
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0])
          .join()
          .toUpperCase();

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          titleSpacing: AppSpacing.screenGutter,
          title: Row(
            children: [
              IconCircleButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: AppSpacing.sm),
              UserAvatar(initials: initials, size: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_error != null)
                MaterialBanner(
                  content: Text(_error!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _error = null),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messages,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppSpacing.screenGutter,
                          ),
                          child: Text(
                            'Could not receive messages: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.bodyMedium!.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rows = snapshot.data!;
                    return ListView.builder(
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[rows.length - index - 1];
                        return _MessageBubble(
                          text: row['body'] as String,
                          outgoing: row['sender_id'] == currentUserId,
                        );
                      },
                    );
                  },
                ),
              ),
              _composer(),
            ],
          ),
        ),
      );
    },
  );

  Widget _composer() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Write a message',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  borderSide: const BorderSide(color: AppColors.brand500),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Send reply',
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.brand500),
          ),
        ],
      ),
    ),
  );

  Future<void> _send() async {
    if (_sending) return;
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.service.sendConversationMessage(
        conversationId: widget.conversationId,
        body: body,
      );
      if (mounted) _controller.clear();
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not send message: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _errorScaffold(String message) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenGutter),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodyMedium!.copyWith(
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.outgoing});

  final String text;
  final bool outgoing;

  @override
  Widget build(BuildContext context) => Align(
    alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.messageBubbleMaxWidth,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: outgoing ? AppColors.brand500 : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: outgoing ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.textTheme.bodyMedium!.copyWith(
          color: outgoing ? AppColors.surface : AppColors.ink2,
        ),
      ),
    ),
  );
}
