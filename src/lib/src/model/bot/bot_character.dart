/// Bot character definitions for ChessPals
/// Each BotCharacter maps to a real Lichess bot account (challenged via POST /api/challenge/{username}).
/// All bots are between 700–1550 rapid rating. No embedded engine — internet required for bot play.
library;

// lib/src/model/bot/bot_character.dart

import '../../network/lichess_client.dart';
import '../../view/game/bot_reaction.dart';

/// Represents a real Lichess bot account that kids can challenge.
enum BotCharacter {
  // ~458 rapid — StupidfishBOTBYDSCS, deliberately blunder-heavy Stockfish variant
  bee(
    id: 'bee',
    name: 'Bella the Bee',
    emoji: '🐝',
    svgAsset: 'assets/bot_avatars/bee.svg',
    imageDir: 'assets/bot_avatars/bee',
    lichessUsername: 'StupidfishBOTBYDSCS',
    approxRating: 458,
    stockfishFallbackLevel: 1,
    description: "I'm just a little bee — I buzz around and make lots of mistakes!",
    difficulty: '⭐ Beginner',
    colorHex: 0xFFFDD835,
  ),
  // ~871 rapid — dala-700, Elo-aligned neural network, 60+ rapid games
  butterfly(
    id: 'butterfly',
    name: 'Flutter the Butterfly',
    emoji: '🦋',
    svgAsset: 'assets/bot_avatars/butterfly.svg',
    imageDir: 'assets/bot_avatars/butterfly',
    lichessUsername: 'dala-700',
    approxRating: 871,
    stockfishFallbackLevel: 1,
    description: "I flutter around the board — I'm still finding my wings!",
    difficulty: '⭐⭐ Explorer',
    colorHex: 0xFFCE93D8,
  ),
  // ~884 rapid — larryz-alterego, Turochamp-style beginner bot, 6,044+ rapid games
  hummingbird(
    id: 'hummingbird',
    name: 'Zip the Hummingbird',
    emoji: '🐦',
    svgAsset: 'assets/bot_avatars/hummingbird.svg',
    imageDir: 'assets/bot_avatars/hummingbird',
    lichessUsername: 'larryz-alterego',
    approxRating: 884,
    stockfishFallbackLevel: 1,
    description: "I move super fast — blink and you'll miss my tricks!",
    difficulty: '⭐⭐ Speedy',
    colorHex: 0xFF80DEEA,
  ),
  // ~896 rapid — uSunfish-l0, MicroPython Sunfish on ESP32, 3,245+ rapid games
  rabbit(
    id: 'rabbit',
    name: 'Rosie the Rabbit',
    emoji: '🐰',
    svgAsset: 'assets/bot_avatars/rabbit.svg',
    imageDir: 'assets/bot_avatars/rabbit',
    lichessUsername: 'uSunfish-l0',
    approxRating: 896,
    stockfishFallbackLevel: 1,
    description: "I hop around quickly — watch out, I can be tricky!",
    difficulty: '⭐⭐⭐ Tricky',
    colorHex: 0xFFFFCDD2,
  ),
  // ~1016 rapid — dala-900, Elo-aligned neural network, 114+ rapid games
  kangaroo(
    id: 'kangaroo',
    name: 'Kira the Kangaroo',
    emoji: '🦘',
    svgAsset: 'assets/bot_avatars/kangaroo.svg',
    imageDir: 'assets/bot_avatars/kangaroo',
    lichessUsername: 'dala-900',
    approxRating: 1016,
    stockfishFallbackLevel: 2,
    description: "I learn by watching — I'll leap ahead when you least expect it!",
    difficulty: '⭐⭐⭐ Cunning',
    colorHex: 0xFFD7CCC8,
  ),
  // ~1302 rapid — dala-1100, Elo-aligned neural network, 90+ rapid games
  deer(
    id: 'deer',
    name: 'Dino the Deer',
    emoji: '🦌',
    svgAsset: 'assets/bot_avatars/deer.svg',
    imageDir: 'assets/bot_avatars/deer',
    lichessUsername: 'dala-1100',
    approxRating: 1302,
    stockfishFallbackLevel: 2,
    description: "I play sharp and fast — watch out for my attacks!",
    difficulty: '⭐⭐⭐ Sharp',
    colorHex: 0xFFA1887F,
  ),
  // ~1392 rapid — dala-1300, Elo-aligned neural network, 116+ rapid games
  giraffe(
    id: 'giraffe',
    name: 'Gabi the Giraffe',
    emoji: '🦒',
    svgAsset: 'assets/bot_avatars/giraffe.svg',
    imageDir: 'assets/bot_avatars/giraffe',
    lichessUsername: 'dala-1300',
    approxRating: 1392,
    stockfishFallbackLevel: 2,
    description: "I see the whole board from up high — I play like a real person!",
    difficulty: '⭐⭐⭐⭐ Fierce',
    colorHex: 0xFFFFCC80,
  ),
  // ~1543 rapid — dala-1600, Elo-aligned neural network, 221+ rapid games
  tiger(
    id: 'tiger',
    name: 'Tara the Tiger',
    emoji: '🐯',
    svgAsset: 'assets/bot_avatars/tiger.svg',
    imageDir: 'assets/bot_avatars/tiger',
    lichessUsername: 'dala-1600',
    approxRating: 1543,
    stockfishFallbackLevel: 3,
    description: "I pounce when you make a mistake — can you outsmart me?",
    difficulty: '⭐⭐⭐⭐ Fierce+',
    colorHex: 0xFFEF6C00,
  );

  const BotCharacter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.svgAsset,
    required this.imageDir,
    required this.lichessUsername,
    required this.approxRating,
    required this.stockfishFallbackLevel,
    required this.description,
    required this.difficulty,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String emoji;
  final String svgAsset;
  final String imageDir;
  final String lichessUsername;
  final int approxRating;
  final int stockfishFallbackLevel;
  final String description;
  final String difficulty;
  final int colorHex;

  /// Returns the asset path for the given emotion state.
  /// Uses PNG if available, falls back to SVG.
  String emotionAsset(BotReaction? reaction) {
    final emotion = switch (reaction) {
      BotReaction.happy => 'happy',
      BotReaction.sad => 'sad',
      BotReaction.scared => 'scared',
      BotReaction.furious => 'furious',
      null => 'neutral',
    };
    final ext = hasPngEmotions ? 'png' : 'svg';
    return '$imageDir/$emotion.$ext';
  }

  /// Whether this character has custom PNG emotion images.
  /// Set to true once AI-generated PNGs are added for an animal.
  bool get hasPngEmotions => true;
}

/// Challenges a real Lichess bot account, falling back to Stockfish AI
/// if the bot is unavailable.
class BotService {
  final LichessClient _client;

  BotService(this._client);

  Future<String> challengeBot(
    BotCharacter character, {
    String color = 'white',
  }) async {
    try {
      return await _client.challengeUser(
        username: character.lichessUsername,
        color: color,
        clockLimit: 1440,
        clockIncrement: 0,
        rated: false,
      );
    } catch (e) {
      print('Bot ${character.lichessUsername} challenge failed: $e — falling back to Stockfish level ${character.stockfishFallbackLevel}');
      return _client.challengeAi(
        level: character.stockfishFallbackLevel,
        color: color,
        clockLimit: 10800,
        clockIncrement: 0,
      );
    }
  }
}
