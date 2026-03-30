# ChessPals — Full Development Plan

## 1. Vision & Goals

**App Name:** ChessPals
**Target Audience:** Kids ages 5–14
**Platform:** iOS + Android (Flutter)
**Core Pillars:**
1. Play vs. animal-themed bots (8 difficulty levels)
2. Bite-sized puzzles with hints and celebrations
3. Safe human multiplayer with parental controls

---

## 2. Feature Breakdown

### Feature 1: Play vs. Bots

**What it does:** Kids challenge one of 8 animal characters, each backed by a real Lichess bot account below 1800 rapid rating, challenged via `POST /api/challenge/{username}`.

**Animal Characters → Lichess Bot Accounts:**
| Character | Lichess Bot | Approx. Rapid | Description |
|-----------|------------|--------------|-------------|
| Benny the Bear 🐻 | `uSunfish-l0` | ~887 | Just learning — makes lots of mistakes |
| Pip the Penguin 🐧 | `nittedal` | ~913 | Friendly beginner persona — tries its best |
| Foxy the Fox 🦊 | `AllieTheChessBot` | ~1222 | Learns from human games — cunning |
| Luna the Lion 🦁 | `Humaia` | ~1327 | Plays like a real ~1400 human |
| Oliver the Owl 🦉 | `maia1` | ~1573 | Maia: trained on 1100-rated human games |
| Zara the Zebra 🦓 | `maia5` | ~1613 | Maia: trained on 1500-rated human games |
| Anya the Eagle 🦅 | `marvin-1600` | ~1695 | Transformer mimicking a 1600-rated human |
| Rex the Dragon 🐉 | `maia9` | ~1694 | Maia: trained on 1900-rated games |

> **Note on Maia bots:** `maia1`, `maia5`, `maia9` are from a Cornell/UofT research project. They make human-like mistakes (not sterile engine errors), which is pedagogically better for kids learning pattern recognition.

**API Integration:**
- Challenge bot: `POST /api/challenge/{lichessUsername}` with `rated=false`
- Move streaming: `GET /api/board/game/stream/{gameId}` (ndjson)
- Move submission: `POST /api/board/game/{gameId}/move/{move}`
- **Internet required** — no offline bot play (no embedded engine)

**Game settings:**
- Time control: Unlimited (kids default), 5+3, 10+5
- Color: White / Black / Random
- Piece set: Animal pieces (default), Classic, Cartoon

**Kid UX:**
- Character intro animation when selecting opponent
- "Undo last move" button (unlimited, vs bots only — via abort+rematch from same position)
- Move hints (3 per game, highlighted target square)
- Win → confetti + character celebration animation
- Loss → encouraging message + "Rematch?" / "Try easier opponent?"

---

### Feature 2: Puzzles / Tactics

**What it does:** Daily puzzles + offline batch, rated by beginner difficulty. Kids earn stars and fill a trophy shelf.

**API Integration:**
- Daily puzzle: `GET /api/puzzle/daily` (no auth)
- Batch download: `GET /api/puzzle/batch/{angle}` with `puzzle:read` scope
  - Filter angles: `short` (1–2 moves), `fork`, `pin`, `mateIn1`, `mateIn2`, `promotion`
- Offline cache: SQLite via `sqflite` — store 100 puzzles per batch
- Progress sync: `POST /api/puzzle/batch/{angle}` to submit results

**Difficulty mapping for kids:**
| Star Level | Lichess Rating Range | Theme Focus |
|------------|---------------------|-------------|
| ⭐ Beginner | 800–1000 | mateIn1, oneMove |
| ⭐⭐ Explorer | 1000–1200 | mateIn2, pin, fork |
| ⭐⭐⭐ Adventurer | 1200–1400 | fork, pin, deflection |
| ⭐⭐⭐⭐ Champion | 1400–1600 | sacrifice, discoveredAttack |
| ⭐⭐⭐⭐⭐ Master | 1600+ | All themes |

**Puzzle UX flow:**
1. Show board position + "Find the best move!" prompt
2. Kid makes a move
3. **Correct:** Highlight move in green, play celebration sound, show next move in sequence
4. **Wrong:** Gentle "Not quite — try again!" (max 3 attempts), then show hint (highlight the key piece)
5. After solving: Star rating (1–3 stars based on hints/attempts), XP earned
6. Progress tracked in puzzle streak counter

