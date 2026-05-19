import 'package:flutter/material.dart';

/// Предопределённые темы доски (совместимы с squares/bishop)
class BoardTheme {
  final String id;
  final String label;
  final Color light;
  final Color dark;

  const BoardTheme({required this.id, required this.label, required this.light, required this.dark});

  static const classic = BoardTheme(id: 'classic', label: 'Классика', light: Color(0xFFF0D9B5), dark: Color(0xFFB58863));
  static const green   = BoardTheme(id: 'green',   label: 'Зелёная',   light: Color(0xFFEEEDD9), dark: Color(0xFF769656));
  static const blue    = BoardTheme(id: 'blue',    label: 'Синяя',     light: Color(0xFFDEEBCF), dark: Color(0xFF5B8A47));
  static const wood    = BoardTheme(id: 'wood',    label: 'Дерево',    light: Color(0xFFE8C99E), dark: Color(0xFF8B6F47));
  static const marble  = BoardTheme(id: 'marble',  label: 'Мрамор',    light: Color(0xFFF5F5F5), dark: Color(0xFF424242));

  static const List<BoardTheme> all = [classic, green, blue, wood, marble];
}

/// Интенсивность вибрации
enum VibrationIntensity {
  low('Низкая'),
  medium('Средняя'),
  high('Высокая');

  final String label;
  const VibrationIntensity(this.label);
}