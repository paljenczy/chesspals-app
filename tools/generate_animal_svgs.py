#!/usr/bin/env python3
"""
Generate simple rounded-square animal face SVGs for ChessPals.
8 animals × 5 emotions = 40 SVGs, plus 8 top-level neutral avatars.

Run: python3 tools/generate_animal_svgs.py
"""

import os

BASE_DIR = os.path.join(os.path.dirname(__file__), '..', 'src', 'assets', 'bot_avatars')

# ─── Colors ───────────────────────────────────────────────────────────────────
ANIMALS = {
    'bee':         {'fill': '#FDD835', 'dark': '#F9A825', 'light': '#FFF9C4'},
    'butterfly':   {'fill': '#CE93D8', 'dark': '#AB47BC', 'light': '#F3E5F5'},
    'hummingbird': {'fill': '#80DEEA', 'dark': '#00ACC1', 'light': '#E0F7FA'},
    'rabbit':      {'fill': '#FFCDD2', 'dark': '#EF5350', 'light': '#FFEBEE'},
    'kangaroo':    {'fill': '#D7CCC8', 'dark': '#8D6E63', 'light': '#EFEBE9'},
    'deer':        {'fill': '#A1887F', 'dark': '#6D4C41', 'light': '#D7CCC8'},
    'giraffe':     {'fill': '#FFCC80', 'dark': '#FF9800', 'light': '#FFF3E0'},
    'tiger':       {'fill': '#EF6C00', 'dark': '#BF360C', 'light': '#FFF3E0'},
}

EMOTIONS = ['neutral', 'happy', 'sad', 'scared', 'furious']


# ─── SVG builder ──────────────────────────────────────────────────────────────

def svg_wrap(inner: str) -> str:
    return f'''<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
{inner}
</svg>
'''


def rounded_rect_face(fill: str) -> str:
    return f'  <rect x="20" y="24" width="88" height="88" rx="28" ry="28" fill="{fill}" />'


def cheeks(light: str) -> str:
    return (
        f'  <circle cx="36" cy="78" r="9" fill="{light}" opacity="0.6" />\n'
        f'  <circle cx="92" cy="78" r="9" fill="{light}" opacity="0.6" />'
    )


# ─── Eyes per emotion ─────────────────────────────────────────────────────────

def eyes_neutral() -> str:
    return (
        '  <circle cx="46" cy="64" r="7" fill="#2C2C2C" />\n'
        '  <circle cx="82" cy="64" r="7" fill="#2C2C2C" />\n'
        '  <circle cx="48" cy="62" r="2.5" fill="white" />\n'
        '  <circle cx="84" cy="62" r="2.5" fill="white" />'
    )


def eyes_happy() -> str:
    return (
        '  <path d="M38 64 Q46 56 54 64" stroke="#2C2C2C" stroke-width="3.5" fill="none" stroke-linecap="round" />\n'
        '  <path d="M74 64 Q82 56 90 64" stroke="#2C2C2C" stroke-width="3.5" fill="none" stroke-linecap="round" />'
    )


def eyes_sad() -> str:
    return (
        '  <circle cx="46" cy="66" r="7" fill="#2C2C2C" />\n'
        '  <circle cx="82" cy="66" r="7" fill="#2C2C2C" />\n'
        '  <circle cx="48" cy="64" r="2.5" fill="white" />\n'
        '  <circle cx="84" cy="64" r="2.5" fill="white" />\n'
        '  <line x1="36" y1="54" x2="52" y2="56" stroke="#2C2C2C" stroke-width="2.5" stroke-linecap="round" />\n'
        '  <line x1="92" y1="54" x2="76" y2="56" stroke="#2C2C2C" stroke-width="2.5" stroke-linecap="round" />'
    )


