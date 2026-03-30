# ChessPals — Implementation Specification

A kid-friendly Flutter chess app with three features: bot play, puzzles, and safe human matchmaking via Lichess.

---

## 1. Project Setup

### Flutter & Dart
- Flutter SDK: `>=3.22.0`
- Dart SDK: `>=3.3.0 <4.0.0`
- Platform target: Android (primary), iOS (secondary)
- Project root: `src/` (pubspec.yaml lives here)

### pubspec.yaml dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  dartchess: ^0.12.3
  chessground: ^9.0.0
  fast_immutable_collections: ^11.1.0
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  go_router: ^14.2.7
  http: ^1.2.1
  web_socket_channel: ^3.0.1
  sqflite: ^2.3.3+1
  shared_preferences: ^2.3.2
  flutter_secure_storage: ^10.0.0
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0
  intl: ^0.20.2
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.0.10+1
  audioplayers: ^6.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.13.1
  freezed: ^3.2.5
  json_serializable: ^6.8.0
  riverpod_generator: ^4.0.3
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  generate: true
```

### l10n.yaml
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

### Dev token injection
Pass `--dart-define=LICHESS_TOKEN=lip_xxx` to `flutter run` to pre-seed the OAuth token for development. The `main.dart` writes this to `FlutterSecureStorage` at startup. A `run.sh` script reads from a gitignored `.env` file:
```bash
# .env
LICHESS_TOKEN=your_token_here
```
```bash
# run.sh
source .env
flutter run -d <device> --dart-define=LICHESS_TOKEN=$LICHESS_TOKEN
```

---

## 2. Architecture

### State management: Riverpod
- All state through `AsyncNotifierProvider` / `NotifierProvider`
- No `StateNotifierProvider` (deprecated pattern)
- `ProviderScope` wraps the app in `main.dart`

### Navigation: go_router 14.x
- `ShellRoute` wraps the 3-tab home screens
- Async auth redirect: unauthenticated → `/login`
- `PopScope(canPop: false)` in game screens for back-button interception

### UI: Material 3
- Theme: `MaterialApp.router` with `ThemeData(useMaterial3: true)`
- Primary color: Forest green `#4CAF50`
- Font: Nunito (loaded via `google_fonts` at runtime)
- `ChessboardColorScheme.green` for offline, `.brown` for online games
- `PieceSet.cburnett.assets` for piece graphics

---

## 3. File Structure

```
src/
├── .env                          # gitignored — LICHESS_TOKEN=lip_...
├── .env.example                  # template with placeholder
├── .gitignore                    # includes .env
├── run.sh                        # reads .env, runs flutter with --dart-define
├── pubspec.yaml
├── l10n.yaml
├── assets/
│   ├── avatars/                  # kid avatar SVGs (DiceBear Adventurer)
│   ├── bot_avatars/              # bot animal face SVGs (code-generated)
│   │   ├── bee.svg … tiger.svg   # 8 top-level neutral avatars
│   │   ├── bee/                  # per-animal emotion dirs
│   │   │   ├── neutral.svg
│   │   │   ├── happy.svg
│   │   │   ├── sad.svg
│   │   │   ├── scared.svg
│   │   │   └── furious.svg
│   │   └── … (butterfly/ hummingbird/ rabbit/ kangaroo/ deer/ giraffe/ tiger/)
│   └── sounds/                   # reaction WAV files
│       ├── reaction_happy.wav
│       ├── reaction_sad.wav
│       ├── reaction_scared.wav
│       └── reaction_furious.wav
└── lib/
    ├── main.dart
    ├── l10n/
    │   ├── app_en.arb            # English strings
    │   ├── app_hu.arb            # Hungarian strings
    │   ├── app_localizations.dart           # generated
    │   ├── app_localizations_en.dart        # generated
    │   └── app_localizations_hu.dart        # generated
    └── src/
        ├── app.dart              # router + ChessPalsApp widget
        ├── model/
        │   ├── auth/
        │   │   └── lichess_account.dart   # also defines KidAvatar + KidAvatarWidget
        │   ├── bot/
        │   │   └── bot_character.dart
        │   ├── game/
        │   │   └── offline_game_controller.dart
        │   ├── matchmaking/
        │   │   └── matchmaking_controller.dart
        │   ├── parental/
        │   │   └── parental_settings.dart
        │   ├── puzzle/
        │   │   ├── puzzle.dart
        │   │   └── puzzle_controller.dart
        │   └── settings/
        │       └── locale_provider.dart
        ├── network/
        │   └── lichess_client.dart
        ├── service/
        │   └── reaction_audio.dart        # audio feedback for bot reactions
        ├── styles/
        │   ├── colors.dart
        │   ├── typography.dart
        │   └── theme.dart
        ├── utils/
        │   └── bot_l10n.dart              # localized bot name/difficulty/description helpers
        └── view/
            ├── auth/
            │   └── login_screen.dart
            ├── game/
            │   ├── online_game_screen.dart
            │   ├── bot_reaction.dart       # BotReaction enum, detectReaction(), BotCharacterAvatar
            │   ├── game_over_dialog.dart   # shared game-over dialog with analyze option
            │   └── analysis_screen.dart    # post-game move-by-move replay
            ├── home/
            │   └── home_screen.dart
            ├── kid/
            │   ├── kid_bot_select_screen.dart
            │   └── offline_game_screen.dart
            ├── play/
            │   └── play_human_screen.dart
            ├── puzzle/
            │   └── puzzle_screen.dart
            └── settings/
                └── settings_screen.dart
```

