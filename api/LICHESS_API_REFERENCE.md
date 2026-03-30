# Lichess API Integration Reference

## Base URL
```
https://lichess.org
```

## Authentication

ChessPals uses **Lichess OAuth2** (PKCE flow — no client secret needed for mobile).

### OAuth Scopes Required
| Scope | Feature |
|-------|---------|
| `challenge:write` | Challenge bot accounts and humans |
| `board:play` | Play games, stream events, seek human opponents |
| `puzzle:read` | Fetch puzzle batches and activity |
| `puzzle:write` | Submit puzzle results for tracking |

### Token Storage
Tokens stored in `flutter_secure_storage` under key `lichess_token`.

---

## Feature 1: Play vs. Bots

All bots are **real Lichess BOT accounts**, challenged via `POST /api/challenge/{username}`.
No embedded engine — internet connection required for bot play.
All bots are below 1800 rapid rating, spanning ~887 to ~1694.

### Challenge a Bot Account
```http
POST https://lichess.org/api/challenge/{username}
Authorization: Bearer {token}
Content-Type: application/x-www-form-urlencoded

rated=false&color=random&clock.limit=600&clock.increment=5
```

**Response (201):**
```json
{
  "id": "abc12345",
  "color": "white",
  "variant": { "key": "standard", "name": "Standard" },
  "speed": "rapid",
  "rated": false
}
```

**Bot account mapping (all under 1800 rapid):**
| Character | Lichess Username | Approx. Rapid Rating | Bot Type |
|-----------|-----------------|---------------------|----------|
| Benny the Bear 🐻 | `uSunfish-l0` | ~887 | Sunfish port, designed for early beginners |
| Pip the Penguin 🐧 | `nittedal` | ~913 | Beginner-friendly persona, plays like a learning human |
| Foxy the Fox 🦊 | `AllieTheChessBot` | ~1222 | Learns from human games |
| Luna the Lion 🦁 | `Humaia` | ~1327 | Plays like a ~1400 human with realistic mistakes |
| Oliver the Owl 🦉 | `maia1` | ~1573 | Maia (Cornell/UofT), trained on 1100-rated human games |
| Zara the Zebra 🦓 | `maia5` | ~1613 | Maia trained on 1500-rated human games |
| Anya the Eagle 🦅 | `marvin-1600` | ~1695 | Transformer bot mimicking a 1600-rated human |
| Rex the Dragon 🐉 | `maia9` | ~1694 | Maia trained on 1900-rated games (plays under 1750) |

**About the Maia bots:** `maia1`, `maia5`, `maia9` are a Cornell University / University of Toronto research project. They are trained on millions of real human games and make **human-like mistakes** rather than sterile engine errors — ideal for kids developing pattern recognition.

### Stream Game Events
```http
GET https://lichess.org/api/board/game/stream/{gameId}
Authorization: Bearer {token}
Accept: application/x-ndjson
```

**Stream events:**
```json
// Initial full state
{ "type": "gameFull", "id": "abc12345", "white": {...}, "black": {...},
  "state": { "type": "gameState", "moves": "", "wtime": 600000, "btime": 600000 } }

// After each move
{ "type": "gameState", "moves": "e2e4 e7e5", "wtime": 595000, "btime": 598000, "status": "started" }

// Game over
{ "type": "gameState", "moves": "...", "status": "mate", "winner": "white" }
```

### Make a Move
```http
POST https://lichess.org/api/board/game/{gameId}/move/{move}
Authorization: Bearer {token}

# move in UCI format: e.g., "e2e4", "e7e8q" (promotion)
```

### Resign / Abort
```http
POST https://lichess.org/api/board/game/{gameId}/resign
POST https://lichess.org/api/board/game/{gameId}/abort
Authorization: Bearer {token}
```

---

## Feature 2: Puzzles

### Daily Puzzle (No Auth)
```http
GET https://lichess.org/api/puzzle/daily
```

**Response:**
```json
{
  "game": {
    "id": "xyzGame",
    "pgn": "...",
    "players": [...]
  },
  "puzzle": {
    "id": "pzlId",
    "initialPly": 12,
    "rating": 1150,
    "plays": 34521,
    "solution": ["d5e4", "f3e4", "d8d1"],
    "themes": ["fork", "middlegame"]
  }
}
```

### Fetch Puzzle Batch (Offline Cache)
```http
GET https://lichess.org/api/puzzle/batch/{angle}?nb=50
Authorization: Bearer {token}

# Angle options for kids:
# mateIn1, mateIn2, fork, pin, short, promotion, oneMove
```

**Response:**
```json
{
  "puzzles": [
    {
      "game": { "id": "...", "pgn": "..." },
      "puzzle": {
        "id": "pzl001",
        "initialPly": 8,
        "rating": 950,
        "solution": ["g1f3"],
        "themes": ["mateIn1", "short"]
      }
    }
  ]
}
```

### Submit Puzzle Results
```http
POST https://lichess.org/api/puzzle/batch/{angle}
Authorization: Bearer {token}
Content-Type: application/json

{
  "solutions": [
    { "id": "pzl001", "win": true },
    { "id": "pzl002", "win": false }
  ]
}
```

### Kid-Appropriate Puzzle Angles
Fetch these angles for the difficulty levels:
```
⭐ Beginner:    mateIn1, oneMove
⭐⭐ Explorer:  mateIn2, pin, fork
⭐⭐⭐ Adventurer: fork, pin, deflection
⭐⭐⭐⭐ Champion: sacrifice, discoveredAttack
⭐⭐⭐⭐⭐ Master: all angles
```

---

## Feature 3: Human Matchmaking

### Seek Opponent
```http
POST https://lichess.org/api/board/seek
Authorization: Bearer {token}
Content-Type: application/x-www-form-urlencoded

rated=false&time=5&increment=3&ratingRange=800-1200
```

**Behavior:** For real-time seeks, connection stays open (streaming empty keep-alive lines) until an opponent accepts. Then the stream closes and `GET /api/stream/event` fires a `gameStart` event.

### Stream All Events (Listen for game start)
```http
GET https://lichess.org/api/stream/event
Authorization: Bearer {token}
Accept: application/x-ndjson
```

**Events:**
```json
// Game started
{ "type": "gameStart", "game": { "id": "xyz99999", "color": "white", ... } }

// Challenge received (friend challenge)
{ "type": "challenge", "challenge": { "id": "...", "challenger": {...} } }
```

### Accept / Decline Challenge
```http
POST https://lichess.org/api/challenge/{challengeId}/accept
POST https://lichess.org/api/challenge/{challengeId}/decline
Authorization: Bearer {token}
```

### Safe Chat (Board API)
```http
POST https://lichess.org/api/board/game/{gameId}/chat
Authorization: Bearer {token}
Content-Type: application/x-www-form-urlencoded

room=player&text=Good+game%21
```
> ChessPals restricts `text` to pre-approved phrases only. Users never see a free-text input.

---

## Error Handling

| HTTP Status | Meaning | Action |
|-------------|---------|--------|
| 401 | Token expired | Trigger OAuth refresh |
| 429 | Rate limited | Wait 60s, retry once |
| 404 | Game/puzzle not found | Show "try again" message |
| 503 | Lichess maintenance | Show "come back soon" message |

All errors shown to kids as friendly messages with character illustrations, never raw error text.