def eyes_scared() -> str:
    return (
        '  <circle cx="46" cy="62" r="10" fill="white" />\n'
        '  <circle cx="82" cy="62" r="10" fill="white" />\n'
        '  <circle cx="46" cy="63" r="5" fill="#2C2C2C" />\n'
        '  <circle cx="82" cy="63" r="5" fill="#2C2C2C" />\n'
        '  <circle cx="48" cy="61" r="2" fill="white" />\n'
        '  <circle cx="84" cy="61" r="2" fill="white" />'
    )


def eyes_furious() -> str:
    return (
        '  <circle cx="46" cy="66" r="6" fill="#2C2C2C" />\n'
        '  <circle cx="82" cy="66" r="6" fill="#2C2C2C" />\n'
        '  <circle cx="48" cy="64" r="2" fill="white" />\n'
        '  <circle cx="84" cy="64" r="2" fill="white" />\n'
        '  <line x1="36" y1="56" x2="54" y2="52" stroke="#2C2C2C" stroke-width="3" stroke-linecap="round" />\n'
        '  <line x1="92" y1="56" x2="74" y2="52" stroke="#2C2C2C" stroke-width="3" stroke-linecap="round" />'
    )


EYES = {
    'neutral': eyes_neutral,
    'happy': eyes_happy,
    'sad': eyes_sad,
    'scared': eyes_scared,
    'furious': eyes_furious,
}


# ─── Mouth per emotion ───────────────────────────────────────────────────────

def mouth_neutral() -> str:
    return '  <path d="M56 84 Q64 90 72 84" stroke="#2C2C2C" stroke-width="2.5" fill="none" stroke-linecap="round" />'


def mouth_happy() -> str:
    return (
        '  <path d="M50 82 Q64 96 78 82" stroke="#2C2C2C" stroke-width="2.5" fill="none" stroke-linecap="round" />\n'
        '  <path d="M52 83 Q64 94 76 83" fill="#E53935" opacity="0.3" />'
    )


def mouth_sad() -> str:
    return '  <path d="M52 90 Q64 80 76 90" stroke="#2C2C2C" stroke-width="2.5" fill="none" stroke-linecap="round" />'


def mouth_scared() -> str:
    return '  <ellipse cx="64" cy="88" rx="7" ry="9" fill="#2C2C2C" />'


def mouth_furious() -> str:
    return '  <path d="M48 86 L56 82 L64 86 L72 82 L80 86" stroke="#2C2C2C" stroke-width="2.5" fill="none" stroke-linecap="round" />'


MOUTHS = {
    'neutral': mouth_neutral,
    'happy': mouth_happy,
    'sad': mouth_sad,
    'scared': mouth_scared,
    'furious': mouth_furious,
}


# ─── Nose (shared) ────────────────────────────────────────────────────────────

def nose(dark: str) -> str:
    return f'  <ellipse cx="64" cy="74" rx="4" ry="3" fill="{dark}" />'


# ─── Animal-specific features ─────────────────────────────────────────────────
# Each returns (behind_face: str, on_top_of_face: str)
# "behind" = ears, wings, antennae that go under the face rect
# "on_top" = stripes, spots, markings that overlay the face

def features_bee(fill: str, dark: str, **_) -> tuple[str, str]:
    behind = (
        f'  <line x1="48" y1="26" x2="40" y2="8" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <circle cx="40" cy="7" r="4" fill="{dark}" />\n'
        f'  <line x1="80" y1="26" x2="88" y2="8" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <circle cx="88" cy="7" r="4" fill="{dark}" />'
    )
    on_top = f'  <rect x="28" y="42" width="72" height="8" rx="4" fill="{dark}" opacity="0.3" />'
    return behind, on_top


