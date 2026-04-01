import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dartchess/dartchess.dart';
import 'package:chessground/chessground.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../model/auth/lichess_account.dart';
import '../../model/bot/bot_character.dart';
import '../../model/game/bot_game_controller.dart';
import '../../service/reaction_audio.dart';
import '../../utils/bot_l10n.dart';
import '../game/bot_reaction.dart';
import '../game/game_over_dialog.dart';

/// Chess board screen for bot play.
/// The [level] (1–8) maps to a Stockfish difficulty, displayed as [BotCharacter].
class BotGameScreen extends ConsumerStatefulWidget {
  const BotGameScreen({
    super.key,
    required this.level,
    required this.characterIndex,
  });

  final int level;           // Stockfish level 1–8
  final int characterIndex;  // Index into BotCharacter.values for display

  @override
  ConsumerState<BotGameScreen> createState() => _BotGameScreenState();
}

class _BotGameScreenState extends ConsumerState<BotGameScreen> {
  // ignore: prefer_const_declarations
  final _avatarKey = GlobalKey<BotCharacterAvatarState>();
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    ReactionAudio.preload();
  }

  @override
  void dispose() {
    ReactionAudio.dispose();
    super.dispose();
  }

  bool _isGameOver(GameStatus status) =>
      status == GameStatus.whiteWins ||
      status == GameStatus.blackWins ||
      status == GameStatus.draw ||
      status == GameStatus.resigned;

  void _showGameOverDialog(BotGameState state) {
    if (_dialogShown) return;
    _dialogShown = true;

    final l = AppLocalizations.of(context);
    final (text, color) = switch (state.status) {
      GameStatus.whiteWins => (l.botGameStatusYouWon, Colors.green[800]!),
      GameStatus.blackWins => (l.botGameStatusBotWins, Colors.red[700]!),
      GameStatus.draw => (l.botGameStatusDraw, Colors.blue[700]!),
      GameStatus.resigned => (l.botGameStatusBotWins, Colors.red[700]!),
      _ => ('', Colors.grey),
    };

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final choice = await showGameOverDialog(
        context,
        resultText: text,
        resultColor: color,
      );
      if (!mounted) return;
      // Reset the game so re-entering this bot starts fresh
      ref.read(botGameProvider(widget.level).notifier).newGame();
      _dialogShown = false;
      if (choice == 'analyze') {
        context.push('/analysis', extra: {
          'moves': state.moveHistory,
          'fen': Chess.initial.fen,
          'side': Side.white,
        });
      } else {
        context.go('/bot');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const characters = BotCharacter.values;
    final character = characters[widget.characterIndex.clamp(0, characters.length - 1)];

    // Detect reactions on each state change
    ref.listen<AsyncValue<BotGameState>>(
      botGameProvider(widget.level),
      (prev, next) {
        final oldState = prev?.value;
        final newState = next.value;
        if (oldState == null || newState == null) return;
        final reaction = detectReaction(
          oldState.position,
          newState.position,
          newState.lastMove,
          playerSide: Side.white,
        );
        if (reaction != null) {
          _avatarKey.currentState?.trigger(reaction);
          ReactionAudio.play(reaction);
        }

        // Show game-over dialog when game ends
        if (!_isGameOver(oldState.status) && _isGameOver(newState.status)) {
          _showGameOverDialog(newState);
        }
      },
    );

    final gameState = ref.watch(botGameProvider(widget.level));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/bot'),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            character.hasPngEmotions
                ? Image.asset(character.emotionAsset(null), width: 36, height: 36, fit: BoxFit.contain)
                : SvgPicture.asset(character.emotionAsset(null), width: 36, height: 36),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                localizedBotName(l, character),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l.botGameTooltipNewGame,
            onPressed: () {
              _dialogShown = false;
              ref.read(botGameProvider(widget.level).notifier).newGame();
            },
          ),
        ],
      ),
      body: gameState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) => _GameBody(
          state: state,
          level: widget.level,
          character: character,
          avatarKey: _avatarKey,
        ),
      ),
    );
  }
}

