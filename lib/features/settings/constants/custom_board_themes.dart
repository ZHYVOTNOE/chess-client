import 'package:flutter/material.dart';
import 'package:squares/squares.dart' as squares;

/// Твои кастомные темы доски (15+ вариантов)
class CustomBoardThemes {
  // 🔥 Классические
  static const classic = squares.BoardTheme(
    lightSquare: Color(0xFFF0D9B5),
    darkSquare: Color(0xFFB58863),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const green = squares.BoardTheme(
    lightSquare: Color(0xFFEEEDD9),
    darkSquare: Color(0xFF769656),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const blue = squares.BoardTheme(
    lightSquare: Color(0xFFB3E5FC),
    darkSquare: Color(0xFF01579B),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const wood = squares.BoardTheme(
    lightSquare: Color(0xFFE8C99E),
    darkSquare: Color(0xFF8B6F47),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const marble = squares.BoardTheme(
    lightSquare: Color(0xFFF5F5F5),
    darkSquare: Color(0xFF424242),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const pink = squares.BoardTheme(
    lightSquare: Color(0xFFFCE4EC),
    darkSquare: Color(0xFFC2185B),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const purple = squares.BoardTheme(
    lightSquare: Color(0xFFE1BEE7),
    darkSquare: Color(0xFF7B1FA2),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const orange = squares.BoardTheme(
    lightSquare: Color(0xFFFFCC80),
    darkSquare: Color(0xFFEF6C00),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const teal = squares.BoardTheme(
    lightSquare: Color(0xFFB2DFDB),
    darkSquare: Color(0xFF00796B),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const red = squares.BoardTheme(
    lightSquare: Color(0xFFFFCDD2),
    darkSquare: Color(0xFFC62828),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const yellow = squares.BoardTheme(
    lightSquare: Color(0xFFFFF9C4),
    darkSquare: Color(0xFFF9A825),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const grey = squares.BoardTheme(
    lightSquare: Color(0xFFEEEEEE),
    darkSquare: Color(0xFF616161),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const midnight = squares.BoardTheme(
    lightSquare: Color(0xFF262626),
    darkSquare: Color(0xFF000000),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const ocean = squares.BoardTheme(
    lightSquare: Color(0xFFB3E5FC),
    darkSquare: Color(0xFF01579B),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  static const forest = squares.BoardTheme(
    lightSquare: Color(0xFFC8E6C9),
    darkSquare: Color(0xFF1B5E20),
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  // 🔥 Вспомогательный список для UI (с ключами локализации)
  static const List<BoardThemeEntry> all = [
    BoardThemeEntry(id: 'classic', labelKey: 'board_theme_classic', theme: classic),
    BoardThemeEntry(id: 'green', labelKey: 'board_theme_green', theme: green),
    BoardThemeEntry(id: 'blue', labelKey: 'board_theme_blue', theme: blue),
    BoardThemeEntry(id: 'wood', labelKey: 'board_theme_wood', theme: wood),
    BoardThemeEntry(id: 'marble', labelKey: 'board_theme_marble', theme: marble),
    BoardThemeEntry(id: 'pink', labelKey: 'board_theme_pink', theme: pink),
    BoardThemeEntry(id: 'purple', labelKey: 'board_theme_purple', theme: purple),
    BoardThemeEntry(id: 'orange', labelKey: 'board_theme_orange', theme: orange),
    BoardThemeEntry(id: 'teal', labelKey: 'board_theme_teal', theme: teal),
    BoardThemeEntry(id: 'red', labelKey: 'board_theme_red', theme: red),
    BoardThemeEntry(id: 'yellow', labelKey: 'board_theme_yellow', theme: yellow),
    BoardThemeEntry(id: 'grey', labelKey: 'board_theme_grey', theme: grey),
    BoardThemeEntry(id: 'midnight', labelKey: 'board_theme_midnight', theme: midnight),
    BoardThemeEntry(id: 'ocean', labelKey: 'board_theme_ocean', theme: ocean),
    BoardThemeEntry(id: 'forest', labelKey: 'board_theme_forest', theme: forest),
  ];
}

/// Вспомогательный класс для выпадающего списка в настройках
class BoardThemeEntry {
  final String id;
  final String labelKey; // 🔥 Ключ локализации вместо прямого текста
  final squares.BoardTheme theme;

  const BoardThemeEntry({
    required this.id,
    required this.labelKey,
    required this.theme,
  });
}