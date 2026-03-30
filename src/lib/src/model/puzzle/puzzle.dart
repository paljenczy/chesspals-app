// lib/src/model/puzzle/puzzle.dart
// Puzzle domain model for ChessPals

import 'package:dartchess/dartchess.dart';
import 'package:sqflite/sqflite.dart';

class Puzzle {
  final String id;
  final String fen;              // FEN BEFORE the triggering move (penultimate position)
  final String fenAfterTrigger;  // FEN AFTER the triggering move (user starts here)
  final String? triggerUci;      // UCI of the last PGN move (the triggering move to auto-play)
  final int initialPly;          // Move number where puzzle starts
  final List<String> solution;   // UCI move strings — solution[0] is the USER's first move
  final List<String> themes;     // e.g. ["fork", "middlegame"]
  final int rating;              // Lichess puzzle rating
  final String angle;            // Batch angle this was fetched under

  const Puzzle({
    required this.id,
    required this.fen,
    required this.fenAfterTrigger,
    this.triggerUci,
    required this.initialPly,
    required this.solution,
    required this.themes,
    required this.rating,
    required this.angle,
  });

  factory Puzzle.fromLichessJson(Map<String, dynamic> json, String angle) {
    final puzzleData = json['puzzle'] as Map<String, dynamic>;
    final gameData = json['game'] as Map<String, dynamic>? ?? {};
    final pgn = gameData['pgn'] as String? ?? '';
    final initialPly = puzzleData['initialPly'] as int;

    final (fenBefore, fenAfter, triggerUci) = _parsePgn(pgn);

    return Puzzle(
      id: puzzleData['id'] as String,
      fen: fenBefore,
      fenAfterTrigger: fenAfter,
      triggerUci: triggerUci,
      initialPly: initialPly,
      solution: (puzzleData['solution'] as List).cast<String>(),
      themes: (puzzleData['themes'] as List).cast<String>(),
      rating: puzzleData['rating'] as int,
      angle: angle,
    );
  }

  /// Replay PGN moves, returning:
  /// - FEN before the last move (penultimate position — what the user sees first)
  /// - FEN after the last move (position where solution[0] starts)
  /// - UCI of the last PGN move (the triggering move to animate)
  static (String fenBefore, String fenAfter, String? triggerUci) _parsePgn(
      String pgn) {
    if (pgn.isEmpty) return (Chess.initial.fen, Chess.initial.fen, null);
    try {
      final game = PgnGame.parsePgn(pgn);
      Position pos = PgnGame.startingPosition(game.headers);
      Position prevPos = pos;
      Move? lastMove;

      for (final node in game.moves.mainline()) {
        final move = pos.parseSan(node.san);
        if (move == null) break;
        prevPos = pos;
        lastMove = move;
        pos = pos.play(move);
      }

      final triggerUci = lastMove is NormalMove ? lastMove.uci : null;
      return (prevPos.fen, pos.fen, triggerUci);
    } catch (_) {
      return (Chess.initial.fen, Chess.initial.fen, null);
    }
  }
}

// Kid-friendly difficulty label from rating
extension PuzzleDifficulty on Puzzle {
  String get kidDifficulty {
    if (rating < 1000) return '⭐ Easy';
    if (rating < 1300) return '⭐⭐ Medium';
    if (rating < 1600) return '⭐⭐⭐ Hard';
    return '⭐⭐⭐⭐ Expert';
  }

  bool get isKidFriendly => rating < 1600;
}

// PuzzleBatchStorage below uses sqflite (imported above)

const _tableName = 'puzzle_batch';

const _createTableSql = '''
  CREATE TABLE IF NOT EXISTS $_tableName (
    id TEXT PRIMARY KEY,
    fen TEXT NOT NULL,
    solution TEXT NOT NULL,
    themes TEXT NOT NULL,
    rating INTEGER NOT NULL,
    angle TEXT NOT NULL,
    solved INTEGER DEFAULT 0
  );
''';

class PuzzleBatchStorage {
  final Database _db;

  PuzzleBatchStorage(this._db);

  static Future<PuzzleBatchStorage> open() async {
    final db = await openDatabase(
      'chesspals_puzzles.db',
      version: 1,
      onCreate: (db, version) => db.execute(_createTableSql),
    );
    return PuzzleBatchStorage(db);
  }

  Future<void> insertBatch(List<Puzzle> puzzles) async {
    final batch = _db.batch();
    for (final p in puzzles) {
      batch.insert(
        _tableName,
        {
          'id': p.id,
          'fen': p.fen,
          'solution': p.solution.join(','),
          'themes': p.themes.join(','),
          'rating': p.rating,
          'angle': p.angle,
          'solved': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<Puzzle?> nextUnsolvedPuzzle({String? angle, int? maxRating}) async {
    final where = [
      'solved = 0',
      if (angle != null) "angle = '$angle'",
      if (maxRating != null) 'rating <= $maxRating',
    ].join(' AND ');

    final rows = await _db.query(
      _tableName,
      where: where,
      orderBy: 'rating ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToPuzzle(rows.first);
  }

  Future<void> markSolved(String id) async {
    await _db.update(
      _tableName,
      {'solved': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countUnsolved() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE solved = 0',
    );
    return result.first['count'] as int;
  }

  Puzzle _rowToPuzzle(Map<String, dynamic> row) => Puzzle(
    id: row['id'] as String,
    fen: row['fen'] as String,
    fenAfterTrigger: row['fen'] as String,
    initialPly: 0,
    solution: (row['solution'] as String).split(','),
    themes: (row['themes'] as String).split(','),
    rating: row['rating'] as int,
    angle: row['angle'] as String,
  );
}
