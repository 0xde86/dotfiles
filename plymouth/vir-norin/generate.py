#!/usr/bin/env python3
"""Generate image assets for the 'Vir Norin' Plymouth boot theme,
matching the green CRT look of the web page."""
import os, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

OUT = "/home/claude/vir-norin"
os.makedirs(OUT, exist_ok=True)

MONO_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"

# palette (matches the page)
INK      = (2, 10, 5)         # near-black green
GREEN    = (51, 255, 102)     # #33ff66 phosphor
GRAD = [(0.0, (198, 255, 0)),  # #c6ff00 chartreuse
        (0.5, (57, 255, 136)), # #39ff88 spring
        (1.0, (0, 207, 106))]  # #00cf6a emerald

def grad_color(t):
    for i in range(len(GRAD) - 1):
        a, ca = GRAD[i]; b, cb = GRAD[i + 1]
        if a <= t <= b:
            k = (t - a) / (b - a)
            return tuple(int(ca[j] + (cb[j] - ca[j]) * k) for j in range(3))
    return GRAD[-1][1]

# ---------------------------------------------------------------- background
def make_background(W=1920, H=1080):
    img = Image.new("RGB", (W, H), INK)
    d = ImageDraw.Draw(img, "RGBA")
    hy = int(H * 0.46)                 # horizon
    vpx = W // 2                       # vanishing point x
    # vertical lane lines converging to vanishing point
    n = 26
    for i in range(-n, n + 1):
        bx = vpx + i * (W / n)
        d.line([(bx, H), (vpx, hy)], fill=(*GREEN, 42), width=1)
    # horizontal lines, spaced by perspective (denser near horizon)
    rows = 22
    for i in range(1, rows + 1):
        f = (i / rows) ** 2.2
        y = int(hy + (H - hy) * f)
        d.line([(0, y), (W, y)], fill=(*GREEN, 50), width=1)
    # faint horizon glow
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rectangle([0, hy - 2, W, hy + 2], fill=(*GREEN, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    # vignette
    vig = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vig)
    vd.ellipse([-W * 0.25, -H * 0.25, W * 1.25, H * 1.25], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(220))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 235))
    dark.putalpha(Image.eval(vig, lambda p: 235 - p))
    img = Image.alpha_composite(img, dark)
    img.convert("RGB").save(f"{OUT}/background.png")
    print("background.png")

# ---------------------------------------------------------------- logo
# (removed) The "VIR NORIN" handle is now drawn as live text inside
# vir-norin.script, with the gradient + glow applied programmatically.
# No logo.png is generated anymore.

# ---------------------------------------------------------------- progress bar
def make_bar(width=620, height=16):
    # outline box (transparent interior, green border)
    box = Image.new("RGBA", (width + 8, height + 8), (0, 0, 0, 0))
    ImageDraw.Draw(box).rectangle([0, 0, width + 7, height + 7],
                                  outline=(*GREEN, 230), width=1)
    box.save(f"{OUT}/bar_box.png")
    # fill swatch (full width; script scales width by progress)
    fill = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fill)
    fd.rectangle([0, 0, width - 1, height - 1], fill=(*GREEN, 235))
    fd.rectangle([0, 0, width - 1, 2], fill=(170, 255, 187, 255))  # bright top edge
    glow = fill.filter(ImageFilter.GaussianBlur(4))
    fill = Image.alpha_composite(glow, fill)
    fill.save(f"{OUT}/bar_fill.png")
    print("bar_box.png / bar_fill.png", (width, height))

# ---------------------------------------------------------------- scanlines
def make_scanlines(W=1920, H=1080):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for y in range(0, H, 3):
        d.line([(0, y), (W, y)], fill=(0, 0, 0, 70), width=1)
    img.save(f"{OUT}/scanlines.png")
    print("scanlines.png")

make_background()
make_bar()
make_scanlines()
print("done ->", OUT)
