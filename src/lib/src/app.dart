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
import 'view/kid/bot_game_screen.dart';
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
        path: '/bot/game/:level',
        builder: (context, state) => BotGameScreen(
          level: int.parse(state.pathParameters['level']!),
          characterIndex: int.parse(
            state.uri.queryParameters['char'] ?? '0',
          ),
        ),
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

class ChessPalsApp extends ConsumerStatefulWidget {
  const ChessPalsApp({super.key});

  @override
  ConsumerState<ChessPalsApp> createState() => _ChessPalsAppState();
}

class _ChessPalsAppState extends ConsumerState<ChessPalsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(ref);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch account so redirect re-evaluates on login/logout
    ref.watch(accountProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'ChessPals',
      theme: ChessPalsTheme.light,
      routerConfig: _router,
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