**Daily Challenge:** One featured daily puzzle, always the Lichess daily puzzle. Special gold star reward.

---

### Feature 3: Play vs. Humans

**What it does:** Safe matchmaking against other kids with parental oversight and no free-form chat.

**API Integration:**
- Seek: `POST /api/board/seek` with `rated: false`, `ratingRange` filtered
- Event stream: `GET /api/stream/event` for game start/challenge events
- Move streaming + submission: same Board API as bot games

**Safety Features:**
- **No free-form chat.** Communication limited to:
  - Pre-set emoji reactions: 👍 👏 🤔 😮
  - "Good game!" / "Nice move!" / "Good luck!" pre-approved phrases only
- **Rating-range matchmaking:** Automatically filters opponents within ±200 rating points
- **Parent PIN** required to enable online play at all
- **Session time limits:** Parent sets max daily play time (30min / 1hr / unlimited)
- **Friend challenges only (optional):** Parent can restrict to friend-list only
- **Anonymous usernames:** Auto-generated animal names (e.g., "HappyLion42") — no real names
- **Rematch/abort:** Kids can resign or abort without penalty in casual mode

**Online Play UX:**
- "Find a Friend to Play!" matching animation (animal characters shaking hands)
- Opponent shown as their animal avatar (not username by default)
- Move countdown timer shown as a colored arc (not just numbers)
- Disconnect → automatic abort after 60 seconds, no loss recorded

---

## 3. Screen Architecture

### Navigation Structure
```
Tab Bar (bottom):
├── 🏠 Home
├── 🧩 Puzzles
├── 🤖 Play Bot
├── 👥 Play Human
└── 🏆 My Trophies
```

### Screen List
| Screen | Purpose |
|--------|---------|
| `HomeScreen` | Daily puzzle preview, streak, recent activity, character greeting |
| `PuzzleScreen` | Puzzle board + hints + star rating |
| `PuzzleDoneScreen` | Result + XP + next puzzle CTA |
| `BotSelectScreen` | Grid of 8 animal characters with level descriptions |
| `GameScreen` | Chess board, move list, undo/hint buttons |
| `GameResultScreen` | Win/loss animation + stats + rematch |
| `LobbyScreen` | Seek matchmaking, time control picker |
| `TrophyScreen` | Achievement shelf, puzzle stats, win history |
| `ParentSettingsScreen` | PIN-protected: online play, time limits, friend-only mode |
| `OnboardingScreen` | Animated tutorial (piece movements, rules intro) |
| `SettingsScreen` | Piece set, board theme, sound, language |

---

## 4. Technical Architecture

### Package Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter_riverpod: ^3.2.0       # State management
  dartchess: ^0.12.0              # Chess logic, FEN/PGN
  chessground: ^9.0.0             # Board UI widget
  stockfish: ^1.8.1               # Embedded Stockfish engine
  sqflite: ^2.2.5                 # Offline puzzle SQLite cache
  shared_preferences: ^2.1.0      # User settings
  flutter_secure_storage: ^10.0.0 # OAuth tokens, parent PIN
  http: ^1.1.0                    # Lichess API HTTP client
  web_socket_channel: ^3.0.0     # Lichess game event streaming
  lottie: ^3.0.0                  # Celebration animations
  flutter_local_notifications: ^21.0.0  # Game reminders
  go_router: ^14.0.0              # Navigation
  freezed_annotation: ^2.4.0     # Immutable state models
  json_annotation: ^4.8.0        # JSON serialization

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.7.0
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

