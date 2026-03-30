import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'puzzle.dart';
import '../../network/lichess_client.dart';
import '../../model/auth/lichess_account.dart';
import '../game/offline_game_controller.dart' show toValidMoves;

enum PuzzleResult { correct, wrong, solved }
enum PuzzleMode { solving, viewingSolution, review }

class PuzzleState {
  const PuzzleState({
    required this.puzzle,
    required this.position,
    required this.solutionIndex,
    required this.isDaily,
    required this.userSide,
    this.mode = PuzzleMode.solving,
    this.result,
    this.lastMove,
    this.hintSquare,
    this.positionHistory = const [],
    this.moveHistory = const [],
    this.reviewIndex = 0,
  });

  final Puzzle puzzle;
  final Position position;
  final int solutionIndex;
  final bool isDaily;
  final Side userSide;
  final PuzzleMode mode;
  final PuzzleResult? result;
  final NormalMove? lastMove;
  final Square? hintSquare;
  final List<Position> positionHistory;
  final List<NormalMove> moveHistory;
  final int reviewIndex;

  String get fen => position.fen;
  Side get sideToMove => position.turn;
  bool get isCheck => position.isCheck;
  bool get isSolved => solutionIndex >= puzzle.solution.length;

  /// Board orientation: show from the user's perspective.
  Side get orientation => userSide;

  IMap<Square, ISet<Square>> get validMoves {
    if (result != null) return IMap(); // lock board during animation/result
    if (mode != PuzzleMode.solving) return IMap(); // lock during solution/review
    return toValidMoves(position.legalMoves);
  }

  PuzzleState copyWith({
    Position? position,
    int? solutionIndex,
    PuzzleMode? mode,
    PuzzleResult? result,
    NormalMove? lastMove,
    Square? hintSquare,
    List<Position>? positionHistory,
    List<NormalMove>? moveHistory,
    int? reviewIndex,
    bool clearResult = false,
    bool clearHint = false,
    bool clearLastMove = false,
  }) =>
      PuzzleState(
        puzzle: puzzle,
        position: position ?? this.position,
        solutionIndex: solutionIndex ?? this.solutionIndex,
        isDaily: isDaily,
        userSide: userSide,
        mode: mode ?? this.mode,
        result: clearResult ? null : (result ?? this.result),
        lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
        hintSquare: clearHint ? null : (hintSquare ?? this.hintSquare),
        positionHistory: positionHistory ?? this.positionHistory,
        moveHistory: moveHistory ?? this.moveHistory,
        reviewIndex: reviewIndex ?? this.reviewIndex,
      );
}

class PuzzleController extends AsyncNotifier<PuzzleState?> {
  @override
  Future<PuzzleState?> build() async => null;

