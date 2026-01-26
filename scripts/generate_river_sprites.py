#!/usr/bin/env python3
"""Generate isometric river tile sprites for Arcology.

Creates Earth theme river tiles:
- straight_ns.png (64x64) - north-south river section
- straight_ew.png (64x64) - east-west river section
- corner_ne.png (64x64) - north-east corner
- corner_nw.png (64x64) - north-west corner
- corner_se.png (64x64) - south-east corner
- corner_sw.png (64x64) - south-west corner
- end_n.png (64x64) - river end facing north
- end_s.png (64x64) - river end facing south
- end_e.png (64x64) - river end facing east
- end_w.png (64x64) - river end facing west

Note: In isometric view, N/S alignment runs along the Y axis (NE-SW screen diagonal)
and E/W alignment runs along the X axis (NW-SE screen diagonal).

Usage: python3 scripts/generate_river_sprites.py
"""

from PIL import Image, ImageDraw
import os

# Standard sprite dimensions (isometric diamond)
TILE_WIDTH = 64
TILE_HEIGHT = 64

# Diamond coordinates (isometric top-down view)
# The visible ground is a diamond shape
DIAMOND_TOP = (32, 16)     # Top point
DIAMOND_RIGHT = (56, 32)   # Right point
DIAMOND_BOTTOM = (32, 48)  # Bottom point
DIAMOND_LEFT = (8, 32)     # Left point


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def lerp_color(c1: tuple, c2: tuple, t: float) -> tuple:
    """Linear interpolate between two colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


# Water colors
WATER_DEEP = hex_to_rgb("#1e3a5f")     # Deep water (center)
WATER_MID = hex_to_rgb("#2563eb")      # Mid water
WATER_SHALLOW = hex_to_rgb("#60a5fa")  # Shallow water (edges)
WATER_HIGHLIGHT = hex_to_rgb("#93c5fd") # Surface highlights
BANK_DARK = hex_to_rgb("#5c4827")      # River bank (earth)
BANK_LIGHT = hex_to_rgb("#8b7355")     # Bank highlight


def create_base_diamond() -> Image.Image:
    """Create a base transparent image with diamond reference."""
    return Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))


def draw_isometric_diamond(draw: ImageDraw.Draw, points: list, fill: tuple, outline=None):
    """Draw an isometric diamond shape."""
    draw.polygon(points, fill=fill, outline=outline)


def create_straight_ns() -> Image.Image:
    """Create north-south oriented river (flows along Y axis).

    In isometric view, this runs from top-left to bottom-right diagonal.
    The river fills the middle of the diamond from N to S edges.
    """
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # River channel runs from top to bottom of diamond
    # Banks on left and right sides

    # Left bank
    bank_left = [
        DIAMOND_LEFT,           # Left point
        DIAMOND_TOP,            # Top point
        (28, 20),               # Inner top
        (12, 32),               # Inner left
    ]
    draw.polygon(bank_left, fill=BANK_DARK)

    # Right bank
    bank_right = [
        (36, 20),               # Inner top
        DIAMOND_TOP,            # Top point (shared)
        DIAMOND_RIGHT,          # Right point
        (52, 32),               # Inner right
    ]
    # Second part of right bank
    bank_right2 = [
        DIAMOND_RIGHT,
        DIAMOND_BOTTOM,
        (36, 44),
        (52, 32),
    ]
    draw.polygon(bank_right, fill=BANK_LIGHT)
    draw.polygon(bank_right2, fill=BANK_LIGHT)

    # Left bank lower
    bank_left2 = [
        DIAMOND_LEFT,
        DIAMOND_BOTTOM,
        (28, 44),
        (12, 32),
    ]
    draw.polygon(bank_left2, fill=BANK_DARK)

    # Water channel (center)
    water_main = [
        (28, 20),   # Top edge (inner)
        (36, 20),   # Top edge (inner)
        (52, 32),   # Right inner
        (36, 44),   # Bottom inner
        (28, 44),   # Bottom inner
        (12, 32),   # Left inner
    ]
    draw.polygon(water_main, fill=WATER_MID)

    # Water center highlight
    water_center = [
        (30, 24),
        (34, 24),
        (44, 32),
        (34, 40),
        (30, 40),
        (20, 32),
    ]
    draw.polygon(water_center, fill=WATER_DEEP)

    # Surface highlights (ripples)
    draw.line([(24, 28), (40, 28)], fill=WATER_HIGHLIGHT + (180,), width=1)
    draw.line([(22, 34), (42, 34)], fill=WATER_HIGHLIGHT + (180,), width=1)
    draw.line([(24, 40), (40, 40)], fill=WATER_HIGHLIGHT + (180,), width=1)

    return img


def create_straight_ew() -> Image.Image:
    """Create east-west oriented river (flows along X axis).

    In isometric view, this runs from top-right to bottom-left diagonal.
    """
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # Top bank
    bank_top = [
        DIAMOND_TOP,
        DIAMOND_RIGHT,
        (48, 28),
        (32, 20),
        (16, 28),
        DIAMOND_LEFT,
    ]
    draw.polygon(bank_top, fill=BANK_LIGHT)

    # Top bank left section highlight
    bank_top_left = [
        DIAMOND_TOP,
        DIAMOND_LEFT,
        (16, 28),
        (32, 20),
    ]
    draw.polygon(bank_top_left, fill=BANK_DARK)

    # Bottom bank
    bank_bottom = [
        (16, 36),
        (32, 44),
        (48, 36),
        DIAMOND_RIGHT,
        DIAMOND_BOTTOM,
        DIAMOND_LEFT,
    ]
    draw.polygon(bank_bottom, fill=BANK_DARK)

    # Water channel
    water_main = [
        (16, 28),
        (32, 20),
        (48, 28),
        (48, 36),
        (32, 44),
        (16, 36),
    ]
    draw.polygon(water_main, fill=WATER_MID)

    # Water center
    water_center = [
        (20, 30),
        (32, 24),
        (44, 30),
        (44, 34),
        (32, 40),
        (20, 34),
    ]
    draw.polygon(water_center, fill=WATER_DEEP)

    # Surface highlights
    draw.line([(20, 32), (44, 32)], fill=WATER_HIGHLIGHT + (180,), width=1)

    return img


def create_corner_ne() -> Image.Image:
    """Create corner turning from N to E (or E to N)."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # This corner has water in the NE quadrant, banks elsewhere

    # SW bank (large)
    bank_sw = [
        DIAMOND_LEFT,
        DIAMOND_BOTTOM,
        (32, 44),
        (20, 36),
        (20, 28),
        (32, 20),
    ]
    draw.polygon(bank_sw, fill=BANK_DARK)

    # Top-left bank
    bank_nw = [
        DIAMOND_TOP,
        DIAMOND_LEFT,
        (20, 28),
        (32, 20),
    ]
    draw.polygon(bank_nw, fill=BANK_LIGHT)

    # Bottom-right bank
    bank_se = [
        DIAMOND_BOTTOM,
        DIAMOND_RIGHT,
        (44, 36),
        (32, 44),
    ]
    draw.polygon(bank_se, fill=BANK_LIGHT)

    # Water (NE corner curve)
    water = [
        (32, 20),     # Top inner
        DIAMOND_TOP,  # Top point
        DIAMOND_RIGHT,# Right point
        (44, 36),     # Inner bottom right
        (32, 44),     # Bottom inner
        (20, 36),     # Inner curve
        (20, 28),     # Inner top
    ]
    draw.polygon(water, fill=WATER_MID)

    # Inner water (deeper)
    water_inner = [
        (32, 22),
        (36, 20),
        (50, 30),
        (42, 36),
        (32, 42),
        (24, 36),
        (24, 28),
    ]
    draw.polygon(water_inner, fill=WATER_DEEP)

    return img


