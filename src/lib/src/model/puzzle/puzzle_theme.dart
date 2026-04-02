/// Puzzle themes, difficulty levels, and settings for Lichess puzzle training.
///
/// Theme data sourced from Lichess API.
/// Hungarian translations from the official Lichess hu-HU.xml.

import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';

// ─── Difficulty ──────────────────────────────────────────────────────────────

enum PuzzleDifficulty {
  easiest,
  easier,
  normal,
  harder,
  hardest;

  /// The value sent to the Lichess API.
  String get apiValue => name;
}

// ─── Theme Categories ────────────────────────────────────────────────────────

enum PuzzleThemeCategory {
  meta,
  tactics,
  checkmates,
  phases,
  endgameTypes,
  goals,
  specialMoves,
  length,
  attackSide,
  origin;

  String localizedName(AppLocalizations l) => switch (this) {
        meta => l.puzzleCategoryMeta,
        tactics => l.puzzleCategoryTactics,
        checkmates => l.puzzleCategoryCheckmates,
        phases => l.puzzleCategoryPhases,
        endgameTypes => l.puzzleCategoryEndgameTypes,
        goals => l.puzzleCategoryGoals,
        specialMoves => l.puzzleCategorySpecialMoves,
        length => l.puzzleCategoryLength,
        attackSide => l.puzzleCategoryAttackSide,
        origin => l.puzzleCategoryOrigin,
      };
}

// ─── Themes ──────────────────────────────────────────────────────────────────

class PuzzleTheme {
  const PuzzleTheme({
    required this.apiKey,
    required this.nameEn,
    required this.nameHu,
    required this.emoji,
    required this.category,
  });

  /// The value sent to the Lichess API as the "angle" parameter.
  final String apiKey;
  final String nameEn;
  final String nameHu;
  final String emoji;
  final PuzzleThemeCategory category;

