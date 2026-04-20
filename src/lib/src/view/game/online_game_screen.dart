import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/auth/lichess_account.dart';
import '../../model/bot/bot_character.dart';
import '../../model/game/bot_game_controller.dart' show toValidMoves;
import '../../model/game/material_diff.dart';
import '../../network/lichess_client.dart';
import '../../service/reaction_audio.dart';
import '../../utils/bot_l10n.dart';
import 'bot_reaction.dart';
import 'game_over_dialog.dart';
import 'material_diff_display.dart';

/// Online game screen — streams a Lichess board API game and handles moves.
class OnlineGameScreen extends ConsumerStatefulWidget {
  const OnlineGameScreen({
    super.key,
    required this.gameId,
    required this.playerSide,
    this.from = 'play',         // 'bot' or 'play' — determines back destination
    this.characterIndex,        // set when coming from bot select
  });

  final String gameId;
  final String playerSide;
  final String from;
  final int? characterIndex;

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  Position _position = Chess.initial;
  NormalMove? _lastMove;
  NormalMove? _pendingPromotion;
  Side _playerSide = Side.white;
  bool _gameOver = false;
  String? _gameResult;
  bool _connected = false;
  String? _error;
  int _totalMoves = 0; // total half-moves played (from server move list)
  List<NormalMove> _moveHistory = [];
  bool _dialogShown = false;
  StreamSubscription<Map<String, dynamic>>? _gameSub;
  final LichessClient _client = LichessClient();
  final _avatarKey = GlobalKey<BotCharacterAvatarState>();

  // ─── Clock state ───────────────────────────────────────────────────────────
  int _whiteTimeMs = 0;
  int _blackTimeMs = 0;
  Timer? _clockTimer;
  DateTime? _lastClockTick;

  // ─── Draw offer state ──────────────────────────────────────────────────────
  bool _drawOfferedByMe = false;
  bool _opponentOfferedDraw = false;

  // ─── Opponent gone state ───────────────────────────────────────────────────
  bool _opponentGone = false;
  int _claimWinInSeconds = 0;

  // ─── Opponent info ─────────────────────────────────────────────────────────
  String? _opponentName;
  int? _opponentRating;

  /// Resolved once from widget.characterIndex — null for human vs human games.
  BotCharacter? get _character {
    final i = widget.characterIndex;
    if (i == null || i < 0 || i >= BotCharacter.values.length) return null;
    return BotCharacter.values[i];
  }

  @override
  void initState() {
    super.initState();
    if (widget.playerSide == 'black') {
      _playerSide = Side.black;
    } else {
      _playerSide = Side.white;
    }
    _subscribeToGame();
    if (widget.characterIndex != null) ReactionAudio.preload();
  }

