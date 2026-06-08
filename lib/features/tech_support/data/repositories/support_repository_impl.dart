import '../../domain/entities/support_message.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_remote_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDataSource _dataSource;
  SupportRepositoryImpl(this._dataSource);

  @override
  Future<SupportTicket?> getMyOpenTicket() => _dataSource.getMyOpenTicket();

  @override
  Future<SupportTicket> createTicket() => _dataSource.createTicket();

  @override
  Future<List<SupportTicket>> getAdminTickets() => _dataSource.getAdminTickets();

  @override
  Future<List<SupportMessage>> getMessages(String ticketId) =>
      _dataSource.getMessages(ticketId);

  @override
  Stream<List<SupportMessage>> messagesStream(String ticketId) =>
      _dataSource.messagesStream(ticketId);

  @override
  Stream<List<SupportTicket>> adminTicketsStream() =>
      _dataSource.adminTicketsStream();

  @override
  Future<void> sendMessage(String ticketId, String body) =>
      _dataSource.sendMessage(ticketId, body);

  @override
  Future<void> closeTicket(String ticketId) => _dataSource.closeTicket(ticketId);
}
