class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  // Обогащённые данные
  final bool isAdmin;
  final String? senderNickname;
  final String? senderAvatarUrl;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    required this.isAdmin,
    this.senderNickname,
    this.senderAvatarUrl,
  });
}
