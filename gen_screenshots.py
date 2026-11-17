#!/usr/bin/env python3
"""Render preview screenshots for Brainrot Bonanza (roblox-brainrot-01).

Roblox Studio does not run on this Linux VM, so these are rendered previews
of the game world (top-down map + HUD), drawn from the same layout numbers
the server uses. The thumbnail (1-start.png) is a composed 16:9 image, which
the kit's rules allow. Replace with real Studio captures after playtesting.
All images are 1280x720 and kept under 256 KiB.
"""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1280, 720
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screenshots")
os.makedirs(OUT, exist_ok=True)

def font(size, bold=True):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()

# Map area (top-down): world x in [-100,100] -> px, world z in [-100,100] -> py.
MX0, MY0, MX1, MY1 = 90, 90, 1190, 620
def mx(x): return MX0 + (x + 100) / 200 * (MX1 - MX0)
def my(z): return MY0 + (z + 100) / 200 * (MY1 - MY0)

BASES = [
    ("BASE 1\nRED", (-70, -60), (255, 80, 80)),
    ("BASE 2\nORANGE", (-25, -60), (255, 170, 0)),
    ("BASE 3\nBLUE", (20, -60), (80, 200, 255)),
    ("BASE 4\nPURPLE", (65, -60), (170, 90, 255)),
    ("BASE 5\nGREEN", (-70, 60), (90, 255, 140)),
    ("BASE 6\nPINK", (-25, 60), (255, 120, 200)),
    ("BASE 7\nYELLOW", (20, 60), (255, 255, 90)),
    ("BASE 8\nWHITE", (65, 60), (235, 235, 235)),
]
BRAINROTS = [
    ("Tung Tung\nTung Sahur", -60, (150, 110, 70), "$5/s"),
    ("Tralalero\nTralala", -35, (90, 160, 255), "$8/s"),
    ("Bombardiro\nCrocodilo", -10, (90, 200, 90), "$15/s"),
    ("Ballerina\nCappuccina", 15, (255, 220, 240), "$40/s"),
    ("Trippi\nTroppi", 40, (255, 150, 60), "$120/s"),
    ("La Vaca\nSaturno", 62, (200, 220, 255), "$200/s"),
]

def draw_base(img, hud_cash="$12,450", hud_per="$312/s", hud_n="6/8", wave="Wave in 42s"):
    d = ImageDraw.Draw(img, "RGBA")
    # Sky / backdrop.
    d.rectangle([0, 0, W, H], fill=(18, 20, 45))
    # HUD bar.
    d.rounded_rectangle([20, 12, W - 20, 64], radius=10, fill=(25, 25, 55, 220))
    d.text((34, 22), f"Cash: {hud_cash}", font=font(22), fill=(120, 255, 120))
    d.text((300, 22), f"+{hud_per}", font=font(22), fill=(255, 215, 0))
    d.text((480, 22), f"Brainrots: {hud_n}", font=font(22), fill=(140, 220, 255))
    d.text((700, 22), "Rebirths: 2 (x1.56)", font=font(22), fill=(255, 150, 255))
    d.text((980, 22), wave, font=font(22), fill=(255, 120, 120))
    # Map ground.
    d.rounded_rectangle([MX0, MY0, MX1, MY1], radius=12, fill=(110, 190, 90))
    # Plaza + conveyor.
    d.rectangle([mx(-85), my(-20), mx(85), my(20)], fill=(70, 70, 90))
    d.rectangle([mx(-75), my(-5), mx(75), my(5)], fill=(40, 40, 55))
    d.rectangle([mx(-75), my(-5.6), mx(75), my(-4.4)], fill=(255, 215, 0))
    d.rectangle([mx(-75), my(4.4), mx(75), my(5.6)], fill=(255, 215, 0))
    # Totem.
    d.ellipse([mx(-8), my(-43), mx(8), my(-27)], fill=(255, 215, 0))
    # Bases.
    for label, (bx, bz), color in BASES:
        x0, y0 = mx(bx - 13), my(bz - 9)
        x1, y1 = mx(bx + 13), my(bz + 9)
        d.rounded_rectangle([x0, y0, x1, y1], radius=6, fill=color, outline=(255, 255, 255), width=2)
        d.multiline_text(((x0 + x1) / 2, (y0 + y1) / 2), label, font=font(13),
                         fill=(20, 20, 20), anchor="mm", align="center")
    # Trees.
    for tx, tz in [(-95, -40), (-95, 40), (95, -40), (95, 40), (-45, -85), (45, -85)]:
        d.ellipse([mx(tx) - 10, my(tz) - 10, mx(tx) + 10, my(tz) + 10], fill=(40, 140, 60))
    # Spawn.
    d.rounded_rectangle([mx(-5), my(80), mx(5), my(90)], radius=4, fill=(90, 255, 140))
    d.text((mx(0), my(96)), "SPAWN", font=font(13), fill=(255, 255, 255), anchor="mm")
    return d

