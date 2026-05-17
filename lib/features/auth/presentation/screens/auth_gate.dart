// lib/features/auth/presentation/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
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
    if (userProvider.userId != null) {
      await userProvider.loadProfile();
    }

    // 🔥 Здесь можно добавить другие инициализации:
    // - Загрузка настроек
    // - Кэширование рейтингов

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Пока инициализация — показываем сплэш
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка профиля...'),
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