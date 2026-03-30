import 'package:audioplayers/audioplayers.dart';

import '../view/game/bot_reaction.dart';

/// Plays short sound effects for bot character reactions.
/// Call [preload] once when the game screen initialises.
class ReactionAudio {
  static final Map<BotReaction, AudioPlayer> _players = {};

  static const _assets = {
    BotReaction.happy:   'sounds/reaction_happy.wav',
    BotReaction.sad:     'sounds/reaction_sad.wav',
    BotReaction.scared:  'sounds/reaction_scared.wav',
    BotReaction.furious: 'sounds/reaction_furious.wav',
  };

  /// Pre-creates one AudioPlayer per reaction so first playback has no lag.
  static Future<void> preload() async {
    for (final reaction in BotReaction.values) {
      final player = AudioPlayer();
      await player.setVolume(0.7);
      await player.setSource(AssetSource(_assets[reaction]!));
      _players[reaction] = player;
    }
  }

  /// Plays the sound for the given reaction (fire-and-forget).
  static Future<void> play(BotReaction reaction) async {
    final player = _players[reaction];
    if (player == null) return;
    await player.stop();
    await player.resume();
  }

  /// Releases all players. Call from [dispose] of the game screen.
  static Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
