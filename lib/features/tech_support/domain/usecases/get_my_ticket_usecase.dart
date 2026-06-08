import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class GetMyTicketUseCase {
  final SupportRepository _repo;
  GetMyTicketUseCase(this._repo);
  Future<SupportTicket?> call() => _repo.getMyOpenTicket();
}
