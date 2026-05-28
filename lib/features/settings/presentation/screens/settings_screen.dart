// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squares/squares.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/piece_set_loader.dart';
import '../../constants/custom_board_themes.dart';
import '../../constants/custom_piece_sets.dart';
import '../../constants/setting_constants.dart'; // ← VibrationIntensity

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    if (settings.isLoading || settings.settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final s = settings.settings!;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCardTitle('🎨 Доска'),

          _buildDropdown(
            title: 'Тема доски',
            value: s.boardTheme,
            items: CustomBoardThemes.all.map((entry) =>
                DropdownMenuItem(value: entry.id, child: Text(entry.label))
            ).toList(),
            onChanged: (val) => settings.setBoardTheme(val!),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Предпросмотр:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CustomBoardThemes.all
                            .firstWhere((e) => e.id == s.boardTheme,
                            orElse: () => CustomBoardThemes.all[0])
                            .label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Board(
                    state: const BoardState(
                      board: ['', ''],
                      turn: 0,
                      orientation: 0,
                    ),
                    playState: PlayState.finished,
                    pieceSet: PieceSet.merida(),
                    theme: CustomBoardThemes.all
                        .firstWhere((e) => e.id == s.boardTheme,
                        orElse: () => CustomBoardThemes.all[0])
                        .theme,

                    size: const BoardSize(2, 2),
                    draggable: false,
                    labelConfig: LabelConfig.disabled,
                  ),
                ),
              ],
            ),
          ),

          _buildSwitch('Показывать координаты', s.showCoordinates, settings.setShowCoordinates),
          _buildSwitch('Подсветка последнего хода', s.highlightLastMove, settings.setHighlightLastMove),
          _buildSwitch('Подсветка возможных ходов', s.highlightPossibleMoves, settings.setHighlightPossibleMoves),

          const SizedBox(height: 24),

          // 🔹 Фигуры
          _buildCardTitle('♟️ Фигуры'),
          _buildDropdown(
            title: 'Набор фигур',
            value: s.pieceSet,
            items: CustomPieceSets.all.map((entry) =>
                DropdownMenuItem(value: entry.id, child: Text(entry.label))
            ).toList(),
            onChanged: (val) => settings.setPieceSet(val!),
          ),

          // 🔥 Превью: белые + чёрные фигуры в два ряда
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Белые фигуры (верхний ряд)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['P', 'N', 'B', 'R', 'Q', 'K'].map((symbol) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: PieceSetLoader.load(s.pieceSet).piece(context, symbol.toUpperCase()),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 🔹 Чёрные фигуры (нижний ряд)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['P', 'N', 'B', 'R', 'Q', 'K'].map((symbol) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: PieceSetLoader.load(s.pieceSet).piece(context, symbol.toLowerCase()),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSlider('Размер фигур', s.pieceSize, 0.8, 1.2, settings.setPieceSize),

          const SizedBox(height: 24),

          // 🔹 Звуки
          _buildCardTitle('🔊 Звуки'),
          _buildSwitch('Включить звуки', s.soundEnabled, settings.setSoundEnabled),
          if (s.soundEnabled)
            _buildDropdown(
              title: 'Набор звуков',
              value: s.soundSet,
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Стандартные')),
                DropdownMenuItem(value: 'soft', child: Text('Мягкие')),
              ],
              onChanged: (val) => settings.setSoundSet(val!),
            ),

          const SizedBox(height: 16),

          // 🔹 Вибрация
          _buildCardTitle('📳 Вибрация'),
          _buildSwitch('Включить вибрацию', s.vibrationEnabled, settings.setVibrationEnabled),
          if (s.vibrationEnabled)
            _buildDropdown(
              title: 'Интенсивность',
              value: s.vibrationIntensity,
              items: VibrationIntensity.values.map((v) =>
                  DropdownMenuItem(value: v.name, child: Text(v.label))
              ).toList(),
              onChanged: (val) => settings.setVibrationIntensity(val!),
            ),
        ],
      ),
    );
  }

  Widget _buildCardTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    ),
  );

  Widget _buildDropdown({
    required String title,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: DropdownButton<String>(value: value, items: items, onChanged: onChanged),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, void Function(bool) onChanged) {
    return Card(child: SwitchListTile(title: Text(title), value: value, onChanged: onChanged));
  }

  Widget _buildSlider(String title, double value, double min, double max, void Function(double) onChanged) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Slider(
          value: value,
          min: min,
          max: max,
          divisions: 4,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ),
    );
  }
}