  String localizedName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'hu' ? nameHu : nameEn;
  }

  static const all = <PuzzleTheme>[
    // ── Meta ──
    PuzzleTheme(apiKey: 'mix', nameEn: 'Healthy Mix', nameHu: 'Vegyes mix', emoji: '🎲', category: PuzzleThemeCategory.meta),

    // ── Tactics ──
    PuzzleTheme(apiKey: 'fork', nameEn: 'Fork', nameHu: 'Villa', emoji: '🍴', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'pin', nameEn: 'Pin', nameHu: 'Kötés', emoji: '📌', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'skewer', nameEn: 'Skewer', nameHu: 'Nyárs', emoji: '🗡️', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'sacrifice', nameEn: 'Sacrifice', nameHu: 'Áldozat', emoji: '💎', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'hangingPiece', nameEn: 'Hanging Piece', nameHu: 'Lógó figura', emoji: '🎯', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'discoveredAttack', nameEn: 'Discovered Attack', nameHu: 'Felfedett támadás', emoji: '🔓', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'discoveredCheck', nameEn: 'Discovered Check', nameHu: 'Felfedett sakk', emoji: '🔑', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'doubleCheck', nameEn: 'Double Check', nameHu: 'Kettős sakk', emoji: '✌️', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'deflection', nameEn: 'Deflection', nameHu: 'Elterelés', emoji: '↪️', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'attraction', nameEn: 'Attraction', nameHu: 'Ráterelés', emoji: '🧲', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'interference', nameEn: 'Interference', nameHu: 'Akadályozás', emoji: '🚧', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'intermezzo', nameEn: 'Intermezzo', nameHu: 'Köztes lépés', emoji: '⚡', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'quietMove', nameEn: 'Quiet Move', nameHu: 'Csendes lépés', emoji: '🤫', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'defensiveMove', nameEn: 'Defensive Move', nameHu: 'Védekező lépés', emoji: '🛡️', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'clearance', nameEn: 'Clearance', nameHu: 'Felszabadítás', emoji: '🧹', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'capturingDefender', nameEn: 'Capturing Defender', nameHu: 'A védő leütése', emoji: '⚔️', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'advancedPawn', nameEn: 'Advanced Pawn', nameHu: 'Előretört gyalog', emoji: '♟', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'attackingF2F7', nameEn: 'Attacking f2/f7', nameHu: 'Az f2 vagy f7 támadása', emoji: '🎪', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'exposedKing', nameEn: 'Exposed King', nameHu: 'Kiszolgáltatott király', emoji: '👑', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'trappedPiece', nameEn: 'Trapped Piece', nameHu: 'Csapda', emoji: '🪤', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'xRayAttack', nameEn: 'X-Ray Attack', nameHu: 'Röntgen támadás', emoji: '🔬', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'zugzwang', nameEn: 'Zugzwang', nameHu: 'Lépéskényszer', emoji: '🔒', category: PuzzleThemeCategory.tactics),
    PuzzleTheme(apiKey: 'collinearMove', nameEn: 'Collinear Move', nameHu: 'Kollineáris lépés', emoji: '📐', category: PuzzleThemeCategory.tactics),

    // ── Checkmates ──
    PuzzleTheme(apiKey: 'mate', nameEn: 'Checkmate', nameHu: 'Matt', emoji: '👑', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'mateIn1', nameEn: 'Mate in 1', nameHu: 'Matt 1 lépésben', emoji: '1️⃣', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'mateIn2', nameEn: 'Mate in 2', nameHu: 'Matt 2 lépésben', emoji: '2️⃣', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'mateIn3', nameEn: 'Mate in 3', nameHu: 'Matt 3 lépésben', emoji: '3️⃣', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'mateIn4', nameEn: 'Mate in 4', nameHu: 'Matt 4 lépésben', emoji: '4️⃣', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'mateIn5', nameEn: 'Mate in 5+', nameHu: 'Matt 5 vagy több lépésben', emoji: '5️⃣', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'backRankMate', nameEn: 'Back Rank Mate', nameHu: 'Alapsori matt', emoji: '🏰', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'smotheredMate', nameEn: 'Smothered Mate', nameHu: 'Fojtott matt', emoji: '🫂', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'anastasiaMate', nameEn: 'Anastasia\'s Mate', nameHu: 'Anasztázia-matt', emoji: '🌹', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'arabianMate', nameEn: 'Arabian Mate', nameHu: 'Arab matt', emoji: '🐪', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'bodenMate', nameEn: 'Boden\'s Mate', nameHu: 'Boden mattja', emoji: '✝️', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'doubleBishopMate', nameEn: 'Double Bishop Mate', nameHu: 'Futópár matt', emoji: '⛪', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'dovetailMate', nameEn: 'Dovetail Mate', nameHu: 'Fecskefark matt', emoji: '🕊️', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'hookMate', nameEn: 'Hook Mate', nameHu: 'Horog matt', emoji: '🪝', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'operaMate', nameEn: 'Opera Mate', nameHu: 'Opera matt', emoji: '🎭', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'killBoxMate', nameEn: 'Kill Box Mate', nameHu: 'Kill box matt', emoji: '📦', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'balestraMate', nameEn: 'Balestra Mate', nameHu: 'Balestra-matt', emoji: '🤺', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'blindSwineMate', nameEn: 'Blind Swine Mate', nameHu: 'Vakmalac-matt', emoji: '🐷', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'cornerMate', nameEn: 'Corner Mate', nameHu: 'Sarok matt', emoji: '📐', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'epauletteMate', nameEn: 'Epaulette Mate', nameHu: 'Epaulette matt', emoji: '🎖️', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'morphysMate', nameEn: 'Morphy\'s Mate', nameHu: 'Morphy mattja', emoji: '🎩', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'pillsburysMate', nameEn: 'Pillsbury\'s Mate', nameHu: 'Pillsbury mattja', emoji: '🏛️', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'swallowstailMate', nameEn: 'Swallow\'s Tail Mate', nameHu: 'Fecskefark-matt', emoji: '🦅', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'triangleMate', nameEn: 'Triangle Mate', nameHu: 'Háromszög matt', emoji: '🔺', category: PuzzleThemeCategory.checkmates),
    PuzzleTheme(apiKey: 'vukovicMate', nameEn: 'Vukovic Mate', nameHu: 'Vukovic matt', emoji: '🏅', category: PuzzleThemeCategory.checkmates),

    // ── Game Phases ──
    PuzzleTheme(apiKey: 'opening', nameEn: 'Opening', nameHu: 'Megnyitás', emoji: '🌅', category: PuzzleThemeCategory.phases),
    PuzzleTheme(apiKey: 'middlegame', nameEn: 'Middlegame', nameHu: 'Középjáték', emoji: '⚔️', category: PuzzleThemeCategory.phases),
    PuzzleTheme(apiKey: 'endgame', nameEn: 'Endgame', nameHu: 'Végjáték', emoji: '🌇', category: PuzzleThemeCategory.phases),

    // ── Endgame Types ──
    PuzzleTheme(apiKey: 'pawnEndgame', nameEn: 'Pawn Endgame', nameHu: 'Gyalogvégjáték', emoji: '♟', category: PuzzleThemeCategory.endgameTypes),
    PuzzleTheme(apiKey: 'knightEndgame', nameEn: 'Knight Endgame', nameHu: 'Huszár végjáték', emoji: '♞', category: PuzzleThemeCategory.endgameTypes),
    PuzzleTheme(apiKey: 'bishopEndgame', nameEn: 'Bishop Endgame', nameHu: 'Futóvégjáték', emoji: '♝', category: PuzzleThemeCategory.endgameTypes),
    PuzzleTheme(apiKey: 'rookEndgame', nameEn: 'Rook Endgame', nameHu: 'Bástya végjáték', emoji: '♜', category: PuzzleThemeCategory.endgameTypes),
    PuzzleTheme(apiKey: 'queenEndgame', nameEn: 'Queen Endgame', nameHu: 'Vezér végjáték', emoji: '♛', category: PuzzleThemeCategory.endgameTypes),
    PuzzleTheme(apiKey: 'queenRookEndgame', nameEn: 'Queen & Rook', nameHu: 'Vezér és bástya', emoji: '♛♜', category: PuzzleThemeCategory.endgameTypes),

    // ── Goals ──
    PuzzleTheme(apiKey: 'equality', nameEn: 'Equality', nameHu: 'Egyenlőség', emoji: '⚖️', category: PuzzleThemeCategory.goals),
    PuzzleTheme(apiKey: 'advantage', nameEn: 'Advantage', nameHu: 'Előny', emoji: '📈', category: PuzzleThemeCategory.goals),
    PuzzleTheme(apiKey: 'crushing', nameEn: 'Crushing', nameHu: 'Megsemmisítés', emoji: '💥', category: PuzzleThemeCategory.goals),

    // ── Special Moves ──
    PuzzleTheme(apiKey: 'castling', nameEn: 'Castling', nameHu: 'Sáncolás', emoji: '🏰', category: PuzzleThemeCategory.specialMoves),
    PuzzleTheme(apiKey: 'enPassant', nameEn: 'En Passant', nameHu: 'En passant', emoji: '👻', category: PuzzleThemeCategory.specialMoves),
    PuzzleTheme(apiKey: 'promotion', nameEn: 'Promotion', nameHu: 'Átváltozás', emoji: '⬆️', category: PuzzleThemeCategory.specialMoves),
    PuzzleTheme(apiKey: 'underPromotion', nameEn: 'Under-Promotion', nameHu: 'Minor-átváltozás', emoji: '♞', category: PuzzleThemeCategory.specialMoves),

    // ── Length ──
    PuzzleTheme(apiKey: 'oneMove', nameEn: 'One Move', nameHu: 'Egy lépéses feladvány', emoji: '1️⃣', category: PuzzleThemeCategory.length),
    PuzzleTheme(apiKey: 'short', nameEn: 'Short', nameHu: 'Rövid feladvány', emoji: '⏱️', category: PuzzleThemeCategory.length),
    PuzzleTheme(apiKey: 'long', nameEn: 'Long', nameHu: 'Hosszú feladvány', emoji: '⏳', category: PuzzleThemeCategory.length),
    PuzzleTheme(apiKey: 'veryLong', nameEn: 'Very Long', nameHu: 'Nagyon hosszú feladvány', emoji: '🕐', category: PuzzleThemeCategory.length),

    // ── Attack Side ──
    PuzzleTheme(apiKey: 'kingsideAttack', nameEn: 'Kingside Attack', nameHu: 'Királyszárnyi támadás', emoji: '➡️', category: PuzzleThemeCategory.attackSide),
    PuzzleTheme(apiKey: 'queensideAttack', nameEn: 'Queenside Attack', nameHu: 'Vezérszárnytámadás', emoji: '⬅️', category: PuzzleThemeCategory.attackSide),

    // ── Origin ──
    PuzzleTheme(apiKey: 'master', nameEn: 'Master Games', nameHu: 'Mesterjátszmák', emoji: '🏆', category: PuzzleThemeCategory.origin),
    PuzzleTheme(apiKey: 'masterVsMaster', nameEn: 'Master vs Master', nameHu: 'Mesterek egymás ellen', emoji: '🤝', category: PuzzleThemeCategory.origin),
    PuzzleTheme(apiKey: 'superGM', nameEn: 'Super GM', nameHu: 'Szupernagymesteri játszmák', emoji: '🌟', category: PuzzleThemeCategory.origin),
    PuzzleTheme(apiKey: 'playerGames', nameEn: 'Player Games', nameHu: 'Felhasználók játszmái', emoji: '👤', category: PuzzleThemeCategory.origin),
  ];

  /// Themes grouped by category, preserving the order of [PuzzleThemeCategory].
  static Map<PuzzleThemeCategory, List<PuzzleTheme>> get groupedByCategory {
    final map = <PuzzleThemeCategory, List<PuzzleTheme>>{};
    for (final cat in PuzzleThemeCategory.values) {
      final themes = all.where((t) => t.category == cat).toList();
      if (themes.isNotEmpty) map[cat] = themes;
    }
    return map;
  }

  /// Find a theme by its API key. Falls back to 'mix'.
  static PuzzleTheme fromApiKey(String key) =>
      all.firstWhere((t) => t.apiKey == key, orElse: () => all.first);
}

// ─── Settings ────────────────────────────────────────────────────────────────

class PuzzleSettings {
  const PuzzleSettings({
    this.theme = 'mix',
    this.difficulty = PuzzleDifficulty.normal,
    this.rated = true,
  });

  /// The Lichess API angle value (e.g. 'mix', 'fork', 'mateIn1').
  final String theme;
  final PuzzleDifficulty difficulty;
  final bool rated;

  PuzzleSettings copyWith({
    String? theme,
    PuzzleDifficulty? difficulty,
    bool? rated,
  }) =>
      PuzzleSettings(
        theme: theme ?? this.theme,
        difficulty: difficulty ?? this.difficulty,
        rated: rated ?? this.rated,
      );
}