  void _subscribeToGame({int retryCount = 0}) {
    _gameSub = _client.streamGame(widget.gameId).listen(
      _handleGameEvent,
      onError: (e) {
        // Bot challenge takes ~1s to be accepted — retry on 404 before giving up
        final isNotFound = e.toString().contains('No such game') ||
            e.toString().contains('404');
        if (isNotFound && retryCount < 5) {
          _gameSub?.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _subscribeToGame(retryCount: retryCount + 1);
          });
        } else if (mounted) {
          setState(() => _error = e.toString());
        }
      },
    );
  }

  void _handleGameEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == 'gameFull') {
      final white = event['white'] as Map<String, dynamic>?;
      final black = event['black'] as Map<String, dynamic>?;
      final account = ref.read(accountProvider).value;
      if (account != null) {
        final whiteId = (white?['id'] as String?)?.toLowerCase();
        final myId = account.id.toLowerCase();
        final isWhite = whiteId == myId;
        final opponent = isWhite ? black : white;
        setState(() {
          _playerSide = isWhite ? Side.white : Side.black;
          _connected = true;
          _opponentName = opponent?['username'] as String?;
          _opponentRating = (opponent?['rating'] as num?)?.toInt();
        });
      } else {
        setState(() => _connected = true);
      }
      final state = event['state'] as Map<String, dynamic>?;
      if (state != null) _applyState(state);
    } else if (type == 'gameState') {
      _applyState(event);
    } else if (type == 'opponentGone') {
      final gone = event['gone'] as bool? ?? false;
      setState(() {
        _opponentGone = gone;
        _claimWinInSeconds = gone ? (event['claimWinInSeconds'] as int? ?? 0) : 0;
      });
    }
  }

  void _applyState(Map<String, dynamic> state) {
    final moves = (state['moves'] as String?)?.trim() ?? '';
    final status = state['status'] as String?;

    Position pos = Chess.initial;
    NormalMove? lastMove;
    int moveCount = 0;
    final parsedMoves = <NormalMove>[];
    if (moves.isNotEmpty) {
      for (final uci in moves.split(' ')) {
        if (uci.isEmpty) continue;
        final move = _parseUci(uci);
        if (move == null) break;
        try {
          pos = pos.play(move);
          lastMove = move;
          moveCount++;
          parsedMoves.add(move);
        } catch (_) {
          break;
        }
      }
    }

    // Parse clock times from server (authoritative)
    final wtime = state['wtime'] as int?;
    final btime = state['btime'] as int?;

    // Parse draw offers
    final wdraw = state['wdraw'] as bool? ?? false;
    final bdraw = state['bdraw'] as bool? ?? false;
    final myDraw = _playerSide == Side.white ? wdraw : bdraw;
    final theirDraw = _playerSide == Side.white ? bdraw : wdraw;

    String? result;
    bool gameOver = false;
    if (status != null && status != 'started' && status != 'created') {
      gameOver = true;
      final winner = state['winner'] as String?;
      final account = ref.read(accountProvider).value;
      if (winner != null && account != null) {
        result = winner == 'white'
            ? (_playerSide == Side.white ? 'win' : 'loss')
            : (_playerSide == Side.black ? 'win' : 'loss');
      } else if (status == 'draw' || status == 'stalemate') {
        result = 'draw';
      }
    }

    if (mounted) {
      // Detect bot reaction before applying new state
      if (_character != null && lastMove != null) {
        final reaction = detectReaction(
          _position, pos, lastMove,
          playerSide: _playerSide,
        );
        if (reaction != null) {
          _avatarKey.currentState?.trigger(reaction);
          ReactionAudio.play(reaction);
        }
      }

      final wasGameOver = _gameOver;

      setState(() {
        _position = pos;
        _lastMove = lastMove;
        _pendingPromotion = null;
        _gameOver = gameOver;
        _gameResult = result;
        _totalMoves = moveCount;
        _moveHistory = parsedMoves;
        if (wtime != null) _whiteTimeMs = wtime;
        if (btime != null) _blackTimeMs = btime;
        _drawOfferedByMe = myDraw;
        _opponentOfferedDraw = theirDraw;
      });

      _restartClockTimer();

      // Aborted games: just navigate home silently
      if (status == 'aborted' && !wasGameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/${widget.from}');
        });
        return;
      }

      // Show game-over dialog when game just ended
      if (gameOver && !wasGameOver) {
        _showGameOverDialog();
      }
    }
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

  bool _needsPromotion(NormalMove move) {
    final piece = _position.board.pieceAt(move.from);
    if (piece?.role != Role.pawn || move.promotion != null) return false;
    final toRank = move.to.rank;
    return (_playerSide == Side.white && toRank == Rank.eighth) ||
        (_playerSide == Side.black && toRank == Rank.first);
  }

  Future<void> _onMove(Move rawMove, {bool? viaDragAndDrop}) async {
    if (rawMove is! NormalMove || _gameOver) return;
    if (_position.turn != _playerSide) return;

    if (_needsPromotion(rawMove)) {
      // Pause and show promotion picker
      setState(() => _pendingPromotion = rawMove);
      return;
    }

    await _submitMove(rawMove);
  }

  Future<void> _onPromotionSelection(Role? role) async {
    final pending = _pendingPromotion;
    setState(() => _pendingPromotion = null);
    if (pending == null || role == null) return;
    final move = NormalMove(from: pending.from, to: pending.to, promotion: role);
    await _submitMove(move);
  }

  Future<void> _submitMove(NormalMove move) async {
    try {
      final newPos = _position.play(move);
      setState(() {
        _position = newPos;
        _lastMove = move;
      });
      await _client.makeMove(widget.gameId, move.uci);
    } catch (_) {
      // Revert handled by next gameState from stream
    }
  }

  Future<void> _resign() async {
    try {
      await _client.resign(widget.gameId);
    } catch (_) {}
  }

  Future<void> _abort() async {
    try {
      await _client.abort(widget.gameId);
    } catch (_) {}
  }

  Future<void> _offerDraw() async {
    try {
      await _client.offerDraw(widget.gameId);
      setState(() => _drawOfferedByMe = true);
    } catch (_) {}
  }

  Future<void> _acceptDraw() async {
    try {
      await _client.offerDraw(widget.gameId); // same endpoint accepts
    } catch (_) {}
  }

  Future<void> _declineDraw() async {
    try {
      await _client.declineDraw(widget.gameId);
      setState(() => _opponentOfferedDraw = false);
    } catch (_) {}
  }

  Future<void> _claimVictory() async {
    try {
      await _client.claimVictory(widget.gameId);
    } catch (_) {}
  }

  // ─── Clock timer ───────────────────────────────────────────────────────────

  void _restartClockTimer() {
    _clockTimer?.cancel();
    if (_gameOver) return;
    _lastClockTick = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastClockTick!).inMilliseconds;
      _lastClockTick = now;
      setState(() {
        if (_position.turn == Side.white) {
          _whiteTimeMs = (_whiteTimeMs - elapsed).clamp(0, 999999999);
        } else {
          _blackTimeMs = (_blackTimeMs - elapsed).clamp(0, 999999999);
        }
      });
    });
  }

  /// Shows the leave dialog. Returns true if the user confirmed and the
  /// game was properly closed (resigned or aborted). Returns false if cancelled.
  Future<bool> _confirmLeave() async {
    if (_gameOver) return true; // already over, just navigate
    final l = AppLocalizations.of(context);
    final canAbort = _totalMoves < 2; // fewer than one full move each
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(canAbort ? l.onlineAbortTitle : l.onlineResignTitle),
        content: Text(canAbort ? l.onlineAbortContent : l.onlineResignContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.onlineKeepPlaying),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(canAbort ? l.onlineCancelGame : l.onlineResignButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    if (canAbort) {
      await _abort();
    } else {
      await _resign();
    }
    return true;
  }

  void _showGameOverDialog() {
    if (_dialogShown) return;
    _dialogShown = true;

    final l = AppLocalizations.of(context);
    final resultText = _resultLabel(l);
    final resultColor = switch (_gameResult) {
      'win' => Colors.green[800]!,
      'loss' => Colors.red[700]!,
      _ => Colors.blue[700]!,
    };

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final choice = await showGameOverDialog(
        context,
        resultText: resultText,
        resultColor: resultColor,
      );
      if (!mounted) return;
      if (choice == 'analyze') {
        context.push('/analysis', extra: {
          'moves': _moveHistory,
          'fen': Chess.initial.fen,
          'side': _playerSide,
        });
      } else {
        context.go('/${widget.from}');
      }
    });
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _clockTimer?.cancel();
    if (widget.characterIndex != null) ReactionAudio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isMyTurn = !_gameOver && _position.turn == _playerSide;
    final validMoves = (!_gameOver && isMyTurn)
        ? toValidMoves(_position.legalMoves)
        : IMap<Square, ISet<Square>>();

    // Determine which clock belongs to opponent vs player
    final opponentTimeMs = _playerSide == Side.white ? _blackTimeMs : _whiteTimeMs;
    final playerTimeMs = _playerSide == Side.white ? _whiteTimeMs : _blackTimeMs;
    final opponentActive = !_gameOver && _position.turn != _playerSide;
    final playerActive = !_gameOver && _position.turn == _playerSide;

    return PopScope(
      canPop: false, // always intercept — we handle it ourselves
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && mounted) context.go('/${widget.from}');
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final leave = await _confirmLeave();
            if (leave && mounted) context.go('/${widget.from}');
          },
        ),
        title: _buildTitle(isMyTurn, l),
        centerTitle: true,
        actions: [
          if (!_gameOver && _totalMoves >= 2)
            IconButton(
              icon: Icon(
                Icons.handshake_outlined,
                color: _drawOfferedByMe ? Colors.orange : null,
              ),
              tooltip: _drawOfferedByMe ? l.onlineDrawOfferSent : l.onlineDrawOfferTooltip,
              onPressed: _drawOfferedByMe ? null : _offerDraw,
            ),
          if (!_gameOver)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: l.onlineResignTooltip,
              onPressed: () async {
                final leave = await _confirmLeave();
                if (leave && mounted) context.go('/${widget.from}');
              },
            ),
        ],
      ),
      body: !_connected
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l)
              : Column(
                  children: [
                    // Opponent row (animal character or generic opponent) with clock
                    _buildOpponentRow(isMyTurn, l, opponentTimeMs, opponentActive),

                    // Draw offer banner
                    if (_opponentOfferedDraw && !_gameOver)
                      _DrawOfferBanner(
                        onAccept: _acceptDraw,
                        onDecline: _declineDraw,
                      ),

                    // Opponent gone banner
                    if (_opponentGone && !_gameOver)
                      _OpponentGoneBanner(
                        claimWinInSeconds: _claimWinInSeconds,
                        onClaimVictory: _claimVictory,
                        onOfferDraw: _offerDraw,
                      ),

                    // Board
                    Chessboard(
                        size: MediaQuery.of(context).size.width,
                        fen: _position.fen,
                        orientation: _playerSide,
                        lastMove: _lastMove != null
                            ? NormalMove(
                                from: _lastMove!.from,
                                to: _lastMove!.to,
                              )
                            : null,
                        game: GameData(
                          playerSide: _playerSide == Side.white
                              ? PlayerSide.white
                              : PlayerSide.black,
                          isCheck: _position.isCheck,
                          sideToMove: _position.turn,
                          validMoves: validMoves,
                          promotionMove: _pendingPromotion,
                          onMove: _onMove,
                          onPromotionSelection: _onPromotionSelection,
                        ),
                        settings: ChessboardSettings(
                          colorScheme: ChessboardColorScheme.brown,
                          pieceAssets: PieceSet.cburnett.assets,
                        ),
                      ),

                    // Player row with clock
                    _buildPlayerRow(l, playerTimeMs, playerActive),
                  ],
                ),
      ),  // Scaffold
    );   // PopScope
  }

  String _resultLabel(AppLocalizations l) {
    return switch (_gameResult) {
      'win' => l.onlineResultWin,
      'loss' => l.onlineResultLoss,
      'draw' => l.onlineResultDraw,
      _ => l.onlineResultGameOver,
    };
  }

  Widget _buildTitle(bool isMyTurn, AppLocalizations l) {
    final character = _character;

    if (!_connected) return Text(l.onlineConnecting);

    if (_gameOver) {
      return Text(_resultLabel(l), style: const TextStyle(fontWeight: FontWeight.w700));
    }

    if (character != null) {
      final localizedName = localizedBotName(l, character);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          character.hasPngEmotions
              ? Image.asset(character.emotionAsset(null), width: 36, height: 36, fit: BoxFit.contain)
              : SvgPicture.asset(character.emotionAsset(null), width: 36, height: 36),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isMyTurn ? l.onlineYourTurn : l.botThinking(localizedName),
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      isMyTurn ? l.onlineYourTurn : l.onlineOpponentsTurn,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildOpponentRow(bool isMyTurn, AppLocalizations l, int timeMs, bool active) {
    final character = _character;
    final thinking = !_gameOver && !isMyTurn;
    final diff = MaterialDiff.fromPosition(_position);
    final opponentSide = _playerSide == Side.white ? diff.black : diff.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Avatar — animated when a bot character is present
          if (character != null)
            BotCharacterAvatar(
              key: _avatarKey,
              character: character,
              isThinking: thinking,
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('\u{1F464}', style: TextStyle(fontSize: 28)),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character != null
                      ? localizedBotName(l, character)
                      : (_opponentName ?? l.onlineOpponentLabel),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  character != null
                      ? '~${roundedRating(character.approxRating)} ${l.onlineRapidSuffix}'
                      : _opponentRating != null
                          ? '$_opponentRating ${l.onlineRapidSuffix}'
                          : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                MaterialDiffDisplay(side: opponentSide),
              ],
            ),
          ),
          _ChessClock(timeMs: timeMs, active: active),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(AppLocalizations l, int timeMs, bool active) {
    final account = ref.watch(accountProvider).value;
    final avatarIndex = account?.avatarIndex ?? 0;
    final username = account?.username ?? l.onlineYouLabel;
    final rapid = account?.rapidRating;
    final diff = MaterialDiff.fromPosition(_position);
    final playerSide = _playerSide == Side.white ? diff.white : diff.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          KidAvatarWidget(
            avatarIndex: avatarIndex,
            size: 48,
            onTap: () => ref.read(accountProvider.notifier).cycleAvatar(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  rapid != null ? '$rapid ${l.onlineRapidSuffix}' : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                MaterialDiffDisplay(side: playerSide),
              ],
            ),
          ),
          _ChessClock(timeMs: timeMs, active: active),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l.onlineConnectionError(_error!),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _subscribeToGame();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l.onlineRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chess clock widget: shows time remaining with color-coded background.
class _ChessClock extends StatelessWidget {
  const _ChessClock({required this.timeMs, required this.active});

  final int timeMs;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = (timeMs / 1000).ceil();
    final lowTime = totalSeconds < 30;

    Color bgColor;
    Color textColor;
    if (active && lowTime) {
      bgColor = Colors.red[700]!;
      textColor = Colors.white;
    } else if (active) {
      bgColor = Colors.green[700]!;
      textColor = Colors.white;
    } else {
      bgColor = Colors.grey[300]!;
      textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatTime(timeMs),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _formatTime(int ms) {
    if (ms <= 0) return '0:00';
    final totalSeconds = ms ~/ 1000;
    if (totalSeconds >= 60) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      final tenths = (ms % 1000) ~/ 100;
      return '$totalSeconds.$tenths';
    }
  }
}

/// Amber banner shown when the opponent offers a draw.
class _DrawOfferBanner extends StatelessWidget {
  const _DrawOfferBanner({required this.onAccept, required this.onDecline});

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[400]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.handshake, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.onlineDrawOfferReceived,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onDecline,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l.onlineDrawDecline),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l.onlineDrawAccept),
          ),
        ],
      ),
    );
  }
}

class _OpponentGoneBanner extends StatelessWidget {
  const _OpponentGoneBanner({
    required this.claimWinInSeconds,
    required this.onClaimVictory,
    required this.onOfferDraw,
  });

  final int claimWinInSeconds;
  final VoidCallback onClaimVictory;
  final VoidCallback onOfferDraw;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canClaim = claimWinInSeconds <= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canClaim
                      ? l.onlineOpponentGone
                      : l.onlineOpponentGoneCountdown(claimWinInSeconds),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (canClaim) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onOfferDraw,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l.onlineOfferDrawButton),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onClaimVictory,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l.onlineClaimVictory),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
