import '../entities/support_ticket.dart';
import '../repositories/support_repository.dart';

class GetAdminTicketsUseCase {
  final SupportRepository _repo;
  GetAdminTicketsUseCase(this._repo);
  Future<List<SupportTicket>> call() => _repo.getAdminTickets();
}
