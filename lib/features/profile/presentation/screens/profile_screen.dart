import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/providers/locale_provider.dart';
import '../../../../../core/services/presence_service.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../social/presentation/screens/social_screen.dart';
import '../cubits/profile_cubit.dart';
import '../cubits/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final bool isReadOnly;

  const ProfileScreen({
    super.key,
    this.userId,
    this.isReadOnly = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  Timer? _uiRefreshTimer;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadProfile();
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _loadProfile();
        _startUiRefreshTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _uiRefreshTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _loadProfile() {
    final userId = widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      context.read<ProfileCubit>().loadProfile(userId);
      if (!widget.isReadOnly) {
        _startUiRefreshTimer();
      }
    }
  }

  void _startUiRefreshTimer() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  String _getCountryFlag(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return '';
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

  void _showLogoutConfirmation(LocaleProvider locale) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.get('logout_title')),
        content: Text(locale.get('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.get('cancel')),
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
            child: Text(locale.get('logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    final locale = context.watch<LocaleProvider>();
    final profileCubit = context.watch<ProfileCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('profile_title')),
        centerTitle: true,
        actions: widget.isReadOnly
            ? []
            : [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final currentState = profileCubit.state;
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
                  Text('${locale.get('error_loading')}${state.message}'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => _loadProfile(),
                    child: Text(locale.get('profile_retry')),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded || state is ProfileUpdated) {
            final profile = state is ProfileLoaded
                ? state.profile
                : (state as ProfileUpdated).profile;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(locale, profile),
                  SizedBox(height: 16.h),
                  _buildRatingsSection(locale),
                  SizedBox(height: 16.h),
                  _buildRadarChart(locale),
                  SizedBox(height: 16.h),
                  _buildGameHistory(locale),
                  if (!widget.isReadOnly) ...[
                    SizedBox(height: 16.h),
                    _buildLogoutSection(locale),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileHeader(LocaleProvider locale, dynamic profile) {
    final isOwnProfile = !widget.isReadOnly;
    final isOnline = isOwnProfile ? false : PresenceService.isOnline(profile.lastSeenAt);
    final statusText = isOwnProfile ? '' : PresenceService.formatLastSeen(profile.lastSeenAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  key: ValueKey(profile.avatarUrl),
                  radius: 50.r,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                if (!isOwnProfile)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18.r,
                      height: 18.r,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile.title != null && profile.title!.isNotEmpty) ...[
                  TitleBadge(title: profile.title!),
                  const SizedBox(width: 8),
                ],
                Text(
                  profile.nickname,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  _buildInfoRow(locale.get('profile_game_id_label'), profile.displayId.toString()),
                _buildInfoRow(locale.get('profile_reg_date_label'), _formatDate(profile.joinedAt)),
                if (!isOwnProfile) ...[
                  if (isOnline)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    )
                  else
                    _buildInfoRow(locale.get('profile_online_status'), statusText),
                ],
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
                      locale.get('profile_about_section'),
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

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection(LocaleProvider locale) {
    final currentState = context.read<ProfileCubit>().state;
    final profile = currentState is ProfileLoaded
        ? currentState.profile
        : (currentState is ProfileUpdated ? currentState.profile : null);

    final ratingModes = [
      {'key': 'standard_bullet', 'name': locale.get('profile_bullet'), 'icon': MdiIcons.bullet},
      {'key': 'standard_blitz', 'name': locale.get('profile_blitz'), 'icon': Icons.flash_on},
      {'key': 'standard_rapid', 'name': locale.get('profile_rapid'), 'icon': Icons.timer},
      {'key': 'puzzles', 'name': locale.get('profile_puzzles'), 'icon': MdiIcons.puzzle},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.get('profile_ratings'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ratingModes.map((mode) {
                  final ratingKey = mode['key'] as String;
                  final rating = profile?.ratings?[ratingKey];
                  final ratingValue = rating?.rating.toInt() ?? 1500;

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
                        Icon(mode['icon'] as IconData, size: 24, color: _getRatingColor(ratingValue)),
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
                          ratingValue.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getRatingColor(ratingValue),
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

  Widget _buildRadarChart(LocaleProvider locale) {
    final data = [0.8, 0.7, 0.6, 0.75, 0.85, 0.9];
    final titles = [
      locale.get('stat_tactics'),
      locale.get('stat_strategy'),
      locale.get('stat_endgame'),
      locale.get('stat_opening'),
      locale.get('stat_calculation'),
      locale.get('stat_speed'),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.get('profile_stats'),
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
                  locale.get('profile_history'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(locale.get('view_all')),
                ),
              ],
            ),
          ),
          ...games.map((g) => _GameHistoryTile(game: g, locale: locale)),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(LocaleProvider locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(locale),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          locale.get('logout'),
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

class _GameHistoryTile extends StatelessWidget {
  final Map<String, dynamic> game;
  final LocaleProvider locale;

  const _GameHistoryTile({required this.game, required this.locale});

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
      'win': locale.get('profile_win'),
      'loss': locale.get('profile_loss'),
      'draw': locale.get('profile_draw'),
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
      subtitle: Text('${game['mode']} • ${game['moves']} ${locale.get('profile_moves')}'),
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