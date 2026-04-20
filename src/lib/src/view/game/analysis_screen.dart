import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// A screen for reviewing a completed game move-by-move.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.moves,
    required this.startingFen,
    required this.playerSide,
  });

  final List<NormalMove> moves;
  final String startingFen;
  final Side playerSide;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _currentPly = 0;

  /// Pre-computed positions for each ply (index 0 = starting position).
  late final List<Position> _positions;
  /// Last move at each ply (null for starting position).
  late final List<NormalMove?> _lastMoves;

  @override
  void initState() {
    super.initState();
    _positions = [Chess.initial];
    _lastMoves = [null];
    var pos = _positions.first;
    for (final move in widget.moves) {
      try {
        pos = pos.play(move);
        _positions.add(pos);
        _lastMoves.add(move);
      } catch (_) {
        break;
      }
    }
    // Start at the final position
    _currentPly = _positions.length - 1;
  }

  int get _totalPlies => _positions.length - 1; // exclude starting position

  void _goTo(int ply) {
    setState(() => _currentPly = ply.clamp(0, _positions.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final position = _positions[_currentPly];
    final lastMove = _lastMoves[_currentPly];
    final boardSize =
        MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.analysisTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Move counter
          Text(
            _totalPlies > 0
                ? l.analysisMoveCounter(_currentPly, _totalPlies)
                : '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Board
          Center(
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Chessboard(
                size: boardSize,
                orientation: widget.playerSide,
                fen: position.fen,
                lastMove: lastMove,
                game: GameData(
                  playerSide: PlayerSide.none,
                  sideToMove: position.turn,
                  isCheck: position.isCheck,
                  validMoves: IMap<Square, ISet<Square>>(),
                  promotionMove: null,
                  onMove: (_, {viaDragAndDrop}) {},
                  onPromotionSelection: (_) {},
                ),
                settings: ChessboardSettings(
                  colorScheme: ChessboardColorScheme.green,
                  pieceAssets: PieceSet.cburnett.assets,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _currentPly > 0 ? () => _goTo(0) : null,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Start',
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed:
                    _currentPly > 0 ? () => _goTo(_currentPly - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _currentPly < _positions.length - 1
                    ? () => _goTo(_currentPly + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _currentPly < _positions.length - 1
                    ? () => _goTo(_positions.length - 1)
                    : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'End',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
