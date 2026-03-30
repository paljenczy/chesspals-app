import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/puzzle/puzzle_controller.dart';

/// Simplified puzzle tab — Daily Puzzle + "More Puzzles" batch.
/// Storm and Streak are intentionally omitted for the kid-friendly MVP.
class PuzzleScreen extends ConsumerWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(puzzleControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: puzzleState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (state) => state == null
            ? const _NoPuzzleView()
            : _PuzzleView(state: state),
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
    final boardSize =
        MediaQuery.of(context).size.width.clamp(200.0, 500.0).toDouble();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              state.isDaily ? l.puzzleDailyTitle : l.puzzleTitle(state.puzzle.id),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                  onMove: (move, {viaDragAndDrop}) =>
                      controller.onMove(move, viaDragAndDrop: viaDragAndDrop),
                  onPromotionSelection: (_) {},
                ),
                settings: ChessboardSettings(
                  colorScheme: ChessboardColorScheme.green,
                  pieceAssets: PieceSet.cburnett.assets,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

          const SizedBox(height: 12),
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

class _NoPuzzleView extends ConsumerWidget {
  const _NoPuzzleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧩', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            l.puzzleReadyText,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(puzzleControllerProvider.notifier).loadDailyPuzzle(),
            icon: const Icon(Icons.today),
            label: Text(l.puzzleButtonLoad),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(puzzleControllerProvider.notifier).loadNextPuzzle(),
            icon: const Icon(Icons.shuffle),
            label: Text(l.puzzleButtonRandom),
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
              onPressed: () =>
                  ref.read(puzzleControllerProvider.notifier).loadDailyPuzzle(),
              icon: const Icon(Icons.refresh),
              label: Text(l.puzzleTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
