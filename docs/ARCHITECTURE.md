# Architecture & Technical Reference

## Tech Stack Overview

| Layer | Choice | Version | Why |
|-------|--------|---------|-----|
| Framework | Flutter (Dart) | 3.x | Lichess mobile uses it; single codebase iOS+Android |
| State | flutter_riverpod | ^3.2.0 | Async streams, autoDispose, tested at Lichess scale |
| Chess board UI | chessground | ^9.0.0 | Lichess's own widget — customizable, performant |
| Chess logic | dartchess | ^0.12.0 | Full move gen, FEN/PGN, chess960, used by Lichess |
| Bot play | Lichess API (`challenge:write` scope) | — | Challenge real bot accounts (no embedded engine) |
| Local DB | sqflite | ^2.2.5 | Offline puzzle batch cache |
| Auth | flutter_secure_storage | ^10.0.0 | OAuth tokens + parent PIN |
| Routing | go_router | ^14.0.0 | Declarative navigation, deep links |
| HTTP | http | ^1.1.0 | Lichess API calls |
| WebSocket | web_socket_channel | ^3.0.0 | Lichess ndjson game streams |
| Animations | lottie | ^3.0.0 | Celebration overlays |
| Notifications | flutter_local_notifications | ^21.0.0 | Turn reminders |

## Reference: Lichess Mobile Repository

- **URL:** https://github.com/lichess-org/mobile
- **License:** GPL-3.0
- **Language:** Dart / Flutter (99.8%)
- **Pattern:** Feature-driven, domain-driven architecture

### Key Lichess Source Files to Study
```
lib/src/model/puzzle/
  puzzle_service.dart         # Business logic for puzzle fetch/submit
  puzzle_repository.dart      # API calls
  puzzle_batch_storage.dart   # SQLite batch cache
  puzzle_storage.dart         # Individual puzzle storage

lib/src/model/game/
  game_controller.dart        # Game state machine
  game_socket.dart            # WebSocket stream management

lib/src/model/lobby/
  game_seek.dart              # Seek creation
  lobby_repository.dart       # Seek API

lib/src/network/
  http.dart                   # LichessClient HTTP wrapper
  socket.dart                 # WebSocket with reconnect

lib/src/view/game/
  game_screen.dart            # Main game board UI
  game_result_screen.dart     # Post-game result

lib/src/view/puzzle/
  puzzle_screen.dart          # Puzzle solving UI
```

## Lichess API: Key Patterns

### AI Challenge Flow
```
POST /api/challenge/ai
  body: { level: 3, color: "white", clock: { limit: 600, increment: 5 } }
  → 201 { id: "abc12345", ... }

GET /api/board/game/stream/abc12345   ← ndjson stream
  → { type: "gameFull", ... }         ← initial full state
  → { type: "gameState", moves: "e2e4 e7e5", ... }  ← each move

POST /api/board/game/abc12345/move/e2e4   ← make a move
```

### Puzzle Batch Flow
```
GET /api/puzzle/batch/fork?nb=50    ← requires puzzle:read scope
  → { puzzles: [ { puzzle: { id, rating, solution, themes }, game: {...} }, ... ] }

POST /api/puzzle/batch/fork
  body: { solutions: [{ id: "abc", win: true }, ...] }
  ← submit results
```

### Human Seek Flow
```
POST /api/board/seek
  body: { rated: false, time: 5, increment: 3, ratingRange: "800-1200" }

GET /api/stream/event   ← keep open; fires when opponent found
  → { type: "gameStart", game: { id: "xyz99999" } }
  ← then switch to game stream
```

## Riverpod Provider Patterns

### Async data fetch (puzzle)
```dart
final dailyPuzzleProvider = FutureProvider.autoDispose<Puzzle>((ref) async {
  final repo = ref.watch(puzzleRepositoryProvider);
  return repo.fetchDailyPuzzle();
});
```

### Game state stream
```dart
final gameControllerProvider =
  NotifierProvider.autoDispose.family<GameController, GameState, GameId>(
    GameController.new,
  );
```

### Offline-first puzzle batch
```dart
final nextPuzzleProvider = FutureProvider.autoDispose<Puzzle>((ref) async {
  final storage = ref.watch(puzzleBatchStorageProvider);
  final service = ref.watch(puzzleServiceProvider);

  // Get from local cache first
  final cached = await storage.nextPuzzle();
  if (cached != null) return cached;

  // Fetch new batch from API
  return service.fetchAndCacheNext();
});
```

## Safety Architecture

### Parental Controls Flow
```
App launch
  └─ Check if parental controls enabled (SharedPreferences)
     ├─ Online play disabled → show bot/puzzle only
     └─ Online play enabled
          └─ Session time tracking
               └─ Over daily limit → show "Time's up!" lock screen
```

### PIN Storage
```dart
// Store parent PIN in secure storage
const _pinKey = 'parent_pin';
await secureStorage.write(key: _pinKey, value: hashedPin);

// Verify PIN before settings access
final stored = await secureStorage.read(key: _pinKey);
return stored == hashPin(inputPin);
```

### Safe Chat Implementation
```dart
// Only these messages allowed
const approvedMessages = [
  'Good game!',
  'Nice move!',
  'Good luck!',
  'Well played!',
];

const approvedEmoji = ['👍', '👏', '🤔', '😮', '🎉'];
```

## Database Schema (SQLite)

### puzzle_batch table
```sql
CREATE TABLE puzzle_batch (
  id TEXT PRIMARY KEY,
  fen TEXT NOT NULL,
  solution TEXT NOT NULL,        -- JSON array of moves
  themes TEXT NOT NULL,          -- JSON array of theme strings
  rating INTEGER NOT NULL,
  angle TEXT NOT NULL,           -- 'fork', 'pin', 'mateIn1', etc.
  solved INTEGER DEFAULT 0,      -- 0=unsolved, 1=solved, 2=failed
  starred INTEGER DEFAULT 0      -- 1=star saved
);
```

### game_history table
```sql
CREATE TABLE game_history (
  id TEXT PRIMARY KEY,
  opponent_type TEXT NOT NULL,   -- 'bot' or 'human'
  opponent_level INTEGER,        -- 1-8 for bots
  result TEXT NOT NULL,          -- 'win', 'loss', 'draw'
  moves TEXT NOT NULL,           -- PGN moves string
  played_at INTEGER NOT NULL     -- Unix timestamp
);
```

### user_progress table
```sql
CREATE TABLE user_progress (
  id INTEGER PRIMARY KEY,
  xp INTEGER DEFAULT 0,
  puzzle_streak INTEGER DEFAULT 0,
  last_puzzle_date TEXT,
  trophies_json TEXT DEFAULT '[]'
);
```