---

## 4. Entry Point

### lib/main.dart
```dart
const _devToken = String.fromEnvironment('LICHESS_TOKEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_devToken.isNotEmpty) {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'lichess_token', value: _devToken);
  }
  runApp(const ProviderScope(child: ChessPalsApp()));
}
```

---

## 5. Router (lib/src/app.dart)

```
/login               → LoginScreen
/bot                 → KidBotSelectScreen  (ShellRoute tab 0)
  /bot/game/:level   → OfflineGameScreen   (?char=0-7)
/puzzles             → PuzzleScreen        (ShellRoute tab 1)
/play                → PlayHumanScreen     (ShellRoute tab 2)
/game/:id            → OnlineGameScreen    (?side=white|black|random, ?from=bot|play, ?char=0-7)
/analysis            → AnalysisScreen      (via extra: {moves, fen, side})
/settings            → SettingsScreen
```

**Auth redirect:** If `accountProvider` resolves to `null` (not logged in), redirect to `/login`. Skip redirect for `/login`, `/bot/*`, and `/analysis`.

**`ChessPalsApp`** is a `ConsumerWidget` that:
- Watches `accountProvider` (so router rebuilds on login/logout)
- Watches `localeProvider`
- Returns `MaterialApp.router` with `localizationsDelegates`, `supportedLocales`, `locale`

---

## 6. Authentication

### Lichess OAuth2 PKCE Flow

The app uses Lichess OAuth2 with PKCE (Proof Key for Code Exchange) for authentication. No client secret or app registration needed — Lichess accepts any `client_id` for PKCE flows.

**Configuration:**
- Client ID: `chesspals`
- Redirect URI: `com.chesspals.chesspals://oauth-callback`
- Scope: `board:play`
- Authorization URL: `https://lichess.org/oauth`
- Token exchange URL: `https://lichess.org/api/token`

**Flow:**
1. App generates PKCE code verifier (64 random URL-safe chars) + code challenge (SHA-256, base64url, no padding) + random state
2. App opens `https://lichess.org/oauth?response_type=code&client_id=chesspals&...` in the browser
3. User authorizes → Lichess redirects to `com.chesspals.chesspals://oauth-callback?code=...&state=...`
4. App catches deep link via `app_links`, verifies state, exchanges code for token via `POST /api/token`
5. Token saved to `FlutterSecureStorage` → app navigates to `/bot`

**Platform deep link config:**
- Android: intent-filter in `AndroidManifest.xml` for `com.chesspals.chesspals://oauth-callback`
- iOS: `CFBundleURLSchemes` in `Info.plist` for `com.chesspals.chesspals`

### lib/src/network/lichess_oauth.dart
- `LichessOAuth` class: generates PKCE params, builds authorization URL, exchanges code for token
- One-shot usage: create instance, open `authorizationUrl` in browser, call `exchangeCodeForToken(code)` on callback

### lib/src/network/lichess_client.dart
- Token stored in `FlutterSecureStorage` under key `lichess_token`
- All authenticated requests include `Authorization: Bearer <token>` header
- Throws `LichessAuthException` (401), `LichessRateLimitException` (429), `LichessApiException` (other 4xx/5xx)
- `isLoggedIn` → async bool, checks token existence
- `saveToken(token)` / `clearToken()`

### lib/src/model/auth/lichess_account.dart

**`LichessAccount`** data class:
```dart
class LichessAccount {
  final String id;
  final String username;
  final int avatarIndex;   // 0–11
  final int? rapidRating;
  final int? puzzleRating;
}
```
Parsed from `GET /api/account` JSON (`perfs.rapid.rating`, `perfs.puzzle.rating`).

**`AccountNotifier extends AsyncNotifier<LichessAccount?>`**
- `build()`: checks `isLoggedIn`, calls `fetchAccount()`, loads/assigns avatar
- `login(token)`: saves token, reloads
- `logout()`: clears token, sets state to null
- `cycleAvatar()`: increments `avatarIndex` mod 12, persists to secure storage under key `kid_avatar_index_{userId}`
- Avatar index persisted separately per user ID in secure storage

**`accountProvider`** = `AsyncNotifierProvider<AccountNotifier, LichessAccount?>`

### Login screen (lib/src/view/auth/login_screen.dart)
- "Sign in with Lichess" button triggers OAuth PKCE flow
- Shows loading spinner during authorization
- On success: navigate to `/bot`
- On failure: show error message with retry
- Listens for deep link callback via `app_links`

### Dev token injection
Pass `--dart-define=LICHESS_TOKEN=lip_xxx` to `flutter run` to pre-seed a token for development, bypassing the OAuth flow.

---

## 7. Lichess API Client

### lib/src/network/lichess_client.dart

All calls to `https://lichess.org` with `Authorization: Bearer <token>`.

