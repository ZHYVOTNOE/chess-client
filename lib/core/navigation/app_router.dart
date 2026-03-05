import 'package:client/features/game_hub/presentation/play_bot/play_bot_screen.dart';
import 'package:client/features/game_hub/presentation/play_friend/play_friend_screens.dart';
import 'package:client/features/game_hub/presentation/tournament/create_daily_tournament_screen.dart';
import 'package:client/features/game_hub/presentation/tournament/create_live_tournament_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/registration/verification_screen.dart';
import '../../features/auth/presentation/welcome/welcome_screen.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../features/auth/presentation/registration/registration_screen.dart';
import '../../features/auth/presentation/forgot_password/forgot_password_screen.dart';
import '../../features/game_hub/presentation/game_hub_screen.dart';
import '../../features/game_hub/presentation/quick_match/quick_match_screen.dart';
import '../../features/game_hub/presentation/tournament/join_daily_tournament_screen.dart';
import '../../features/game_hub/presentation/tournament/join_live_tournament_screen.dart';
import '../../features/game_hub/presentation/tournament/tournament_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/presentation/learn_hub_screen.dart';
import '../../features/learn/presentation/openings/openings_screen.dart';
import '../../features/learn/presentation/puzzles/puzzles_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/profile/profile_screen.dart';
import 'main_shell.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
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
      path: '/verify',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return VerificationScreen(email: email);
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
                  builder: (context, state) => const QuickMatchScreen(),
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
                  builder: (context, state) => const PlayFriendScreen(),
                ),
                // Игра с ботом
                GoRoute(
                  path: 'bot',
                  builder: (context, state) => const PlayBotScreen(),
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
