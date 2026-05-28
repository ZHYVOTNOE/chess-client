// lib/features/settings/constants/custom_board_themes.dart
import 'package:flutter/material.dart';
import 'package:squares/squares.dart' as squares; // ← ЯВНЫЙ ПРЕФИКС

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

  // 🔥 ИСПРАВЛЕННАЯ "Синяя" тема (настоящие синие цвета)
  static const blue = squares.BoardTheme(
    lightSquare: Color(0xFFB3E5FC),  // светло-голубой
    darkSquare: Color(0xFF01579B),   // тёмно-синий
    check: Color(0xFFEB5160),
    checkmate: Colors.orange,
    previous: Color(0x809CC700),
    selected: Color(0x8014551E),
    premove: Color(0x80141E55),
  );

  // 🔥 Остальные темы с squares.BoardTheme
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

  // 🔥 Вспомогательный класс для UI
  static const List<BoardThemeEntry> all = [
    BoardThemeEntry(id: 'classic', label: 'Классика', theme: classic),
    BoardThemeEntry(id: 'green', label: 'Зелёная', theme: green),
    BoardThemeEntry(id: 'blue', label: 'Синяя', theme: blue),
    BoardThemeEntry(id: 'wood', label: 'Дерево', theme: wood),
    BoardThemeEntry(id: 'marble', label: 'Мрамор', theme: marble),
    BoardThemeEntry(id: 'pink', label: 'Розовая', theme: pink),
    BoardThemeEntry(id: 'purple', label: 'Фиолетовая', theme: purple),
    BoardThemeEntry(id: 'orange', label: 'Оранжевая', theme: orange),
    BoardThemeEntry(id: 'teal', label: 'Бирюзовая', theme: teal),
    BoardThemeEntry(id: 'red', label: 'Красная', theme: red),
    BoardThemeEntry(id: 'yellow', label: 'Жёлтая', theme: yellow),
    BoardThemeEntry(id: 'grey', label: 'Серая', theme: grey),
    BoardThemeEntry(id: 'midnight', label: 'Полночь', theme: midnight),
    BoardThemeEntry(id: 'ocean', label: 'Океан', theme: ocean),
    BoardThemeEntry(id: 'forest', label: 'Лес', theme: forest),
  ];
}

/// Вспомогательный класс для выпадающего списка в настройках
class BoardThemeEntry {
  final String id;
  final String label;
  final squares.BoardTheme theme; // ← ЯВНЫЙ ТИП из squares!

  const BoardThemeEntry({
    required this.id,
    required this.label,
    required this.theme,
  });
}