| Method | HTTP | Endpoint | Purpose |
|--------|------|----------|---------|
| `fetchAccount()` | GET | `/api/account` | Returns user JSON |
| `challengeUser(username, color, clockLimit, clockIncrement, rated)` | POST | `/api/challenge/{username}` | Returns `gameId` string |
| `streamGame(gameId)` | GET | `/api/board/game/stream/{gameId}` | Returns `Stream<Map<String,dynamic>>` of ndjson events |
| `makeMove(gameId, uci)` | POST | `/api/board/game/{gameId}/move/{uci}` | Submits a move |
| `resign(gameId)` | POST | `/api/board/game/{gameId}/resign` | Resign |
| `abort(gameId)` | POST | `/api/board/game/{gameId}/abort` | Abort (before 2 half-moves) |
| `offerDraw(gameId)` | POST | `/api/board/game/{gameId}/draw/yes` | Offer or accept a draw |
| `declineDraw(gameId)` | POST | `/api/board/game/{gameId}/draw/no` | Decline a draw offer |
| `fetchDailyPuzzle()` | GET | `/api/puzzle/daily` | Returns puzzle JSON |
| `fetchPuzzleBatch(angle, nb, ratingMin, ratingMax)` | GET | `/api/puzzle/batch/{angle}` | Returns batch of puzzles |
| `submitPuzzleResults(angle, results)` | POST | `/api/puzzle/batch/{angle}` | Submits solve/fail data |
| `seekOpponent(minutes, increment, rated)` | POST | `/api/board/seek` | Posts seek (fire-and-forget, blocks until matched) |
| `streamEvents()` | GET | `/api/stream/event` | Returns `Stream<Map<String,dynamic>>` of user events |

**ndjson streaming**: Use `http` chunked response + line splitting. Each line is a JSON object. Empty lines are heartbeats (ignore).

**Bot challenge defaults**: `clockLimit=600` (10 min), `clockIncrement=5`, `rated=false`, `color=random`.

---

## 8. Bot Characters

### lib/src/model/bot/bot_character.dart

8 characters as a Dart `enum` with const constructor fields:

| Enum | English Name | Emoji | Lichess Username | Rating | Difficulty |
|------|-------------|-------|-----------------|--------|------------|
| `bee` | Bella the Bee | 🐝 | grandQ_AI | 744 | ⭐ Beginner |
| `butterfly` | Flutter the Butterfly | 🦋 | larryz-alterego | 884 | ⭐⭐ Explorer |
| `hummingbird` | Zip the Hummingbird | 🐦 | uSunfish-l0 | 896 | ⭐⭐ Speedy |
| `rabbit` | Rosie the Rabbit | 🐰 | EdwardKillick | 1140 | ⭐⭐⭐ Tricky |
| `kangaroo` | Kira the Kangaroo | 🦘 | AllieTheChessBot | 1260 | ⭐⭐⭐ Cunning |
| `deer` | Dino the Deer | 🦌 | sargon-1ply | 1290 | ⭐⭐⭐ Sharp |
| `giraffe` | Gabi the Giraffe | 🦒 | Humaia | 1376 | ⭐⭐⭐⭐ Fierce |
| `tiger` | Tara the Tiger | 🐯 | bernstein-4ply | 1408 | ⭐⭐⭐⭐ Fierce+ |

Fields per character: `id`, `name` (English), `emoji`, `svgAsset`, `imageDir`, `lichessUsername`, `approxRating`, `description` (English), `difficulty` (English), `colorHex` (ARGB int).

**Color palette** (used for face fill and UI accents):
| Bot | Color hex | Visual |
|-----|-----------|--------|
| bee | `0xFFFDD835` | Yellow |
| butterfly | `0xFFCE93D8` | Purple |
| hummingbird | `0xFF80DEEA` | Cyan |
| rabbit | `0xFFFFCDD2` | Pink |
| kangaroo | `0xFFD7CCC8` | Taupe |
| deer | `0xFFA1887F` | Brown |
| giraffe | `0xFFFFCC80` | Gold |
| tiger | `0xFFEF6C00` | Orange |

**Emotion images**: Each bot has 5 SVG emotion variants in `assets/bot_avatars/{id}/`:
`neutral.svg`, `happy.svg`, `sad.svg`, `scared.svg`, `furious.svg`.

**`emotionAsset(BotReaction? reaction)`**: returns the asset path for a given emotion. Uses PNG if `hasPngEmotions` is true, SVG otherwise. Currently all bots use SVG (`hasPngEmotions => false`).

**Rating display**: Round to nearest 10 (`(rating / 10).round() * 10`).

**`BotService`**: wraps `LichessClient.challengeUser()`. Returns `gameId` string.

### SVG generation

A Python script (`tools/generate_animal_svgs.py`) generates all 48 SVG files (40 emotion variants + 8 top-level neutrals). Each animal is a simple rounded-square face with:
- Distinguishing features (antennae, ears, antlers, beak, stripes, spots, wings, ossicones)
- Cheek blush circles
- Emotion-specific eyes, mouth, and brows

Run: `python3 tools/generate_animal_svgs.py`

---

## 9. Bot Play Screens

### KidBotSelectScreen (lib/src/view/kid/kid_bot_select_screen.dart)
- 2-column `GridView` of 8 `_BotCard` widgets
- Each card: SVG animal avatar, localized name, localized difficulty, `~NNN rapid` rating, localized description
- Tap → call `BotService.challengeBot()` → show spinner → navigate to `/game/$gameId?side=random&from=bot&char=$index`
- Errors: show inline (login required / could not start game)

