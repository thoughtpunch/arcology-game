#!/usr/bin/env python3
"""Generate isometric block sprites for Arcology.

Creates 64x64 PNG sprites with hexagonal cutaway appearance:
- Top diamond (floor face): lighter color
- Left wall: medium color
- Right wall: darker color

Usage: python3 scripts/generate_sprites.py
"""

from PIL import Image, ImageDraw
import os

# Sprite dimensions
WIDTH = 64
HEIGHT = 64
TILE_DEPTH = 32  # Diamond height
WALL_HEIGHT = 32  # Wall faces height

# Block colors: (floor_color, left_wall, right_wall)
# Using the specified colors from the task
BLOCK_COLORS = {
    "corridor": ("#9ca3af", "#6b7280", "#4b5563"),      # Grays
    "entrance": ("#fbbf24", "#f59e0b", "#d97706"),      # Golds
    "stairs": ("#5eead4", "#14b8a6", "#0d9488"),        # Teals
    "elevator": ("#a78bfa", "#8b5cf6", "#7c3aed"),      # Purples
    "residential": ("#93c5fd", "#3b82f6", "#2563eb"),   # Blues
    "commercial": ("#86efac", "#22c55e", "#16a34a"),    # Greens
}


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def create_isometric_block(floor_color: str, left_color: str, right_color: str) -> Image.Image:
    """Create a 64x64 isometric block sprite with cutaway view.

    The sprite has a hexagonal perimeter:
    - Top: diamond floor face
    - Bottom-left: left wall face
    - Bottom-right: right wall face

    Hexagon vertices (0-indexed from top, clockwise):
      0: top center (32, 0)
      1: top-right (64, 16)
      2: bottom-right (64, 48)
      3: bottom center (32, 64)
      4: bottom-left (0, 48)
      5: top-left (0, 16)
    """
    img = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Hexagon vertices
    top_center = (32, 0)
    top_right = (63, 16)
    bottom_right = (63, 48)
    bottom_center = (32, 63)
    bottom_left = (0, 48)
    top_left = (0, 16)

    # Center point where all three faces meet
    center = (32, 32)

    # Draw top face (diamond/floor)
    top_face = [top_center, top_right, center, top_left]
    draw.polygon(top_face, fill=hex_to_rgb(floor_color))

    # Draw left wall face
    left_face = [top_left, center, bottom_center, bottom_left]
    draw.polygon(left_face, fill=hex_to_rgb(left_color))

    # Draw right wall face
    right_face = [center, top_right, bottom_right, bottom_center]
    draw.polygon(right_face, fill=hex_to_rgb(right_color))

    # Draw outline edges for definition
    outline_color = (0, 0, 0, 128)  # Semi-transparent black

    # Top diamond outline
    draw.line([top_center, top_right], fill=outline_color, width=1)
    draw.line([top_right, center], fill=outline_color, width=1)
    draw.line([center, top_left], fill=outline_color, width=1)
    draw.line([top_left, top_center], fill=outline_color, width=1)

    # Outer hexagon edges
    draw.line([top_right, bottom_right], fill=outline_color, width=1)
    draw.line([bottom_right, bottom_center], fill=outline_color, width=1)
    draw.line([bottom_center, bottom_left], fill=outline_color, width=1)
    draw.line([bottom_left, top_left], fill=outline_color, width=1)

    # Center vertical line
    draw.line([center, bottom_center], fill=outline_color, width=1)

    return img


def main():
    output_dir = "assets/sprites/blocks"
    os.makedirs(output_dir, exist_ok=True)

    print(f"Generating block sprites in {output_dir}/")

    for block_type, colors in BLOCK_COLORS.items():
        floor_color, left_color, right_color = colors
        img = create_isometric_block(floor_color, left_color, right_color)

        output_path = os.path.join(output_dir, f"{block_type}.png")
        img.save(output_path, 'PNG')
        print(f"  Created {output_path}")

    print(f"\nGenerated {len(BLOCK_COLORS)} sprites")


if __name__ == "__main__":
    main()
