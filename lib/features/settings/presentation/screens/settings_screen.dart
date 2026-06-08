// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:squares/squares.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/piece_set_loader.dart';
import '../../constants/custom_board_themes.dart';
import '../../constants/custom_piece_sets.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        context.read<SettingsCubit>().loadSettings(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(child: Text('Ошибка: ${state.message}'));
          }

          if (state is SettingsLoaded) {
            final s = state.settings;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🔹 Язык
                _buildCardTitle('🌐 Язык'),
                _buildDropdown(
                  title: 'Язык интерфейса',
                  value: s.language,
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (val) {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null && val != null) {
                      context.read<SettingsCubit>().updateLanguage(userId, val, context: context);
                    }
                  },
                ),

                SizedBox(height: 24.h),

                _buildCardTitle('🎨 Доска'),

                _buildDropdown(
                  title: 'Тема доски',
                  value: s.boardTheme,
                  items: CustomBoardThemes.all.map((entry) =>
                      DropdownMenuItem(value: entry.id, child: Text(entry.label))
                  ).toList(),
                  onChanged: (val) {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null && val != null) {
                      context.read<SettingsCubit>().updateBoardTheme(userId, val, context: context);
                    }
                  },
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
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4.h),
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
                        width: 80.r,
                        height: 80.r,
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

                SizedBox(height: 24.h),

                // 🔹 Фигуры
                _buildCardTitle('♟️ Фигуры'),
                _buildDropdown(
                  title: 'Набор фигур',
                  value: s.pieceTheme,
                  items: CustomPieceSets.all.map((entry) =>
                      DropdownMenuItem(value: entry.id, child: Text(entry.label))
                  ).toList(),
                  onChanged: (val) {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null && val != null) {
                      context.read<SettingsCubit>().updatePieceTheme(userId, val, context: context);
                    }
                  },
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
                                  child: PieceSetLoader.load(s.pieceTheme).piece(context, symbol.toUpperCase()),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 4.h),
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
                                  child: PieceSetLoader.load(s.pieceTheme).piece(context, symbol.toLowerCase()),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // 🔹 Звуки (commented out for future)
                // _buildCardTitle('🔊 Звуки'),
                // _buildSwitch('Включить звуки', s.soundEnabled, settings.setSoundEnabled),
                // if (s.soundEnabled)
                //   _buildDropdown(
                //     title: 'Набор звуков',
                //     value: s.soundSet,
                //     items: const [
                //       DropdownMenuItem(value: 'default', child: Text('Стандартные')),
                //       DropdownMenuItem(value: 'soft', child: Text('Мягкие')),
                //     ],
                //     onChanged: (val) => settings.setSoundSet(val!),
                //   ),

                // const SizedBox(height: 16),

                // 🔹 Вибрация (commented out for future)
                // _buildCardTitle('📳 Вибрация'),
                // _buildSwitch('Включить вибрацию', s.vibrationEnabled, settings.setVibrationEnabled),
                // if (s.vibrationEnabled)
                //   _buildDropdown(
                //     title: 'Интенсивность',
                //     value: s.vibrationIntensity,
                //     items: VibrationIntensity.values.map((v) =>
                //         DropdownMenuItem(value: v.name, child: Text(v.label))
                //     ).toList(),
                //     onChanged: (val) => settings.setVibrationIntensity(val!),
                //   ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
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
}