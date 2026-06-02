import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/providers/locale_provider.dart';
import '../../../../../core/services/presence_service.dart';
import '../../../auth/domain/auth_provider.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  Timer? _uiRefreshTimer;
  Timer? _presenceTimer;
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          context.read<ProfileCubit>().loadProfile(userId);
          _startPresenceTimer(userId);
          _startUiRefreshTimer();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiRefreshTimer?.cancel();
    _presenceTimer?.cancel();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startPresenceTimer(userId);
        _startUiRefreshTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _presenceService.stopHeartbeat();
        _uiRefreshTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startPresenceTimer(String userId) {
    _presenceService.startHeartbeat(userId);
  }

  void _startUiRefreshTimer() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool _isOnline(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return false;
    return DateTime.now().difference(lastSeenAt).inMinutes < 3;
  }

  String _getCountryFlag(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return '';
    // Convert ISO code to flag emoji
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Никогда';
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) return 'Сейчас';
    if (difference.inMinutes < 60) return '${difference.inMinutes} мин назад';
    if (difference.inHours < 24) return '${difference.inHours} ч назад';
    if (difference.inDays < 7) return '${difference.inDays} д назад';
    return _formatDate(lastSeen);
  }

  /// 🔥 Выход из аккаунта
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

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('profile_title') ?? 'Профиль'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final currentState = context.read<ProfileCubit>().state;
              if (mounted && (currentState is ProfileLoaded || currentState is ProfileUpdated)) {
                final profile = currentState is ProfileLoaded
                    ? currentState.profile
                    : (currentState as ProfileUpdated).profile;
                context.push('/profile/edit', extra: profile);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userId = Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) {
                        context.read<ProfileCubit>().loadProfile(userId);
                      }
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded || state is ProfileUpdated) {
            final profile = state is ProfileLoaded ? state.profile : (state as ProfileUpdated).profile;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(locale, profile),
                  const SizedBox(height: 16),
                  _buildRatingsSection(locale),
                  const SizedBox(height: 16),
                  _buildRadarChart(locale),
                  const SizedBox(height: 16),
                  _buildGameHistory(locale),
                  const SizedBox(height: 16),
                  _buildLogoutSection(locale),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// 🔥 Шапка профиля
  Widget _buildProfileHeader(LocaleProvider locale, dynamic profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                // Переносим логику индикатора сюда
                if (_isOnline(profile.lastSeenAt))
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3), // Белая обводка
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title (LEFT) - only if not null
                if (profile.title != null && profile.title!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          profile.title!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Nickname (CENTER)
                Text(
                  profile.nickname,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Flag (RIGHT)
                if (profile.countryCode != null && profile.countryCode!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    _getCountryFlag(profile.countryCode),
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ],
            ),
            if (profile.fullName != null && profile.fullName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.fullName!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Column(
              children: [
                if (profile.displayId != null)
                  _buildInfoRow('Game ID', profile.displayId.toString()),
                _buildInfoRow('Рег. дата', _formatDate(profile.joinedAt)),
                //_buildInfoRow('Был в сети', _formatLastSeen(profile.lastSeenAt)),
              ],
            ),
            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'О себе',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.bio!,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 Рейтинги (горизонтальные)
  Widget _buildRatingsSection(LocaleProvider locale) {
    // Placeholder ratings - will be fetched from database later
    final ratings = {
      'bullet': 1500,
      'blitz': 1500,
      'rapid': 1500,
      'puzzles': 1500,
    };

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
                  final rating = ratings[mode['key'] as String] ?? 1500;
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

  /// 🔥 Радар-чарт (заглушка)
  Widget _buildRadarChart(LocaleProvider locale) {
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

  /// 🔥 История игр (заглушка)
  Widget _buildGameHistory(LocaleProvider locale) {
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

  /// 🔥 Кнопка выхода
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

/// 🔥 Вспомогательный виджет для истории игр
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