import 'package:dartchess/dartchess.dart';

const _pieceValues = {
  Role.queen: 9,
  Role.rook: 5,
  Role.bishop: 3,
  Role.knight: 3,
  Role.pawn: 1,
};

const _displayOrder = [Role.queen, Role.rook, Role.bishop, Role.knight, Role.pawn];

class MaterialDiffSide {
  final Map<Role, int> pieces;
  final int score;

  const MaterialDiffSide({required this.pieces, required this.score});

  bool get isEmpty => pieces.isEmpty && score <= 0;
}

class MaterialDiff {
  final MaterialDiffSide white;
  final MaterialDiffSide black;

  const MaterialDiff({required this.white, required this.black});

  static const displayOrder = _displayOrder;

  factory MaterialDiff.fromPosition(Position position) {
    final wMat = position.board.materialCount(Side.white);
    final bMat = position.board.materialCount(Side.black);

    final whitePieces = <Role, int>{};
    final blackPieces = <Role, int>{};
    var score = 0;

    for (final role in _displayOrder) {
      final diff = (wMat[role] ?? 0) - (bMat[role] ?? 0);
      score += diff * (_pieceValues[role] ?? 0);
      if (diff > 0) {
        whitePieces[role] = diff;
      } else if (diff < 0) {
        blackPieces[role] = -diff;
      }
    }

    return MaterialDiff(
      white: MaterialDiffSide(
        pieces: whitePieces,
        score: score > 0 ? score : 0,
      ),
      black: MaterialDiffSide(
        pieces: blackPieces,
        score: score < 0 ? -score : 0,
      ),
    );
  }
}
