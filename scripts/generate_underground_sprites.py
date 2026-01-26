#!/usr/bin/env python3
"""Generate isometric underground terrain sprites for Arcology.

Creates underground layer sprites for Earth and Mars themes:
- soil.png (64x64) - Z=-1 brown topsoil (Earth) / red regolith (Mars)
- rock.png (64x64) - Z=-2 clay/rock mix (Earth) / orange rock (Mars)
- bedrock.png (64x64) - Z=-3+ gray bedrock (Earth) / dark basalt (Mars)

Each sprite is an isometric block (top diamond + 2 walls) representing
solid terrain that must be excavated.

Usage: python3 scripts/generate_underground_sprites.py
"""

from PIL import Image, ImageDraw
import os

# Standard sprite dimensions (same as blocks)
TILE_WIDTH = 64
TILE_HEIGHT = 64

# Isometric geometry
DIAMOND_HEIGHT = 32  # Top face diamond height
WALL_HEIGHT = 32     # Height of side walls


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def darken(color: tuple, factor: float = 0.7) -> tuple:
    """Darken a color by a factor."""
    return tuple(int(c * factor) for c in color)


def lighten(color: tuple, factor: float = 1.3) -> tuple:
    """Lighten a color by a factor."""
    return tuple(min(255, int(c * factor)) for c in color)


def create_isometric_block(
    top_color: tuple,
    left_color: tuple,
    right_color: tuple,
    texture_noise: bool = True
) -> Image.Image:
    """Create an isometric block sprite (solid underground terrain).

    The block has:
    - A diamond-shaped top face
    - A left wall (darker)
    - A right wall (lighter than left, darker than top)
    """
    img = Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Define points for isometric block
    # Top diamond
    top_points = [
        (32, 0),      # Top
        (64, 16),     # Right
        (32, 32),     # Bottom
        (0, 16),      # Left
    ]

    # Left wall (parallelogram)
    left_points = [
        (0, 16),      # Top left
        (32, 32),     # Top right
        (32, 64),     # Bottom right
        (0, 48),      # Bottom left
    ]

    # Right wall (parallelogram)
    right_points = [
        (32, 32),     # Top left
        (64, 16),     # Top right
        (64, 48),     # Bottom right
        (32, 64),     # Bottom left
    ]

    # Draw walls first (behind top)
    draw.polygon(left_points, fill=left_color)
    draw.polygon(right_points, fill=right_color)

    # Draw top face
    draw.polygon(top_points, fill=top_color)

    # Add subtle texture/noise if enabled
    if texture_noise:
        _add_texture(img, top_points, top_color, 0.1)
        _add_texture(img, left_points, left_color, 0.08)
        _add_texture(img, right_points, right_color, 0.08)

    # Outline for definition
    outline = (0, 0, 0, 60)
    draw.polygon(top_points, outline=outline, width=1)
    draw.polygon(left_points, outline=outline, width=1)
    draw.polygon(right_points, outline=outline, width=1)

    return img


