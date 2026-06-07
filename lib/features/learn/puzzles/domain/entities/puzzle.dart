import 'package:equatable/equatable.dart';

class Puzzle extends Equatable {
  final String id;
  final String fen;
  final List<String> moves;
  final int rating;
  final int? ratingDeviation;
  final int? popularity;
  final int? nbPlays;
  final List<String> themes;
  final String? gameUrl;
  final List<String>? openingTags;

  const Puzzle({
    required this.id,
    required this.fen,
    required this.moves,
    required this.rating,
    this.ratingDeviation,
    this.popularity,
    this.nbPlays,
    required this.themes,
    this.gameUrl,
    this.openingTags,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: (json['PuzzleId'] ?? json['puzzle_id'] ?? json['id'])?.toString() ?? '',
      fen: (json['FEN'] ?? json['fen'])?.toString() ?? '',
      moves: _parseMoves((json['Moves'] ?? json['moves'])?.toString() ?? ''),
      rating: (json['Rating'] ?? json['rating']) as int? ?? 1500,
      ratingDeviation: (json['RatingDeviation'] ?? json['rating_deviation']) as int?,
      popularity: (json['Popularity'] ?? json['popularity']) as int?,
      nbPlays: (json['NbPlays'] ?? json['nb_plays']) as int?,
      themes: _parseThemes((json['Themes'] ?? json['themes'])?.toString()),
      gameUrl: (json['GameUrl'] ?? json['game_url'])?.toString(),
      openingTags: json['OpeningTags'] != null
          ? (json['OpeningTags'] as String).split(',')
          : (json['opening_tags'] != null ? (json['opening_tags'] as String).split(',') : null),
    );
  }

  static List<String> _parseMoves(String movesString) {
    if (movesString.isEmpty) return [];
    return movesString.trim().split(' ').where((m) => m.isNotEmpty).toList();
  }

  static List<String> _parseThemes(String? themesString) {
    if (themesString == null || themesString.isEmpty) return [];
    return themesString.trim().split(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'PuzzleId': id,
      'FEN': fen,
      'Moves': moves.join(' '),
      'Rating': rating,
      'RatingDeviation': ratingDeviation,
      'Popularity': popularity,
      'NbPlays': nbPlays,
      'Themes': themes.join(','),
      'GameUrl': gameUrl,
      'OpeningTags': openingTags?.join(','),
    };
  }

  @override
  List<Object?> get props => [
        id,
        fen,
        moves,
        rating,
        ratingDeviation,
        popularity,
        nbPlays,
        themes,
        gameUrl,
        openingTags,
      ];
}
