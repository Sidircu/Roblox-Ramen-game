#!/usr/bin/env python3
"""Pictures of the game's interface on a phone, a tablet and a computer, without Roblox Studio.

Runs the server and the real client of one player in the simulator (tools/sim.py), plays a short
script from tools/sim/ui/<name>.lua that sets the scene (joins, waits for an order, opens a
window...) and takes snapshots with Sim.snapshot("name"). Each snapshot is drawn into a PNG from
the laid-out GUI (tools/sim/gui.lua): panels, rounded corners, strokes, gradients, text with emoji
and Japanese, clipping; the Roblox top bar and, on touch screens, the thumbstick and the jump
button are drawn faintly on top so overlaps show.

  python3 tools/ui_preview.py hud                          # phone, tablet and desktop
  python3 tools/ui_preview.py hud --devices=phone,laptop --out=/tmp/ui
  python3 tools/ui_preview.py --list                       # the scripts in tools/sim/ui
Requires: pip install lupa pillow fonttools numpy
"""
import math
import os
import sys

import numpy as np
from fontTools.ttLib import TTFont
from lupa.lua54 import lua_type
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sim  # noqa: E402

UI_DIR = os.path.join(sim.SIM, "ui")
ZOOM = {"phone": 2, "phone_small": 2, "tablet": 1.5, "laptop": 1, "desktop": 1}


def find_font(*candidates):
    for c in candidates:
        if os.path.exists(c):
            return c
    return None


