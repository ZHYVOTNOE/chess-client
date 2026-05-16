import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/auth_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 🔥 Просто показываем лоадер — навигация в redirect GoRouter
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(auth.isLoading ? 'Загрузка...' : 'Проверка сессии...'),
          ],
        ),
      ),
    );
  }
}