def create_corner_nw() -> Image.Image:
    """Create corner turning from N to W (or W to N)."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # SE bank (large)
    bank_se = [
        DIAMOND_RIGHT,
        DIAMOND_BOTTOM,
        (32, 44),
        (44, 36),
        (44, 28),
        (32, 20),
    ]
    draw.polygon(bank_se, fill=BANK_LIGHT)

    # Bottom-left bank
    bank_sw = [
        DIAMOND_LEFT,
        DIAMOND_BOTTOM,
        (32, 44),
        (20, 36),
    ]
    draw.polygon(bank_sw, fill=BANK_DARK)

    # Top-right bank
    bank_ne = [
        DIAMOND_TOP,
        DIAMOND_RIGHT,
        (44, 28),
        (32, 20),
    ]
    draw.polygon(bank_ne, fill=BANK_LIGHT)

    # Water (NW corner)
    water = [
        DIAMOND_TOP,
        DIAMOND_LEFT,
        (20, 36),
        (32, 44),
        (44, 36),
        (44, 28),
        (32, 20),
    ]
    draw.polygon(water, fill=WATER_MID)

    # Inner water
    water_inner = [
        (28, 20),
        (14, 30),
        (22, 36),
        (32, 42),
        (40, 36),
        (40, 28),
        (32, 22),
    ]
    draw.polygon(water_inner, fill=WATER_DEEP)

    return img


def create_corner_se() -> Image.Image:
    """Create corner turning from S to E (or E to S)."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # NW bank
    bank_nw = [
        DIAMOND_TOP,
        DIAMOND_LEFT,
        (20, 36),
        (32, 44),
        (32, 28),
        (20, 20),
    ]
    draw.polygon(bank_nw, fill=BANK_DARK)

    # Top-right bank
    bank_ne = [
        DIAMOND_TOP,
        DIAMOND_RIGHT,
        (44, 28),
        (32, 20),
    ]
    draw.polygon(bank_ne, fill=BANK_LIGHT)

    # Water (SE corner)
    water = [
        (32, 20),
        (44, 28),
        DIAMOND_RIGHT,
        DIAMOND_BOTTOM,
        DIAMOND_LEFT,
        (20, 36),
        (32, 44),
        (32, 28),
    ]
    draw.polygon(water, fill=WATER_MID)

    # Inner water
    water_inner = [
        (32, 24),
        (40, 28),
        (50, 34),
        (32, 46),
        (14, 34),
        (24, 38),
        (32, 40),
    ]
    draw.polygon(water_inner, fill=WATER_DEEP)

    return img


