import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session != null) {
      Future.microtask(() {
        if (mounted) {
          context.go('/home');
        }
      });
    } else {
      Future.microtask(() {
        if (mounted) {
          context.go('/welcome');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}