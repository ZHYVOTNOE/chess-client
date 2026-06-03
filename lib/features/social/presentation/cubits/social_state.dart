part of 'social_cubit.dart';

class SocialState {
  final List<Friend> friends;
  final List<Friend> friendRequests;
  final List<Friend> searchResults;
  final List<Map<String, dynamic>> gameInvites;
  final bool isSearching;
  final String? error;

  SocialState({
    required this.friends,
    required this.friendRequests,
    required this.searchResults,
    required this.gameInvites,
    required this.isSearching,
    this.error,
  });

  factory SocialState.initial() {
    return SocialState(
      friends: [],
      friendRequests: [],
      searchResults: [],
      gameInvites: [],
      isSearching: false,
    );
  }

  SocialState copyWith({
    List<Friend>? friends,
    List<Friend>? friendRequests,
    List<Friend>? searchResults,
    List<Map<String, dynamic>>? gameInvites,
    bool? isSearching,
    String? error,
  }) {
    return SocialState(
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      searchResults: searchResults ?? this.searchResults,
      gameInvites: gameInvites ?? this.gameInvites,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}
