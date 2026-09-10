#!/usr/bin/env python3
"""Turns the source artwork in assets/branding/src into everything the app ships.

    python3 tool/make_branding.py

Sources keep their flat matte; every generated asset is knocked out to
transparency so the art sits on the app's own dark background instead of a grey
square. The knockout is a flood fill from the four corners, so only the matte
*around* the artwork goes — dark areas inside the frame are left alone.
"""

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SRC = Path('assets/branding/src')
OUT = Path('assets/branding')
RES = Path('android/app/src/main/res')

# Legacy launcher icon, px per density bucket.
LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
# Adaptive layers are 108dp; same buckets at 2.25x the legacy size.
ADAPTIVE = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}

# Android 8+ masks the 108dp canvas down to a guaranteed-visible 72dp circle.
# Art with its own frame — like ours — has to live inside that or get clipped.
SAFE_ZONE = 72 / 108

# Matches RaColors.background, so the icon sits on the same dark as the app.
BACKGROUND = '#0B0B0F'


def knockout(img: Image.Image, tolerance: int = 46) -> Image.Image:
    """Makes the matte around the artwork transparent, flooding from the corners."""
    img = img.convert('RGBA')
    w, h = img.size
    rgb = img.convert('RGB').load()
    alpha = Image.new('L', (w, h), 255)
    mask = alpha.load()

    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    base = rgb[0, 0]
    queue = deque(seeds)
    seen = set(seeds)

    def matches(px):
        return sum(abs(a - b) for a, b in zip(px, base)) <= tolerance * 3

    while queue:
        x, y = queue.popleft()
        if not matches(rgb[x, y]):
            continue
        mask[x, y] = 0
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen:
                seen.add((nx, ny))
                queue.append((nx, ny))

    # One pixel of feathering, so the neon edge is not a staircase.
    img.putalpha(alpha.filter(ImageFilter.GaussianBlur(0.6)))
    return img


def trim(img: Image.Image) -> Image.Image:
    """Crops to what is left after the knockout."""
    box = img.getbbox()
    return img.crop(box) if box else img


def square(img: Image.Image) -> Image.Image:
    """Pads to a square so no resize step ever distorts the artwork."""
    w, h = img.size
    if w == h:
        return img
    side = max(w, h)
    out = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    out.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return out


def write(img: Image.Image, bucket: str, name: str) -> None:
    target = RES / f'mipmap-{bucket}'
    target.mkdir(parents=True, exist_ok=True)
    img.save(target / f'{name}.png')


def build_icons(art: Image.Image) -> None:
    for bucket, size in LEGACY.items():
        write(art.resize((size, size), Image.LANCZOS), bucket, 'ic_launcher')

        # Pre-26 round launchers crop to a circle; insetting the art keeps the
        # shield whole instead of shaving its corners off.
        canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        circle = Image.new('L', (size * 4, size * 4), 0)
        ImageDraw.Draw(circle).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
        disc = Image.new('RGBA', (size, size), BACKGROUND)
        disc.putalpha(circle.resize((size, size), Image.LANCZOS))
        canvas.alpha_composite(disc)
        inner = int(size * 0.78)
        canvas.alpha_composite(
            art.resize((inner, inner), Image.LANCZOS),
            ((size - inner) // 2, (size - inner) // 2),
        )
        write(canvas, bucket, 'ic_launcher_round')

    for bucket, canvas_size in ADAPTIVE.items():
        inner = int(canvas_size * SAFE_ZONE)
        layer = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        layer.paste(
            art.resize((inner, inner), Image.LANCZOS),
            ((canvas_size - inner) // 2, (canvas_size - inner) // 2),
        )
        write(layer, bucket, 'ic_launcher_foreground')

    (RES / 'mipmap-anydpi-v26').mkdir(parents=True, exist_ok=True)
    for name in ('ic_launcher', 'ic_launcher_round'):
        (RES / 'mipmap-anydpi-v26' / f'{name}.xml').write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background" />\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />\n'
            '</adaptive-icon>\n'
        )

    (RES / 'values' / 'colors.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        f'    <color name="ic_launcher_background">{BACKGROUND}</color>\n'
        '</resources>\n'
    )


def main() -> int:
    icon_src = SRC / 'app_icon.png'
    if not icon_src.exists():
        print(f'missing {icon_src}')
        return 1

    art = square(trim(knockout(Image.open(icon_src))))
    build_icons(art)
    art.save(OUT / 'logo.png')
    print(f'icons + logo.png from {art.size[0]}px artwork')

    hero_src = SRC / 'hero.png'
    if hero_src.exists():
        trim(knockout(Image.open(hero_src))).save(OUT / 'hero.png')
        print('hero.png')

    # The sheet is a 2x2 grid of independent badges; slice so each can be used
    # on its own.
    sheet_src = SRC / 'badges.jpeg'
    if sheet_src.exists():
        sheet = Image.open(sheet_src).convert('RGBA')
        w, h = sheet.size
        for index, (col, row) in enumerate(
                ((0, 0), (1, 0), (0, 1), (1, 1)), start=1):
            tile = sheet.crop(
                (col * w // 2, row * h // 2,
                 (col + 1) * w // 2, (row + 1) * h // 2))
            trim(knockout(tile)).save(OUT / f'badge_{index}.png')
        print('badge_1..4.png')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