### OfflineGameScreen (lib/src/view/kid/offline_game_screen.dart)
- Route: `/bot/game/:level?char=N`
- Shows `AppBar` with bot SVG avatar + name
- Chessboard: `ChessboardColorScheme.green`, white always at bottom
- Status banner: "Your turn" / "Bot is thinking..." with spinner
- **Bot avatar reactions**: `BotCharacterAvatar` with animated emotional expressions triggered by game events (captures, checks, promotions)
- **Reaction audio**: plays corresponding WAV sound for each reaction
- Buttons: Resign (with confirmation dialog), New Game
- **Resign confirmation**: shows AlertDialog ("Resign?" / "Are you sure you want to give up this game?") before resigning
- **Game over dialog**: shows result with "Go Home" and "Analyze" options; "Analyze" navigates to `/analysis`

### OfflineGameController (lib/src/model/game/offline_game_controller.dart)
- `AsyncNotifierProvider.family<OfflineGameNotifier, OfflineGameState, int>`
- State: `fen`, `lastMove`, `sideToMove`, `isCheck`, `validMoves`, `status`, `pendingPromotion`, `moveHistory`
- `onMove(move)`: plays user move, triggers bot move via `_scheduleBotMove()`
- `onPromotion(role)`: completes pending promotion
- `resign()` / `newGame()`
- **Bot move delay**: 3 seconds before the bot responds (gives kids time to see their move)
- Bot AI: simple heuristic (pool-size shrinks with higher level), configurable by level 1–8

---

## 10. Online Game Screen

### lib/src/view/game/online_game_screen.dart

**Constructor params**: `gameId`, `playerSide` (white/black/random), `from` (bot/play), `characterIndex` (nullable int).

**Key behaviors**:
- Subscribes to `LichessClient.streamGame(gameId)` on `initState`
- Handles `gameFull` event: determines player side from `white.id` vs account id; extracts opponent name and rating
- Handles `gameState` events: replays all UCI moves from scratch using `dartchess`; parses `wtime`/`btime` for clocks, `wdraw`/`bdraw` for draw offers, `status` for game state
- Handles `status == 'aborted'`: navigates home silently (no error dialog)
- Pawn promotion: detects when a pawn reaches the last rank, sets `_pendingPromotion`, shows chessground's promotion picker UI
- `PopScope(canPop: false)`: intercepts Android back gesture

**Layout** (top to bottom):
1. `AppBar` with back button + draw offer icon (handshake, shown after ≥2 half-moves) + resign flag icon
2. Opponent row: 👤 emoji (or `BotCharacterAvatar` for bot games), name, rating, **opponent clock** (trailing)
3. Draw offer banner (conditional amber bar with Accept/Decline, shown when opponent offers a draw)
4. `Chessboard` widget (full width minus 16px padding)
5. Player row: `KidAvatarWidget` (tappable to cycle), username, rating, **player clock** (trailing)

**Chess Clocks**:
- State: `_whiteTimeMs`, `_blackTimeMs` (remaining milliseconds)
- Local countdown: 100ms `Timer.periodic` with wall-clock drift correction (`DateTime.now()` delta)
- Server-authoritative: each `gameState` event resets clocks to server values
- Display: `MM:SS` when ≥60s, `SS.T` (with tenths) when <60s
- Colors: green background = active, grey = inactive, red = low time (<30s)
- Monospace tabular figures for stable width

**Draw Offers**:
- Outgoing: handshake icon in AppBar, disabled+orange when already offered, only shown after ≥2 half-moves
- Incoming: `_DrawOfferBanner` amber bar between opponent row and board with Accept/Decline buttons
- API: `offerDraw()` = `POST /api/board/game/{id}/draw/yes` (also accepts), `declineDraw()` = `POST /api/board/game/{id}/draw/no`
- State parsed from `wdraw`/`bdraw` flags in `gameState` events, mapped to player perspective

**Bot reactions** (when `characterIndex` is set):
- `BotCharacterAvatar` shows animated emotional expressions
- `ReactionAudio` plays corresponding WAV sound
- Triggered by `detectReaction()` comparing old and new positions

**Opponent display** (human games):
- Shows opponent's Lichess username and rapid rating
- 👤 emoji instead of 🤖

**Back button / resign flow**:
- If game already over: navigate back immediately
- If `_totalMoves < 2`: show "Cancel game?" dialog → call `abort()`
- If `_totalMoves >= 2`: show "Resign?" dialog → call `resign()`
- Dialog strings are fully localized

**Game over dialog**: shows result with "Go Home" and "Analyze" options; "Analyze" navigates to `/analysis`.

**Error state**: shows "Connection error: {message}" with a Retry button that re-subscribes.

**ndjson stream resilience**: Both `streamGame()` and `streamEvents()` wrap `jsonDecode` in try-catch for `FormatException` — Lichess streams may send non-JSON data when closing (e.g., after abort). Invalid lines are silently skipped.

---

## 10a. Bot Reaction System

### lib/src/view/game/bot_reaction.dart

**`BotReaction`** enum: `happy`, `sad`, `scared`, `furious`.

