part of 'social_cubit.dart';

class SocialState {
  final List<Friend> friends;
  final List<Friend> friendRequests;
  final List<Friend> sentRequests;
  final List<Friend> searchResults;
  final List<Map<String, dynamic>> gameInvites;
  final int pendingRequestsCount;
  final bool isSearching;
  final String? error;

  SocialState({
    required this.friends,
    required this.friendRequests,
    required this.sentRequests,
    required this.searchResults,
    required this.gameInvites,
    this.pendingRequestsCount = 0,
    required this.isSearching,
    this.error,
  });

  factory SocialState.initial() {
    return SocialState(
      friends: [],
      friendRequests: [],
      sentRequests: [],
      searchResults: [],
      gameInvites: [],
      pendingRequestsCount: 0,
      isSearching: false,
    );
  }

  SocialState copyWith({
    List<Friend>? friends,
    List<Friend>? friendRequests,
    List<Friend>? sentRequests,
    List<Friend>? searchResults,
    List<Map<String, dynamic>>? gameInvites,
    int? pendingRequestsCount,
    bool? isSearching,
    String? error,
  }) {
    return SocialState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      searchResults: searchResults ?? this.searchResults,
      gameInvites: gameInvites ?? this.gameInvites,
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}
