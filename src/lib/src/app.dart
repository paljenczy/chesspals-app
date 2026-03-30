import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'model/auth/lichess_account.dart';
import 'model/settings/locale_provider.dart';
import 'styles/theme.dart';
import 'view/auth/login_screen.dart';
import 'view/home/home_screen.dart';
import 'view/kid/kid_bot_select_screen.dart';
import 'view/kid/offline_game_screen.dart';
import 'view/puzzle/puzzle_screen.dart';
import 'view/play/play_human_screen.dart';
import 'view/game/online_game_screen.dart';
import 'view/game/analysis_screen.dart';
import 'view/settings/settings_screen.dart';

import 'package:flutter/material.dart' show MaterialApp;
import '../l10n/app_localizations.dart';

// Redirect to /login if no account loaded yet.
// GoRouter needs a listenable to re-evaluate redirects when auth changes.
GoRouter _buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/bot',
    redirect: (context, state) async {
      // Skip redirect for login screen and analysis (passed via extra)
      if (state.matchedLocation == '/login') return null;
      if (state.matchedLocation == '/analysis') return null;
      final account = ref.read(accountProvider);
      // Still loading — don't redirect yet
      if (account.isLoading) return null;
      // Not logged in → login screen
      if (account.value == null) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/bot',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KidBotSelectScreen(),
            ),
            routes: [
              GoRoute(
                path: 'game/:level',
                builder: (context, state) => OfflineGameScreen(
                  level: int.parse(state.pathParameters['level']!),
                  characterIndex: int.parse(
                    state.uri.queryParameters['char'] ?? '0',
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/puzzles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PuzzleScreen(),
            ),
          ),
          GoRoute(
            path: '/play',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlayHumanScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) => OnlineGameScreen(
          gameId: state.pathParameters['id']!,
          playerSide: state.uri.queryParameters['side'] ?? 'white',
          from: state.uri.queryParameters['from'] ?? 'play',
          characterIndex: int.tryParse(state.uri.queryParameters['char'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return AnalysisScreen(
            moves: args['moves'] as List<NormalMove>,
            startingFen: args['fen'] as String,
            playerSide: args['side'] as Side,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

class ChessPalsApp extends ConsumerWidget {
  const ChessPalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch account so router rebuilds when login state changes
    ref.watch(accountProvider);
    final router = _buildRouter(ref);

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'ChessPals',
      theme: ChessPalsTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
    );
  }
}