**`detectReaction(Position oldPos, Position newPos, NormalMove? lastMove, {required Side playerSide})`**:
Priority order (first match wins):
- Player promotes a pawn → `furious`
- Player gives check → `scared`
- Player captures a piece → `sad`
- Bot captures a piece → `happy`
- Nothing notable → `null`

**`BotCharacterAvatar`** widget:
- Displays the current emotion SVG for the bot character at 48×48
- Animated transitions when `trigger(BotReaction)` is called
- Animation effects per reaction:
  - `happy` (800ms): elastic bounce + green tint
  - `sad` (1000ms): droop/shrink + blue tint
  - `scared` (600ms): rapid shake + yellow flash
  - `furious` (700ms): aggressive shake + red tint
- `isThinking` flag shows a subtle pulse animation

Used in both `OfflineGameScreen` and `OnlineGameScreen` (when `characterIndex` is set).

### lib/src/service/reaction_audio.dart

Static class for audio feedback during bot reactions.

- `preload()`: pre-loads 4 AudioPlayer instances for each reaction WAV at volume 0.7
- `play(BotReaction)`: fire-and-forget playback
- `dispose()`: cleanup
- Assets: `assets/sounds/reaction_{happy,sad,scared,furious}.wav`

---

## 10b. Game Over Dialog & Analysis

### lib/src/view/game/game_over_dialog.dart

`showGameOverDialog(context, {resultText, resultColor})` → returns `'home'` or `'analyze'`.

Displays:
- Result text (win/loss/draw) with color
- Two buttons: "Go Home" (icon: home) and "Analyze" (icon: analytics)

### lib/src/view/game/analysis_screen.dart

Post-game move-by-move replay screen.

**Constructor params**: `moves` (List<NormalMove>), `startingFen` (String), `playerSide` (Side).

**Behavior**:
- Pre-computes all board positions in `initState()` by replaying moves sequentially
- Starts at the final position
- Navigation buttons: Start (⏮), Previous (◀), Next (▶), End (⏭) with proper disabled states
- Shows ply counter ("Move N of M")
- Read-only chessboard (`PlayerSide.none`), green color scheme
- Board oriented to `playerSide`

---

## 11. Puzzles

### Puzzle data model (lib/src/model/puzzle/puzzle.dart)