### Module Structure
```
lib/src/
├── model/
│   ├── auth/           # OAuth tokens, session
│   ├── puzzle/         # Puzzle batch, storage, service, repository
│   ├── game/           # Game state, move history, clock
│   ├── lobby/          # Seek, matchmaking
│   ├── bot/            # Bot character definitions, Stockfish wrapper
│   ├── user/           # User profile, rating, avatar
│   └── parental/       # Parental control settings
├── view/
│   ├── home/
│   ├── puzzle/
│   ├── game/
│   ├── bot_select/
│   ├── lobby/
│   ├── trophy/
│   ├── settings/
│   └── onboarding/
├── network/
│   ├── lichess_client.dart     # HTTP client with Bearer auth
│   ├── lichess_socket.dart     # WebSocket event stream
│   └── api_constants.dart      # Base URLs, endpoints
├── db/
│   ├── puzzle_batch_storage.dart
│   └── game_history_storage.dart
├── styles/
│   ├── colors.dart             # ChessPals color palette
│   ├── typography.dart         # Kid-friendly fonts
│   └── theme.dart              # MaterialTheme config
└── widgets/
    ├── animal_avatar.dart      # Reusable animal character widget
    ├── star_rating.dart        # 1–3 star display
    ├── celebration_overlay.dart # Confetti + animation overlay
    ├── safe_chat_bar.dart       # Pre-approved phrases only
    └── timer_arc.dart          # Arc-style countdown timer
```

### Lichess API Client Pattern
```dart
// network/lichess_client.dart
class LichessClient {
  static const baseUrl = 'https://lichess.org';

  Future<Response> challengeAi({required int level, String color = 'random'});
  Future<Response> boardSeek({int? ratingRangeMin, int? ratingRangeMax});
  Stream<GameEvent> streamGameEvents(String gameId);
  Future<Response> makeMove(String gameId, String move);
  Future<PuzzleBatch> fetchPuzzleBatch(String angle, {int count = 50});
  Future<Puzzle> fetchDailyPuzzle();
}
```

---

## 5. Design System

### Color Palette
| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#4CAF50` | Buttons, progress bars, highlights |
| `primaryDark` | `#388E3C` | Pressed states, headers |
| `secondary` | `#FF9800` | Stars, XP, warm accents |
| `accent` | `#2196F3` | Links, selection highlights |
| `background` | `#FAFFF4` | App background (light, slightly green) |
| `surface` | `#FFFFFF` | Cards, dialogs |
| `error` | `#F44336` | Wrong move indicator |
| `success` | `#66BB6A` | Correct move, win state |
| `boardLight` | `#F5CBA7` | Light board squares (warm wood) |
| `boardDark` | `#A0522D` | Dark board squares |

### Typography
- **Headings:** Nunito (round, friendly, great for kids)
- **Body:** Nunito Sans
- **Minimum font size:** 16sp (body), 20sp (headings)

### Chess Board Themes
1. **Forest** (default) — green and wood tones, animal piece set
2. **Ocean** — blue and teal tones
3. **Classic** — standard brown/cream
4. **Candy** — pink/purple for younger kids

### Piece Sets
1. **Animal** (default) — cartoon animal pieces (custom artwork)
2. **Classic** — standard SVG pieces
3. **Cartoon** — rounded, colorful cartoon pieces

---

## 6. Safety & Compliance

### COPPA Compliance
- No collection of personal data from users under 13 without verifiable parental consent
- No behavioral advertising targeting minors
- Parental email verification for account creation
- All game data anonymous by default

### Child Safety Design
| Feature | Implementation |
|---------|---------------|
| No free-form chat | Only emoji + pre-approved phrases |
| Anonymous usernames | Auto-generated (e.g., "SwiftFox42") |
| No public profiles | Stats visible only to the child and parent |
| Parent dashboard | PIN-protected settings screen |
| Time limits | App enforces daily play cap with lock screen |
| Safe matchmaking | Rating range filter, no messaging before game |
| Reporting | "Report opponent" button — sends flag to moderation |

---

## 7. Gamification & Progression System

### XP and Levels
- Earn XP for: solving puzzles (+10–50 based on difficulty), winning games (+25), daily login (+5)
- Level up every 500 XP: unlocks new board theme or piece set

### Trophy System
| Trophy | Condition |
|--------|-----------|
| 🧩 First Puzzle | Solve your first puzzle |
| 🔥 3-Day Streak | Solve puzzles 3 days in a row |
| 🤖 Bot Beater | Beat a bot for the first time |
| 👥 Social Player | Play 10 games vs humans |
| ♟️ Fork Master | Solve 10 fork puzzles |
| 👑 Champion | Beat Level 8 (Rex the Dragon) |
| 📅 Daily Hero | Complete 7 daily puzzles |

