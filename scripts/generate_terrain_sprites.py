#!/usr/bin/env python3
"""Generate isometric terrain decoration sprites for Arcology.

Creates Earth theme decoration sprites:
- tree_oak.png (64x64) - deciduous tree
- tree_pine.png (64x64) - conifer tree
- rock_small.png (64x64) - small boulder
- rock_large.png (128x96) - large 2x2 boulder
- bush.png (64x64) - shrub/bush
- flowers.png (64x64) - flower patch

Usage: python3 scripts/generate_terrain_sprites.py
"""

from PIL import Image, ImageDraw
import os

# Standard sprite dimensions
TILE_WIDTH = 64
TILE_HEIGHT = 64

# 2x2 sprite dimensions
LARGE_WIDTH = 128
LARGE_HEIGHT = 96


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def create_tree_oak() -> Image.Image:
    """Create a deciduous (oak) tree sprite.

    Isometric tree with round foliage canopy on trunk.
    """
    img = Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    trunk_dark = hex_to_rgb("#5c4033")  # Dark brown
    trunk_light = hex_to_rgb("#8b6914")  # Light brown
    foliage_dark = hex_to_rgb("#228b22")  # Forest green
    foliage_mid = hex_to_rgb("#32cd32")  # Lime green
    foliage_light = hex_to_rgb("#90ee90")  # Light green
    outline = (0, 0, 0, 100)

    # Draw trunk (center bottom)
    trunk_points = [
        (28, 64),  # Bottom left
        (36, 64),  # Bottom right
        (36, 40),  # Top right
        (28, 40),  # Top left
    ]
    draw.polygon(trunk_points, fill=trunk_dark)
    # Trunk highlight on right side
    draw.polygon([(32, 64), (36, 64), (36, 40), (32, 40)], fill=trunk_light)

    # Draw foliage canopy (ellipse/oval shape)
    # Main canopy - dark base
    draw.ellipse([8, 4, 56, 44], fill=foliage_dark)
    # Mid-tone highlight
    draw.ellipse([12, 8, 48, 36], fill=foliage_mid)
    # Light highlight (top-left)
    draw.ellipse([16, 10, 36, 28], fill=foliage_light)

    # Outline for definition
    draw.ellipse([8, 4, 56, 44], outline=outline, width=1)

    return img


def create_tree_pine() -> Image.Image:
    """Create a conifer (pine) tree sprite.

    Isometric pine tree with triangular layers.
    """
    img = Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    trunk_dark = hex_to_rgb("#5c4033")
    foliage_dark = hex_to_rgb("#0f5132")  # Dark evergreen
    foliage_mid = hex_to_rgb("#198754")  # Mid green
    foliage_light = hex_to_rgb("#20c997")  # Teal-green highlight
    outline = (0, 0, 0, 100)

    # Draw trunk (thin center)
    trunk_points = [
        (30, 64),
        (34, 64),
        (34, 50),
        (30, 50),
    ]
    draw.polygon(trunk_points, fill=trunk_dark)

    # Draw triangular foliage layers (bottom to top)
    # Bottom layer (widest)
    layer1 = [(32, 48), (8, 52), (56, 52)]
    draw.polygon(layer1, fill=foliage_dark)

    # Second layer
    layer2 = [(32, 32), (12, 44), (52, 44)]
    draw.polygon(layer2, fill=foliage_mid)

    # Third layer
    layer3 = [(32, 18), (16, 34), (48, 34)]
    draw.polygon(layer3, fill=foliage_mid)

    # Top layer (narrowest)
    layer4 = [(32, 4), (22, 22), (42, 22)]
    draw.polygon(layer4, fill=foliage_light)

    # Outlines
    draw.polygon(layer1, outline=outline, width=1)
    draw.polygon(layer2, outline=outline, width=1)
    draw.polygon(layer3, outline=outline, width=1)
    draw.polygon(layer4, outline=outline, width=1)

    return img


def create_rock_small() -> Image.Image:
    """Create a small boulder sprite.

    Irregular polygonal rock shape.
    """
    img = Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    rock_dark = hex_to_rgb("#4a4a4a")  # Dark gray
    rock_mid = hex_to_rgb("#6b6b6b")   # Mid gray
    rock_light = hex_to_rgb("#8f8f8f")  # Light gray
    outline = (0, 0, 0, 120)

    # Irregular rock shape (sitting on isometric ground)
    # Main rock body
    rock_points = [
        (16, 48),  # Bottom left
        (8, 38),   # Left
        (12, 28),  # Top left
        (28, 22),  # Top
        (48, 26),  # Top right
        (56, 36),  # Right
        (52, 48),  # Bottom right
        (32, 54),  # Bottom center
    ]
    draw.polygon(rock_points, fill=rock_dark)

    # Lighter face (top surface)
    top_face = [
        (12, 28),
        (28, 22),
        (48, 26),
        (44, 34),
        (24, 32),
    ]
    draw.polygon(top_face, fill=rock_mid)

    # Highlight
    highlight = [
        (16, 28),
        (28, 24),
        (36, 26),
        (30, 30),
    ]
    draw.polygon(highlight, fill=rock_light)

    # Outline
    draw.polygon(rock_points, outline=outline, width=1)

    return img