**`Puzzle`** fields: `id`, `fen` (FEN before the triggering move), `fenAfterTrigger` (FEN after the triggering move — where the user starts solving), `triggerUci` (UCI of the last PGN move — the triggering move to auto-play), `initialPly`, `solution` (list of UCI moves — solution[0] is the user's first move), `rating`, `themes`, `angle`.

**Fetching**: `GET /api/puzzle/daily` and `GET /api/puzzle/batch/mix?nb=50&ratingMin=X&ratingMax=Y`.

**Local cache**: SQLite via `sqflite`. Puzzles stored in a `puzzle_batch` table, consumed one by one.

**PGN parsing** (`_parsePgn`): The Lichess puzzle API returns a game PGN containing all moves up to the puzzle position. The parser replays all PGN moves using dartchess's built-in `PgnGame.parsePgn()` + `Position.parseSan()` and returns three values:
- `fenBefore`: position before the last PGN move (what the user sees initially)
- `fenAfter`: position after the last PGN move (where solution[0] starts)
- `triggerUci`: the last PGN move in UCI format (the triggering move that auto-plays)

**Lichess puzzle structure**: The last PGN move is the opponent's "triggering" move that sets up the puzzle. `solution[0]` is the user's first move to find, not the trigger. The user plays the side to move **after** the trigger.

**Kid difficulty filter**: Map rating to stars:
- `<1000` → ⭐ Easy
- `1000–1300` → ⭐⭐ Medium
- `1300–1600` → ⭐⭐⭐ Hard
- `>1600` → ⭐⭐⭐⭐ Expert

### PuzzleController (lib/src/model/puzzle/puzzle_controller.dart)

**`puzzleControllerProvider`** = `AsyncNotifierProvider<PuzzleController, PuzzleState?>`

**`PuzzleMode`** enum: `solving`, `viewingSolution`, `review`.

**`PuzzleResult`** enum: `correct`, `wrong`, `solved`.

**`PuzzleState`** fields: `puzzle`, `position`, `solutionIndex`, `isDaily`, `userSide`, `mode`, `result`, `lastMove`, `hintSquare`, `positionHistory`, `moveHistory`, `reviewIndex`.

Key computed properties:
- `fen` → `position.fen`
- `orientation` → `userSide` (board shown from user's perspective)
- `validMoves` → empty when `result != null` or `mode != solving`; otherwise `position.legalMoves` converted via `toValidMoves()`

**Puzzle initialization (`_stateForPuzzle`)**:
1. Parse `puzzle.fen` (penultimate position — before trigger) as the initial board position
2. Determine `userSide` from `puzzle.fenAfterTrigger` — the side to move after the trigger

**Auto-play triggering move (`_autoPlayFirstMove`)**:
1. Wait 600ms so the user sees the "before" position
2. Play `puzzle.triggerUci` (the last PGN move) on the board
3. `solutionIndex` remains at 0 — solution[0] is the user's first move

**Move flow (`onMove`)**:
1. User moves; compare UCI to `solution[solutionIndex]`
2. If wrong: play the wrong move on the board briefly (800ms), show "That's not it" banner, snap back to previous position. Submit `win: false` on first wrong attempt (like Lichess). User can retry.
3. If correct and more moves remain: show "Best move!" banner, wait 600ms, auto-play opponent's response (`solution[solutionIndex + 1]`), advance index by 2
4. If correct and no more moves: show "Puzzle complete!" banner. Submit `win: true` if no prior failures.

**Hint system (`showHint`)**:
- Parses the expected move (`solution[solutionIndex]`) and sets `hintSquare` to the move's source square
- The UI renders a semi-transparent green circle on that square via chessground's `shapes` parameter (`Circle(color: Color(0x8015781B), orig: hintSquare)`)
- Hint is cleared when the user makes a move or views the solution

**View Solution (`viewSolution`)**:
1. Submit `win: false` if not already failed
2. Set mode to `viewingSolution`, clear hint and result
3. Auto-play remaining solution moves from `solutionIndex` to end with 800ms delays
4. After all moves played: enter `review` mode, populate `positionHistory` and `moveHistory`

**Review mode** (`reviewStepBack`, `reviewStepForward`, `reviewGoToStart`, `reviewGoToEnd`):
- Navigate through `positionHistory` by adjusting `reviewIndex`
- Board updates position and lastMove to match the review index
- Board is locked (validMoves returns empty)

**Puzzle results submission**: after each puzzle, submit win/loss via `POST /api/puzzle/batch/mix`. Best-effort, errors ignored.

### PuzzleScreen (lib/src/view/puzzle/puzzle_screen.dart)

- **Loading**: spinner
- **No puzzle loaded**: `_NoPuzzleView` with "Load Daily Puzzle" and "Random Puzzle" buttons
- **Active puzzle**:
  - Title (daily vs numbered), subtitle adapts to mode:
    - Solving: "White/Black to move — find the best move!"
    - Viewing solution: "Showing solution..."
    - Review: "Puzzle complete!"
  - Chessboard with hint circle shapes overlay
  - Result banner (correct/wrong/solved) with kid-friendly text and emoji
  - Toolbar during solving: Hint (lightbulb icon) + View Solution (eye icon) buttons
  - Move navigation bar during review: |◁ ◁ ▷ ▷| buttons
  - "Continue Training" button after solved or in review mode
- **Error**: network error vs generic, with Try Again button

---

## 12. Human Matchmaking

### MatchmakingController (lib/src/model/matchmaking/matchmaking_controller.dart)

**`matchmakingProvider`** = `AsyncNotifierProvider<MatchmakingNotifier, MatchmakingState?>`

**`MatchmakingState`**: `isSeeking: bool`, `gameId: String?`

**Flow**:
1. `seek(minutes, increment, rated)`: Start event stream first, then POST `/api/board/seek` (fire-and-forget)
2. Subscribe to `GET /api/stream/event` (ndjson) — must open BEFORE posting the seek
3. After 300ms delay (to ensure stream is open), post the seek via a separate `LichessClient` instance
4. On `gameStart` event: extract `gameId` from `event['game']['gameId']`, set `isSeeking = false, gameId = id`
5. `cancelSeek()`: close event stream subscription
6. `reset()`: clear state — called by `PlayHumanScreen.initState` to prevent stale seeking state on re-entry

**Auto-navigation**: `PlayHumanScreen` uses `ref.listen` on `matchmakingProvider`. When `gameId` is set, calls `reset()` then `context.go('/game/$gameId?side=random')`.

### Lichess Board API — Time Control Restriction

**IMPORTANT**: The `POST /api/board/seek` endpoint enforces `isBoardCompatible`, which requires **Speed >= Rapid** for third-party apps. The estimated game duration formula is `limit + 40 * increment` seconds, and the Rapid threshold is **480 seconds**.

The `allowFastGames` bypass (which permits Blitz/Bullet) is only granted to tokens with the `web:mobile` OAuth scope, which is **reserved exclusively for the official Lichess mobile app** — third-party apps cannot request it.

Valid time controls for `POST /api/board/seek` (third-party apps):
| Time Control | Estimated Duration | Speed | Board API |
|---|---|---|---|
| 5+3 | 420s | Blitz | **REJECTED** (400 "Invalid time control") |
| 8+0 | 480s | Rapid | OK |
| 10+0 | 600s | Rapid | OK |
| 10+5 | 800s | Rapid | OK |
| 15+10 | 1300s | Rapid | OK |
| 30+0 | 1800s | Classical | OK |

Note: The **Challenge API** (`POST /api/challenge/{username}`) has a separate, more permissive check (`speed >= Speed.Blitz`), so bot challenges with faster time controls work fine.

### PlayHumanScreen (lib/src/view/play/play_human_screen.dart)

Three Rapid-compatible time controls shown as cards with emoji + minutes label + description:
- **10+0** (🏃) — "Fast and fun"
- **10+5** (🧘) — "Take your time and think carefully"
- **15+10** (🌳) — "Plenty of time to think deeply"

Additional features:
- Shows user's rapid rating
- **Rated/Unrated toggle**: `SegmentedButton<bool>`, default unrated. Bottom info note updates dynamically.
- On tap: calls `matchmakingProvider.notifier.seek(minutes, increment, rated)`
- While seeking: spinner + progress indicator + Cancel button
- Error: login required vs connection error
- `PlayHumanScreen` is a `ConsumerStatefulWidget` — `initState` resets the matchmaking provider to clear stale state

---

## 13. Kid Avatar System

8 DiceBear Adventurer-style SVG avatars (4 boys, 4 girls, various skin tones and hair styles) defined in `KidAvatar.all` as a const list in `lib/src/model/auth/lichess_account.dart`.

**`KidAvatarWidget`** (also defined in `lichess_account.dart`): renders SVG via `flutter_svg`, circular container with colored background.
- `avatarIndex` parameter
- `size` parameter (default 56)
- `onTap` callback for cycling
- Optional `label` below

**Avatar assignment**: random on first login, persisted to `FlutterSecureStorage` under `kid_avatar_index_{userId}`.

**Cycling**: `AccountNotifier.cycleAvatar()` increments index mod 8, persists immediately.

**Usage**: shown below the board in `OnlineGameScreen`. Tap to cycle through all 12 avatars.

---

## 14. Home Screen & Navigation

### HomeScreen (lib/src/view/home/home_screen.dart)

Root `Scaffold` with:
- `AppBar`: localized app title, account chip (username + ⚡rapid + 🧩puzzle ratings), settings icon
- `NavigationBar` (Material 3) with 3 destinations: 🐾 Play Animal / 🧩 Puzzles / 👥 Play Human
- Tab active state derived from current route path prefix

**`_AccountChip`**: pill-shaped container showing username + ratings. Only shown when logged in.

---

## 15. Settings Screen

### lib/src/view/settings/settings_screen.dart

Two sections:

**Parental Controls** (stubs — framework only):
- Set Parental PIN (4-digit PIN, TODO)
- Daily Play Limit (default 60 min, TODO)
- Online Play toggle (disabled by default, TODO: require PIN to enable)

**App**:
- Language picker: `SegmentedButton` with English / Magyar options. Calls `localeProvider.notifier.setLocale()`. Persists via `shared_preferences`.
- About: `showAboutDialog` with app name, version (1.0.0), description
- Privacy Policy (TODO)

---

## 16. Localisation

Two languages: English (`en`) and Hungarian (`hu`).

### ARB key categories

| Prefix | Screens covered |
|--------|----------------|
| `appTitle`, `settingsTooltip` | Global |
| `nav*` | Bottom nav labels |
| `login*` | Login screen |
| `bot*` | Bot select + bot names/desc/difficulty |
| `offline*` | Offline game screen |
| `online*` | Online game screen |
| `playHuman*` | Human play screen |
| `puzzle*` | Puzzle screen |
| `settings*` | Settings screen |

### Parametric strings
- `loginErrorFailed(String error)`
- `botRatingLabel(int rating)` — e.g. "~880 rapid"
- `botThinking(String name)` — e.g. "Bundi a Medve gondolkodik..."
- `onlineOpponentThinking(String name)`
- `onlineConnectionError(String error)`
- `playHumanYourRating(int rating)`
- `playHumanTimeMinutes(String label)`
- `puzzleTitle(String id)`

### Bot character localization pattern
Bot names/descriptions/difficulties are NOT stored in the enum (which holds only English). Helper functions in `lib/src/utils/bot_l10n.dart` use switch expressions on the `BotCharacter` enum to look up the appropriate ARB key:

```dart
String localizedBotName(AppLocalizations l, BotCharacter c) => switch (c) {
  BotCharacter.bee => l.botNameBee,
  BotCharacter.butterfly => l.botNameButterfly,
  // ...
};
String localizedBotDifficulty(AppLocalizations l, BotCharacter c) => ...;
String localizedBotDescription(AppLocalizations l, BotCharacter c) => ...;
```

### Locale persistence
`LocaleNotifier extends Notifier<Locale>` — initial value `Locale('en')`, async-loads persisted value from `shared_preferences` key `app_locale` on `build()`, persists on `setLocale()`.

---

## 17. Chessboard Integration (chessground v9)

### Key API
```dart
Chessboard(
  size: boardSize,
  fen: positionFen,
  orientation: Side.white | Side.black,
  lastMove: NormalMove(from: sq, to: sq),
  game: GameData(
    playerSide: PlayerSide.white | PlayerSide.black | PlayerSide.both,
    sideToMove: Side.white | Side.black,
    isCheck: bool,
    validMoves: IMap<Square, ISet<Square>>,
    promotionMove: NormalMove?,          // non-null triggers promotion UI
    onMove: (Move, {bool? viaDragAndDrop}) => void,
    onPromotionSelection: (Role?) => void,
  ),
  settings: ChessboardSettings(
    colorScheme: ChessboardColorScheme.green,  // or .brown
    pieceAssets: PieceSet.cburnett.assets,
  ),
)
```

### Valid moves
Compute from `dartchess` position:
```dart
IMap<Square, ISet<Square>> toValidMoves(Iterable<Move> legalMoves) {
  final map = <Square, Set<Square>>{};
  for (final move in legalMoves) {
    if (move is NormalMove) {
      map.putIfAbsent(move.from, () => {}).add(move.to);
    }
  }
  return IMap(map.map((k, v) => MapEntry(k, ISet(v))));
}
```

### Pawn promotion
When user moves a pawn to the last rank: set `_pendingPromotion = move` without playing it. Pass `promotionMove: _pendingPromotion` to `GameData` — this triggers chessground's built-in promotion piece picker. In `onPromotionSelection(Role? role)`: complete the move with the chosen role, clear `_pendingPromotion`.

---

## 18. Parental Controls (Framework Only)

`ParentalSettings` model with fields:
- `onlinePlayEnabled` (bool, default false)
- `friendOnlyMode` (bool)
- `dailyLimitMinutes` (int, 0 = unlimited, default 60)
- `pushNotificationsEnabled` (bool)

Chat functionality is intentionally excluded from the app entirely — no chat UI, no approved phrases, no chat API calls.

PIN and time enforcement are stubbed — UI placeholders exist in `SettingsScreen`.

---

## 19. Styles

### Colors (lib/src/styles/colors.dart)
```dart
abstract class ChessPalsColors {
  static const primary = Color(0xFF4CAF50);       // Forest green
  static const primaryDark = Color(0xFF388E3C);
  static const accent = Color(0xFFFF9800);         // Warm orange
  static const surface = Color(0xFFF9FBF2);        // Off-white
  static const onPrimary = Colors.white;
}
```

### Typography (lib/src/styles/typography.dart)
- Font: Nunito via `google_fonts`
- Weights used: 400 (regular), 600 (semibold), 700 (bold), 800 (extrabold)

### Theme (lib/src/styles/theme.dart)
- `ChessPalsTheme.light` → `ThemeData` with Material 3, `ColorScheme.fromSeed(seedColor: ChessPalsColors.primary)`, Nunito text theme

---

## 20. Known Constraints & Notes

1. **Bot play requires internet** — all 8 bots are real Lichess accounts. There is a local heuristic bot for offline mode (level 1–8) but it is not Stockfish.
2. **Auth is OAuth2 PKCE** — the app uses Lichess OAuth2 with PKCE for login. The `web:mobile` scope is reserved for the official Lichess app and cannot be requested by third-party apps. Dev token injection (`--dart-define=LICHESS_TOKEN`) is available for development.
3. **Rated games supported** — seeks and challenges support `rated: true/false` via a toggle in the Play Human screen.
4. **`playerSide` from query param is unreliable** — the actual side is determined server-side from the `gameFull.white.id` vs the logged-in account id.
5. **Puzzle PGN parsing** — the Lichess puzzle API returns a game PGN (not a ready-to-use FEN). The app replays the full PGN using dartchess's built-in `PgnGame.parsePgn()` + `Position.parseSan()`, extracting the penultimate position (before trigger), the final position (after trigger), and the triggering move UCI. `solution[0]` is the user's first move, not the trigger.
6. **Chessground `PieceSet.cburnett.assets`** — must be in a non-const context (it's not a const value).
7. **ndjson streaming** — Lichess returns newline-delimited JSON. Use HTTP chunked reading, split on newlines, skip empty lines (heartbeats). Wrap `jsonDecode` in try-catch for `FormatException` — streams may send non-JSON data when closing.
8. **`PopScope` wrapping** — the entire `Scaffold` must be wrapped in `PopScope(canPop: false)` with `onPopInvokedWithResult` to intercept the Android back gesture.
9. **Locale rebuild** — `ChessPalsApp` watches `localeProvider`; changing locale rebuilds the entire widget tree, updating all strings instantly without navigation.
10. **AppBar title overflow** — when showing "Bot thinking..." in AppBar, wrap the text in `Flexible` with `TextOverflow.ellipsis` to prevent overflow on smaller screens or with long localized names.
11. **Bot move delay** — offline bot waits 3 seconds before responding, giving kids time to see their move on the board. The "thinking" spinner and status banner display during this delay.
12. **SVG animal assets** — all bot avatars are code-generated SVGs (`tools/generate_animal_svgs.py`). The system supports PNG emotions via `hasPngEmotions` flag but currently all bots use SVG. To regenerate: `python3 tools/generate_animal_svgs.py`.
13. **Resign confirmation** — both offline and online games show a confirmation dialog before resigning. Offline reuses the online localization keys (`onlineResignTitle`, `onlineResignContent`, etc.).
14. **Board API time control restriction** — `POST /api/board/seek` enforces `Speed >= Rapid` (≥480s estimated) for third-party apps. The `web:mobile` OAuth scope that bypasses this is reserved for the official Lichess app. Blitz (e.g., 5+3 = 420s) returns HTTP 400 "Invalid time control". The Challenge API (`POST /api/challenge/{username}`) is more permissive (allows Blitz+). All three time controls in the app (10+0, 10+5, 15+10) are Rapid and work with the Board API.
15. **Chat excluded** — chat functionality is intentionally excluded from the app entirely. No chat UI, no approved phrases, no `sendChatMessage()` method.
16. **Game abort handling** — when a game is aborted (e.g., no moves within 30s), the `gameState` event has `status == 'aborted'`. The app navigates home silently without showing an error dialog.
17. **Seek endpoint is streaming** — `POST /api/board/seek` is a streaming endpoint that blocks until a match is found. Must be fire-and-forget (not awaited). Use a separate `http.Client` instance for the seek and the event stream to avoid blocking.
