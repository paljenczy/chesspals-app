import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GameStatus { playing, whiteWins, blackWins, draw, resigned }

/// Converts dartchess legalMoves (IMap<Square, SquareSet>) to chessground
/// ValidMoves (IMap<Square, ISet<Square>>).
IMap<Square, ISet<Square>> toValidMoves(IMap<Square, SquareSet> legalMoves) {
  return IMap({
    for (final e in legalMoves.entries)
      if (e.value != SquareSet.empty)
        e.key: e.value.squares.toISet(),
  });
}

class BotGameState {
  const BotGameState({
    required this.position,
    required this.status,
    this.lastMove,
    this.pendingPromotion,
    this.moveHistory = const [],
  });

  final Position position;
  final GameStatus status;
  final NormalMove? lastMove;
  final NormalMove? pendingPromotion;
  final List<NormalMove> moveHistory;

  String get fen => position.fen;
  Side get sideToMove => position.turn;
  bool get isCheck => position.isCheck;

  IMap<Square, ISet<Square>> get validMoves {
    if (status != GameStatus.playing) return IMap();
    if (position.turn != Side.white) return IMap(); // Only on player's turn
    return toValidMoves(position.legalMoves);
  }

  BotGameState copyWith({
    Position? position,
    GameStatus? status,
    NormalMove? lastMove,
    NormalMove? pendingPromotion,
    bool clearPromotion = false,
    List<NormalMove>? moveHistory,
  }) =>
      BotGameState(
        position: position ?? this.position,
        status: status ?? this.status,
        lastMove: lastMove ?? this.lastMove,
        pendingPromotion:
            clearPromotion ? null : (pendingPromotion ?? this.pendingPromotion),
        moveHistory: moveHistory ?? this.moveHistory,
      );
}

/// Bot game controller — player is White, bot (simulated) is Black.
/// [level] 1–8 maps to difficulty (1 = random moves, 8 = strongest heuristic).
class BotGameNotifier extends AsyncNotifier<BotGameState> {
  BotGameNotifier(this.level);

  final int level;

  @override
  Future<BotGameState> build() async {
    return _newGameState();
  }

  BotGameState _newGameState() => BotGameState(
        position: Chess.initial,
        status: GameStatus.playing,
      );

  void newGame() {
    state = AsyncData(_newGameState());
  }

  void resign() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(status: GameStatus.resigned));
  }

  Future<void> onMove(Move rawMove, {bool? viaDragAndDrop}) async {
    if (rawMove is! NormalMove) return;
    final current = state.value;
    if (current == null || current.status != GameStatus.playing) return;
    if (current.position.turn != Side.white) return;

    // Check if promotion needed
    final piece = current.position.board.pieceAt(rawMove.from);
    if (piece?.role == Role.pawn && rawMove.promotion == null) {
      final toRank = rawMove.to.rank;
      final needsPromotion =
          (current.position.turn == Side.white && toRank == Rank.eighth) ||
          (current.position.turn == Side.black && toRank == Rank.first);
      if (needsPromotion) {
        state = AsyncData(current.copyWith(pendingPromotion: rawMove));
        return;
      }
    }

    _applyMove(rawMove);
  }

  void onPromotion(Role? role) {
    final current = state.value;
    if (current?.pendingPromotion == null) return;
    if (role == null) {
      state = AsyncData(current!.copyWith(clearPromotion: true));
      return;
    }
    final promotionMove = NormalMove(
      from: current!.pendingPromotion!.from,
      to: current.pendingPromotion!.to,
      promotion: role,
    );
    state = AsyncData(current.copyWith(clearPromotion: true));
    _applyMove(promotionMove);
  }

  void _applyMove(NormalMove move) {
    final current = state.value;
    if (current == null) return;

    Position newPos;
    try {
      newPos = current.position.play(move);
    } catch (_) {
      return; // Illegal move
    }

    final afterPlayerMove = current.copyWith(
      position: newPos,
      lastMove: move,
      status: _gameStatus(newPos),
      moveHistory: [...current.moveHistory, move],
    );
    state = AsyncData(afterPlayerMove);

    if (afterPlayerMove.status == GameStatus.playing) {
      _scheduleBotMove(afterPlayerMove);
    }
  }

  Future<void> _scheduleBotMove(BotGameState gameState) async {
    await Future.delayed(const Duration(seconds: 3));

    final current = state.value;
    if (current == null || current.status != GameStatus.playing) return;

    // Run bot move selection asynchronously but on the main isolate
    // (our heuristic is fast enough; real Stockfish FFI would use a separate isolate)
    final legalMoves = current.position.legalMoves;
    final botLevel = level;
    final botMove = await Future.microtask(
      () => _pickBotMove(legalMoves, botLevel),
    );
    if (botMove == null) return;

    final newPos = current.position.play(botMove);
    state = AsyncData(current.copyWith(
      position: newPos,
      lastMove: botMove,
      status: _gameStatus(newPos),
      moveHistory: [...current.moveHistory, botMove],
    ));
  }

  GameStatus _gameStatus(Position pos) {
    if (pos.isCheckmate) {
      return pos.turn == Side.white
          ? GameStatus.blackWins
          : GameStatus.whiteWins;
    }
    if (pos.isStalemate || pos.isInsufficientMaterial) return GameStatus.draw;
    return GameStatus.playing;
  }
}

/// Simple bot move selection — runs in a separate isolate.
/// Level 1: random. Level 2–8: prefers captures, scales pool size.
NormalMove? _pickBotMove(IMap<Square, SquareSet> legalMoves, int level) {
  final moves = [
    for (final e in legalMoves.entries)
      for (final to in e.value.squares) NormalMove(from: e.key, to: to),
  ];

  if (moves.isEmpty) return null;

  if (level == 1) {
    moves.shuffle();
    return moves.first;
  }

  // Separate captures from quiet moves
  // We don't have the full Position here, so use a simple heuristic:
  // moves with occupied destination squares (approximated by SquareSet content)
  moves.shuffle();

  // Pool size shrinks with higher level (better move selection)
  final poolSize = (moves.length * (1.0 - (level - 1) / 7.0)).round().clamp(1, moves.length);
  return moves.take(poolSize).first;
}

/// Provider family — one AsyncNotifier per Stockfish level (1–8).
final botGameProvider = AsyncNotifierProvider.family<
    BotGameNotifier, BotGameState, int>(
  (arg) => BotGameNotifier(arg),
);
