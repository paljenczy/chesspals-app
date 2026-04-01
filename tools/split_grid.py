#!/usr/bin/env python3
"""
Split an 8×5 grid image of ChessPals avatars into 40 individual files.

Usage:
    python3 tools/split_grid.py <grid_image.png>
    python3 tools/split_grid.py <grid_image.png> --cols 4  # for a 4×5 half-grid (first or second 4 animals)
    python3 tools/split_grid.py <grid_image.png> --offset 4  # start at animal index 4 (kangaroo) for second half-grid

Layout:
    Columns (left→right): bee, butterfly, hummingbird, rabbit, kangaroo, deer, giraffe, tiger
    Rows (top→bottom): neutral, happy, sad, scared, furious

Slices the grid into cells, crops each to square, resizes to 512×512,
applies a circular alpha mask, and saves to src/assets/bot_avatars/{animal}/{emotion}.png
"""

import sys
import os
from pathlib import Path
import argparse

ANIMALS = ['bee', 'butterfly', 'hummingbird', 'rabbit', 'kangaroo', 'deer', 'giraffe', 'tiger']
EMOTIONS = ['neutral', 'happy', 'sad', 'scared', 'furious']

ASSET_DIR = Path(__file__).resolve().parent.parent / 'src' / 'assets' / 'bot_avatars'
TARGET_SIZE = 512
COLS = 8
ROWS = 5


def ensure_pillow():
    try:
        from PIL import Image, ImageDraw
        return Image, ImageDraw
    except ImportError:
        print("Pillow not installed. Installing...")
        os.system(f"{sys.executable} -m pip install Pillow")
        from PIL import Image, ImageDraw
        return Image, ImageDraw


def apply_circular_mask(img, Image, ImageDraw):
    """Mask the image to a circle with transparent corners."""
    size = img.size
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size[0] - 1, size[1] - 1), fill=255)
    img.putalpha(mask)
    return img


def split_grid(grid_path: Path, cols: int = COLS, animal_offset: int = 0):
    Image, ImageDraw = ensure_pillow()

    grid = Image.open(grid_path)
    if grid.mode != 'RGBA':
        grid = grid.convert('RGBA')

    w, h = grid.size
    cell_w = w / cols
    cell_h = h / ROWS

    print(f"Grid: {w}×{h}px → {cols} cols × {ROWS} rows → cells ~{cell_w:.0f}×{cell_h:.0f}px")

    processed = 0
    for col in range(cols):
        animal_idx = col + animal_offset
        if animal_idx >= len(ANIMALS):
            print(f"  ⚠ Column {col + 1} exceeds animal list (offset={animal_offset}), skipping")
            continue
        animal = ANIMALS[animal_idx]
        out_dir = ASSET_DIR / animal
        out_dir.mkdir(parents=True, exist_ok=True)

        for row in range(ROWS):
            emotion = EMOTIONS[row]

            # Extract cell
            left = round(col * cell_w)
            top = round(row * cell_h)
            right = round((col + 1) * cell_w)
            bottom = round((row + 1) * cell_h)
            cell = grid.crop((left, top, right, bottom))

            # Crop to square (center)
            cw, ch = cell.size
            side = min(cw, ch)
            cl = (cw - side) // 2
            ct = (ch - side) // 2
            cell = cell.crop((cl, ct, cl + side, ct + side))

            # Resize
            cell = cell.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)

            # Circular mask
            cell = apply_circular_mask(cell, Image, ImageDraw)

            # Save
            out_path = out_dir / f"{emotion}.png"
            cell.save(out_path, 'PNG', optimize=True)
            print(f"  ✓ {animal}/{emotion}.png")
            processed += 1

    print(f"\nProcessed: {processed} avatars")
    print(f"Saved to: {ASSET_DIR}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Split avatar grid into individual files')
    parser.add_argument('grid_image', type=Path, help='Path to the grid image')
    parser.add_argument('--cols', type=int, default=COLS,
                        help=f'Number of columns in the grid (default: {COLS})')
    parser.add_argument('--offset', type=int, default=0,
                        help='Animal index offset for the first column (default: 0). '
                             'Use --offset 4 for a second half-grid starting at kangaroo.')
    args = parser.parse_args()

    if not args.grid_image.exists():
        print(f"Error: {args.grid_image} not found")
        sys.exit(1)

    split_grid(args.grid_image, cols=args.cols, animal_offset=args.offset)
