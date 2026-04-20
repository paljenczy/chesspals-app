import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/puzzle/puzzle_controller.dart';
import '../../model/puzzle/puzzle_stars.dart';

/// Full-screen puzzle solving view (no bottom navigation bar).
class PuzzleSolveScreen extends ConsumerWidget {
  const PuzzleSolveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(puzzleControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(puzzleControllerProvider.notifier).backToSetup();
          context.go('/puzzles');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: puzzleState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (state) {
            if (state == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/puzzles');
              });
              return const SizedBox.shrink();
            }
            return _PuzzleView(state: state);
          },
        ),
      ),
    );
  }
}

class _PuzzleView extends ConsumerWidget {
  const _PuzzleView({required this.state});
  final PuzzleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final controller = ref.read(puzzleControllerProvider.notifier);
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Reserve space for header (~52), subtitle (~28), and controls (~120).
          // Board fills the rest, capped at screen width.
          final maxBoard = constraints.maxHeight - 200;
          final boardSize = maxBoard.clamp(200.0, screenWidth);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref
                            .read(puzzleControllerProvider.notifier)
                            .backToSetup();
                        context.go('/puzzles');
                      },
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l.puzzleChangeSettings,
                    ),
                    Expanded(
                      child: Text(
                        state.isDaily
                            ? l.puzzleDailyTitle
                            : l.puzzleSetupTitle,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  state.mode == PuzzleMode.viewingSolution
                      ? l.puzzleViewingSolution
                      : state.mode == PuzzleMode.review
                          ? l.puzzleSolved
                          : state.sideToMove == Side.white
                              ? l.puzzleWhiteToMove
                              : l.puzzleBlackToMove,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),

              // Board
              Center(
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: Chessboard(
                    size: boardSize,
                    orientation: state.orientation,
                    fen: state.fen,
                    lastMove: state.lastMove,
                    shapes: state.hintSquare != null
                        ? ISet({
                            Circle(
                              color: const Color(0x8015781B),
                              orig: state.hintSquare!,
                            ),
                          })
                        : null,
                    game: GameData(
                      playerSide: state.orientation == Side.white
                          ? PlayerSide.white
                          : PlayerSide.black,
                      validMoves: state.validMoves,
                      sideToMove: state.sideToMove,
                      isCheck: state.isCheck,
                      promotionMove: null,
                      onMove: (move, {viaDragAndDrop}) => controller.onMove(
                          move,
                          viaDragAndDrop: viaDragAndDrop),
                      onPromotionSelection: (_) {},
                    ),
                    settings: ChessboardSettings(
                      colorScheme: ChessboardColorScheme.green,
                      pieceAssets: PieceSet.cburnett.assets,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Stars & streak bar
              const _StarsBar(),

              // Result overlay
              if (state.result != null)
                _ResultBanner(result: state.result!),

              // Toolbar: hint + view solution (during solving)
              if (state.mode == PuzzleMode.solving && state.result == null)
                _PuzzleToolbar(controller: controller),

              // Review navigation (during review mode)
              if (state.mode == PuzzleMode.review)
                _MoveNavigationBar(controller: controller, state: state),

              // Continue Training button (after solved or in review)
              if (state.result == PuzzleResult.solved ||
                  state.mode == PuzzleMode.review)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => controller.loadNextPuzzle(),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(l.puzzleContinueTraining),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _StarsBar extends ConsumerWidget {
  const _StarsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final stars = ref.watch(puzzleStarsProvider);

    final bigStars = stars.stars ~/ 5;
    final smallStars = stars.stars % 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (bigStars > 0)
            ...List.generate(
              bigStars.clamp(0, 6),
              (_) => const Text('🌟', style: TextStyle(fontSize: 20)),
            ),
          if (smallStars > 0)
            ...List.generate(
              smallStars.clamp(0, 4),
              (_) => const Text('⭐', style: TextStyle(fontSize: 16)),
            ),
          if (stars.stars == 0)
            const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${stars.stars}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.amber[800],
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '|',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
          ),
          if (stars.streak >= 1) ...[
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              l.puzzleStreakLabel(stars.streak),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange[600],
                  ),
            ),
          ] else ...[
            const Text('💪', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              l.puzzleStreakStart,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PuzzleToolbar extends StatelessWidget {
  const _PuzzleToolbar({required this.controller});
  final PuzzleController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => controller.showHint(),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: Text(l.puzzleHint),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => controller.viewSolution(),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(l.puzzleViewSolution),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveNavigationBar extends StatelessWidget {
  const _MoveNavigationBar({required this.controller, required this.state});
  final PuzzleController controller;
  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final atStart = state.reviewIndex <= 0;
    final atEnd = state.positionHistory.isEmpty ||
        state.reviewIndex >= state.positionHistory.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: atStart ? null : () => controller.reviewGoToStart(),
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Go to start',
          ),
          IconButton(
            onPressed: atStart ? null : () => controller.reviewStepBack(),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Step back',
          ),
          IconButton(
            onPressed: atEnd ? null : () => controller.reviewStepForward(),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Step forward',
          ),
          IconButton(
            onPressed: atEnd ? null : () => controller.reviewGoToEnd(),
            icon: const Icon(Icons.skip_next),
            tooltip: 'Go to end',
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result});
  final PuzzleResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (text, color, icon) = switch (result) {
      PuzzleResult.correct => (l.puzzleCorrect, Colors.green[700]!, '✅'),
      PuzzleResult.wrong => (l.puzzleWrong, Colors.red[700]!, '❌'),
      PuzzleResult.solved => (l.puzzleSolved, Colors.green[800]!, '🏆'),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isNetworkError = message.contains('SocketException') ||
        message.contains('connection') ||
        message.contains('host lookup');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? l.puzzleErrorNoInternet : l.puzzleErrorGeneric,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(puzzleControllerProvider.notifier).backToSetup();
                context.go('/puzzles');
              },
              icon: const Icon(Icons.refresh),
              label: Text(l.puzzleTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
