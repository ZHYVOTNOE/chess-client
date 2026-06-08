import '../repositories/support_repository.dart';

class CloseTicketUseCase {
  final SupportRepository _repo;
  CloseTicketUseCase(this._repo);
  Future<void> call(String ticketId) => _repo.closeTicket(ticketId);
}
