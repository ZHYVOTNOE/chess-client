// lib/features/auth/presentation/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 🔥 Ждём загрузки профиля (если пользователь авторизован)
    final userProvider = context.read<UserProvider>();
    debugPrint('🔐 [AuthGate] _initialize called, userId: ${userProvider.userId}');
    
    if (userProvider.userId != null) {
      debugPrint('🔐 [AuthGate] User is authenticated, loading profile...');
      await userProvider.loadProfile();
      
      // 🔥 Загрузка настроек для авторизованного пользователя
      final settingsProvider = context.read<SettingsProvider>();
      debugPrint('🔐 [AuthGate] Loading settings for user: ${userProvider.userId!}');
      await settingsProvider.loadSettings(userProvider.userId!);
    } else {
      debugPrint('🔐 [AuthGate] User is not authenticated');
    }

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    // 🔥 Пока инициализация — показываем сплэш
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(locale.get('auth_loading_profile')),
            ],
          ),
        ),
      );
    }

    // 🔥 После инициализации — редирект по статусу авторизации
    final isAuthenticated = context.watch<UserProvider>().userId != null;

    if (isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          context.replace('/home');
        }
      });
      return const SizedBox.shrink();
    }

    return const WelcomeScreen();
  }
}