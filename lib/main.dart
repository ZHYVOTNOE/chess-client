import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/auth_refresh_listenable.dart';
import 'core/providers/game_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/presence_service.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/matchmaking/presentation/cubits/matchmaking_cubit.dart';
import 'features/profile/profile_di.dart';
import 'features/profile/presentation/cubits/profile_cubit.dart'; // ✅ ДОБАВЛЕНО
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/settings_di.dart';
import 'features/play/game_di.dart';
import 'features/social/presentation/cubits/social_cubit.dart';
import 'features/social/social_di.dart';
import 'features/leaderboard/leaderboard_di.dart';

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

  final currentSession = Supabase.instance.client.auth.currentSession;
  final currentUser = Supabase.instance.client.auth.currentUser;
  print('🚀 [Main] After Supabase.init:');
  print('   currentSession = ${currentSession != null ? "YES" : "NO"}');
  print('   currentUser = ${currentUser?.id ?? "NULL"}');

  sl.registerSingleton<PresenceService>(PresenceService());
  print('✅ [Main] PresenceService registered: ${sl<PresenceService>().hashCode}');

  // ✅ ПРАВИЛЬНЫЙ ПОРЯДОК:
  initGameDI();       // 1️⃣ Сначала play (регистрирует RatingsRemoteDataSource + RatingRepository)
  initProfile();      // 2️⃣ Потом profile (использует RatingRepository)
  initSettingsDI();
  initSocialDI();
  initLeaderboardDI();

  final localeProvider = LocaleProvider();
  await localeProvider.load('en');

  sl.registerSingleton<LocaleProvider>(localeProvider);

  final authProvider = AuthProvider();
  final userProvider = UserProvider();

  final authRefreshListenable = AuthRefreshListenable(authProvider);

  userProvider.startBackgroundRefresh();
  unawaited(userProvider.loadProfile());

  final settingsRepo = SettingsRepository(Supabase.instance.client);
  final settingsProvider = SettingsProvider(settingsRepo);

  runApp(
    ScreenUtilInit(
      designSize: const Size(388, 863),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: userProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider(create: (_) => GameProvider()),

          // ✅ ДОБАВЛЕНО: ProfileCubit должен быть доступен всему приложению
          BlocProvider<ProfileCubit>(
            create: (_) => sl<ProfileCubit>(),
          ),

          BlocProvider(create: (_) => sl<MatchmakingCubit>()),
          BlocProvider(create: (_) => sl<SocialCubit>()),
        ],
        child: MyApp(authRefreshListenable: authRefreshListenable),
      ),
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