def create_corner_sw() -> Image.Image:
    """Create corner turning from S to W (or W to S)."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # NE bank
    bank_ne = [
        DIAMOND_TOP,
        DIAMOND_RIGHT,
        (44, 36),
        (32, 44),
        (32, 28),
        (44, 20),
    ]
    draw.polygon(bank_ne, fill=BANK_LIGHT)

    # Top-left bank
    bank_nw = [
        DIAMOND_TOP,
        DIAMOND_LEFT,
        (20, 28),
        (32, 20),
    ]
    draw.polygon(bank_nw, fill=BANK_DARK)

    # Water (SW corner)
    water = [
        (32, 20),
        (20, 28),
        DIAMOND_LEFT,
        DIAMOND_BOTTOM,
        DIAMOND_RIGHT,
        (44, 36),
        (32, 44),
        (32, 28),
    ]
    draw.polygon(water, fill=WATER_MID)

    # Inner water
    water_inner = [
        (32, 24),
        (24, 28),
        (14, 34),
        (32, 46),
        (50, 34),
        (40, 38),
        (32, 40),
    ]
    draw.polygon(water_inner, fill=WATER_DEEP)

    return img


def create_end_n() -> Image.Image:
    """Create river end pointing north (source/sink)."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # Banks on all sides except where water enters from south
    # Bank around the pool
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, DIAMOND_LEFT], fill=BANK_DARK)

    # Right side lighter
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, (32, 32)], fill=BANK_LIGHT)

    # Water pool (smaller, centered, open at bottom)
    water = [
        (32, 24),     # Top (rounded end)
        (40, 28),     # Upper right
        (44, 34),     # Mid right
        (40, 42),     # Lower right
        (32, 48),     # Bottom (open)
        (24, 42),     # Lower left
        (20, 34),     # Mid left
        (24, 28),     # Upper left
    ]
    draw.polygon(water, fill=WATER_MID)

    # Center deep
    draw.ellipse([26, 28, 38, 40], fill=WATER_DEEP)

    return img


