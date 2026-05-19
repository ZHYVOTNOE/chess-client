import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../constants/setting_constants.dart';

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
          // 🔹 Доска
          _buildCardTitle('🎨 Доска'),
          _buildDropdown(
            title: 'Тема доски',
            value: s.boardTheme,
            items: BoardTheme.all.map((t) => DropdownMenuItem(value: t.id, child: Text(t.label))).toList(),
            onChanged: (val) => settings.setBoardTheme(val!),
          ),
          _buildSwitch('Показывать координаты', s.showCoordinates, settings.setShowCoordinates),
          _buildSwitch('Подсветка последнего хода', s.highlightLastMove, settings.setHighlightLastMove),
          _buildSwitch('Подсветка возможных ходов', s.highlightPossibleMoves, settings.setHighlightPossibleMoves),

          const SizedBox(height: 16),

          // 🔹 Фигуры
          _buildCardTitle('♟️ Фигуры'),
          _buildDropdown(
            title: 'Набор фигур',
            value: s.pieceSet,
            items: const [
              DropdownMenuItem(value: 'merida', child: Text('Merida')),
              DropdownMenuItem(value: 'staunton', child: Text('Staunton')),
              DropdownMenuItem(value: 'alpha', child: Text('Alpha')),
            ],
            onChanged: (val) => settings.setPieceSet(val!),
          ),
          _buildSlider('Размер фигур', s.pieceSize, 0.8, 1.2, settings.setPieceSize),

          const SizedBox(height: 16),

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
              items: VibrationIntensity.values.map((v) => DropdownMenuItem(value: v.name, child: Text(v.label))).toList(),
              onChanged: (val) => settings.setVibrationIntensity(val!),
            ),
        ],
      ),
    );
  }

  Widget _buildCardTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 8),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _buildDropdown({required String title, required String value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
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
        subtitle: Slider(value: value, min: min, max: max, divisions: 4, label: value.toStringAsFixed(1), onChanged: onChanged),
      ),
    );
  }
}