def features_butterfly(fill: str, dark: str, light: str, **_) -> tuple[str, str]:
    behind = (
        f'  <ellipse cx="10" cy="48" rx="14" ry="22" fill="{fill}" opacity="0.7" />\n'
        f'  <ellipse cx="10" cy="48" rx="8" ry="14" fill="{light}" opacity="0.5" />\n'
        f'  <ellipse cx="118" cy="48" rx="14" ry="22" fill="{fill}" opacity="0.7" />\n'
        f'  <ellipse cx="118" cy="48" rx="8" ry="14" fill="{light}" opacity="0.5" />\n'
        f'  <path d="M50 26 Q44 4 34 6" stroke="{dark}" stroke-width="2" fill="none" stroke-linecap="round" />\n'
        f'  <circle cx="34" cy="5" r="3" fill="{dark}" />\n'
        f'  <path d="M78 26 Q84 4 94 6" stroke="{dark}" stroke-width="2" fill="none" stroke-linecap="round" />\n'
        f'  <circle cx="94" cy="5" r="3" fill="{dark}" />'
    )
    return behind, ''


def features_hummingbird(fill: str, dark: str, **_) -> tuple[str, str]:
    behind = (
        f'  <path d="M54 26 Q50 10 56 14" stroke="{dark}" stroke-width="2" fill="{fill}" />\n'
        f'  <path d="M64 24 Q62 6 68 12" stroke="{dark}" stroke-width="2" fill="{fill}" />\n'
        f'  <path d="M74 26 Q78 10 72 14" stroke="{dark}" stroke-width="2" fill="{fill}" />'
    )
    on_top = f'  <polygon points="108,72 124,76 108,80" fill="{dark}" />'
    return behind, on_top


def features_rabbit(fill: str, dark: str, light: str, **_) -> tuple[str, str]:
    behind = (
        f'  <ellipse cx="42" cy="10" rx="10" ry="24" fill="{fill}" />\n'
        f'  <ellipse cx="42" cy="10" rx="5" ry="16" fill="{light}" />\n'
        f'  <ellipse cx="86" cy="10" rx="10" ry="24" fill="{fill}" />\n'
        f'  <ellipse cx="86" cy="10" rx="5" ry="16" fill="{light}" />'
    )
    return behind, ''


def features_kangaroo(fill: str, dark: str, **_) -> tuple[str, str]:
    behind = (
        f'  <polygon points="28,30 20,4 40,24" fill="{fill}" />\n'
        f'  <polygon points="30,28 24,10 38,24" fill="{dark}" opacity="0.3" />\n'
        f'  <polygon points="100,30 108,4 88,24" fill="{fill}" />\n'
        f'  <polygon points="98,28 104,10 90,24" fill="{dark}" opacity="0.3" />'
    )
    return behind, ''


def features_deer(fill: str, dark: str, **_) -> tuple[str, str]:
    behind = (
        f'  <circle cx="26" cy="30" r="10" fill="{fill}" />\n'
        f'  <circle cx="102" cy="30" r="10" fill="{fill}" />\n'
        f'  <line x1="34" y1="28" x2="24" y2="4" stroke="{dark}" stroke-width="3" stroke-linecap="round" />\n'
        f'  <line x1="28" y1="14" x2="18" y2="6" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <line x1="30" y1="20" x2="38" y2="10" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <line x1="94" y1="28" x2="104" y2="4" stroke="{dark}" stroke-width="3" stroke-linecap="round" />\n'
        f'  <line x1="100" y1="14" x2="110" y2="6" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <line x1="98" y1="20" x2="90" y2="10" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />'
    )
    return behind, ''


def features_giraffe(fill: str, dark: str, **_) -> tuple[str, str]:
    behind = (
        f'  <line x1="46" y1="28" x2="42" y2="8" stroke="{dark}" stroke-width="3" stroke-linecap="round" />\n'
        f'  <circle cx="42" cy="6" r="4" fill="{dark}" />\n'
        f'  <line x1="82" y1="28" x2="86" y2="8" stroke="{dark}" stroke-width="3" stroke-linecap="round" />\n'
        f'  <circle cx="86" cy="6" r="4" fill="{dark}" />'
    )
    on_top = (
        f'  <circle cx="34" cy="50" r="5" fill="{dark}" opacity="0.2" />\n'
        f'  <circle cx="94" cy="50" r="5" fill="{dark}" opacity="0.2" />\n'
        f'  <circle cx="40" cy="94" r="4" fill="{dark}" opacity="0.2" />\n'
        f'  <circle cx="88" cy="94" r="4" fill="{dark}" opacity="0.2" />\n'
        f'  <circle cx="64" cy="42" r="4" fill="{dark}" opacity="0.15" />'
    )
    return behind, on_top


