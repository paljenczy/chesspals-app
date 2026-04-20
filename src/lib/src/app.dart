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

// Bridges Riverpod's accountProvider to a Listenable so GoRouter
// re-evaluates its redirect whenever auth state changes.
class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

GoRouter _buildRouter(WidgetRef ref, ChangeNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      if (state.matchedLocation == '/analysis') return null;
      final account = ref.read(accountProvider);
      // Still loading — stay on splash
      if (account.isLoading) return null;
      final loggedIn = account.value != null;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash';
      // Not logged in → login screen
      if (!loggedIn && state.matchedLocation != '/login') return '/login';
      // Logged in but on splash or login → go to home
      if (loggedIn && onAuth) return '/bot';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
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
    errorBuilder: (context, state) => const _SplashScreen(),
  );
}

class ChessPalsApp extends ConsumerStatefulWidget {
  const ChessPalsApp({super.key});

  @override
  ConsumerState<ChessPalsApp> createState() => _ChessPalsAppState();
}

class _ChessPalsAppState extends ConsumerState<ChessPalsApp> {
  late final GoRouter _router;
  final _authNotifier = _AuthNotifier();

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(ref, _authNotifier);
    ref.listenManual(accountProvider, (_, __) => _authNotifier.notify());
  }

  @override
  void dispose() {
    _router.dispose();
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFFFFF),
      child: Center(
        child: Image(
          image: AssetImage('assets/icon/app_icon.png'),
          width: 160,
          height: 160,
        ),
      ),
    );
  }
}