def create_end_s() -> Image.Image:
    """Create river end pointing south."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # Bank all around
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, DIAMOND_LEFT], fill=BANK_DARK)
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, (32, 32)], fill=BANK_LIGHT)

    # Water pool (open at top)
    water = [
        (32, 16),     # Top (open)
        (40, 22),     # Upper right
        (44, 30),     # Mid right
        (40, 38),     # Lower right
        (32, 42),     # Bottom (rounded end)
        (24, 38),     # Lower left
        (20, 30),     # Mid left
        (24, 22),     # Upper left
    ]
    draw.polygon(water, fill=WATER_MID)

    # Center deep
    draw.ellipse([26, 24, 38, 36], fill=WATER_DEEP)

    return img


def create_end_e() -> Image.Image:
    """Create river end pointing east."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # Bank all around
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, DIAMOND_LEFT], fill=BANK_DARK)
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, (32, 32)], fill=BANK_LIGHT)

    # Water pool (open at right)
    water = [
        (24, 26),     # Top left
        (32, 22),     # Top center
        (56, 32),     # Right (open)
        (32, 42),     # Bottom center
        (24, 38),     # Bottom left
        (18, 32),     # Left (rounded end)
    ]
    draw.polygon(water, fill=WATER_MID)

    # Center deep
    draw.ellipse([22, 28, 40, 38], fill=WATER_DEEP)

    return img


def create_end_w() -> Image.Image:
    """Create river end pointing west."""
    img = create_base_diamond()
    draw = ImageDraw.Draw(img)

    # Bank all around
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, DIAMOND_LEFT], fill=BANK_DARK)
    draw.polygon([DIAMOND_TOP, DIAMOND_RIGHT, DIAMOND_BOTTOM, (32, 32)], fill=BANK_LIGHT)

    # Water pool (open at left)
    water = [
        (40, 26),     # Top right
        (46, 32),     # Right (rounded end)
        (40, 38),     # Bottom right
        (32, 42),     # Bottom center
        (8, 32),      # Left (open)
        (32, 22),     # Top center
    ]
    draw.polygon(water, fill=WATER_MID)

    # Center deep
    draw.ellipse([24, 28, 42, 38], fill=WATER_DEEP)

    return img


def main():
    output_dir = "assets/sprites/terrain/earth/river_tiles"
    os.makedirs(output_dir, exist_ok=True)

    print(f"Generating river tile sprites in {output_dir}/")

    sprites = {
        "straight_ns": create_straight_ns,
        "straight_ew": create_straight_ew,
        "corner_ne": create_corner_ne,
        "corner_nw": create_corner_nw,
        "corner_se": create_corner_se,
        "corner_sw": create_corner_sw,
        "end_n": create_end_n,
        "end_s": create_end_s,
        "end_e": create_end_e,
        "end_w": create_end_w,
    }

    for name, create_func in sprites.items():
        img = create_func()
        output_path = os.path.join(output_dir, f"{name}.png")
        img.save(output_path, 'PNG')
        print(f"  Created {output_path} ({img.width}x{img.height})")

    print(f"\nGenerated {len(sprites)} river tile sprites")


if __name__ == "__main__":
    main()
