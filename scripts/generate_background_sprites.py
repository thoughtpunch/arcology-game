#!/usr/bin/env python3
"""Generate background sprites for Arcology terrain system.

Creates theme-specific background images:
- earth_sky.png - Blue sky gradient with distant mountains
- mars_sky.png - Orange-pink Martian sky
- space_stars.png - High-res starfield

These render at z_index -2000 behind everything.

Usage: python3 scripts/generate_background_sprites.py
"""

from PIL import Image, ImageDraw
import random
import os

# Background dimensions (large to cover screen with camera movement)
BG_WIDTH = 2048
BG_HEIGHT = 1536


def hex_to_rgb(hex_color: str) -> tuple:
    """Convert hex color to RGB tuple."""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def lerp_color(c1: tuple, c2: tuple, t: float) -> tuple:
    """Linearly interpolate between two RGB colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def create_earth_sky() -> Image.Image:
    """Create Earth sky gradient with distant mountains.

    Blue sky gradient from light blue (top) to white-blue (horizon).
    Distant blue-gray mountains silhouette at bottom.
    """
    img = Image.new('RGB', (BG_WIDTH, BG_HEIGHT))
    draw = ImageDraw.Draw(img)

    # Sky gradient colors
    sky_top = hex_to_rgb("#4a90d9")      # Deep sky blue
    sky_mid = hex_to_rgb("#87ceeb")      # Sky blue
    sky_horizon = hex_to_rgb("#b8d4e8")  # Pale blue-white

    # Mountain colors
    mountain_far = hex_to_rgb("#7a8fa8")   # Blue-gray distant
    mountain_mid = hex_to_rgb("#5d7a94")   # Darker blue-gray

    # Draw sky gradient
    horizon_y = int(BG_HEIGHT * 0.75)  # Sky takes top 75%

    for y in range(horizon_y):
        # Two-stage gradient: top->mid, mid->horizon
        mid_y = horizon_y // 2
        if y < mid_y:
            t = y / mid_y
            color = lerp_color(sky_top, sky_mid, t)
        else:
            t = (y - mid_y) / (horizon_y - mid_y)
            color = lerp_color(sky_mid, sky_horizon, t)
        draw.line([(0, y), (BG_WIDTH, y)], fill=color)

    # Fill below horizon with horizon color
    draw.rectangle([0, horizon_y, BG_WIDTH, BG_HEIGHT], fill=sky_horizon)

    # Draw distant mountains (silhouette)
    random.seed(42)  # Deterministic mountains

    # Far mountains (lighter, smaller)
    far_mountain_y = int(BG_HEIGHT * 0.70)
    _draw_mountain_range(draw, far_mountain_y, BG_HEIGHT * 0.10, mountain_far, 8)

    # Mid mountains (darker, taller)
    mid_mountain_y = int(BG_HEIGHT * 0.75)
    _draw_mountain_range(draw, mid_mountain_y, BG_HEIGHT * 0.12, mountain_mid, 6)

    return img


def _draw_mountain_range(draw: ImageDraw, base_y: int, max_height: float,
                         color: tuple, num_peaks: int) -> None:
    """Draw a silhouette mountain range."""
    peak_width = BG_WIDTH // num_peaks
    points = [(0, BG_HEIGHT)]  # Start bottom-left

    for i in range(num_peaks + 1):
        x = i * peak_width
        # Vary peak heights
        height = max_height * (0.5 + random.random() * 0.5)
        peak_y = base_y - height

        # Add some randomness to peak x position
        peak_x = x + random.randint(-peak_width//4, peak_width//4)
        peak_x = max(0, min(BG_WIDTH, peak_x))

        # Add valley before peak
        if i > 0:
            valley_x = x - peak_width // 2
            valley_y = base_y - height * 0.2
            points.append((valley_x, valley_y))

        points.append((peak_x, peak_y))

    points.append((BG_WIDTH, BG_HEIGHT))  # End bottom-right
    draw.polygon(points, fill=color)


def create_mars_sky() -> Image.Image:
    """Create Mars sky gradient.

    Orange-pink gradient suggesting Martian atmosphere.
    Dusty, hazy appearance.
    """
    img = Image.new('RGB', (BG_WIDTH, BG_HEIGHT))
    draw = ImageDraw.Draw(img)

    # Mars sky gradient colors
    sky_top = hex_to_rgb("#8b5a3c")       # Brown-orange (upper)
    sky_mid = hex_to_rgb("#d4856a")       # Salmon-orange (mid)
    sky_horizon = hex_to_rgb("#e8b89d")   # Pale peach (horizon)
    ground_fade = hex_to_rgb("#a0522d")   # Sienna (ground)

    # Draw sky gradient
    horizon_y = int(BG_HEIGHT * 0.7)

    for y in range(horizon_y):
        mid_y = horizon_y // 2
        if y < mid_y:
            t = y / mid_y
            color = lerp_color(sky_top, sky_mid, t)
        else:
            t = (y - mid_y) / (horizon_y - mid_y)
            color = lerp_color(sky_mid, sky_horizon, t)
        draw.line([(0, y), (BG_WIDTH, y)], fill=color)

    # Ground fade below horizon
    for y in range(horizon_y, BG_HEIGHT):
        t = (y - horizon_y) / (BG_HEIGHT - horizon_y)
        color = lerp_color(sky_horizon, ground_fade, t)
        draw.line([(0, y), (BG_WIDTH, y)], fill=color)

    # Add subtle dust haze (scattered lighter pixels)
    random.seed(42)
    haze_color = hex_to_rgb("#e8c8a8")
    for _ in range(2000):
        x = random.randint(0, BG_WIDTH - 1)
        y = random.randint(0, BG_HEIGHT - 1)
        alpha = random.randint(20, 60)
        # Blend with existing pixel
        existing = img.getpixel((x, y))
        blended = lerp_color(existing, haze_color, alpha / 255)
        img.putpixel((x, y), blended)

    return img


def create_space_stars() -> Image.Image:
    """Create space starfield background.

    Deep black with scattered stars of varying brightness.
    Optional nebula colors for visual interest.
    """
    img = Image.new('RGB', (BG_WIDTH, BG_HEIGHT), hex_to_rgb("#0a0a1a"))
    draw = ImageDraw.Draw(img)

    random.seed(42)  # Deterministic stars

    # Add subtle nebula colors (very faint)
    _add_nebula(img, draw)

    # Star colors
    star_white = (255, 255, 255)
    star_blue = (200, 220, 255)
    star_yellow = (255, 255, 200)
    star_red = (255, 200, 200)

    star_colors = [star_white] * 7 + [star_blue] * 2 + [star_yellow] + [star_red]

    # Draw stars of varying sizes and brightness
    # Small dim stars (many)
    for _ in range(3000):
        x = random.randint(0, BG_WIDTH - 1)
        y = random.randint(0, BG_HEIGHT - 1)
        brightness = random.randint(60, 150)
        color = random.choice(star_colors)
        dimmed = tuple(int(c * brightness / 255) for c in color)
        img.putpixel((x, y), dimmed)

    # Medium stars
    for _ in range(500):
        x = random.randint(0, BG_WIDTH - 1)
        y = random.randint(0, BG_HEIGHT - 1)
        brightness = random.randint(150, 220)
        color = random.choice(star_colors)
        dimmed = tuple(int(c * brightness / 255) for c in color)
        # 2x2 pixel stars
        for dx in range(2):
            for dy in range(2):
                nx, ny = x + dx, y + dy
                if 0 <= nx < BG_WIDTH and 0 <= ny < BG_HEIGHT:
                    img.putpixel((nx, ny), dimmed)

    # Bright stars (few)
    for _ in range(50):
        x = random.randint(2, BG_WIDTH - 3)
        y = random.randint(2, BG_HEIGHT - 3)
        color = random.choice(star_colors)
        # Cross pattern for bright stars
        draw.point((x, y), fill=color)
        draw.point((x-1, y), fill=tuple(c // 2 for c in color))
        draw.point((x+1, y), fill=tuple(c // 2 for c in color))
        draw.point((x, y-1), fill=tuple(c // 2 for c in color))
        draw.point((x, y+1), fill=tuple(c // 2 for c in color))

    return img


def _add_nebula(img: Image.Image, draw: ImageDraw) -> None:
    """Add subtle nebula color patches."""
    # Nebula colors (very subtle)
    nebula_colors = [
        hex_to_rgb("#1a1a3a"),  # Deep blue
        hex_to_rgb("#2a1a2a"),  # Deep purple
        hex_to_rgb("#1a2a2a"),  # Deep teal
    ]

    # Create a few nebula patches
    for _ in range(5):
        cx = random.randint(0, BG_WIDTH)
        cy = random.randint(0, BG_HEIGHT)
        radius = random.randint(200, 500)
        color = random.choice(nebula_colors)

        # Draw radial gradient (approximation with circles)
        for r in range(radius, 0, -20):
            alpha = int(15 * (1 - r / radius))  # Very subtle
            ellipse_bbox = [cx - r, cy - r, cx + r, cy + r]
            # Blend by drawing semi-transparent
            for x in range(max(0, cx - r), min(BG_WIDTH, cx + r)):
                for y in range(max(0, cy - r), min(BG_HEIGHT, cy + r)):
                    dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                    if dist < r:
                        existing = img.getpixel((x, y))
                        t = alpha / 255 * (1 - dist / r)
                        blended = lerp_color(existing, color, t)
                        img.putpixel((x, y), blended)


def main():
    output_dir = "assets/sprites/terrain/backgrounds"
    os.makedirs(output_dir, exist_ok=True)

    print(f"Generating background sprites in {output_dir}/")

    sprites = {
        "earth_sky": create_earth_sky,
        "mars_sky": create_mars_sky,
        "space_stars": create_space_stars,
    }

    for name, create_func in sprites.items():
        print(f"  Creating {name}.png...")
        img = create_func()
        output_path = os.path.join(output_dir, f"{name}.png")
        img.save(output_path, 'PNG')
        print(f"    Saved {output_path} ({img.width}x{img.height})")

    print(f"\nGenerated {len(sprites)} background sprites")


if __name__ == "__main__":
    main()
