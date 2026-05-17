import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/auth_refresh_listenable.dart';
import 'core/providers/game_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/domain/auth_provider.dart';
import 'features/profile/profile_di.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  initProfile();

  final localeProvider = LocaleProvider();
  await localeProvider.load('en');

  final authProvider = AuthProvider();
  final userProvider = UserProvider();
  final authRefreshListenable = AuthRefreshListenable(authProvider);

  userProvider.startBackgroundRefresh();
  unawaited(userProvider.loadProfile());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MyApp(authRefreshListenable: authRefreshListenable),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthRefreshListenable authRefreshListenable;

  const MyApp({super.key, required this.authRefreshListenable});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter(authRefreshListenable),
    );
  }
}
