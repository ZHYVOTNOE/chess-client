import 'dart:math';

import 'package:squares/squares.dart';

enum PlayerColor {
  white(Squares.white, 'white'),
  black(Squares.black, 'black');

  final int value;
  final String code;
  const PlayerColor(this.value, this.code);

  factory PlayerColor.fromCode(String code) => switch (code) {
    'white' => white,
    'black' => black,
    _ => white,
  };

  factory PlayerColor.random() =>
      Random().nextBool() ? white : black;

  PlayerColor get opposite => this == white ? black : white;
  bool get isWhite => this == white;
  bool get isBlack => this == black;
}