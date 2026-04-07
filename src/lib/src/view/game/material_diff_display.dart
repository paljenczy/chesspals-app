import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../model/game/material_diff.dart';

// Use the white piece glyphs (U+2654–U+2659) — they all render as
// uniform text glyphs on Android.  The black pawn U+265F is an emoji
// on many Android fonts, causing a size/style mismatch.
const _pieceSymbols = {
  Role.queen: '\u2655',  // ♕
  Role.rook: '\u2656',   // ♖
  Role.bishop: '\u2657', // ♗
  Role.knight: '\u2658', // ♘
  Role.pawn: '\u2659',   // ♙
};

class MaterialDiffDisplay extends StatelessWidget {
  const MaterialDiffDisplay({super.key, required this.side});

  final MaterialDiffSide side;

  @override
  Widget build(BuildContext context) {
    if (side.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];

    for (final role in MaterialDiff.displayOrder) {
      final count = side.pieces[role] ?? 0;
      for (var i = 0; i < count; i++) {
        children.add(Text(
          _pieceSymbols[role]!,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1),
        ));
      }
    }

    if (side.score > 0) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          '+${side.score}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[600],
            height: 1,
          ),
        ),
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
