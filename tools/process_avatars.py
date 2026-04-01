#!/usr/bin/env python3
"""
Process AI-generated avatar images for ChessPals.

Usage:
    python3 tools/process_avatars.py <input_dir>

Expects files named: {animal}_{emotion}.png (e.g. bee_happy.png)
Crops to square, resizes to 512x512, and copies to src/assets/bot_avatars/{animal}/{emotion}.png
"""

import sys
import os
from pathlib import Path

ANIMALS = ['bee', 'butterfly', 'hummingbird', 'rabbit', 'kangaroo', 'deer', 'giraffe', 'tiger']
EMOTIONS = ['neutral', 'happy', 'sad', 'scared', 'furious']

ASSET_DIR = Path(__file__).resolve().parent.parent / 'src' / 'assets' / 'bot_avatars'
TARGET_SIZE = 512


def crop_center_square(img):
    """Crop the largest centered square from an image."""
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def apply_circular_mask(img):
    """Mask the image to a circle with transparent corners."""
    from PIL import Image, ImageDraw
    size = img.size
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size[0] - 1, size[1] - 1), fill=255)
    img.putalpha(mask)
    return img


def process_images(input_dir: Path):
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not installed. Installing...")
        os.system(f"{sys.executable} -m pip install Pillow")
        from PIL import Image

    input_dir = Path(input_dir)
    if not input_dir.is_dir():
        print(f"Error: {input_dir} is not a directory")
        sys.exit(1)

    processed = 0
    missing = []

    for animal in ANIMALS:
        out_dir = ASSET_DIR / animal
        out_dir.mkdir(parents=True, exist_ok=True)

        for emotion in EMOTIONS:
            # Try multiple naming patterns
            candidates = [
                input_dir / f"{animal}_{emotion}.png",
                input_dir / f"{animal}_{emotion}.jpg",
                input_dir / f"{animal}_{emotion}.jpeg",
                input_dir / f"{animal}_{emotion}.webp",
                input_dir / f"{animal}-{emotion}.png",
                input_dir / f"{animal} {emotion}.png",
            ]

            src = None
            for c in candidates:
                if c.exists():
                    src = c
                    break

            if src is None:
                missing.append(f"{animal}_{emotion}")
                continue

            img = Image.open(src)

            # Convert to RGBA (keep transparency if present, add if not)
            if img.mode != 'RGBA':
                img = img.convert('RGBA')

            # Crop to square
            img = crop_center_square(img)

            # Resize to target
            img = img.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)

            # Apply circular mask (transparent corners)
            img = apply_circular_mask(img)

            # Save as PNG
            out_path = out_dir / f"{emotion}.png"
            img.save(out_path, 'PNG', optimize=True)
            print(f"  ✓ {animal}/{emotion}.png ({src.name})")
            processed += 1

    print(f"\nProcessed: {processed}/40")
    if missing:
        print(f"Missing ({len(missing)}):")
        for m in missing:
            print(f"  ✗ {m}")

    if processed > 0:
        print(f"\nFiles saved to: {ASSET_DIR}")
        print("\nNext step: update bot_character.dart to enable PNG emotions:")
        print("  Change `bool get hasPngEmotions => false;` to `=> true;`")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input_directory>")
        print(f"  e.g.: {sys.argv[0]} ~/Downloads/chesspals_avatars")
        sys.exit(1)

    process_images(Path(sys.argv[1]))