def features_tiger(fill: str, dark: str, **_) -> tuple[str, str]:
    behind = (
        f'  <circle cx="24" cy="30" r="12" fill="{fill}" />\n'
        f'  <circle cx="24" cy="30" r="7" fill="{dark}" opacity="0.3" />\n'
        f'  <circle cx="104" cy="30" r="12" fill="{fill}" />\n'
        f'  <circle cx="104" cy="30" r="7" fill="{dark}" opacity="0.3" />'
    )
    on_top = (
        f'  <line x1="52" y1="34" x2="48" y2="44" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <line x1="64" y1="32" x2="64" y2="42" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <line x1="76" y1="34" x2="80" y2="44" stroke="{dark}" stroke-width="2.5" stroke-linecap="round" />\n'
        f'  <line x1="24" y1="56" x2="30" y2="66" stroke="{dark}" stroke-width="2" stroke-linecap="round" />\n'
        f'  <line x1="22" y1="68" x2="28" y2="78" stroke="{dark}" stroke-width="2" stroke-linecap="round" />\n'
        f'  <line x1="104" y1="56" x2="98" y2="66" stroke="{dark}" stroke-width="2" stroke-linecap="round" />\n'
        f'  <line x1="106" y1="68" x2="100" y2="78" stroke="{dark}" stroke-width="2" stroke-linecap="round" />'
    )
    return behind, on_top


FEATURES = {
    'bee': features_bee,
    'butterfly': features_butterfly,
    'hummingbird': features_hummingbird,
    'rabbit': features_rabbit,
    'kangaroo': features_kangaroo,
    'deer': features_deer,
    'giraffe': features_giraffe,
    'tiger': features_tiger,
}


# ─── Assembly ─────────────────────────────────────────────────────────────────

def build_svg(animal: str, emotion: str) -> str:
    colors = ANIMALS[animal]
    fill, dark, light = colors['fill'], colors['dark'], colors['light']

    behind, on_top = FEATURES[animal](**colors)

    parts = []
    # 1. Features behind the face (ears, wings, antennae)
    if behind:
        parts.append(behind)
    # 2. Face
    parts.append(rounded_rect_face(fill))
    # 3. On-face markings (stripes, spots) — drawn on top of face, under facial features
    if on_top:
        parts.append(on_top)
    # 4. Cheeks
    parts.append(cheeks(light))
    # 5. Eyes
    parts.append(EYES[emotion]())
    # 6. Nose
    parts.append(nose(dark))
    # 7. Mouth
    parts.append(MOUTHS[emotion]())

    return svg_wrap('\n'.join(parts))


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    count = 0
    for animal in ANIMALS:
        animal_dir = os.path.join(BASE_DIR, animal)
        os.makedirs(animal_dir, exist_ok=True)

        for emotion in EMOTIONS:
            svg = build_svg(animal, emotion)
            path = os.path.join(animal_dir, f'{emotion}.svg')
            with open(path, 'w') as f:
                f.write(svg)
            count += 1
            print(f'  ✓ {animal}/{emotion}.svg')

        # Also write the top-level neutral avatar
        neutral_svg = build_svg(animal, 'neutral')
        top_path = os.path.join(BASE_DIR, f'{animal}.svg')
        with open(top_path, 'w') as f:
            f.write(neutral_svg)
        print(f'  ✓ {animal}.svg (top-level)')

    print(f'\nDone! Generated {count} emotion SVGs + {len(ANIMALS)} top-level avatars.')


if __name__ == '__main__':
    main()
