import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_ticket.dart';

class SupportRemoteDataSource {
  final SupabaseClient _supabase;

  SupportRemoteDataSource(this._supabase);

  String get _currentUserId =>
      _supabase.auth.currentUser!.id;

  // ─── ТИКЕТЫ ───────────────────────────────────────────────

  Future<SupportTicket?> getMyOpenTicket() async {
    final data = await _supabase
        .from('support_tickets')
        .select()
        .eq('user_id', _currentUserId)
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(1);

    if (data.isEmpty) return null;
    return _ticketFromMap(data.first);
  }

  Future<SupportTicket> createTicket() async {
    // Выбираем случайного админа
    final admins = await _supabase
        .from('profiles')
        .select('id')
        .eq('role', 'admin');

    if (admins.isEmpty) {
      throw Exception('Нет доступных администраторов');
    }

    admins.shuffle();
    final adminId = admins.first['id'] as String;

    final data = await _supabase
        .from('support_tickets')
        .insert({
          'user_id': _currentUserId,
          'assigned_admin_id': adminId,
          'status': 'open',
        })
        .select()
        .single();

    return _ticketFromMap(data);
  }

  Future<List<SupportTicket>> getAdminTickets() async {
    final data = await _supabase
        .from('support_tickets')
        .select('''
          *,
          profiles!support_tickets_user_id_fkey (
            nickname,
            avatar_url
          )
        ''')
        .eq('assigned_admin_id', _currentUserId)
        .order('updated_at', ascending: false);

    return (data as List).map((item) {
      final profile = item['profiles'] as Map<String, dynamic>?;
      return _ticketFromMap(item).copyWith().let((t) => SupportTicket(
            id: t.id,
            userId: t.userId,
            assignedAdminId: t.assignedAdminId,
            status: t.status,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
            userNickname: profile?['nickname'] as String?,
            userAvatarUrl: profile?['avatar_url'] as String?,
          ));
    }).toList();
  }

  // ─── СООБЩЕНИЯ ────────────────────────────────────────────

  Future<List<SupportMessage>> getMessages(String ticketId) async {
    final data = await _supabase
        .from('support_messages')
        .select('''
          *,
          profiles!support_messages_sender_id_fkey (
            nickname,
            avatar_url,
            role
          )
        ''')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    return (data as List).map((json) => _messageFromMap(json as Map<String, dynamic>)).toList();
  }

  Stream<List<SupportMessage>> messagesStream(String ticketId) {
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true)
        .asyncMap((rows) async {
          // Подгружаем профили для каждого сообщения
          final senderIds = rows
              .map((r) => r['sender_id'] as String)
              .toSet()
              .toList();

          final profiles = await _supabase
              .from('profiles')
              .select('id, nickname, avatar_url, role')
              .inFilter('id', senderIds);

          final profileMap = {
            for (final p in profiles) p['id'] as String: p,
          };

          return rows.map((row) {
            final profile = profileMap[row['sender_id']];
            return SupportMessage(
              id: row['id'] as String,
              ticketId: row['ticket_id'] as String,
              senderId: row['sender_id'] as String,
              body: row['body'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              isAdmin: profile?['role'] == 'admin',
              senderNickname: profile?['nickname'] as String?,
              senderAvatarUrl: profile?['avatar_url'] as String?,
            );
          }).toList();
        });
  }

  Stream<List<SupportTicket>> adminTicketsStream() {
    return _supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .eq('assigned_admin_id', _currentUserId)
        .order('updated_at', ascending: false)
        .asyncMap((rows) async {
          final userIds = rows
              .map((r) => r['user_id'] as String)
              .toSet()
              .toList();

          if (userIds.isEmpty) return <SupportTicket>[];

          final profiles = await _supabase
              .from('profiles')
              .select('id, nickname, avatar_url')
              .inFilter('id', userIds);

          final profileMap = {
            for (final p in profiles) p['id'] as String: p,
          };

          return rows.map((row) {
            final profile = profileMap[row['user_id']];
            return SupportTicket(
              id: row['id'] as String,
              userId: row['user_id'] as String,
              assignedAdminId: row['assigned_admin_id'] as String?,
              status: row['status'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              userNickname: profile?['nickname'] as String?,
              userAvatarUrl: profile?['avatar_url'] as String?,
            );
          }).toList();
        });
  }

  Future<void> sendMessage(String ticketId, String body) async {
    await _supabase.from('support_messages').insert({
      'ticket_id': ticketId,
      'sender_id': _currentUserId,
      'body': body,
    });
    // обновляем updated_at тикета
    await _supabase
        .from('support_tickets')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);
  }

  Future<void> closeTicket(String ticketId) async {
    await _supabase
        .from('support_tickets')
        .update({'status': 'closed'})
        .eq('id', ticketId);
  }

  // ─── МАППИНГ ──────────────────────────────────────────────

  SupportTicket _ticketFromMap(Map<String, dynamic> map) {
    return SupportTicket(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      assignedAdminId: map['assigned_admin_id'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SupportMessage _messageFromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return SupportMessage(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      senderId: map['sender_id'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isAdmin: profile?['role'] == 'admin',
      senderNickname: profile?['nickname'] as String?,
      senderAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}

// Мелкий хелпер чтобы не писать вложенные конструкторы
extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