def _add_texture(img: Image.Image, region_points: list, base_color: tuple, intensity: float):
    """Add subtle random texture noise within a region."""
    import random

    # Get bounding box of region
    xs = [p[0] for p in region_points]
    ys = [p[1] for p in region_points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)

    # Create mask for region
    mask = Image.new('L', img.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.polygon(region_points, fill=255)

    # Add random noise pixels
    random.seed(42)  # Deterministic for consistency
    pixels = img.load()
    mask_pixels = mask.load()

    for y in range(min_y, min(max_y, TILE_HEIGHT)):
        for x in range(min_x, min(max_x, TILE_WIDTH)):
            if mask_pixels[x, y] > 0 and random.random() < 0.15:
                variation = int(255 * intensity * (random.random() - 0.5) * 2)
                r, g, b = base_color
                r = max(0, min(255, r + variation))
                g = max(0, min(255, g + variation))
                b = max(0, min(255, b + variation))
                pixels[x, y] = (r, g, b, 255)


def create_earth_soil() -> Image.Image:
    """Create brown topsoil for Z=-1 (Earth theme).

    Rich brown soil with organic texture.
    """
    top = hex_to_rgb("#8B5A2B")     # Sienna brown (top)
    left = hex_to_rgb("#6B4423")    # Dark brown (left shadow)
    right = hex_to_rgb("#7A5128")   # Medium brown (right)
    return create_isometric_block(top, left, right)


def create_earth_rock() -> Image.Image:
    """Create clay/rock mix for Z=-2 (Earth theme).

    Grayish-brown rocky clay layer.
    """
    top = hex_to_rgb("#8B7355")     # Tan/clay (top)
    left = hex_to_rgb("#5C4A3D")    # Dark clay (left shadow)
    right = hex_to_rgb("#6B5B4F")   # Medium clay (right)
    return create_isometric_block(top, left, right)


def create_earth_bedrock() -> Image.Image:
    """Create gray bedrock for Z=-3+ (Earth theme).

    Hard gray stone layer.
    """
    top = hex_to_rgb("#696969")     # Dim gray (top)
    left = hex_to_rgb("#3D3D3D")    # Dark gray (left shadow)
    right = hex_to_rgb("#505050")   # Medium gray (right)
    return create_isometric_block(top, left, right)


def create_mars_regolith() -> Image.Image:
    """Create red regolith for Z=-1 (Mars theme).

    Rusty Martian surface soil.
    """
    top = hex_to_rgb("#B5451C")     # Rusty red (top)
    left = hex_to_rgb("#8B3014")    # Dark rust (left shadow)
    right = hex_to_rgb("#9C3D18")   # Medium rust (right)
    return create_isometric_block(top, left, right)


def create_mars_rock() -> Image.Image:
    """Create orange rock for Z=-2 (Mars theme).

    Martian subsurface rock.
    """
    top = hex_to_rgb("#CD6839")     # Orange-brown (top)
    left = hex_to_rgb("#8B4726")    # Dark orange (left shadow)
    right = hex_to_rgb("#A85530")   # Medium orange (right)
    return create_isometric_block(top, left, right)


def create_mars_basalt() -> Image.Image:
    """Create dark basalt for Z=-3+ (Mars theme).

    Martian basaltic bedrock.
    """
    top = hex_to_rgb("#4A4A4A")     # Dark gray (top)
    left = hex_to_rgb("#2D2D2D")    # Very dark (left shadow)
    right = hex_to_rgb("#3A3A3A")   # Medium dark (right)
    return create_isometric_block(top, left, right)


def main():
    # Earth underground sprites
    earth_dir = "assets/sprites/terrain/earth/underground"
    os.makedirs(earth_dir, exist_ok=True)

    print(f"Generating Earth underground sprites in {earth_dir}/")

    earth_sprites = {
        "soil": create_earth_soil,
        "rock": create_earth_rock,
        "bedrock": create_earth_bedrock,
    }

    for name, create_func in earth_sprites.items():
        img = create_func()
        output_path = os.path.join(earth_dir, f"{name}.png")
        img.save(output_path, 'PNG')
        print(f"  Created {output_path} ({img.width}x{img.height})")

    # Mars underground sprites
    mars_dir = "assets/sprites/terrain/mars/underground"
    os.makedirs(mars_dir, exist_ok=True)

    print(f"\nGenerating Mars underground sprites in {mars_dir}/")

    mars_sprites = {
        "regolith": create_mars_regolith,
        "rock": create_mars_rock,
        "basalt": create_mars_basalt,
    }

    for name, create_func in mars_sprites.items():
        img = create_func()
        output_path = os.path.join(mars_dir, f"{name}.png")
        img.save(output_path, 'PNG')
        print(f"  Created {output_path} ({img.width}x{img.height})")

    print(f"\nGenerated {len(earth_sprites) + len(mars_sprites)} underground sprites")


if __name__ == "__main__":
    main()
