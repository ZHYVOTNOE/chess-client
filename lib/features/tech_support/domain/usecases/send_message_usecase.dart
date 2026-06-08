import '../repositories/support_repository.dart';

class SendMessageUseCase {
  final SupportRepository _repo;
  SendMessageUseCase(this._repo);
  Future<void> call(String ticketId, String body) =>
      _repo.sendMessage(ticketId, body);
}
