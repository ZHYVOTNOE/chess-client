import 'package:client/features/auth/presentation/screens/auth_gate.dart';
import 'package:client/features/auth/presentation/screens/welcome_screen.dart';
import 'package:client/features/game_hub/presentation/tournament/create_daily_tournament_screen.dart';
import 'package:client/features/game_hub/presentation/tournament/create_live_tournament_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/game_hub/presentation/game_hub_screen.dart';
import '../../features/play/presentation/setup_game_screen.dart';
import '../../features/game_hub/presentation/tournament/join_daily_tournament_screen.dart';
import '../../features/game_hub/presentation/tournament/join_live_tournament_screen.dart';
import '../../features/game_hub/presentation/tournament/tournament_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/presentation/learn_hub_screen.dart';
import '../../features/learn/presentation/openings/openings_screen.dart';
import '../../features/learn/presentation/puzzles/puzzles_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/play/presentation/board_screen.dart';
import '../../features/play/presentation/widgets/game_config.dart';
import '../../features/profile/profile_screen.dart';
import 'auth_refresh_listenable.dart';
import 'main_shell.dart';

GoRouter appRouter(AuthRefreshListenable authRefreshListenable) => GoRouter(
  // 🔥 КРИТИЧНО: пересчитывать redirect при изменении AuthProvider
  refreshListenable: authRefreshListenable,

  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final directSession = Supabase.instance.client.auth.currentSession;

    // 🔥 Объединяем оба источника истины
    final isAuthenticated = auth.isAuthenticated || directSession != null;

    // 🔥 Логирование для отладки
    print('🔐 [Redirect] location=${state.matchedLocation}, '
        'isLoading=${auth.isLoading}, '
        'auth.isAuthenticated=${auth.isAuthenticated}, '
        'directSession=${directSession != null}, '
        'final isAuthenticated=$isAuthenticated');

    // 🔥 Пока загружается И нет прямой сессии — показываем лоадер
    if (auth.isLoading && directSession == null) {
      print('🔐 [Redirect] Still loading, returning null');
      return null;
    }

    final location = state.matchedLocation;
    final isAuthRoute = [
      '/welcome', '/login', '/registration', '/forgot-password',
    ].contains(location);

    // 🔥 Явно обрабатываем корень
    if (location == '/') {
      print('🔐 [Redirect] Root path → ${isAuthenticated ? "/home" : "/welcome"}');
      return isAuthenticated ? '/home' : '/welcome';
    }

    // 🔥 НЕ авторизован + защищённый экран → /welcome
    if (!isAuthenticated && !isAuthRoute) {
      print('🔐 [Redirect] Not auth + protected → /welcome');
      return '/welcome';
    }

    // 🔥 Авторизован + экран аутентификации → /home
    if (isAuthenticated && isAuthRoute) {
      print('🔐 [Redirect] Auth + auth route → /home');
      return '/home';
    }

    print('🔐 [Redirect] All good, returning null');
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthGate();
      },
    ),
    GoRoute(
      path: '/welcome',
      builder: (BuildContext context, GoRouterState state) {
        return const WelcomeScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/registration',
      builder: (BuildContext context, GoRouterState state) {
        return const RegistrationScreen();
      },
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordScreen();
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(
          navigationShell: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/game',
              builder: (context, state) => const GameHubScreen(),
              routes: [
                // Быстрая игра
                GoRoute(
                  path: 'quick',
                  builder: (context, state) => const SetupGameScreen(initialMode: 'random'),
                ),
                GoRoute(
                  path: 'setup/:mode',
                  name: 'game-setup',
                  builder: (context, state) {
                    final mode = state.pathParameters['mode'];
                    return SetupGameScreen(initialMode: mode);
                  },
                ),
                GoRoute(
                  path: 'tournament',
                  builder: (context, state) => const TournamentScreen(),
                  routes: [
                    GoRoute(
                      path: 'join-live',
                      builder: (context, state) => const JoinLiveTournamentScreen(),
                    ),
                    GoRoute(
                      path: 'create-live',
                      builder: (context, state) => const CreateLiveTournamentScreen(),
                    ),
                    GoRoute(
                      path: 'join-daily',
                      builder: (context, state) => const JoinDailyTournamentScreen(),
                    ),
                    GoRoute(
                      path: 'create-daily',
                      builder: (context, state) => const CreateDailyTournamentScreen(),
                    ),
                  ],
                ),
                // Игра с другом
                GoRoute(
                  path: 'friend',
                  builder: (context, state) => const SetupGameScreen(initialMode: 'friend'),
                ),
                // Игра с ботом
                GoRoute(
                  path: 'bot',
                  builder: (context, state) => const SetupGameScreen(initialMode: 'computer'),
                ),
                GoRoute(
                  path: 'play',
                  builder: (context, state) {
                    final config = state.extra as GameConfig;
                    return BoardScreen(config: config);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/learn',
              builder: (context, state) => const LearnHubScreen(),
              routes: [
                GoRoute(
                  path: 'puzzles',
                  builder: (context, state) => const PuzzlesScreen(),
                ),
                GoRoute(
                  path: 'openings',
                  builder: (context, state) => const OpeningsScreen(),
                ),
                /*GoRoute(
                  path: 'strategy',
                  builder: (context, state) => const StrategyScreen(),
                ),
                GoRoute(
                  path: 'endgames',
                  builder: (context, state) => const EndgamesScreen(),
                ),*/
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (context, state) => const MoreScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
