# ChessPals — Design System & UI/UX Spec

## Design Philosophy

**Friendly. Safe. Rewarding.**
- Every screen should feel like a game, not a lesson
- Positive reinforcement over punishment
- Large, tappable elements (minimum 48×48dp)
- Minimal text; prefer icons, colors, and characters
- Immediate feedback on every action

---

## Color Palette

```
Primary Colors:
  Forest Green     #4CAF50   Main CTAs, success, progress
  Dark Green       #388E3C   Pressed states, headers
  Warm Orange      #FF9800   Stars, XP orbs, warm accents
  Sky Blue         #2196F3   Links, online status, selection

Semantic Colors:
  Background       #FAFFF4   App bg (off-white, slightly green)
  Surface          #FFFFFF   Cards, modals, dialogs
  Error / Wrong    #F44336   Incorrect move indicator
  Success          #66BB6A   Correct move, win celebration

Board Themes:
  Forest (default)
    Light square   #F5CBA7   Warm wood
    Dark square    #A0522D   Rich brown
  Ocean
    Light square   #B0E0E6   Powder blue
    Dark square    #4682B4   Steel blue
  Classic
    Light square   #FFFACD   Lemon cream
    Dark square    #8B4513   Saddle brown
  Candy
    Light square   #FFD1DC   Soft pink
    Dark square    #C71585   Medium violet-red
```

---

## Typography

```
Font Family: Nunito (Google Fonts — free, rounded, great for kids)
  H1 Headline     32sp  Bold    Page titles
  H2 Subheading   24sp  Bold    Section headers
  H3 Card title   20sp  SemiBold
  Body            16sp  Regular  Main content
  Caption         13sp  Regular  Secondary info
  Button          16sp  Bold     CTA text (ALL CAPS)

Minimum readable size: 13sp (never go below this)
```

---

## Animal Characters

### Bot Roster
Each animal has:
- Color-coded difficulty badge
- Friendly intro quote
- Unique idle animation

```
Benny the Bear 🐻
  Level: 1 (Stockfish 1)
  Color: Warm brown
  Badge: ⭐ Beginner
  Quote: "I'm still learning — I make lots of mistakes!"
  Idle: Waving paw

Pip the Penguin 🐧
  Level: 2 (Stockfish 2)
  Color: Black & white + yellow scarf
  Badge: ⭐⭐ Explorer
  Quote: "I waddle into the game!"
  Idle: Bobbing head

Foxy the Fox 🦊
  Level: 3 (Stockfish 3)
  Color: Orange with white chest
  Badge: ⭐⭐⭐ Cunning
  Quote: "I'll try to trick you!"
  Idle: Tail swish

Luna the Lion 🦁
  Level: 4 (Stockfish 4)
  Color: Golden mane
  Badge: ⭐⭐⭐⭐ Fierce
  Quote: "Roar! I'm getting serious!"
  Idle: Mane shake

Oliver the Owl 🦉
  Level: 5 (Stockfish 5)
  Color: Brown with big eyes
  Badge: ⭐⭐⭐⭐⭐ Wise
  Quote: "I plan three moves ahead…"
  Idle: Head tilt

Zara the Zebra 🦓
  Level: 6 (Stockfish 6)
  Color: Black & white stripes
  Badge: 🌟 Sharp
  Quote: "Fast and precise — ready?"
  Idle: Hoof tap

Anya the Eagle 🦅
  Level: 7 (Stockfish 7)
  Color: Brown + white head
  Badge: 🌟🌟 Expert
  Quote: "I see every move from above!"
  Idle: Wing flex

Rex the Dragon 🐉
  Level: 8 (Stockfish 8)
  Color: Emerald green with fire
  Badge: 👑 Master
  Quote: "No one has beaten me… yet!"
  Idle: Fire breath puff
```

---

## Screen-by-Screen UI Spec

### Home Screen
```
┌─────────────────────────────────────┐
│  🌳 ChessPals          [⚙️ Settings] │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  👋 Hey, SwiftFox42!        │    │
│  │  🔥 5-day streak!           │    │
│  └─────────────────────────────┘    │
│                                     │
│  📅 Daily Puzzle         [PLAY →]   │
│  ┌───────────┐                      │
│  │ [board]   │  Find the best move! │
│  └───────────┘                      │
│                                     │
│  ──────── Quick Play ────────       │
│  ┌──────────┐  ┌──────────┐         │
│  │  🤖 Bots  │  │ 🧩Puzzles│         │
│  └──────────┘  └──────────┘         │
│  ┌──────────┐                        │
│  │ 👥 Online │                        │
│  └──────────┘                        │
└─────────────────────────────────────┘
```

