import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_circle_button.dart';
import '../../core/widgets/user_avatar.dart';
import '../../data/models/company.dart';
import '../../data/models/demo_chat.dart';
import '../../data/models/job.dart';
import '../../data/models/message.dart';
import '../../data/repositories/supabase_job_service.dart';
import '../../providers/job_providers.dart';

/// Inbox with recruiter and company conversation filters.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  int _filter = 0;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseJobServiceProvider);
    if (service != null) {
      if (service.client.auth.currentUser == null) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenGutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sign in to view your conversations.'),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go('/auth'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return _SupabaseInbox(service: service);
    }

    final messages = [
      ...ref.watch(messagesProvider),
      ..._demoApplicationMessages(ref),
    ];
    final unreadCount = messages.where((message) => message.unread).length;
    final visible = messages.where((message) {
      final matchesFilter = switch (_filter) {
        1 => message.kind == MessageKind.recruiter,
        2 => message.kind == MessageKind.company,
        3 => message.unread,
        _ => true,
      };
      final matchesSearch =
          _query.isEmpty ||
          '${message.name} ${message.company} ${message.preview}'
              .toLowerCase()
              .contains(_query.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.md,
            AppSpacing.screenGutter,
            AppSpacing.xxl,
          ),
          children: [
            Row(
              children: [
                IconCircleButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: AppTypography.textTheme.headlineLarge,
                      ),
                      Text(
                        unreadCount == 0
                            ? 'Your conversations'
                            : '$unreadCount unread conversations',
                        style: AppTypography.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: AppTypography.textTheme.labelSmall!.copyWith(
                        color: AppColors.brand600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSearchBar(
              controller: _searchController,
              hintText: 'Search people or companies',
              onChanged: (value) => setState(() => _query = value.trim()),
              trailing: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear message search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.muted,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  AppChip(
                    label: 'All',
                    active: _filter == 0,
                    onTap: () => setState(() => _filter = 0),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: 'Recruiters',
                    active: _filter == 1,
                    onTap: () => setState(() => _filter = 1),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: 'Companies',
                    active: _filter == 2,
                    onTap: () => setState(() => _filter = 2),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppChip(
                    label: unreadCount == 0
                        ? 'Unread'
                        : 'Unread ($unreadCount)',
                    active: _filter == 3,
                    onTap: () => setState(() => _filter = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (visible.isEmpty)
              EmptyState(
                title: _query.isNotEmpty
                    ? 'No conversations found'
                    : _filter == 3
                    ? 'You’re all caught up'
                    : 'No messages yet',
                message: _query.isNotEmpty
                    ? 'Try another name, company, or keyword.'
                    : 'Recruiter and company conversations will show up here.',
                action: _query.isNotEmpty || _filter != 0
                    ? TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _filter = 0;
                          });
                        },
                        child: const Text('Show all messages'),
                      )
                    : null,
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _filter == 1
                          ? 'Recruiter conversations'
                          : _filter == 2
                          ? 'Company conversations'
                          : _filter == 3
                          ? 'Unread messages'
                          : 'Recent conversations',
                      style: AppTypography.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${visible.length}',
                    style: AppTypography.textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final message in visible)
                _MessageRow(
                  message: message,
                  onTap: () => context.push('/messages/${message.id}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Message> _demoApplicationMessages(WidgetRef ref) {
    final conversations = ref.watch(demoConversationsProvider);
    final jobs = ref.watch(jobsProvider);
    final companies = ref.watch(companiesProvider);
    return [
      for (final conversation in conversations.values)
        if (jobs.where((job) => job.id == conversation.jobId).isNotEmpty)
          _messageForDemo(
            conversation,
            jobs.firstWhere((job) => job.id == conversation.jobId),
            companies,
          ),
    ];
  }

  Message _messageForDemo(
    DemoConversation conversation,
    Job job,
    List<Company> companies,
  ) {
    final company = companies.firstWhere((item) => item.id == job.companyId);
    final latest = conversation.messages.isEmpty
        ? null
        : conversation.messages.last;
    return Message(
      id: 'demo-${job.id}',
      name: company.name,
      company: job.title,
      preview: latest?.body ?? 'Application conversation · Open to chat',
      time: latest == null
          ? 'New'
          : '${latest.sentAt.hour.toString().padLeft(2, '0')}:'
                '${latest.sentAt.minute.toString().padLeft(2, '0')}',
      unread: false,
      kind: MessageKind.company,
    );
  }
}

class _SupabaseInbox extends StatefulWidget {
  const _SupabaseInbox({required this.service});

  final SupabaseJobService service;

  @override
  State<_SupabaseInbox> createState() => _SupabaseInboxState();
}

class _SupabaseInboxState extends State<_SupabaseInbox> {
  final _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _conversations;
  int _filter = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _conversations = widget.service.fetchMyConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenGutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load conversations: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodyMedium!.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = widget.service.client.auth.currentUser!.id;
          final conversations = snapshot.data!;
          final rows = conversations.where((conversation) {
            final isApplicant = conversation['applicant_id'] == currentUserId;
            final matchesKind = switch (_filter) {
              1 => !isApplicant,
              2 => isApplicant,
              3 => conversation['unread'] == true,
              _ => true,
            };
            final searchable = [
              conversation['company_name'],
              conversation['job_title'],
              conversation['applicant_name'],
              conversation['last_message'],
            ].whereType<String>().join(' ').toLowerCase();
            return matchesKind && searchable.contains(_query.toLowerCase());
          }).toList();
          final unreadCount = conversations
              .where((item) => item['unread'] == true)
              .length;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              AppSpacing.md,
              AppSpacing.screenGutter,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  IconCircleButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Messages',
                          style: AppTypography.textTheme.headlineLarge,
                        ),
                        Text(
                          unreadCount == 0
                              ? 'Your conversations'
                              : '$unreadCount unread conversations',
                          style: AppTypography.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  IconCircleButton(
                    icon: Icons.refresh_rounded,
                    semanticLabel: 'Refresh messages',
                    onPressed: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSearchBar(
                controller: _searchController,
                hintText: 'Search people or jobs',
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                trailing: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear message search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.muted,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip('All', 0),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip('Recruiters', 1),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip('Companies', 2),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      unreadCount == 0 ? 'Unread' : 'Unread ($unreadCount)',
                      3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (rows.isEmpty)
                EmptyState(
                  title: _query.isNotEmpty
                      ? 'No conversations found'
                      : 'No conversations yet',
                  message: _query.isNotEmpty
                      ? 'Try another name, company, or job title.'
                      : 'Apply for a job to start a conversation with its employer.',
                )
              else ...[
                Text(
                  'Recent conversations',
                  style: AppTypography.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final row in rows)
                  _MessageRow(
                    message: _messageFromRow(row, currentUserId),
                    onTap: () =>
                        context.push('/messages/${row['conversation_id']}'),
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );

  Widget _filterChip(String label, int index) => AppChip(
    label: label,
    active: _filter == index,
    onTap: () => setState(() => _filter = index),
  );

  Message _messageFromRow(Map<String, dynamic> row, String currentUserId) {
    final isApplicant = row['applicant_id'] == currentUserId;
    final createdAt = DateTime.tryParse(
      row['last_message_at'] as String? ?? '',
    )?.toLocal();
    return Message(
      id: row['conversation_id'] as String,
      name: isApplicant
          ? row['company_name'] as String? ?? 'Employer'
          : row['applicant_name'] as String? ?? 'Applicant',
      company: row['job_title'] as String? ?? 'Job application',
      preview:
          row['last_message'] as String? ?? 'Application conversation started',
      time: createdAt == null
          ? ''
          : '${createdAt.hour.toString().padLeft(2, '0')}:'
                '${createdAt.minute.toString().padLeft(2, '0')}',
      unread: row['unread'] == true,
      kind: isApplicant ? MessageKind.company : MessageKind.recruiter,
    );
  }

  void _refresh() {
    setState(() {
      _conversations = widget.service.fetchMyConversations();
    });
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.onTap});

  final Message message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = message.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1))
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: message.unread ? AppColors.brand50 : AppColors.surface,
        border: Border.all(
          color: message.unread ? AppColors.brand100 : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2B6B).withValues(alpha: 0.05),
            blurRadius: AppSpacing.shadowBlur,
            offset: const Offset(0, AppSpacing.xs),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    UserAvatar(
                      initials: initials,
                      size: AppSpacing.messageAvatarSize,
                    ),
                    if (message.unread)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            message.time,
                            style: AppTypography.textTheme.labelSmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.labelMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _KindBadge(kind: message.kind),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        message.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium!.copyWith(
                          color: message.unread
                              ? AppColors.ink
                              : AppColors.muted,
                          fontWeight: message.unread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});

  final MessageKind kind;

  @override
  Widget build(BuildContext context) {
    final isRecruiter = kind == MessageKind.recruiter;
    final label = isRecruiter ? 'Recruiter' : 'Company';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isRecruiter ? AppColors.brand50 : AppColors.successBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall!.copyWith(
          color: isRecruiter ? AppColors.brand600 : AppColors.success,
        ),
      ),
    );
  }
}
