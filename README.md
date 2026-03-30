# ChessPals — Kids Chess App

A kid-friendly chess app inspired by Lichess mobile, with animal characters, puzzles, bot play, and safe human matchmaking. Built with Flutter, powered by the Lichess API.

## Core Features
1. **Play vs Bots** — 8 difficulty levels mapped to animal characters (powered by Stockfish via Lichess API)
2. **Puzzles / Tactics** — Beginner-friendly puzzles from Lichess's 3M+ puzzle database, cached offline
3. **Play vs Humans** — Safe matchmaking with parental controls (rating-range filtered, no free-form chat)

## Project Structure
```
chess-kids-app/
├── docs/               # Planning, architecture, and design documents
├── design/             # UI/UX mockups, color palettes, character designs
├── src/                # Flutter app source
│   ├── lib/
│   │   ├── src/
│   │   │   ├── model/      # Domain logic per feature
│   │   │   ├── view/       # UI screens per feature
│   │   │   ├── network/    # HTTP + WebSocket clients
│   │   │   ├── db/         # SQLite helpers
│   │   │   ├── styles/     # Theme, colors, typography
│   │   │   ├── widgets/    # Shared reusable widgets
│   │   │   └── utils/      # Helpers
│   │   └── assets/
│   │       ├── images/     # Character artwork, board themes
│   │       ├── animations/ # Lottie/Rive celebration animations
│   │       └── sounds/     # Move sounds, celebrations
└── api/                # Lichess API integration notes and examples
```

## Tech Stack
- **Framework:** Flutter (Dart)
- **State:** Riverpod
- **Chess board UI:** chessground
- **Chess logic:** dartchess
- **Offline engine:** stockfish (embedded Stockfish)
- **Online play:** Lichess API (board:play, puzzle:read scopes)
- **Local DB:** sqflite (offline puzzle cache)
- **Auth:** Lichess OAuth2

## Reference Projects
- [Lichess Mobile App](https://github.com/lichess-org/mobile)
- [Lichess API Docs](https://lichess.org/api)
- [ChessKid.com](https://www.chesskid.com)