FONT_FILES = {
    "body": find_font("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    "bold": find_font("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    "title": find_font("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    "sym": find_font("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    "symbold": find_font("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
    "cjk": find_font("/usr/share/fonts/truetype/fonts-japanese-gothic.ttf", "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf"),
    "uni": find_font("/usr/share/fonts/opentype/unifont/unifont_jp.otf"),
}
EMOJI_FILE = find_font("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf")
EMOJI_STRIKE = 109
EMOJI_ADVANCE = 1.245

_cmaps = {}


def cmap(key):
    if key not in _cmaps:
        path = FONT_FILES.get(key) if key != "emoji" else EMOJI_FILE
        _cmaps[key] = set(TTFont(path, lazy=True).getBestCmap().keys()) if path else set()
    return _cmaps[key]


_fonts = {}


def font(key, size):
    size = max(1, int(round(size)))
    k = (key, size)
    if k not in _fonts:
        _fonts[k] = ImageFont.truetype(FONT_FILES[key], size)
    return _fonts[k]


_emoji_font = None
_emoji_cache = {}


def emoji_image(cluster, size):
    global _emoji_font
    if _emoji_font is None:
        _emoji_font = ImageFont.truetype(EMOJI_FILE, EMOJI_STRIKE)
    key = (cluster, int(round(size)))
    if key not in _emoji_cache:
        w = int(_emoji_font.getlength(cluster)) + 4
        im = Image.new("RGBA", (max(w, 1), 140), (0, 0, 0, 0))
        ImageDraw.Draw(im).text((0, 0), cluster, font=_emoji_font, embedded_color=True)
        bbox = im.getbbox()
        if bbox:
            im = im.crop((0, 0, max(bbox[2], 1), 128))
        target = max(1, int(round(size)))
        tw = max(1, int(round(im.width * target / 128)))
        _emoji_cache[key] = im.resize((tw, target), Image.LANCZOS)
    return _emoji_cache[key]


EMOJI_PRESENTATION = set()
for a, b in [(0x231A, 0x231B), (0x23E9, 0x23EC), (0x23F0, 0x23F0), (0x23F3, 0x23F3), (0x25FD, 0x25FE), (0x2614, 0x2615), (0x2648, 0x2653),
             (0x267F, 0x267F), (0x2693, 0x2693), (0x26A1, 0x26A1), (0x26AA, 0x26AB), (0x26BD, 0x26BE), (0x26C4, 0x26C5), (0x26CE, 0x26CE),
             (0x26D4, 0x26D4), (0x26EA, 0x26EA), (0x26F2, 0x26F3), (0x26F5, 0x26F5), (0x26FA, 0x26FA), (0x26FD, 0x26FD), (0x2705, 0x2705),
             (0x270A, 0x270B), (0x2728, 0x2728), (0x274C, 0x274C), (0x274E, 0x274E), (0x2753, 0x2755), (0x2757, 0x2757), (0x2795, 0x2797),
             (0x27B0, 0x27B0), (0x27BF, 0x27BF), (0x2B1B, 0x2B1C), (0x2B50, 0x2B50), (0x2B55, 0x2B55)]:
    EMOJI_PRESENTATION.update(range(a, b + 1))


def is_joiner(cp):
    return cp in (0xFE0F, 0xFE0E, 0x20E3) or 0x1F3FB <= cp <= 0x1F3FF or 0xE0020 <= cp <= 0xE007F


def segments(text, primary):
    """Splits a line into runs: (font key or "emoji", text)."""
    cps = [ord(c) for c in text]
    out = []
    i = 0
    while i < len(cps):
        cp = cps[i]
        nxt = cps[i + 1] if i + 1 < len(cps) else None
        emoji = EMOJI_FILE and cp in cmap("emoji") and (cp >= 0x1F000 or cp in EMOJI_PRESENTATION or nxt == 0xFE0F)
        if emoji and not (cp < 0x80):
            j = i + 1
            while j < len(cps):
                if is_joiner(cps[j]):
                    j += 1
                elif cps[j] == 0x200D and j + 1 < len(cps):
                    j += 2
                elif 0x1F1E6 <= cp <= 0x1F1FF and 0x1F1E6 <= cps[j] <= 0x1F1FF and j == i + 1:
                    j += 1
                else:
                    break
            out.append(("emoji", "".join(chr(c) for c in cps[i:j])))
            i = j
            continue
        if cp in (0xFE0F, 0x200D):
            i += 1
            continue
        if cp in cmap(primary) or cp < 0x20:
            key = primary
        elif cp in cmap("symbold" if primary != "body" else "sym"):
            key = "symbold" if primary != "body" else "sym"
        elif cp in cmap("cjk"):
            key = "cjk"
        else:
            key = "uni"
        if out and out[-1][0] == key:
            out[-1] = (key, out[-1][1] + chr(cp))
        else:
            out.append((key, chr(cp)))
        i += 1
    return out


def primary_key(font_family, bold):
    if "Fredoka" in (font_family or ""):
        return "title"
    return "bold" if bold else "body"


_measure_cache = {}


def run_width(key, s, size):
    if key == "emoji":
        n = 0
        for _ in segments_emoji_clusters(s):
            n += 1
        return n * size * EMOJI_ADVANCE
    return font(key, size).getlength(s)


def segments_emoji_clusters(s):
    # one emoji run can hold several clusters
    out = []
    for k, t in segments(s, "body"):
        if k == "emoji":
            out.append(t)
    return out


def line_width(line, size, primary):
    return sum(run_width(k, t, size) for k, t in segments(line, primary))


def wrap_lines(text, size, primary, max_width):
    lines = []
    for raw in text.split("\n"):
        if max_width is None:
            lines.append(raw)
            continue
        cur = ""
        for word in raw.split(" "):
            trial = word if cur == "" else cur + " " + word
            if cur != "" and line_width(trial, size, primary) > max_width:
                lines.append(cur)
                cur = word
            else:
                cur = trial
            # a single word longer than the line breaks by characters
            while line_width(cur, size, primary) > max_width and len(cur) > 1:
                cut = len(cur)
                while cut > 1 and line_width(cur[:cut], size, primary) > max_width:
                    cut -= 1
                lines.append(cur[:cut])
                cur = cur[cut:]
        lines.append(cur)
    return lines


def measure(text, size, bold, max_width=None, family=None):
    key = (text, size, bold, max_width, family)
    if key in _measure_cache:
        return _measure_cache[key]
    primary = primary_key(family, bold)
    lines = wrap_lines(text, size, primary, max_width if max_width and max_width > 0 else None)
    w = max((line_width(l, size, primary) for l in lines), default=0)
    res = (w, len(lines) * size)
    _measure_cache[key] = res
    return res


######################################################################## drawing helpers
def rounded_mask(w, h, r, ss=2):
    w, h = max(1, int(math.ceil(w))), max(1, int(math.ceil(h)))
    big = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(big).rounded_rectangle((0, 0, w * ss - 1, h * ss - 1), radius=max(0, r * ss), fill=255)
    return big.resize((w, h), Image.LANCZOS)


def interp(stops, t):
    if not stops:
        return None
    stops = sorted(stops, key=lambda s: s[0])
    if t <= stops[0][0]:
        return stops[0][1]
    for a, b in zip(stops, stops[1:]):
        if a[0] <= t <= b[0]:
            f = 0 if b[0] == a[0] else (t - a[0]) / (b[0] - a[0])
            if isinstance(a[1], (list, tuple)):
                return [a[1][i] + (b[1][i] - a[1][i]) * f for i in range(3)]
            return a[1] + (b[1] - a[1]) * f
    return stops[-1][1]


def gradient_field(w, h, rot):
    w, h = max(1, int(math.ceil(w))), max(1, int(math.ceil(h)))
    a = math.radians(rot)
    c, s = math.cos(a), math.sin(a)
    ys, xs = np.mgrid[0:h, 0:w]
    span = abs(w * c) + abs(h * s)
    t = 0.5 + ((xs - w / 2) * c + (ys - h / 2) * s) / max(span, 1e-6)
    return np.clip(t, 0, 1)


def fill_image(w, h, color, alpha, gradient):
    w, h = max(1, int(math.ceil(w))), max(1, int(math.ceil(h)))
    arr = np.zeros((h, w, 4), dtype=np.float32)
    arr[..., 0], arr[..., 1], arr[..., 2] = color
    arr[..., 3] = alpha * 255
    if gradient and (gradient.get("colors") or gradient.get("transp")):
        t = gradient_field(w, h, gradient.get("rot") or 0)
        if gradient.get("colors"):
            lut = np.array([interp(gradient["colors"], i / 255) for i in range(256)], dtype=np.float32) / 255
            idx = (t * 255).astype(np.int32)
            for ch in range(3):
                arr[..., ch] *= lut[idx, ch]
        if gradient.get("transp"):
            lut = np.array([interp(gradient["transp"], i / 255) for i in range(256)], dtype=np.float32)
            idx = (t * 255).astype(np.int32)
            arr[..., 3] *= 1 - lut[idx]
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


class Canvas:
    def __init__(self, w, h, zoom):
        self.zoom = zoom
        self.img = Image.new("RGBA", (int(w * zoom), int(h * zoom)), (0, 0, 0, 255))

    def paste(self, layer, x, y, clip):
        """Composites `layer` with its top-left at (x, y) (zoomed px), cut to `clip` (zoomed)."""
        x0, y0 = int(round(x)), int(round(y))
        x1, y1 = x0 + layer.width, y0 + layer.height
        cx0, cy0, cx1, cy1 = 0, 0, self.img.width, self.img.height
        if clip:
            cx0, cy0 = max(cx0, int(math.floor(clip[0]))), max(cy0, int(math.floor(clip[1])))
            cx1, cy1 = min(cx1, int(math.ceil(clip[2]))), min(cy1, int(math.ceil(clip[3])))
        ix0, iy0, ix1, iy1 = max(x0, cx0), max(y0, cy0), min(x1, cx1), min(y1, cy1)
        if ix1 <= ix0 or iy1 <= iy0:
            return
        part = layer.crop((ix0 - x0, iy0 - y0, ix1 - x0, iy1 - y0))
        self.img.alpha_composite(part, (ix0, iy0))


def draw_text(canvas, d, x, y, w, h, clip):
    text = d.get("text") or ""
    if text == "" or (d.get("textT") or 0) >= 1:
        return
    z = canvas.zoom
    primary = primary_key(d.get("font"), d.get("bold"))
    size = (d.get("textSize") or 14) * z
    wrapped = d.get("wrapped")
    if d.get("scaled"):
        hi = min(100 * (d.get("k") or 1), d.get("maxText") or 1e9) * z
        lo = 1.0
        best = lo
        while hi - lo > 0.5:
            mid = (lo + hi) / 2
            lines = wrap_lines(text, mid, primary, w if wrapped else None)
            lw = max((line_width(l, mid, primary) for l in lines), default=0)
            if lw <= w and len(lines) * mid * (d.get("lineHeight") or 1) <= h:
                best = mid
                lo = mid
            else:
                hi = mid
        size = best
    lines = wrap_lines(text, size, primary, w if wrapped else None)
    if d.get("truncate") == "AtEnd" and not wrapped:
        out = []
        for l in lines:
            if line_width(l, size, primary) > w:
                while l and line_width(l + "…", size, primary) > w:
                    l = l[:-1]
                l = l + "…"
            out.append(l)
        lines = out
    lh = size * (d.get("lineHeight") or 1)
    total = lh * len(lines)
    ya = d.get("ya") or "Center"
    top = y if ya == "Top" else (y + h - total if ya == "Bottom" else y + (h - total) / 2)
    color = tuple(d.get("textColor") or (0, 0, 0))
    alpha = int(255 * (1 - (d.get("textT") or 0)))
    stroke_w, stroke_fill = 0, None
    ts = d.get("textStroke")
    if ts and (ts.get("t") or 0) < 1:
        stroke_w = max(1, int(round((ts.get("thick") or 1) * z)))
        stroke_fill = tuple(ts.get("color") or (0, 0, 0)) + (int(255 * (1 - (ts.get("t") or 0)) * (1 - (d.get("textT") or 0))),)
    elif (d.get("strokeT") if d.get("strokeT") is not None else 1) < 1:
        stroke_w = max(1, int(round(1 * z)))
        stroke_fill = tuple(d.get("strokeColor") or (0, 0, 0)) + (int(255 * (1 - d["strokeT"])),)
    margin = int(stroke_w + size)
    lw_max = max((line_width(l, size, primary) for l in lines), default=0)
    layer_w = int(max(w, lw_max) + 2 * margin) + 2
    layer_h = int(max(h, total) + 2 * margin) + 2
    layer = Image.new("RGBA", (layer_w, layer_h), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    xa = d.get("xa") or "Center"
    base_font = font(primary, size)
    asc, desc = base_font.getmetrics()
    for i, l in enumerate(lines):
        lw = line_width(l, size, primary)
        if xa == "Left":
            lx = 0
        elif xa == "Right":
            lx = w - lw
        else:
            lx = (w - lw) / 2
        line_top = top - y + i * lh
        baseline = line_top + lh / 2 + (asc - desc) / 2
        cx = lx
        for key, run in segments(l, primary):
            if key == "emoji":
                for cl in segments_emoji_clusters(run):
                    im = emoji_image(cl, size)
                    ey = int(round(margin + line_top + (lh - size) / 2))
                    if alpha < 255:
                        im = im.copy()
                        im.putalpha(Image.eval(im.getchannel("A"), lambda v: v * alpha // 255))
                    layer.alpha_composite(im, (int(round(margin + cx + (size * EMOJI_ADVANCE - im.width) / 2)), max(0, ey)))
                    cx += size * EMOJI_ADVANCE
                continue
            f = font(key, size)
            kw = {}
            if stroke_w:
                kw = {"stroke_width": stroke_w, "stroke_fill": stroke_fill}
            dr.text((margin + cx, margin + baseline), run, font=f, fill=color + (alpha,), anchor="ls", **kw)
            cx += f.getlength(run)
    canvas.paste(layer, x - margin, y - margin, clip)


def draw_element(canvas, d):
    z = canvas.zoom
    x, y, w, h = d["x"] * z, d["y"] * z, d["w"] * z, d["h"] * z
    if w < 0.5 or h < 0.5:
        if not d.get("text"):
            return
    clip = [c * z for c in d["clip"]] if d.get("clip") else None
    r = (d.get("corner") or 0) * z
    rot = d.get("rot") or 0
    stroke = d.get("stroke")
    st = (stroke.get("thick") or 1) * z if stroke and (stroke.get("t") or 0) < 1 else 0
    if rot:
        # draw on a layer, rotate it around its centre
        sub = Canvas(1, 1, 1)
        pad = int(st + 4)
        sub.img = Image.new("RGBA", (int(w + 2 * pad), int(h + 2 * pad)), (0, 0, 0, 0))
        local = dict(d)
        local.update({"x": pad / z, "y": pad / z, "clip": None, "rot": 0})
        sub.zoom = z
        draw_element(sub, local)
        rotated = sub.img.rotate(-rot, resample=Image.BICUBIC, expand=True)
        canvas.paste(rotated, x + w / 2 - rotated.width / 2, y + h / 2 - rotated.height / 2, clip)
        return
    bgT = d.get("bgT")
    bgT = 0 if bgT is None else bgT
    if bgT < 1 and d.get("bg") and w >= 1 and h >= 1:
        fill = fill_image(w, h, d["bg"], 1 - bgT, d.get("gradient"))
        mask = rounded_mask(w, h, r)
        a = Image.eval(fill.getchannel("A"), lambda v: v)
        fill.putalpha(Image.fromarray((np.asarray(a, dtype=np.uint16) * np.asarray(mask, dtype=np.uint16) // 255).astype(np.uint8)))
        canvas.paste(fill, x, y, clip)
    if d.get("image") is not None and (d.get("imageT") or 0) < 1 and d.get("image") != "" and w >= 1 and h >= 1:
        col = d.get("imageColor") or (255, 255, 255)
        ph = fill_image(w, h, [c * 0.8 for c in col], 0.35 * (1 - (d.get("imageT") or 0)), None)
        canvas.paste(ph, x, y, clip)
    if st > 0:
        sw, sh = w + 2 * st, h + 2 * st
        outer = rounded_mask(sw, sh, r + st if r > 0 else 0)
        inner = Image.new("L", outer.size, 0)
        inner.paste(rounded_mask(w, h, r), (int(round(st)), int(round(st))))
        ring = np.clip(np.asarray(outer, dtype=np.int16) - np.asarray(inner, dtype=np.int16), 0, 255).astype(np.uint8)
        col = stroke.get("color") or (0, 0, 0)
        layer = fill_image(sw, sh, col, 1 - (stroke.get("t") or 0), None)
        a = np.asarray(layer.getchannel("A"), dtype=np.uint16)
        layer.putalpha(Image.fromarray((a[: ring.shape[0], : ring.shape[1]] * ring // 255).astype(np.uint8)))
        canvas.paste(layer, x - st, y - st, clip)
    if d.get("text"):
        draw_text(canvas, d, x, y, w, h, clip)
    if d.get("cls") == "ScrollingFrame" and d.get("canvasH") and d.get("windowH") and d["canvasH"] > d["windowH"] + 1:
        bar = max(8 * z, (d.get("scrollBar") or 8) * z / max(d.get("k") or 1, 1e-6) * (d.get("k") or 1))
        bh = max(20 * z, h * d["windowH"] / d["canvasH"])
        col = d.get("scrollColor") or (120, 90, 60)
        layer = fill_image(bar, bh, col, 0.85, None)
        layer.putalpha(Image.fromarray((np.asarray(layer.getchannel("A"), dtype=np.uint16) * np.asarray(rounded_mask(bar, bh, bar / 2), dtype=np.uint16) // 255).astype(np.uint8)))
        canvas.paste(layer, x + w - bar - 1 * z, y + 1 * z, clip)


def backdrop(canvas):
    """A warm restaurant-like background (the 3D world is not drawn)."""
    w, h = canvas.img.size
    t = np.linspace(0, 1, h)[:, None]
    top = np.array([54, 40, 34], dtype=np.float32)
    mid = np.array([112, 78, 52], dtype=np.float32)
    bottom = np.array([70, 52, 40], dtype=np.float32)
    col = np.where(t < 0.62, top + (mid - top) * (t / 0.62), mid + (bottom - mid) * ((t - 0.62) / 0.38))
    arr = np.repeat(col[:, None, :], w, axis=1)
    # a counter and a lantern glow so text contrast is judged on a busy scene
    ys, xs = np.mgrid[0:h, 0:w]
    glow = np.exp(-(((xs - w * 0.62) / (w * 0.22)) ** 2 + ((ys - h * 0.32) / (h * 0.22)) ** 2))
    arr += glow[..., None] * np.array([90, 60, 20])
    counter = (ys > h * 0.62) & (ys < h * 0.7)
    arr[counter] = arr[counter] * 0.6 + np.array([120, 80, 45]) * 0.4
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    canvas.img = img


def overlay(canvas, device, viewport, inset):
    """Roblox top bar and touch controls, drawn faintly."""
    z = canvas.zoom
    W, H = viewport
    layer = Image.new("RGBA", canvas.img.size, (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    # top bar buttons (menu, chat) and the inset line
    for i in range(2):
        x0 = (12 + i * 52) * z
        dr.rounded_rectangle((x0, 8 * z, x0 + 44 * z, 52 * z), radius=12 * z, fill=(20, 20, 24, 150))
    dr.rounded_rectangle(((W - 56) * z, 8 * z, (W - 12) * z, 52 * z), radius=12 * z, fill=(20, 20, 24, 150))
    dr.line((0, inset * z, W * z, inset * z), fill=(255, 255, 255, 40), width=max(1, int(z)))
    if device.get("touch"):
        # dynamic thumbstick: it appears where the thumb lands in the bottom-left; draw its usual spot
        r = 56 * z
        cx, cy = 110 * z, (H - 100) * z
        dr.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(255, 255, 255, 110), width=int(3 * z), fill=(0, 0, 0, 50))
        dr.ellipse((cx - r / 2.6, cy - r / 2.6, cx + r / 2.6, cy + r / 2.6), fill=(255, 255, 255, 90))
        # jump button (TouchGui: small screens 70 pt at (1, -95, 1, -90), larger 120 pt at (1, -170, 1, -210))
        small = min(W, H) <= 500
        js = 70 if small else 120
        jx = W - (js * 1.5 - 10)
        jy = H - js - 20 if small else H - js * 1.75
        dr.ellipse((jx * z, jy * z, (jx + js) * z, (jy + js) * z), outline=(255, 255, 255, 120), width=int(3 * z), fill=(0, 0, 0, 50))
        dr.text(((jx + js / 2) * z, (jy + js / 2) * z), "jump", fill=(255, 255, 255, 150), anchor="mm", font=font("bold", 12 * z))
        dr.text((cx, cy + r + 10 * z), "thumbstick", fill=(255, 255, 255, 150), anchor="mt", font=font("bold", 12 * z))
    canvas.img.alpha_composite(layer)


def to_py(v):
    if lua_type(v) == "table":
        keys = list(v.keys())
        if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
            return [to_py(v[k]) for k in range(1, len(keys) + 1)]
        return {k: to_py(v[k]) for k in keys}
    return v


def render(name, device_name, device, dump, viewport, inset, out_dir):
    zoom = ZOOM.get(device_name, 1)
    W, H = viewport
    canvas = Canvas(W, H, zoom)
    backdrop(canvas)
    for d in dump:
        try:
            draw_element(canvas, d)
        except Exception as e:  # keep drawing the rest
            print(f"  (could not draw {d.get('cls')} {d.get('name')}: {e})")
    overlay(canvas, device, viewport, inset)
    # caption strip
    cap_h = int(26 * max(zoom, 1))
    out = Image.new("RGBA", (canvas.img.width, canvas.img.height + cap_h), (24, 22, 26, 255))
    out.paste(canvas.img, (0, 0))
    ImageDraw.Draw(out).text((10 * zoom, canvas.img.height + cap_h / 2), f"{name} · {device_name} {int(W)}×{int(H)} pt",
                             fill=(230, 220, 205, 255), anchor="lm", font=font("bold", 13 * max(zoom, 1)))
    path = os.path.join(out_dir, f"{name}_{device_name}.png")
    out.convert("RGB").save(path)
    return path


def run(script, device_name, out_dir, verbose):
    shots = []

    def setup(lua):
        g = lua.globals()
        g.Sim.measureText = lambda text, size, bold, max_width=None, family=None: measure(
            str(text), float(size), bool(bold), float(max_width) if max_width else None, str(family) if family else None)
        g.Sim.previewDevice = device_name

        def snapshot(name, dev, dump, viewport, inset):
            gs = lua.eval('game:GetService("GuiService")')
            controls = lua.eval('function(g) return g.TouchControlsEnabled ~= false end')(gs)
            shots.append((str(name), to_py(dump), (viewport.X, viewport.Y), inset, controls))

        g["__snapshot"] = snapshot

    lua = sim.make_runtime(verbose, setup)
    path = os.path.join(UI_DIR, script + ".lua")
    ok = sim.run_scenario(lua, path, "ui_" + script, 3 * 3600)
    errors = list(lua.globals().Sim.errors.values())
    for e in errors:
        print("  ERROR", e)
    device = to_py(lua.globals().Sim.devices[device_name])
    files = []
    for name, dump, viewport, inset, controls in shots:
        dev = dict(device)
        dev["touch"] = dev.get("touch") and controls
        files.append(render(name, device_name, dev, dump, viewport, inset, out_dir))
    return ok and not errors, files


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    available = sorted(f[:-4] for f in os.listdir(UI_DIR) if f.endswith(".lua"))
    if "list" in opts or not args:
        print("ui scripts:", ", ".join(available))
        return 0
    devices = (opts.get("devices") or "phone,tablet,desktop").split(",")
    out_dir = opts.get("out") or os.path.join(sim.ROOT, "build", "ui")
    os.makedirs(out_dir, exist_ok=True)
    failed = 0
    for script in args:
        if script not in available:
            print(f"unknown ui script {script} (available: {', '.join(available)})")
            return 2
        for dev in devices:
            ok, files = run(script, dev, out_dir, "verbose" in opts)
            failed += 0 if ok else 1
            for f in files:
                print(("  " if ok else "  (errors) ") + f)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
