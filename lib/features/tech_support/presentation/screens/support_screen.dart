import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_ticket.dart';
import '../cubits/support_cubit.dart';
import '../cubits/support_state.dart';

class SupportScreen extends StatefulWidget {
  final String currentUserRole;

  const SupportScreen({super.key, required this.currentUserRole});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().initialize(widget.currentUserRole);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportCubit, SupportState>(
      listener: (context, state) {
        if (state is SupportTicketOpen || state is SupportAdminTicketOpen) {
          _scrollToBottom();
        }
        if (state is SupportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is SupportLoading || state is SupportInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── ПОЛЬЗОВАТЕЛЬ: нет тикета ──────────────────────────
        if (state is SupportNoTicket) {
          return _buildNoTicketScreen(context);
        }

        // ── ПОЛЬЗОВАТЕЛЬ: чат ─────────────────────────────────
        if (state is SupportTicketOpen) {
          return _buildChatScreen(
            context: context,
            ticket: state.ticket,
            messages: state.messages,
            isSending: state.isSending,
            isAdmin: false,
          );
        }

        // ── ADMIN: список тикетов ─────────────────────────────
        if (state is SupportAdminList) {
          return _buildAdminList(context, state.tickets);
        }

        // ── ADMIN: чат ────────────────────────────────────────
        if (state is SupportAdminTicketOpen) {
          return _buildChatScreen(
            context: context,
            ticket: state.ticket,
            messages: state.messages,
            isSending: state.isSending,
            isAdmin: true,
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  // ── ЭКРАН: нет тикета ──────────────────────────────────────

  Widget _buildNoTicketScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поддержка')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Здесь вы можете написать в службу поддержки',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Наши администраторы ответят вам в ближайшее время',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_comment),
              label: const Text('Начать обращение'),
              onPressed: () =>
                  context.read<SupportCubit>().createNewTicket(),
            ),
          ],
        ),
      ),
    );
  }

  // ── ЭКРАН: список тикетов (admin) ──────────────────────────

  Widget _buildAdminList(BuildContext context, List<SupportTicket> tickets) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обращения пользователей')),
      body: tickets.isEmpty
          ? const Center(
              child: Text(
                'Нет активных обращений',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _AdminTicketTile(
                  ticket: ticket,
                  onTap: () =>
                      context.read<SupportCubit>().openAdminTicket(ticket),
                );
              },
            ),
    );
  }

  // ── ЭКРАН: чат ─────────────────────────────────────────────

  Widget _buildChatScreen({
    required BuildContext context,
    required SupportTicket ticket,
    required List<SupportMessage> messages,
    required bool isSending,
    required bool isAdmin,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isClosed = ticket.status == 'closed';

    return Scaffold(
      appBar: AppBar(
        leading: isAdmin
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    context.read<SupportCubit>().backToAdminList(),
              )
            : null,
        title: isAdmin
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.userNickname ?? 'Пользователь'),
                  Text(
                    isClosed ? 'Закрыто' : 'Открыто',
                    style: TextStyle(
                      fontSize: 12,
                      color: isClosed ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              )
            : const Text('Поддержка'),
        actions: [
          if (isAdmin && !isClosed)
            TextButton(
              onPressed: () => _showCloseConfirm(context, ticket.id),
              child: const Text('Закрыть', style: TextStyle(color: Colors.red)),
            ),
          if (isClosed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text('Закрыто'),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Список сообщений ──────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      isAdmin
                          ? 'Пользователь ещё не написал'
                          : 'Опишите вашу проблему',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      return _ChatBubble(
                        message: msg,
                        isMe: isMe,
                      );
                    },
                  ),
          ),

          // ── Поле ввода ────────────────────────────────────
          if (!isClosed)
            _MessageInputBar(
              controller: _messageController,
              isSending: isSending,
              onSend: () {
                final body = _messageController.text.trim();
                if (body.isNotEmpty) {
                  context.read<SupportCubit>().sendMessage(ticket.id, body);
                  _messageController.clear();
                }
              },
            ),

          if (isClosed)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: const Text(
                'Обращение закрыто',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showCloseConfirm(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Закрыть обращение?'),
        content: const Text(
            'Пользователь больше не сможет писать в этот тикет.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SupportCubit>().closeTicket(ticketId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

// ── ВИДЖЕТЫ ────────────────────────────────────────────────────

class _AdminTicketTile extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _AdminTicketTile({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: ticket.userAvatarUrl != null
            ? NetworkImage(ticket.userAvatarUrl!)
            : null,
        child: ticket.userAvatarUrl == null
            ? Text(
                (ticket.userNickname ?? '?')[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        ticket.userNickname ?? 'Пользователь',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        DateFormat('dd.MM.yyyy HH:mm').format(ticket.updatedAt.toLocal()),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ticket.isOpen ? Colors.green : Colors.grey,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final SupportMessage message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatarUrl != null
                  ? NetworkImage(message.senderAvatarUrl!)
                  : null,
              child: message.senderAvatarUrl == null
                  ? Text(
                      (message.senderNickname ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && message.isAdmin)
                    Text(
                      'Поддержка',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    message.body,
                    style: TextStyle(
                      color: isMe
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Напишите сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: onSend,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
