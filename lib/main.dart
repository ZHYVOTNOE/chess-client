import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/auth_refresh_listenable.dart';
import 'core/providers/game_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/domain/auth_provider.dart';
import 'features/profile/profile_di.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/settings_di.dart';
import 'features/play/game_di.dart';
import 'features/play/presentation/cubits/matchmaking_cubit.dart';
import 'features/social/presentation/cubits/social_cubit.dart';
import 'features/social/social_di.dart';

final sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  initProfile();
  initSettingsDI();
  initGameDI();
  initSocialDI();

  final localeProvider = LocaleProvider();
  await localeProvider.load('en');

  // Register LocaleProvider in DI for SettingsCubit
  sl.registerSingleton<LocaleProvider>(localeProvider);

  final authProvider = AuthProvider();
  final userProvider = UserProvider();

  final authRefreshListenable = AuthRefreshListenable(authProvider);

  userProvider.startBackgroundRefresh();
  unawaited(userProvider.loadProfile());


  final settingsRepo = SettingsRepository(Supabase.instance.client);
  final settingsProvider = SettingsProvider(settingsRepo);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        BlocProvider(create: (_) => sl<MatchmakingCubit>()),
        BlocProvider(create: (_) => sl<SocialCubit>()),
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
