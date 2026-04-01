/// Bot character definitions for ChessPals
/// Each BotCharacter maps to a real Lichess bot account (challenged via POST /api/challenge/{username}).
/// All bots are between 750–1500 rapid rating. No embedded engine — internet required for bot play.

// lib/src/model/bot/bot_character.dart

import '../../network/lichess_client.dart';
import '../../view/game/bot_reaction.dart';

/// Represents a real Lichess bot account that kids can challenge.
enum BotCharacter {
  // ~744 rapid — grandQ_AI, Q-learning bot, 6,190+ rapid games, reliably online
  bee(
    id: 'bee',
    name: 'Bella the Bee',
    emoji: '🐝',
    svgAsset: 'assets/bot_avatars/bee.svg',
    imageDir: 'assets/bot_avatars/bee',
    lichessUsername: 'grandQ_AI',
    approxRating: 744,
    description: "I'm just a little bee — I buzz around and make lots of mistakes!",
    difficulty: '⭐ Beginner',
    colorHex: 0xFFFDD835,
  ),
  // ~884 rapid — larryz-alterego, Turochamp-style beginner bot, 6,044+ rapid games
  butterfly(
    id: 'butterfly',
    name: 'Flutter the Butterfly',
    emoji: '🦋',
    svgAsset: 'assets/bot_avatars/butterfly.svg',
    imageDir: 'assets/bot_avatars/butterfly',
    lichessUsername: 'larryz-alterego',
    approxRating: 884,
    description: "I flutter around the board — I'm still finding my wings!",
    difficulty: '⭐⭐ Explorer',
    colorHex: 0xFFCE93D8,
  ),
  // ~896 rapid — uSunfish-l0, MicroPython Sunfish on ESP32, 3,245+ rapid games
  hummingbird(
    id: 'hummingbird',
    name: 'Zip the Hummingbird',
    emoji: '🐦',
    svgAsset: 'assets/bot_avatars/hummingbird.svg',
    imageDir: 'assets/bot_avatars/hummingbird',
    lichessUsername: 'uSunfish-l0',
    approxRating: 896,
    description: "I move super fast — blink and you'll miss my tricks!",
    difficulty: '⭐⭐ Speedy',
    colorHex: 0xFF80DEEA,
  ),
  // ~1140 rapid — EdwardKillick, 1,994+ rapid games, reliably online
  rabbit(
    id: 'rabbit',
    name: 'Rosie the Rabbit',
    emoji: '🐰',
    svgAsset: 'assets/bot_avatars/rabbit.svg',
    imageDir: 'assets/bot_avatars/rabbit',
    lichessUsername: 'EdwardKillick',
    approxRating: 1140,
    description: "I hop around quickly — watch out, I can be tricky!",
    difficulty: '⭐⭐⭐ Tricky',
    colorHex: 0xFFFFCDD2,
  ),
  // ~1260 rapid — AllieTheChessBot, human-like ML bot, 4,963+ rapid games
  kangaroo(
    id: 'kangaroo',
    name: 'Kira the Kangaroo',
    emoji: '🦘',
    svgAsset: 'assets/bot_avatars/kangaroo.svg',
    imageDir: 'assets/bot_avatars/kangaroo',
    lichessUsername: 'AllieTheChessBot',
    approxRating: 1260,
    description: "I learn by watching — I'll leap ahead when you least expect it!",
    difficulty: '⭐⭐⭐ Cunning',
    colorHex: 0xFFD7CCC8,
  ),
  // ~1290 rapid — sargon-1ply, classic engine, 39,924+ rapid games, very reliable
  deer(
    id: 'deer',
    name: 'Dino the Deer',
    emoji: '🦌',
    svgAsset: 'assets/bot_avatars/deer.svg',
    imageDir: 'assets/bot_avatars/deer',
    lichessUsername: 'sargon-1ply',
    approxRating: 1290,
    description: "I play sharp and fast — watch out for my attacks!",
    difficulty: '⭐⭐⭐ Sharp',
    colorHex: 0xFFA1887F,
  ),
  // ~1376 rapid — Humaia, Maia-1400 network, 17,786+ rapid games, reliably online
  giraffe(
    id: 'giraffe',
    name: 'Gabi the Giraffe',
    emoji: '🦒',
    svgAsset: 'assets/bot_avatars/giraffe.svg',
    imageDir: 'assets/bot_avatars/giraffe',
    lichessUsername: 'Humaia',
    approxRating: 1376,
    description: "I see the whole board from up high — I play like a real person!",
    difficulty: '⭐⭐⭐⭐ Fierce',
    colorHex: 0xFFFFCC80,
  ),
  // ~1408 rapid — bernstein-4ply, Bernstein 1957 engine, 7,181+ rapid games
  tiger(
    id: 'tiger',
    name: 'Tara the Tiger',
    emoji: '🐯',
    svgAsset: 'assets/bot_avatars/tiger.svg',
    imageDir: 'assets/bot_avatars/tiger',
    lichessUsername: 'bernstein-4ply',
    approxRating: 1408,
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

/// Challenges a real Lichess bot account.
class BotService {
  final LichessClient _client;

  BotService(this._client);

  Future<String> challengeBot(
    BotCharacter character, {
    String color = 'random',
    int clockLimit = 600,
    int clockIncrement = 5,
  }) {
    return _client.challengeUser(
      username: character.lichessUsername,
      color: color,
      clockLimit: clockLimit,
      clockIncrement: clockIncrement,
      rated: false,
    );
  }
}