  Future<void> loadDailyPuzzle() async {
    state = const AsyncLoading();
    _failedOnce = false;
    try {
      final client = LichessClient();
      final json = await client.fetchDailyPuzzle();
      final puzzle = Puzzle.fromLichessJson(json, 'daily');
      state = AsyncData(_stateForPuzzle(puzzle, isDaily: true));
      _autoPlayFirstMove();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadNextPuzzle() async {
    state = const AsyncLoading();
    _failedOnce = false;
    try {
      final client = LichessClient();
      // Use the player's puzzle rating to fetch appropriately-rated puzzles
      final account = ref.read(accountProvider).value;
      final puzzleRating = account?.puzzleRating;
      final puzzles = await client.fetchPuzzleBatch(
        'mix',
        count: 5,
        ratingMin: puzzleRating != null ? puzzleRating - 100 : null,
        ratingMax: puzzleRating != null ? puzzleRating + 100 : null,
      );
      if (puzzles.isEmpty) throw Exception('No puzzles available');
      final puzzle = Puzzle.fromLichessJson(puzzles.first, 'mix');
      state = AsyncData(_stateForPuzzle(puzzle, isDaily: false));
      _autoPlayFirstMove();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  PuzzleState _stateForPuzzle(Puzzle puzzle, {required bool isDaily}) {
    // Start from the penultimate position (before the triggering move).
    // The last PGN move will animate in as the trigger.
    Position pos;
    try {
      pos = Chess.fromSetup(Setup.parseFen(puzzle.fen));
    } catch (_) {
      pos = Chess.initial;
    }
    // The user plays the side to move AFTER the trigger.
    // That's the turn in fenAfterTrigger.
    Position posAfterTrigger;
    try {
      posAfterTrigger = Chess.fromSetup(Setup.parseFen(puzzle.fenAfterTrigger));
    } catch (_) {
      posAfterTrigger = pos;
    }
    final userSide = posAfterTrigger.turn;
    return PuzzleState(
      puzzle: puzzle,
      position: pos,
      solutionIndex: 0,
      isDaily: isDaily,
      userSide: userSide,
    );
  }

  /// Auto-play the triggering move (last PGN move) after a short delay so the
  /// user sees the "before" position, then the move animates in.
  /// After this, solutionIndex stays at 0 — solution[0] is the user's first move.
  Future<void> _autoPlayFirstMove() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final current = state.value;
    if (current == null || current.solutionIndex != 0) return;

    final triggerUci = current.puzzle.triggerUci;
    if (triggerUci == null) return;

    final move = _parseUci(triggerUci);
    if (move == null) return;

    Position newPos;
    try {
      newPos = current.position.play(move);
    } catch (_) {
      return;
    }

    // solutionIndex stays at 0 — the user's first move is solution[0]
    state = AsyncData(current.copyWith(
      position: newPos,
      lastMove: move,
    ));
  }

  bool _failedOnce = false;

  Future<void> onMove(Move rawMove, {bool? viaDragAndDrop}) async {
    if (rawMove is! NormalMove) return;
    final current = state.value;
    if (current == null || current.result != null) return;
    if (current.mode != PuzzleMode.solving) return;

    final expectedUci = current.puzzle.solution[current.solutionIndex];
    final moveUci = rawMove.uci;

    if (moveUci != expectedUci) {
      // Wrong move — show it on the board briefly, then snap back
      Position wrongPos;
      try {
        wrongPos = current.position.play(rawMove);
      } catch (_) {
        return; // illegal move, ignore
      }

      // Submit fail on first wrong attempt (like Lichess)
      if (!_failedOnce) {
        _failedOnce = true;
        _submitResult(current.puzzle.id, win: false);
      }

      // Show the piece on the wrong square
      state = AsyncData(current.copyWith(
        position: wrongPos,
        lastMove: rawMove,
        result: PuzzleResult.wrong,
        clearHint: true,
      ));

      // Wait, then snap back to original position
      await Future.delayed(const Duration(milliseconds: 800));
      state = AsyncData(current.copyWith(clearResult: true, clearHint: true));
      return;
    }

    Position newPos;
    try {
      newPos = current.position.play(rawMove);
    } catch (_) {
      return;
    }

    final nextIndex = current.solutionIndex + 1;
    final isSolved = nextIndex >= current.puzzle.solution.length;

    if (isSolved) {
      state = AsyncData(current.copyWith(
        position: newPos,
        solutionIndex: nextIndex,
        result: PuzzleResult.solved,
        lastMove: rawMove,
        clearHint: true,
      ));
      if (!_failedOnce) _submitResult(current.puzzle.id, win: true);
      return;
    }

    // Show correct, then play opponent's response
    final afterPlayer = current.copyWith(
      position: newPos,
      solutionIndex: nextIndex,
      result: PuzzleResult.correct,
      lastMove: rawMove,
      clearHint: true,
    );
    state = AsyncData(afterPlayer);

    await Future.delayed(const Duration(milliseconds: 600));

    final opponentUci = current.puzzle.solution[nextIndex];
    final opponentMove = _parseUci(opponentUci);
    if (opponentMove == null) return;

    Position afterOpponent;
    try {
      afterOpponent = newPos.play(opponentMove);
    } catch (_) {
      return;
    }

    final nextSolutionIndex = nextIndex + 1;
    final puzzleSolved = nextSolutionIndex >= current.puzzle.solution.length;
    state = AsyncData(afterPlayer.copyWith(
      position: afterOpponent,
      solutionIndex: nextSolutionIndex,
      result: puzzleSolved ? PuzzleResult.solved : null,
      clearResult: !puzzleSolved,
      lastMove: opponentMove,
    ));

    if (nextSolutionIndex >= current.puzzle.solution.length && !_failedOnce) {
      _submitResult(current.puzzle.id, win: true);
    }
  }

  void _submitResult(String puzzleId, {required bool win}) {
    final client = LichessClient();
    client
        .submitPuzzleResults('mix', [(id: puzzleId, win: win)])
        .catchError((_) {}); // best-effort, ignore errors
  }

  void showHint() {
    final current = state.value;
    if (current == null || current.mode != PuzzleMode.solving) return;
    if (current.solutionIndex >= current.puzzle.solution.length) return;

    final uci = current.puzzle.solution[current.solutionIndex];
    final move = _parseUci(uci);
    if (move == null) return;

    state = AsyncData(current.copyWith(hintSquare: move.from));
  }

  void clearHint() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearHint: true));
  }