### Bot Select Screen
```
┌─────────────────────────────────────┐
│  ← Choose Your Opponent             │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │  🐻  │ │  🐧  │ │  🦊  │        │
│  │Benny │ │ Pip  │ │ Foxy │        │
│  │ ⭐   │ │ ⭐⭐  │ │⭐⭐⭐ │        │
│  └──────┘ └──────┘ └──────┘        │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │  🦁  │ │  🦉  │ │  🦓  │        │
│  │ Luna │ │Oliver│ │ Zara │        │
│  │⭐⭐⭐⭐│ │⭐⭐⭐⭐⭐│ │🌟   │        │
│  └──────┘ └──────┘ └──────┘        │
│  ┌──────┐ ┌──────┐                  │
│  │  🦅  │ │  🐉  │                  │
│  │ Anya │ │ Rex  │                  │
│  │🌟🌟  │ │ 👑   │                  │
│  └──────┘ └──────┘                  │
└─────────────────────────────────────┘
```

### Game Screen
```
┌─────────────────────────────────────┐
│  ← Game     🐻 Benny   ⏱ ∞         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │        [ Chess Board ]      │    │
│  │                             │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ⏱ Your turn!                       │
│                                     │
│  [↩️ Undo]  [💡 Hint (3)]  [🏳 Resign]│
└─────────────────────────────────────┘
```

### Puzzle Screen
```
┌─────────────────────────────────────┐
│  ← Puzzle #1042      ⭐⭐ Explorer   │
│                                     │
│  🧩 Find the best move!             │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │        [ Chess Board ]      │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ❌ Not quite! Try again…           │
│  [💡 Show Hint]      Attempt 2/3    │
│                                     │
│  ─────── Themes ───────            │
│  🍴 Fork    📌 Pin                  │
└─────────────────────────────────────┘
```

### Win Celebration Screen
```
┌─────────────────────────────────────┐
│          🎉🎉 You Won! 🎉🎉         │
│                                     │
│         🐻 Benny tipped over!       │
│         [  celebration animation  ] │
│                                     │
│   +25 XP  ───────────── Level 4    │
│   ████████████░░░░░░░ 380/500 XP   │
│                                     │
│  ┌──────────────────────┐           │
│  │ 🔁  Play Again      │           │
│  │ 🤖  Try Harder Bot  │           │
│  │ 🏠  Go Home         │           │
│  └──────────────────────┘           │
└─────────────────────────────────────┘
```

---

## Animation Guidelines

### Celebration (Win)
- Confetti burst from center (Lottie)
- Character does happy dance
- XP counter ticks up with bounce

### Correct Move (Puzzle)
- Board square flashes green briefly
- Short "ding" sound
- Piece glides to target

### Wrong Move (Puzzle)
- Board shakes subtly (not harshly)
- Gentle "uh-oh" sound
- Highlighted key piece

### Streak Counter
- Flame grows taller each day
- Streak number bounces on tap

### Level Up
- Sparkle burst over level badge
- "Level up!" banner slides in
- New unlock revealed

---

## Sound Design

| Event | Sound Description |
|-------|------------------|
| Piece move | Wooden "clack" |
| Piece capture | Louder "snap" |
| Check | Alert tone |
| Correct puzzle | Cheerful "ding" |
| Wrong move | Soft "boing" |
| Win game | Triumphant fanfare |
| Loss game | Gentle "aww" tone |
| Level up | Sparkle chime |
| Streak | Fire crackle |

All sounds should be:
- Short (< 1 second for moves)
- Kid-appropriate (no aggressive sounds)
- Volume-controllable (respect system volume)
- Off by default or user-selectable

---

## Accessibility

- Minimum touch target: 48×48dp
- Color contrast ratio: ≥ 4.5:1 for text
- Screen reader labels on all interactive elements
- Board colors: Avoid red/green only (colorblind support)
- Large board mode: Option to enlarge board to full width
