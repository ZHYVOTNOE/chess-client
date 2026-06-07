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
      id: json['PuzzleId'] as String? ?? json['puzzle_id'] as String? ?? json['id'] as String,
      fen: json['FEN'] as String? ?? json['fen'] as String,
      moves: _parseMoves(json['Moves'] as String? ?? json['moves'] as String),
      rating: json['Rating'] as int? ?? json['rating'] as int,
      ratingDeviation: json['RatingDeviation'] as int? ?? json['rating_deviation'] as int?,
      popularity: json['Popularity'] as int? ?? json['popularity'] as int?,
      nbPlays: json['NbPlays'] as int? ?? json['nb_plays'] as int?,
      themes: _parseThemes(json['Themes'] as String? ?? json['themes'] as String?),
      gameUrl: json['GameUrl'] as String? ?? json['game_url'] as String?,
      openingTags: json['OpeningTags'] != null
          ? (json['OpeningTags'] as String).split(',')
          : (json['opening_tags'] != null ? (json['opening_tags'] as String).split(',') : null),
    );
  }

  static List<String> _parseMoves(String movesString) {
    // Lichess moves format: "e2e4 e7e5 g1f3" etc.
    return movesString.trim().split(' ');
  }

  static List<String> _parseThemes(String? themesString) {
    if (themesString == null || themesString.isEmpty) return [];
    return themesString.split(',').map((t) => t.trim()).toList();
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
