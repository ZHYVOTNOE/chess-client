import '../entities/support_ticket.dart';
import '../entities/support_message.dart';

abstract class SupportRepository {
  /// Получить открытый тикет текущего пользователя (null если нет)
  Future<SupportTicket?> getMyOpenTicket();

  /// Создать новый тикет (назначает случайного админа)
  Future<SupportTicket> createTicket();

  /// Получить все тикеты, назначенные на текущего админа
  Future<List<SupportTicket>> getAdminTickets();

  /// Получить сообщения тикета
  Future<List<SupportMessage>> getMessages(String ticketId);

  /// Realtime-стрим сообщений
  Stream<List<SupportMessage>> messagesStream(String ticketId);

  /// Realtime-стрим тикетов для админа
  Stream<List<SupportTicket>> adminTicketsStream();

  /// Отправить сообщение
  Future<void> sendMessage(String ticketId, String body);

  /// Закрыть тикет (только админ)
  Future<void> closeTicket(String ticketId);
}
