import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../model/bot/bot_character.dart';

// ─── Reaction enum ────────────────────────────────────────────────────────────

enum BotReaction { happy, sad, scared, furious }

// ─── Detection logic ──────────────────────────────────────────────────────────

/// Compares [oldPos] → [newPos] after [lastMove] and returns the appropriate
/// bot reaction, or null if nothing notable happened.
///
/// Priority: furious > scared > sad/happy
/// [playerSide] is the human player's side.
BotReaction? detectReaction(
  Position oldPos,
  Position newPos,
  NormalMove? lastMove, {
  required Side playerSide,
}) {
  if (lastMove == null) return null;
  final wasPlayerTurn = oldPos.turn == playerSide;

  // Promotion — player promoted a pawn → bot is furious
  if (wasPlayerTurn && lastMove.promotion != null) return BotReaction.furious;

  // Check — bot's king is now in check after the player's move → bot is scared
  if (wasPlayerTurn && newPos.isCheck) return BotReaction.scared;

  // Capture — a piece left the board (promotions already handled above)
  final oldCount = oldPos.board.occupied.size;
  final newCount = newPos.board.occupied.size;
  if (oldCount > newCount) {
    return wasPlayerTurn
        ? BotReaction.sad    // player captured bot's piece → bot sad
        : BotReaction.happy; // bot captured player's piece → bot happy
  }

  return null;
}

// ─── BotCharacterAvatar widget ────────────────────────────────────────────────

/// Animated avatar for a bot character. Reacts to game events via [trigger].
/// Access the state with a [GlobalKey<BotCharacterAvatarState>].
class BotCharacterAvatar extends StatefulWidget {
  const BotCharacterAvatar({
    super.key,
    required this.character,
    this.isThinking = false,
    this.size = 64,
  });

  final BotCharacter character;
  final bool isThinking;
  final double size;

  @override
  State<BotCharacterAvatar> createState() => BotCharacterAvatarState();
}

class BotCharacterAvatarState extends State<BotCharacterAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  BotReaction? _activeReaction;

  // Durations per reaction (animation phase)
  static const _durations = {
    BotReaction.happy:   Duration(milliseconds: 2500),
    BotReaction.sad:     Duration(milliseconds: 3000),
    BotReaction.scared:  Duration(milliseconds: 2000),
    BotReaction.furious: Duration(milliseconds: 2500),
  };

  // How long to hold the reaction face after the animation finishes
  static const _holdDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Hold the reaction face for a while before resetting to neutral
        Future.delayed(_holdDuration, () {
          if (mounted) setState(() => _activeReaction = null);
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Call this to play a reaction animation.
  void trigger(BotReaction reaction) {
    if (!mounted) return;
    debugPrint('🎭 Bot reaction: $reaction');
    _ctrl.stop();
    _ctrl.duration = _durations[reaction];
    setState(() => _activeReaction = reaction);
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => _applyAnimation(_avatarCircle()),
    );
  }

  Widget _applyAnimation(Widget child) {
    final t = _ctrl.value;
    switch (_activeReaction) {
      case BotReaction.happy:
        // Elastic bounce + green tint
        final scale = 1.0 + 0.5 * sin(t * pi);
        final greenIntensity = sin(t * pi) * 0.5;
        return Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_greenOverlayMatrix(greenIntensity)),
            child: child,
          ),
        );

      case BotReaction.sad:
        // Droop + blue tint
        final offset = 14.0 * sin(t * pi);
        final scale = 1.0 - 0.2 * sin(t * pi);
        final blueIntensity = sin(t * pi) * 0.5;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Transform.scale(
            scale: scale,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_blueOverlayMatrix(blueIntensity)),
              child: child,
            ),
          ),
        );

      case BotReaction.scared:
        // Rapid left-right shake + yellow flash
        final offset = sin(t * pi * 12) * 14 * (1 - t);
        final yellowIntensity = sin(t * pi) * 0.4;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_yellowOverlayMatrix(yellowIntensity)),
            child: child,
          ),
        );

      case BotReaction.furious:
        // Fast shake + strong red color overlay
        final offset = sin(t * pi * 14) * 12 * (1 - t);
        final redIntensity = sin(t * pi) * 0.7;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_redOverlayMatrix(redIntensity)),
            child: child,
          ),
        );

      case null:
        return child;
    }
  }

  List<double> _greenOverlayMatrix(double intensity) {
    final i = intensity.clamp(0.0, 1.0);
    return [
      1 - i * 0.3, 0, 0, 0, 0,
      0, 1 + i * 0.4, 0, 0, 0,
      0, 0, 1 - i * 0.3, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> _blueOverlayMatrix(double intensity) {
    final i = intensity.clamp(0.0, 1.0);
    return [
      1 - i * 0.3, 0, 0, 0, 0,
      0, 1 - i * 0.2, 0, 0, 0,
      0, 0, 1 + i * 0.5, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> _yellowOverlayMatrix(double intensity) {
    final i = intensity.clamp(0.0, 1.0);
    return [
      1 + i * 0.4, 0, 0, 0, 0,
      0, 1 + i * 0.3, 0, 0, 0,
      0, 0, 1 - i * 0.4, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// Builds a 5×4 color matrix that blends red into the image.
  List<double> _redOverlayMatrix(double intensity) {
    final i = intensity.clamp(0.0, 1.0);
    // Keep original colours but add red tint
    return [
      1 + i * 0.6, 0, 0, 0, 0, // R
      0, 1 - i * 0.3, 0, 0, 0, // G
      0, 0, 1 - i * 0.3, 0, 0, // B
      0, 0, 0, 1, 0,            // A
    ];
  }

  Widget _avatarCircle() {
    final color = Color(widget.character.colorHex);
    final size = widget.size;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.isThinking ? Colors.orange : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _emotionImage(
          widget.character,
          _activeReaction,
          size,
        ),
      ),
    );
  }

  /// Renders the correct emotion image (PNG or SVG) for the character.
  static Widget _emotionImage(BotCharacter character, BotReaction? reaction, double size) {
    final asset = character.emotionAsset(reaction);
    if (character.hasPngEmotions) {
      return Image.asset(asset, width: size, height: size, fit: BoxFit.cover);
    }
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

// ─── Bot emoji avatar (used when no SVG is available) ─────────────────────────

/// Simple emoji-circle avatar for a bot — used in screens that don't need
/// the full animated widget.
class BotEmojiAvatar extends StatelessWidget {
  const BotEmojiAvatar({
    super.key,
    required this.character,
    this.isThinking = false,
    this.size = 64,
  });

  final BotCharacter character;
  final bool isThinking;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(character.colorHex).withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: isThinking ? Colors.orange : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final asset = character.emotionAsset(null);
    if (character.hasPngEmotions) {
      return Image.asset(asset, width: size, height: size, fit: BoxFit.cover);
    }
    return SvgPicture.asset(asset, width: size * 0.65, height: size * 0.65);
  }
}
