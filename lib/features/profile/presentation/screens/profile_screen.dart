// lib/features/profile/presentation/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/locale_provider.dart';
import '../../../../../core/providers/user_provider.dart';
import '../../../auth/domain/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController _nicknameController;
  final _formKey = GlobalKey<FormState>();
  final RegExp _nicknameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
  final ImagePicker _picker = ImagePicker();
  File? _tempAvatar;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // 🔥 Создаём контроллер здесь, а не в поле класса
    _nicknameController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().loadProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && mounted) {
      final user = context.read<UserProvider>();
      // 🔥 Безопасное обновление текста только если виджет активен
      if (_nicknameController.text != user.nickname) {
        _nicknameController.text = user.nickname;
      }
      _tempAvatar = user.avatarFile;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    // 🔥 Только здесь удаляем контроллер
    _nicknameController.dispose();
    super.dispose();
  }

  // 🔥 Показ выбора: камера или галерея
  void _showImageSourceActionSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Запрос разрешений и выбор изображения
  Future<void> _pickImage(ImageSource source) async {
    if (!mounted) return;

    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Доступ к медиафайлам запрещён'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() => _tempAvatar = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора фото: $e')),
        );
      }
    }
  }

  // 🔥 Модальное окно для редактирования никнейма
  // lib/features/profile/presentation/screens/profile_screen.dart

  // 🔥 Модальное окно для редактирования никнейма — ИСПРАВЛЕННАЯ ВЕРСИЯ
  Future<void> _showNicknameEditDialog(String currentNickname) async {
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dialogController = TextEditingController(text: currentNickname);
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text('✏️ Изменить никнейм'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: dialogController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Введите новый никнейм',
                helperText: '3-20 символов: буквы, цифры, _',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Никнейм не может быть пустым';
                if (text.length < 3) return 'Минимум 3 символа';
                if (text.length > 20) return 'Максимум 20 символов';
                if (!_nicknameRegex.hasMatch(text)) return 'Только буквы, цифры и "_"';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // 🔥 Возвращаем только валидное значение
                  Navigator.pop(ctx, dialogController.text.trim());
                }
              },
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );

    // 🔥 Мгновенное локальное обновление UI (до отправки на сервер)
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _nicknameController.text = result);
    }
  }

  // 🔥 Сохранение профиля
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    final newNickname = _nicknameController.text.trim();
    final userProvider = context.read<UserProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сохранение...'), duration: Duration(seconds: 2)),
    );

    try {
      // 1. Отправляем никнейм
      await userProvider.setNickname(newNickname);

      // 2. Если меняли аватар, отправляем его
      if (_tempAvatar != null) {
        await userProvider.setAvatar(_tempAvatar!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Профиль обновлён'), backgroundColor: Colors.green),
        );
        setState(() {
          isEditing = false;
          _tempAvatar = userProvider.avatarFile;
        });
      }
    } catch (e) {
      if (mounted) {
        // 🔥 Откат никнейма при ошибке сети/сервера
        setState(() => _nicknameController.text = userProvider.nickname);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Ошибка сохранения: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔥 Выход из аккаунта
  // 🔥 В методе _showLogoutConfirmation():
  void _showLogoutConfirmation() {
    if (!mounted) return;

    final locale = context.read<LocaleProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.get('logout_title') ?? 'Выход'),
        content: Text(locale.get('logout_confirm') ?? 'Вы действительно хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.get('cancel') ?? 'Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // 🔥 ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ AuthProvider ИЗ КОНТЕКСТА
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();

              if (mounted && context.mounted) {
                context.go('/welcome');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red,
            ),
            child: Text(locale.get('logout') ?? 'Выйти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    final locale = context.watch<LocaleProvider>();
    final user = context.watch<UserProvider>();

    // 🔥 Синхронизация только если не редактируем и виджет активен
    if (!isEditing && mounted && _nicknameController.text != user.nickname) {
      _nicknameController.text = user.nickname;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('profile_title') ?? 'Профиль'),
        centerTitle: true,
        actions: [
          // ❌ КРЕСТИК = ОТМЕНА ИЗМЕНЕНИЙ
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                final user = context.read<UserProvider>();
                setState(() {
                  isEditing = false;
                  // Сбрасываем всё к последнему сохранённому состоянию
                  _nicknameController.text = user.nickname;
                  _tempAvatar = user.avatarFile;
                });
              },
            ),

          // ✅ ГАЛОЧКА (или карандаш) = ВКЛЮЧЕНИЕ РЕДАКТИРОВАНИЯ / СОХРАНЕНИЕ
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveProfile(); // 🔥 Вызывает сохранение на сервер
              } else {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Form(key: _formKey, child: _buildProfileHeader(locale)),
            const SizedBox(height: 16),
            _buildRatingsSection(locale),
            const SizedBox(height: 16),
            _buildRadarChart(locale), // 🔥 ВОССТАНОВЛЕНО
            const SizedBox(height: 16),
            _buildGameHistory(locale), // 🔥 ВОССТАНОВЛЕНО
            const SizedBox(height: 16),
            _buildLogoutSection(locale), // 🔥 ВОССТАНОВЛЕНО
          ],
        ),
      ),
    );
  }

  // 🔥 Шапка профиля
  Widget _buildProfileHeader(LocaleProvider locale) {
    final user = context.watch<UserProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: isEditing ? _showImageSourceActionSheet : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    // 🔥 Если есть локальный файл — показываем его сразу
                    backgroundImage: _tempAvatar != null
                        ? FileImage(_tempAvatar!)
                    // 🔥 Если есть ссылка из профиля — NetworkImage
                        : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!) as ImageProvider
                        : null,
                    child: (_tempAvatar == null && user.avatarUrl == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  )
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _nicknameController.text,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showNicknameEditDialog(_nicknameController.text),
                    tooltip: 'Изменить никнейм',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ID: ${user.formattedUserId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Рейтинги (горизонтальные)
  Widget _buildRatingsSection(LocaleProvider locale) {
    final user = context.watch<UserProvider>();

    final ratingModes = [
      {'key': 'bullet', 'name': 'Пуля', 'icon': MdiIcons.bullet},
      {'key': 'blitz', 'name': 'Блиц', 'icon': MdiIcons.timerSand},
      {'key': 'rapid', 'name': 'Рапид', 'icon': MdiIcons.clockFast},
      {'key': 'puzzles', 'name': 'Задачи', 'icon': MdiIcons.puzzle},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.get('profile_ratings') ?? 'Рейтинги',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ratingModes.map((mode) {
                  final rating = user.getRating(mode['key'] as String) ?? 1500;
                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(mode['icon'] as IconData, size: 24, color: _getRatingColor(rating)),
                        const SizedBox(height: 4),
                        Text(
                          mode['name'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rating.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getRatingColor(rating),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Радар-чарт (восстановлено)
  Widget _buildRadarChart(LocaleProvider locale) {
    // 🔥 Заглушка данных — замени на реальные из UserProvider
    final data = [0.8, 0.7, 0.6, 0.75, 0.85, 0.9];
    final titles = [
      locale.get('stat_tactics') ?? 'Тактика',
      locale.get('stat_strategy') ?? 'Стратегия',
      locale.get('stat_endgame') ?? 'Эндшпиль',
      locale.get('stat_opening') ?? 'Дебюты',
      locale.get('stat_calculation') ?? 'Расчёт',
      locale.get('stat_speed') ?? 'Скорость',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.get('profile_stats') ?? 'Статистика',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: [
                    RadarDataSet(
                      dataEntries: data.map((v) => RadarEntry(value: v)).toList(),
                      fillColor: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      entryRadius: 0,
                    ),
                  ],
                  getTitle: (index, angle) => RadarChartTitle(text: titles[index]),
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  gridBorderData: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 История игр (восстановлено)
  Widget _buildGameHistory(LocaleProvider locale) {
    // 🔥 Заглушка — замени на загрузку из Supabase
    final games = [
      {'result': 'win', 'opponent': 'Player1', 'rating': 1800, 'mode': 'blitz', 'moves': 34},
      {'result': 'loss', 'opponent': 'Player2', 'rating': 1950, 'mode': 'bullet', 'moves': 21},
      {'result': 'draw', 'opponent': 'Player3', 'rating': 1900, 'mode': 'rapid', 'moves': 67},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.get('profile_history') ?? 'История',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(locale.get('view_all') ?? 'Все'),
                ),
              ],
            ),
          ),
          ...games.map((g) => _GameHistoryTile(game: g)),
        ],
      ),
    );
  }

  // 🔥 Кнопка выхода (восстановлено)
  Widget _buildLogoutSection(LocaleProvider locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          locale.get('logout') ?? 'Выйти',
          style: const TextStyle(color: Colors.red),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating < 1200) return Colors.grey;
    if (rating < 1400) return Colors.brown;
    if (rating < 1600) return Colors.green;
    if (rating < 1800) return Colors.blue;
    if (rating < 2000) return Colors.purple;
    if (rating < 2200) return Colors.orange;
    return Colors.red;
  }
}

// 🔥 Вспомогательный виджет для истории (в том же файле)
class _GameHistoryTile extends StatelessWidget {
  final Map<String, dynamic> game;
  const _GameHistoryTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final resultColors = {
      'win': Colors.green,
      'loss': Colors.red,
      'draw': Colors.grey,
    };
    final resultIcons = {
      'win': Icons.add,
      'loss': Icons.remove,
      'draw': Icons.drag_handle,
    };
    final resultTexts = {
      'win': 'Победа',
      'loss': 'Поражение',
      'draw': 'Ничья',
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: resultColors[game['result']]?.withOpacity(0.1),
        child: Icon(
          resultIcons[game['result']],
          color: resultColors[game['result']],
        ),
      ),
      title: Text('${game['opponent']} (${game['rating']})'),
      subtitle: Text('${game['mode']} • ${game['moves']} ходов'),
      trailing: Text(
        resultTexts[game['result']] ?? '',
        style: TextStyle(
          color: resultColors[game['result']],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}