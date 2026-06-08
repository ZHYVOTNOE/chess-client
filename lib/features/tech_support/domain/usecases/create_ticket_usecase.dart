import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class CreateTicketUseCase {
  final SupportRepository _repo;
  CreateTicketUseCase(this._repo);
  Future<SupportTicket> call() => _repo.createTicket();
}
