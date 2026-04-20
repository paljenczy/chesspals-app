# ChessPals — Kids Chess App

A kid-friendly chess app inspired by Lichess mobile, with animal characters, puzzles, bot play, and safe human matchmaking. Built with Flutter, powered by the Lichess API.

## Core Features
1. **Play vs Bots** — 8 difficulty levels mapped to animal characters, each backed by a real Lichess bot account (~750–1400 rapid). Falls back to Lichess Stockfish AI if a bot is offline.
2. **Puzzles / Tactics** — Beginner-friendly puzzles from Lichess's 3M+ puzzle database with theme/difficulty selection, hint system, and daily star tracking.
3. **Play vs Humans** — Safe matchmaking with Rapid time controls (10+0, 10+5, 15+10), rated/unrated toggle, no free-form chat.

## Project Structure
```
chess-kids-app/
├── .github/workflows/  # CI — weekly bot health check
├── src/                # Flutter app source
│   ├── lib/
│   │   ├── src/
│   │   │   ├── model/      # Domain logic per feature
│   │   │   ├── view/       # UI screens per feature
│   │   │   ├── network/    # HTTP clients, OAuth, Lichess API
│   │   │   ├── service/    # Audio, etc.
│   │   │   ├── styles/     # Theme, colors, typography
│   │   │   └── utils/      # Helpers
│   │   └── assets/
│   │       ├── bot_avatars/ # AI-generated animal PNGs (5 emotions each)
│   │       ├── kid_avatars/ # AI-generated kid avatar PNGs
│   │       └── sounds/      # Reaction WAV files
└── tools/              # Python scripts — avatar processing, bot health check
```

## Bot Lineup

| Character | Lichess Bot | Rating | Stockfish Fallback |
|-----------|------------|--------|--------------------|
| Bella the Bee | grandQ_AI | ~740 | Level 1 |
| Flutter the Butterfly | larryz-alterego | ~880 | Level 1 |
| Zip the Hummingbird | uSunfish-l0 | ~900 | Level 1 |
| Rosie the Rabbit | EdwardKillick | ~1140 | Level 1 |
| Kira the Kangaroo | bernstein-2ply | ~1235 | Level 2 |
| Dino the Deer | sargon-1ply | ~1290 | Level 2 |
| Gabi the Giraffe | Humaia | ~1376 | Level 2 |
| Tara the Tiger | bernstein-4ply | ~1408 | Level 3 |

Check bot availability: `python3 tools/check_bots.py`

## Tech Stack
- **Framework:** Flutter (Dart)
- **State:** Riverpod
- **Chess board UI:** chessground
- **Chess logic:** dartchess
- **Online play:** Lichess API (board:play, puzzle:read scopes)
- **Auth:** Lichess OAuth2 with PKCE
- **CI:** GitHub Actions (weekly bot health check)

## Development
```bash
# Dev token from .env
source src/.env
cd src && flutter run -d chrome --wasm --dart-define=LICHESS_TOKEN=$LICHESS_TOKEN

# Or use the launcher script
cd src && ./run.sh
```

## Reference Projects
- [Lichess Mobile App](https://github.com/lichess-org/mobile)
- [Lichess API Docs](https://lichess.org/api)
- [ChessKid.com](https://www.chesskid.com)