  Future<void> viewSolution() async {
    final current = state.value;
    if (current == null) return;
    if (current.mode == PuzzleMode.review) return;

    // Submit loss if not already failed
    if (!_failedOnce) {
      _failedOnce = true;
      _submitResult(current.puzzle.id, win: false);
    }

    // Build position history from the beginning of the puzzle
    final positions = <Position>[current.position];
    final moves = <NormalMove>[];
    var pos = current.position;

    // Set mode to viewingSolution and clear hint
    state = AsyncData(current.copyWith(
      mode: PuzzleMode.viewingSolution,
      clearHint: true,
      clearResult: true,
    ));

    // Auto-play remaining solution moves
    for (int i = current.solutionIndex;
        i < current.puzzle.solution.length;
        i++) {
      await Future.delayed(const Duration(milliseconds: 800));

      final uci = current.puzzle.solution[i];
      final move = _parseUci(uci);
      if (move == null) break;

      try {
        pos = pos.play(move);
      } catch (_) {
        break;
      }

      positions.add(pos);
      moves.add(move);

      state = AsyncData(state.value!.copyWith(
        position: pos,
        lastMove: move,
        solutionIndex: i + 1,
      ));
    }

    // Enter review mode
    state = AsyncData(state.value!.copyWith(
      mode: PuzzleMode.review,
      result: PuzzleResult.solved,
      positionHistory: positions,
      moveHistory: moves,
      reviewIndex: positions.length - 1,
    ));
  }

  void reviewStepBack() {
    final current = state.value;
    if (current == null || current.mode != PuzzleMode.review) return;
    if (current.reviewIndex <= 0) return;

    final newIndex = current.reviewIndex - 1;
    state = AsyncData(current.copyWith(
      reviewIndex: newIndex,
      position: current.positionHistory[newIndex],
      lastMove: newIndex > 0 ? current.moveHistory[newIndex - 1] : null,
      clearLastMove: newIndex == 0,
    ));
  }

  void reviewStepForward() {
    final current = state.value;
    if (current == null || current.mode != PuzzleMode.review) return;
    if (current.reviewIndex >= current.positionHistory.length - 1) return;

    final newIndex = current.reviewIndex + 1;
    state = AsyncData(current.copyWith(
      reviewIndex: newIndex,
      position: current.positionHistory[newIndex],
      lastMove: current.moveHistory[newIndex - 1],
    ));
  }

  void reviewGoToStart() {
    final current = state.value;
    if (current == null || current.mode != PuzzleMode.review) return;
    state = AsyncData(current.copyWith(
      reviewIndex: 0,
      position: current.positionHistory[0],
      clearLastMove: true,
    ));
  }

  void reviewGoToEnd() {
    final current = state.value;
    if (current == null || current.mode != PuzzleMode.review) return;
    final lastIndex = current.positionHistory.length - 1;
    state = AsyncData(current.copyWith(
      reviewIndex: lastIndex,
      position: current.positionHistory[lastIndex],
      lastMove: current.moveHistory.isNotEmpty
          ? current.moveHistory.last
          : null,
    ));
  }

  NormalMove? _parseUci(String uci) {
    if (uci.length < 4) return null;
    try {
      final from = Square.fromName(uci.substring(0, 2));
      final to = Square.fromName(uci.substring(2, 4));
      Role? promotion;
      if (uci.length == 5) promotion = Role.fromChar(uci[4]);
      return NormalMove(from: from, to: to, promotion: promotion);
    } catch (_) {
      return null;
    }
  }
}

final puzzleControllerProvider =
    AsyncNotifierProvider<PuzzleController, PuzzleState?>(
  PuzzleController.new,
);