def draw_brainrots(d, highlight=None):
    for name, x, color, income in BRAINROTS:
        cx, cy = mx(x), my(0)
        d.rounded_rectangle([cx - 26, cy - 22, cx + 26, cy + 22], radius=8,
                            fill=color, outline=(255, 255, 255), width=2)
        d.text((cx, cy - 2), income, font=font(14), fill=(20, 20, 20), anchor="mm")
        d.multiline_text((cx, cy + 34), name, font=font(11), fill=(255, 255, 255),
                         anchor="mm", align="center")

def banner(d, text, color=(220, 40, 40)):
    d.rounded_rectangle([W // 2 - 420, 76, W // 2 + 420, 118], radius=10, fill=color)
    d.text((W // 2, 97), text, font=font(24), fill=(255, 255, 255), anchor="mm")

def footer(d, text):
    d.rounded_rectangle([20, H - 44, W - 20, H - 12], radius=8, fill=(0, 0, 0, 140))
    d.text((W // 2, H - 28), text, font=font(16), fill=(255, 255, 255), anchor="mm")

# 1 — start / cover: title over the world.
img = Image.new("RGB", (W, H))
d = draw_base(img)
draw_brainrots(d)
d.rounded_rectangle([W // 2 - 430, 128, W // 2 + 430, 302], radius=16, fill=(15, 15, 35, 215))
d.text((W // 2, 182), "BRAINROT BONANZA", font=font(52), fill=(255, 215, 0), anchor="mm")
d.text((W // 2, 242), "Collect meme brainrots  •  Earn cash every second  •  Steal. Rebirth.",
       font=font(20), fill=(180, 220, 255), anchor="mm")
d.text((W // 2, 274), "Survive the Brainrot Tsunami!", font=font(20), fill=(255, 150, 150), anchor="mm")
footer(d, "Press PLAY — buy brainrots off the conveyor with E")
img.save(f"{OUT}/1-start.png", optimize=True)

# 2 — play: conveyor full of brainrots, bases filling up.
img = Image.new("RGB", (W, H))
d = draw_base(img, hud_cash="$12,450", hud_per="$312/s", hud_n="6/8", wave="Wave in 42s")
draw_brainrots(d)
# A few brainrots already on bases.
for (bx, bz), color in [((-70, -60), (150, 110, 70)), ((-25, -60), (90, 160, 255)),
                        ((20, -60), (255, 220, 240)), ((65, 60), (255, 150, 60))]:
    d.rounded_rectangle([mx(bx) - 18, my(bz) - 14, mx(bx) + 18, my(bz) + 14], radius=6,
                        fill=color, outline=(255, 255, 255), width=2)
footer(d, "Brainrots walk the conveyor — press E to buy one for your base")
img.save(f"{OUT}/2-play.png", optimize=True)

# 3 — steal: a player carrying a brainrot dashes home.
img = Image.new("RGB", (W, H))
d = draw_base(img, hud_cash="$8,900", hud_per="$210/s", hud_n="4/8", wave="Wave in 67s")
draw_brainrots(d)
# Thief (blue dot) carrying a golden brainrot, running toward the blue base.
tx, ty = mx(35), my(25)
d.ellipse([tx - 16, ty - 16, tx + 16, ty + 16], fill=(80, 200, 255), outline=(255, 255, 255), width=3)
d.rounded_rectangle([tx - 20, ty - 48, tx + 20, ty - 24], radius=6, fill=(255, 215, 0),
                    outline=(255, 255, 255), width=2)
d.text((tx, ty - 36), "$120/s", font=font(12), fill=(20, 20, 20), anchor="mm")
d.line([(tx, ty), (mx(20), my(-60))], fill=(255, 80, 80), width=4)
d.text((W // 2, 640), "STOLEN! Dash home to your base before someone slaps you!",
       font=font(20), fill=(255, 120, 120), anchor="mm")
banner(d, "CARRYING: Trippi Troppi — DASH TO YOUR BASE!", color=(200, 60, 60))
footer(d, "Hold E on another player's brainrot to steal it — F to slap a thief")
img.save(f"{OUT}/3-steal.png", optimize=True)

# 4 — wave: the tsunami wall sweeps the map.
img = Image.new("RGB", (W, H))
d = draw_base(img, hud_cash="$21,300", hud_per="$540/s", hud_n="8/8", wave="TSUNAMI NOW!")
draw_brainrots(d)
# Wave wall: a translucent blue band sweeping left to right.
d.rectangle([mx(-30), MY0, mx(-14), MY1], fill=(60, 140, 255))
for yy in range(MY0, MY1, 26):
    d.line([(mx(-30), yy), (mx(-14), yy + 14)], fill=(200, 230, 255), width=3)
banner(d, "🌊 TSUNAMI! STAY IN YOUR BASE!", color=(30, 90, 220))
footer(d, "Caught outside your base? The wave flings you back to spawn!")
img.save(f"{OUT}/4-wave.png", optimize=True)

for f in sorted(os.listdir(OUT)):
    p = os.path.join(OUT, f)
    print(f, os.path.getsize(p), "bytes")
