import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:client/core/providers/locale_provider.dart';

class PuzzleThemeSelector extends StatelessWidget {
  final List<String> themes;
  final String selectedTheme;
  final Function(String) onThemeSelected;

  const PuzzleThemeSelector({
    super.key,
    required this.themes,
    required this.selectedTheme,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = theme == selectedTheme;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getThemeName(theme, locale)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onThemeSelected(theme);
                }
              },
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  String _getThemeName(String theme, LocaleProvider locale) {
    final themeMap = {
      'all': locale.get('puzzles_all_themes'),
      'fork': locale.get('puzzles_theme_fork'),
      'pin': locale.get('puzzles_theme_pin'),
      'skewer': locale.get('puzzles_theme_skewer'),
      'discovered': locale.get('puzzles_theme_discovered'),
      'mate1': locale.get('puzzles_theme_mate1'),
      'mate2': locale.get('puzzles_theme_mate2'),
      'mate3': locale.get('puzzles_theme_mate3'),
      'endgame': locale.get('puzzles_theme_endgame'),
      'middlegame': locale.get('puzzles_theme_middlegame'),
    };

    return themeMap[theme] ?? theme;
  }
}