def create_rock_large() -> Image.Image:
    """Create a large 2x2 boulder sprite.

    Large irregular rock formation spanning 2x2 grid cells.
    Dimensions: 128x96 pixels
    """
    img = Image.new('RGBA', (LARGE_WIDTH, LARGE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    rock_dark = hex_to_rgb("#3d3d3d")  # Darker gray
    rock_mid = hex_to_rgb("#5a5a5a")   # Mid gray
    rock_light = hex_to_rgb("#7a7a7a")  # Light gray
    rock_highlight = hex_to_rgb("#9a9a9a")  # Highlight
    outline = (0, 0, 0, 120)

    # Large irregular rock formation
    rock_points = [
        (24, 80),   # Bottom left
        (12, 60),   # Left lower
        (8, 44),    # Left upper
        (20, 28),   # Top left
        (48, 16),   # Top
        (88, 12),   # Top right
        (112, 28),  # Right upper
        (120, 48),  # Right lower
        (108, 72),  # Bottom right
        (80, 84),   # Bottom
        (52, 88),   # Bottom center
    ]
    draw.polygon(rock_points, fill=rock_dark)

    # Top surface (lighter)
    top_face = [
        (20, 28),
        (48, 16),
        (88, 12),
        (112, 28),
        (100, 40),
        (64, 32),
        (32, 36),
    ]
    draw.polygon(top_face, fill=rock_mid)

    # Secondary top highlight
    highlight1 = [
        (28, 30),
        (48, 20),
        (76, 18),
        (64, 32),
        (40, 34),
    ]
    draw.polygon(highlight1, fill=rock_light)

    # Top highlight spot
    highlight2 = [
        (44, 22),
        (60, 20),
        (72, 22),
        (60, 28),
    ]
    draw.polygon(highlight2, fill=rock_highlight)

    # Outline
    draw.polygon(rock_points, outline=outline, width=1)

    return img


def create_bush() -> Image.Image:
    """Create a bush/shrub sprite.

    Low, rounded foliage.
    """
    img = Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    foliage_dark = hex_to_rgb("#2d5016")   # Dark green
    foliage_mid = hex_to_rgb("#4a7c23")    # Mid green
    foliage_light = hex_to_rgb("#6b9b37")  # Light green
    outline = (0, 0, 0, 100)

    # Bush shape - low rounded mass
    # Base layer
    draw.ellipse([6, 32, 58, 60], fill=foliage_dark)

    # Middle layer
    draw.ellipse([10, 28, 54, 52], fill=foliage_mid)

    # Top bumps (irregular foliage texture)
    draw.ellipse([8, 26, 32, 46], fill=foliage_mid)
    draw.ellipse([28, 24, 56, 48], fill=foliage_mid)

    # Highlights
    draw.ellipse([14, 28, 30, 42], fill=foliage_light)
    draw.ellipse([32, 26, 48, 40], fill=foliage_light)

    # Subtle outline
    draw.ellipse([6, 32, 58, 60], outline=outline, width=1)

    return img


def create_flowers() -> Image.Image:
    """Create a flower patch sprite.

    Scattered small flowers on grass.
    """
    img = Image.new('RGBA', (TILE_WIDTH, TILE_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    grass_dark = hex_to_rgb("#3d6b2a")
    grass_light = hex_to_rgb("#5a9b3d")
    flower_red = hex_to_rgb("#dc2626")
    flower_yellow = hex_to_rgb("#facc15")
    flower_blue = hex_to_rgb("#3b82f6")
    flower_white = hex_to_rgb("#f8fafc")
    flower_center = hex_to_rgb("#fbbf24")

    # Grass base (isometric diamond-ish area)
    grass_points = [
        (32, 28),   # Top
        (56, 40),   # Right
        (32, 56),   # Bottom
        (8, 40),    # Left
    ]
    draw.polygon(grass_points, fill=grass_dark)
    # Light grass highlight
    draw.polygon([(32, 30), (48, 38), (32, 48), (16, 38)], fill=grass_light)

    # Flower positions and colors
    flowers = [
        (16, 38, flower_red),
        (24, 34, flower_yellow),
        (40, 36, flower_blue),
        (32, 42, flower_white),
        (48, 42, flower_red),
        (20, 46, flower_yellow),
        (38, 48, flower_blue),
        (28, 52, flower_white),
    ]

    for fx, fy, color in flowers:
        # Simple 4-petal flower
        petal_size = 3
        # Petals
        draw.ellipse([fx-petal_size, fy-1, fx+petal_size, fy+1], fill=color)  # Horizontal
        draw.ellipse([fx-1, fy-petal_size, fx+1, fy+petal_size], fill=color)  # Vertical
        # Center
        draw.ellipse([fx-1, fy-1, fx+1, fy+1], fill=flower_center)

    return img


def main():
    output_dir = "assets/sprites/terrain/earth"
    os.makedirs(output_dir, exist_ok=True)

    print(f"Generating terrain decoration sprites in {output_dir}/")

    sprites = {
        "tree_oak": create_tree_oak,
        "tree_pine": create_tree_pine,
        "rock_small": create_rock_small,
        "rock_large": create_rock_large,
        "bush": create_bush,
        "flowers": create_flowers,
    }

    for name, create_func in sprites.items():
        img = create_func()
        output_path = os.path.join(output_dir, f"{name}.png")
        img.save(output_path, 'PNG')
        print(f"  Created {output_path} ({img.width}x{img.height})")

    print(f"\nGenerated {len(sprites)} decoration sprites")


if __name__ == "__main__":
    main()