### Streak System
- Daily puzzle streak tracked locally + synced to Lichess
- Streak broken if no puzzle solved by midnight (local time)
- Streak shown on home screen with fire animation

---

## 8. Development Phases

### Phase 1 — Foundation (Weeks 1–4)
- [ ] Flutter project setup with Riverpod, go_router
- [ ] Lichess API client (HTTP + WebSocket)
- [ ] `dartchess` + `chessground` integration
- [ ] ChessPals design system (colors, typography, theme)
- [ ] Offline Stockfish bot game (levels 1–8)
- [ ] Basic game screen (board, moves, resign)

### Phase 2 — Core Features (Weeks 5–8)
- [ ] Animal bot characters with artwork
- [ ] Puzzle batch download + SQLite storage
- [ ] Puzzle solving screen (hints, attempts, stars)
- [ ] Daily puzzle screen
- [ ] Basic trophy system

### Phase 3 — Online Play (Weeks 9–12)
- [ ] Lichess OAuth2 authentication
- [ ] Online matchmaking (board seek API)
- [ ] Safe chat bar (emoji + pre-approved phrases)
- [ ] Parental controls screen (PIN-protected)
- [ ] Session time limit enforcement

### Phase 4 — Polish (Weeks 13–16)
- [ ] Onboarding tutorial (animated piece movements)
- [ ] Celebration animations (Lottie/Rive)
- [ ] Sound effects (moves, captures, check, win/loss)
- [ ] Multiple board/piece themes
- [ ] Trophy screen with full achievement list
- [ ] Performance optimization (lazy loading, image caching)
- [ ] Accessibility (large tap targets, screen reader support)

### Phase 5 — Launch Prep (Weeks 17–20)
- [ ] Privacy policy and COPPA compliance review
- [ ] App Store / Play Store metadata and screenshots
- [ ] Beta testing with kids age 6–12
- [ ] Firebase Crashlytics + analytics setup (COPPA-mode)
- [ ] Final localization (English + major languages)

---

## 9. API Reference Summary

### Lichess Endpoints Used

| Feature | Method | Endpoint | Auth |
|---------|--------|----------|------|
| Challenge AI bot | POST | `/api/challenge/ai` | `challenge:write` |
| Board game stream | GET | `/api/board/game/stream/{gameId}` | `board:play` |
| Make move | POST | `/api/board/game/{gameId}/move/{move}` | `board:play` |
| Seek human game | POST | `/api/board/seek` | `board:play` |
| Event stream | GET | `/api/stream/event` | `board:play` |
| Daily puzzle | GET | `/api/puzzle/daily` | None |
| Get puzzle by ID | GET | `/api/puzzle/{id}` | None |
| Puzzle batch | GET | `/api/puzzle/batch/{angle}` | `puzzle:read` |
| Submit puzzle results | POST | `/api/puzzle/batch/{angle}` | `puzzle:write` |
| User profile | GET | `/api/user/{username}` | None |

### OAuth Scopes Required
- `challenge:write` — create AI challenges
- `board:play` — play games, seek opponents, stream events
- `puzzle:read` — fetch puzzle batches and history
- `puzzle:write` — submit puzzle results

---

## 10. Open Questions / Decisions Needed

1. **Account required?** Consider "Play as Guest" mode (no OAuth) for offline puzzles only. Bot play and human play both require a Lichess account (OAuth `board:play` scope needed to challenge bot accounts).
2. **Age verification approach:** Use parental email verification flow or rely on app store age restrictions?
3. **Moderation for online play:** Use Lichess's existing moderation, or build an independent moderated environment?
4. **Animal piece set art:** Commission custom SVG animal chess pieces, or use/license existing sets (e.g., from ChessKid or open repositories)?
5. **Push notifications:** Enable "It's your turn!" notifications for correspondence games? Requires parental consent under COPPA.
6. **Puzzle database age-appropriateness:** Lichess puzzles include all themes. Should puzzles be pre-screened/curated, or is the rating-range filter sufficient?