class _GameBody extends ConsumerWidget {
  const _GameBody({
    required this.state,
    required this.level,
    required this.character,
    required this.avatarKey,
  });

  final BotGameState state;
  final int level;
  final BotCharacter character;
  final GlobalKey<BotCharacterAvatarState> avatarKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final controller = ref.read(botGameProvider(level).notifier);
    final isThinking = state.status == GameStatus.playing &&
        state.sideToMove == Side.black;
    final isGameOver = state.status != GameStatus.playing;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve space for rows around the board, then give the rest to the board
        const chromHeight = 200.0; // bot row + status + player row + buttons + padding
        final maxBoardFromWidth = constraints.maxWidth.clamp(200.0, 500.0);
        final maxBoardFromHeight = (constraints.maxHeight - chromHeight).clamp(200.0, 500.0);
        final boardSize = maxBoardFromWidth < maxBoardFromHeight
            ? maxBoardFromWidth
            : maxBoardFromHeight;

        return Column(
          children: [
            // Bot character row
            _BotRow(character: character, avatarKey: avatarKey, isThinking: isThinking),

            // Status banner (only during play)
            _StatusBanner(state: state),

            // Board
            Center(
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: Chessboard(
                  size: boardSize,
                  orientation: Side.white,
                  fen: state.fen,
                  lastMove: state.lastMove,
                  game: GameData(
                    playerSide: PlayerSide.white,
                    sideToMove: state.sideToMove,
                    isCheck: state.isCheck,
                    validMoves: state.validMoves,
                    promotionMove: state.pendingPromotion,
                    onMove: (move, {viaDragAndDrop}) =>
                        controller.onMove(move, viaDragAndDrop: viaDragAndDrop),
                    onPromotionSelection: controller.onPromotion,
                  ),
                  settings: ChessboardSettings(
                    colorScheme: ChessboardColorScheme.green,
                    pieceAssets: PieceSet.cburnett.assets,
                  ),
                ),
              ),
            ),

            // Player row
            _PlayerRow(),

            const SizedBox(height: 8),

            // Control row
            if (!isGameOver)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      label: l.botGameButtonResign,
                      icon: Icons.flag_outlined,
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l.onlineResignTitle),
                            content: Text(l.onlineResignContent),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(l.onlineKeepPlaying),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: Text(l.onlineResignButton),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) controller.resign();
                      },
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      label: l.botGameButtonNewGame,
                      icon: Icons.add_circle_outline,
                      onTap: () => controller.newGame(),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BotRow extends StatelessWidget {
  const _BotRow({
    required this.character,
    required this.avatarKey,
    required this.isThinking,
  });

  final BotCharacter character;
  final GlobalKey<BotCharacterAvatarState> avatarKey;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          BotCharacterAvatar(
            key: avatarKey,
            character: character,
            isThinking: isThinking,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizedBotName(l, character),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                localizedBotDifficulty(l, character),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (isThinking) ...[
            const Spacer(),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final account = ref.watch(accountProvider).value;
    final avatarIndex = account?.avatarIndex ?? 0;
    final username = account?.username ?? l.onlineYouLabel;
    final rapid = account?.rapidRating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          KidAvatarWidget(
            avatarIndex: avatarIndex,
            size: 64,
            onTap: () => ref.read(accountProvider.notifier).cycleAvatar(),
          ),
          const SizedBox(width: 12),
          Column(
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
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});
  final BotGameState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Only show banner during active play
    if (state.status != GameStatus.playing) return const SizedBox.shrink();

    final (text, color) = state.sideToMove == Side.white
        ? (l.botGameStatusYourTurn, Colors.green[700]!)
        : (l.botGameStatusBotThinking, Colors.orange[700]!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: color.withValues(alpha: 0.12),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
