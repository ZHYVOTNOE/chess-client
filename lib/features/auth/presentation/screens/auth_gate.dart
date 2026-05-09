import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  bool _handledInitialAuth = false;

  @override
  void initState() {
    super.initState();

    _authStream =
        Supabase.instance.client.auth.onAuthStateChange;
  }

  void _handleNavigation(BuildContext context) {
    final session =
        Supabase.instance.client.auth.currentSession;

    final currentLocation =
        GoRouterState.of(context).matchedLocation;

    if (session != null &&
        currentLocation != '/home') {
      context.go('/home');
      return;
    }

    if (session == null &&
        currentLocation != '/welcome') {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (!_handledInitialAuth) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          _handledInitialAuth = true;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _handleNavigation(context);
        });

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}