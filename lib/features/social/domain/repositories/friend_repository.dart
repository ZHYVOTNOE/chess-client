import '../entities/friend.dart';

abstract class FriendRepository {
  /// Fetch all friends for the current user
  Future<List<Friend>> getFriends(String userId);

  /// Search for users by nickname
  Future<List<Friend>> searchUsers(String query);

  /// Send a friend request
  Future<void> sendFriendRequest(String fromUserId, String toUserId);

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId);

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId);

  /// Remove a friend
  Future<void> removeFriend(String friendId);

  /// Get pending friend requests (incoming)
  Future<List<Friend>> getPendingRequests(String userId);

  /// Get sent friend requests (outgoing)
  Future<List<Friend>> getSentRequests(String userId);

  /// Cancel a sent friend request
  Future<void> cancelSentRequest(String requestId);

  /// Stream for friend requests (Realtime)
  Stream<List<Friend>> friendRequestsStream(String userId);

  /// Stream for sent requests (Realtime)
  Stream<List<Friend>> sentRequestsStream(String userId);

  /// Stream for friends list (Realtime)
  Stream<List<Friend>> friendsStream(String userId);

  /// Invalidate profile cache for a specific user
  void invalidateProfileCache(String userId);
}
