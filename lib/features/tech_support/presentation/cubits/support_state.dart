import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_ticket.dart';

abstract class SupportState {}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportError extends SupportState {
  final String message;
  SupportError(this.message);
}

/// Состояние пользователя — нет открытого тикета
class SupportNoTicket extends SupportState {}

/// Состояние пользователя — есть открытый тикет, чат открыт
class SupportTicketOpen extends SupportState {
  final SupportTicket ticket;
  final List<SupportMessage> messages;
  final bool isSending;

  SupportTicketOpen({
    required this.ticket,
    required this.messages,
    this.isSending = false,
  });

  SupportTicketOpen copyWith({
    SupportTicket? ticket,
    List<SupportMessage>? messages,
    bool? isSending,
  }) {
    return SupportTicketOpen(
      ticket: ticket ?? this.ticket,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// Состояние администратора — список тикетов
class SupportAdminList extends SupportState {
  final List<SupportTicket> tickets;
  SupportAdminList(this.tickets);
}

/// Состояние администратора — открыт конкретный тикет
class SupportAdminTicketOpen extends SupportState {
  final SupportTicket ticket;
  final List<SupportMessage> messages;
  final bool isSending;

  SupportAdminTicketOpen({
    required this.ticket,
    required this.messages,
    this.isSending = false,
  });

  SupportAdminTicketOpen copyWith({
    SupportTicket? ticket,
    List<SupportMessage>? messages,
    bool? isSending,
  }) {
    return SupportAdminTicketOpen(
      ticket: ticket ?? this.ticket,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}
