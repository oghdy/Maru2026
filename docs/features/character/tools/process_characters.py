#!/usr/bin/env python3
"""MARU character asset post-processor (CHR-1.6.1.6, char-asset).

raw/<kind>_<mood>.png (ChatGPT output)  ->  frontend/maru/assets/characters/<kind>_<mood>.png

Pipeline (per kind, only files that exist are processed; safe to re-run):
  1. Background removal when the image has no real transparency
     (4-corner/border flood fill over the border's dominant colours - also catches a
     painted "fake transparency" checkerboard), 1px rim erosion + soft alpha so no
     white halo remains, detached specks dropped.
  2. Every expression is normalised into the idle image's frame:
       - baseline (feet bottom) and feet centre are always aligned to idle (translation only),
       - scale is corrected only when the character size (sqrt of silhouette area) differs
         from idle by more than --tol (3%). Deviations > tol are reported.
     Then ONE crop/scale is applied to the whole kind: idle height = ~80% of the canvas,
     feet baseline 6% above the canvas bottom, feet centre on the canvas centre line.
     If some expression (cheer with arms up...) would be clipped, the kind-wide scale is
     reduced for all 7 images (reported).
  3. blink is aligned to idle by a +-20px silhouette search (after area-based scale check).
     If the silhouettes match and the pixel difference is confined to a small face region,
     blink = idle with only that eye patch taken from blink (guarantees zero body jitter).
     Otherwise it is reported as "REGENERATE" and NOT written to assets (the widget
     simply skips blinking - CHARACTER_API asset fallback) unless --force-blink.
  4. 512x512 PNG. Kept as full RGBA if <= --max-kb, otherwise 256-colour quantised
     if the edge (alpha) error stays small; if quantisation would visibly damage the
     outline the full-quality file is kept and the size overrun is reported.
  5. Contact sheet (2 rows x 7) on a checkerboard with the baseline in red, file name,
     size and notes per cell, and an idle/blink difference inset.

Only Pillow + numpy.  Usage:
  python3 process_characters.py                       # default paths (below)
  python3 process_characters.py --raw DIR --out DIR --sheet PNG [--kinds rabbit]
"""
from __future__ import annotations

import argparse
import io
import json
import os
import sys
from dataclasses import dataclass, field

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
CHAR_DOCS = os.path.dirname(HERE)  # .../docs/features/character
DEFAULT_RAW = os.path.join(CHAR_DOCS, "raw")
DEFAULT_OUT = "/Users/hadohadopapi/Desktop/Maru-wt/character/frontend/maru/assets/characters"
DEFAULT_SHEET = os.path.join(CHAR_DOCS, "screenshots", "asset_contact_sheet.png")
DEFAULT_REPORT = os.path.join(HERE, "last_report.json")

KINDS = ["rabbit", "turtle"]
MOODS = ["idle", "blink", "happy", "sad", "thinking", "talking", "cheer", "magic"]  # sheet column order
# moods holding a prop/effect (wand + sparkles): scale locked to idle (area would be fooled by the prop),
# detached sparkles kept, and they never shrink the kind-wide scale (clipping is reported instead)
PROP_MOODS = {"magic"}
# lab outfit (CHR-1.8.2): <kind>_lab_<mood>.png, own contact-sheet row. Treated like prop moods
# (flask foam / clipboard / goggles must not drive the scale) - head size checked against idle by hand
LAB_MOODS = ["lab_idle", "lab_happy", "lab_thinking"]
PROP_MOODS |= set(LAB_MOODS)
ALL_MOODS = MOODS + LAB_MOODS

CANVAS = 512
BASELINE_FRAC = 0.06   # feet baseline this far above the canvas bottom
HEIGHT_FRAC = 0.80     # idle character height / canvas
TOP_MARGIN = 6         # px kept free above the tallest expression
SIDE_MARGIN = 6


# --------------------------------------------------------------------------------------
# small numpy helpers
# --------------------------------------------------------------------------------------
def _shift(a: np.ndarray, dy: int, dx: int, fill=0) -> np.ndarray:
    """out[y, x] = a[y - dy, x - dx] (content moves by +dy, +dx)."""
    h, w = a.shape[:2]
    out = np.full_like(a, fill)
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    out[yd, xd] = a[ys, xs]
    return out


def _erode(m: np.ndarray, r: int = 1) -> np.ndarray:
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dy or dx:
                out &= _shift(m, dy, dx, fill=False)
    return out


def _dilate(m: np.ndarray, r: int = 1) -> np.ndarray:
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dy or dx:
                out |= _shift(m, dy, dx, fill=False)
    return out


def _blur121(a: np.ndarray) -> np.ndarray:
    """Separable [1,2,1]/4 blur with edge replication (float)."""
    a = a.astype(np.float32)
    p = np.pad(a, [(1, 1), (0, 0)] + [(0, 0)] * (a.ndim - 2), mode="edge")
    a = (p[:-2] + 2 * p[1:-1] + p[2:]) / 4
    p = np.pad(a, [(0, 0), (1, 1)] + [(0, 0)] * (a.ndim - 2), mode="edge")
    return (p[:, :-2] + 2 * p[:, 1:-1] + p[:, 2:]) / 4


def _propagate(seed: np.ndarray, cand: np.ndarray) -> np.ndarray:
    """4-connected flood fill of `cand` starting from `seed` (scanline run propagation)."""
    reached = seed & cand

    def rows(r: np.ndarray, c: np.ndarray) -> np.ndarray:
        h, w = c.shape
        prev = np.zeros_like(c)
        prev[:, 1:] = c[:, :-1]
        starts = c & ~prev
        ids = np.cumsum(starts.ravel()) * c.ravel()
        hit = np.bincount(ids[r.ravel()], minlength=int(ids.max()) + 1) > 0
        hit[0] = False
        return hit[ids].reshape(h, w)

    while True:
        new = rows(reached, cand)
        new = rows(new.T.copy(), cand.T.copy()).T
        if new.sum() == reached.sum():
            return new
        reached = new


def _robust_bbox(alpha: np.ndarray, thr: int = 128, min_px: int = 3):
    """(x0, y0, x1, y1) exclusive, ignoring rows/cols with fewer than min_px solid pixels."""
    m = alpha >= thr
    rows = np.where(m.sum(1) >= min_px)[0]
    cols = np.where(m.sum(0) >= min_px)[0]
    if len(rows) == 0 or len(cols) == 0:
        return None
    return int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1


# --------------------------------------------------------------------------------------
# 1. background removal
# --------------------------------------------------------------------------------------
def _border_colors(rgb: np.ndarray, ring: int = 4, max_colors: int = 4):
    h, w, _ = rgb.shape
    b = np.concatenate([rgb[:ring].reshape(-1, 3), rgb[-ring:].reshape(-1, 3),
                        rgb[:, :ring].reshape(-1, 3), rgb[:, -ring:].reshape(-1, 3)]).astype(np.int32)
    q = (b // 16)
    keys = q[:, 0] * 256 + q[:, 1] * 16 + q[:, 2]
    uniq, inv, cnt = np.unique(keys, return_inverse=True, return_counts=True)
    order = np.argsort(-cnt)
    colors, covered = [], 0
    for k in order[:max_colors]:
        if cnt[k] < 0.03 * len(b):
            break
        colors.append(np.median(b[inv == k], axis=0))
        covered += cnt[k]
    return np.array(colors), covered / len(b)


def remove_background(img: Image.Image, tol: int, notes: list, keep_detached: bool = False) -> Image.Image:
    rgba = np.array(img.convert("RGBA"))
    a = rgba[..., 3]
    h, w = a.shape
    border = np.concatenate([a[:4].ravel(), a[-4:].ravel(), a[:, :4].ravel(), a[:, -4:].ravel()])
    if (border < 16).mean() > 0.9:
        # real transparency already: just kill near-invisible dust
        rgba[..., 3] = np.where(a < 8, 0, np.where(a >= 250, 255, a))  # ChatGPT writes 254 as "opaque"
        notes.append("alpha: provided")
        if keep_detached:
            notes.append("detached parts kept (prop/sparkles)")
            return Image.fromarray(rgba)
        return _drop_specks(Image.fromarray(rgba), notes)

    rgb = rgba[..., :3].astype(np.int32)
    colors, coverage = _border_colors(rgb)
    if coverage < 0.85:
        notes.append(f"WARN border not uniform ({coverage:.0%}) - bg removal may be incomplete")
    dist = np.min(np.stack([np.abs(rgb - c).max(-1) for c in colors]), axis=0)
    cand = dist <= tol
    seed = np.zeros((h, w), bool)
    seed[0, :] = seed[-1, :] = seed[:, 0] = seed[:, -1] = True
    bg = _propagate(seed, cand)
    fg = ~bg
    if fg.mean() < 0.02:
        notes.append("ERROR bg removal ate the character - REGENERATE with a plain background")
        return img.convert("RGBA")

    core = _erode(fg, 1)                   # drop the 1px rim blended with the background
    alpha = _blur121(core.astype(np.float32))
    alpha = np.where(core, 1.0, alpha)     # soft only on the outside of the rim
    # colour for the new semi-transparent outside pixels: pull from interior (no bg halo)
    col = rgb.astype(np.float32)
    wgt = core.astype(np.float32)
    for _ in range(2):
        s = _blur121(col * wgt[..., None])
        n = _blur121(wgt)
        fill = s / np.maximum(n, 1e-6)[..., None]
        col = np.where(wgt[..., None] > 0, col, fill)
        wgt = np.maximum(wgt, (n > 0).astype(np.float32))
    out = np.dstack([np.clip(col, 0, 255), alpha * 255]).round().astype(np.uint8)
    out[alpha <= 0] = 0
    notes.append(f"bg removed ({len(colors)} border colour(s))")
    if keep_detached:
        return Image.fromarray(out, "RGBA")
    return _drop_specks(Image.fromarray(out, "RGBA"), notes)


def _drop_specks(img: Image.Image, notes: list) -> Image.Image:
    arr = np.array(img)
    fg = arr[..., 3] >= 32
    if not fg.any():
        return img
    ys, xs = np.nonzero(fg)
    cy, cx = ys.mean(), xs.mean()
    k = np.argmin((ys - cy) ** 2 + (xs - cx) ** 2)
    seed = np.zeros_like(fg)
    seed[ys[k], xs[k]] = True
    keep = _propagate(seed, fg)
    main = keep.sum()
    rest = fg & ~keep
    dropped_px, dropped_n = 0, 0
    for _ in range(200):
        if not rest.any():
            break
        ys, xs = np.nonzero(rest)
        seed = np.zeros_like(fg)
        seed[ys[0], xs[0]] = True
        comp = _propagate(seed, rest)
        rest &= ~comp
        if comp.sum() >= 0.01 * main:
            keep |= comp
        else:
            dropped_px += int(comp.sum()); dropped_n += 1
    if rest.any():
        dropped_px += int(rest.sum()); dropped_n += 1
    if dropped_n:
        # also clear faint pixels hugging the dropped specks
        keep_zone = _dilate(keep, 2)
        arr[~keep_zone] = 0
        notes.append(f"dropped {dropped_n} detached speck(s), {dropped_px}px")
    return Image.fromarray(arr, "RGBA")


# --------------------------------------------------------------------------------------
# 2. measurements
# --------------------------------------------------------------------------------------
@dataclass
class Item:
    kind: str
    mood: str
    path: str
    img: Image.Image = None          # bg-removed RGBA, raw resolution
    notes: list = field(default_factory=list)
    area: float = 0.0
    baseline: float = 0.0            # bottom edge of the feet (raw px)
    feet_cx: float = 0.0
    bbox: tuple = None
    rel_scale: float = 1.0           # extra scale to match idle size
    final_scale: float = 1.0
    out_bytes: int = 0
    written: bool = False
    canvas: Image.Image = None
    flags: list = field(default_factory=list)  # 'SIZE', 'BASELINE', 'REGENERATE', 'KB'


def measure(it: Item):
    a = np.array(it.img)[..., 3]
    it.area = float((a.astype(np.float32) / 255).sum())
    it.bbox = _robust_bbox(a)
    if it.bbox is None:
        return
    x0, y0, x1, y1 = it.bbox
    it.baseline = float(y1)
    band = max(3, int(round((y1 - y0) * 0.06)))
    feet = a[y1 - band:y1] >= 128
    cols = np.where(feet.any(0))[0]
    it.feet_cx = (cols[0] + cols[-1] + 1) / 2 if len(cols) else (x0 + x1) / 2


# --------------------------------------------------------------------------------------
# 3. blink alignment
# --------------------------------------------------------------------------------------
def _xor_count(ref: np.ndarray, mov: np.ndarray, dy: int, dx: int) -> int:
    return int((ref ^ _shift(mov, dy, dx, fill=False)).sum())


def align_blink(idle: Item, blink: Item, max_shift: int = 20):
    """Return (scale, dy, dx, report) mapping blink onto idle in idle raw coordinates."""
    rep = {}
    s = float(np.sqrt(idle.area / max(blink.area, 1)))
    rep["area_scale"] = round(s, 4)
    img = blink.img
    if abs(s - 1) > 0.01:
        w, h = img.size
        img = img.convert("RGBa").resize((round(w * s), round(h * s)), Image.LANCZOS).convert("RGBA")
    # put on idle-sized canvas (top-left anchored; the shift search takes care of offset)
    W, H = idle.img.size
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # pre-align by bbox centre / baseline so the +-20px search is about residual error
    b = _robust_bbox(np.array(img)[..., 3])
    ib = idle.bbox
    pre_dx = round((ib[0] + ib[2]) / 2 - (b[0] + b[2]) / 2)
    pre_dy = round(ib[3] - b[3])
    canvas.paste(img, (pre_dx, pre_dy))
    mov_full = np.array(canvas)
    ref_m = np.array(idle.img)[..., 3] >= 128
    mov_m = mov_full[..., 3] >= 128

    # coarse search at 1/4 resolution, then fine at full resolution
    f = 4
    hh, ww = (H // f) * f, (W // f) * f
    rc = ref_m[:hh, :ww].reshape(hh // f, f, ww // f, f).mean((1, 3)) > 0.5
    mc = mov_m[:hh, :ww].reshape(hh // f, f, ww // f, f).mean((1, 3)) > 0.5
    r = max_shift // f
    best = min(((_xor_count(rc, mc, dy, dx), dy, dx) for dy in range(-r, r + 1) for dx in range(-r, r + 1)))
    _, cy, cx = best
    best = min(((_xor_count(ref_m, mov_m, dy, dx), dy, dx)
                for dy in range(cy * f - f, cy * f + f + 1) for dx in range(cx * f - f, cx * f + f + 1)))
    xor, dy, dx = best
    aligned = _shift(mov_full, dy, dx, fill=0)
    rep["shift_px"] = [pre_dx + dx, pre_dy + dy]

    ref = np.array(idle.img)
    both = (ref[..., 3] >= 128) & (aligned[..., 3] >= 128)
    col_diff = (np.abs(ref[..., :3].astype(int) - aligned[..., :3].astype(int)).max(-1) > 48) & both
    sil_diff = ref_m ^ (aligned[..., 3] >= 128)
    diff = _erode(col_diff | sil_diff, 1)          # ignore 1px anti-alias noise
    x0, y0, x1, y1 = idle.bbox
    ch, cw = y1 - y0, x1 - x0
    rep["silhouette_diff_pct"] = round(100 * sil_diff.sum() / max(ref_m.sum(), 1), 2)
    rep["pixel_diff_pct"] = round(100 * diff.sum() / max(ref_m.sum(), 1), 2)
    db = _robust_bbox(diff.astype(np.uint8) * 255, min_px=2)
    ok = rep["silhouette_diff_pct"] <= 2.0 and diff.any()
    if db is not None:
        rep["diff_box_rel"] = [round((db[2] - db[0]) / cw, 3), round((db[3] - db[1]) / ch, 3)]
        # eyes only: the changed area must be a small face band
        ok = ok and (db[2] - db[0]) <= 0.65 * cw and (db[3] - db[1]) <= 0.30 * ch
    else:
        rep["diff_box_rel"] = None
        rep["note"] = "no visible difference - eyes not closed?"
        ok = False
    rep["ok"] = bool(ok)
    return aligned, diff, db, rep


def patch_blink(idle_raw: np.ndarray, aligned: np.ndarray, db) -> np.ndarray:
    """idle with the eye box (padded, feathered) copied from the aligned blink."""
    h, w = idle_raw.shape[:2]
    pad = 8
    m = np.zeros((h, w), np.float32)
    m[max(0, db[1] - pad):db[3] + pad, max(0, db[0] - pad):db[2] + pad] = 1
    for _ in range(3):
        m = _blur121(m)
    m = m * ((idle_raw[..., 3] >= 128) & (aligned[..., 3] >= 128))  # never change the silhouette
    out = idle_raw.astype(np.float32)
    out[..., :3] = out[..., :3] * (1 - m[..., None]) + aligned[..., :3] * m[..., None]
    return out.round().astype(np.uint8)


def local_eye_patch(idle_raw: np.ndarray, aligned: np.ndarray, max_shift: int = 20, feather: int = 5):
    """Fallback when ChatGPT redrew the whole body: find the eyes, align blink locally on the
    face ring around them, and feather only the eye patches onto idle.

    Eyes = solid (4px-eroded) colour-difference blobs: open iris vs closed-lid skin is a filled
    area, while redraw drift of the outline is only thin lines and erodes away.
    Returns (patched or None, report, eye_box).
    """
    rep = {"method": "local eye patch"}
    ref = idle_raw.astype(np.int32)
    mov = aligned.astype(np.int32)
    solid_both = (ref[..., 3] > 200) & (mov[..., 3] > 200)
    d = (np.abs(ref[..., :3] - mov[..., :3]).max(-1) > 60) & solid_both
    solid = _erode(d, 4)
    # blobs (merged when close, one eye can split into iris/white parts) -> two largest that
    # sit side by side = eyes
    merged = _dilate(solid, 12)
    comps, rest = [], merged.copy()
    for _ in range(40):
        if not rest.any():
            break
        ys, xs = np.nonzero(rest)
        seed = np.zeros_like(rest)
        seed[ys[0], xs[0]] = True
        c = _propagate(seed, rest)
        rest &= ~c
        if (c & solid).any():
            comps.append(c & solid)
    comps.sort(key=lambda c: -c.sum())
    boxes = []
    for c in comps:
        b = _robust_bbox(c.astype(np.uint8) * 255, min_px=1)
        if not boxes:
            boxes.append(b)
        elif c.sum() >= 0.3 * comps[0].sum() and (b[2] <= boxes[0][0] or b[0] >= boxes[0][2]):
            boxes.append(b)
            break
    if len(boxes) < 2:
        rep["error"] = f"could not find two side-by-side eyes ({len(comps)} blobs)"
        return None, rep, None
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    ew = max(b[2] - b[0] for b in boxes); eh = max(b[3] - b[1] for b in boxes)
    rep["eye_boxes"] = boxes

    # search area: each eye box padded by ~40% of the eye size (covers lashes / lid lines)
    h, w = solid.shape
    px, py = int(0.4 * ew) + 4, int(0.4 * eh) + 4
    hard = np.zeros((h, w), bool)
    for b in boxes:
        hard[max(0, b[1] - py):b[3] + py, max(0, b[0] - px):b[2] + px] = True

    # local alignment on the face ring around the patches (outline / glasses / brows)
    m = 40
    ry0, ry1 = max(0, y0 - py - m), min(h, y1 + py + m)
    rx0, rx1 = max(0, x0 - px - m), min(w, x1 + px + m)
    ring = ~_dilate(hard, 6)[ry0:ry1, rx0:rx1]
    g_ref = ref[ry0:ry1, rx0:rx1, :3].mean(-1)
    best = None
    for dy in range(-max_shift, max_shift + 1):
        for dx in range(-max_shift, max_shift + 1):
            ys0, xs0 = ry0 - dy, rx0 - dx
            if ys0 < 0 or xs0 < 0 or ys0 + (ry1 - ry0) > h or xs0 + (rx1 - rx0) > w:
                continue
            g_mov = mov[ys0:ys0 + ry1 - ry0, xs0:xs0 + rx1 - rx0, :3].mean(-1)
            err = float(np.abs(g_ref - g_mov)[ring].mean())
            if best is None or err < best[0]:
                best = (err, dy, dx)
    err0 = float(np.abs(g_ref - mov[ry0:ry1, rx0:rx1, :3].mean(-1))[ring].mean())
    _, dy, dx = best
    shifted = _shift(aligned, dy, dx, fill=0)
    rep["local_shift_px"] = [dx, dy]
    rep["ring_err_before"] = round(err0, 1)
    rep["ring_err_after"] = round(best[0], 1)

    # patch = what actually changed inside the eye boxes (after local alignment), dilated 3px,
    # so the feather lands where idle and blink already agree (skin / lens / frame)
    sm = shifted.astype(np.int32)
    changed = (np.abs(ref[..., :3] - sm[..., :3]).max(-1) > 40) & hard
    patch = _dilate(changed, 3) & hard
    rep["patch_px"] = int(patch.sum())
    # feathered composite (never changes the silhouette)
    soft = patch.astype(np.float32)
    for _ in range(feather):
        soft = _blur121(soft)
    soft *= (idle_raw[..., 3] >= 128) & (shifted[..., 3] >= 128)
    out = idle_raw.astype(np.float32)
    out[..., :3] = out[..., :3] * (1 - soft[..., None]) + shifted[..., :3] * soft[..., None]
    patched = out.round().astype(np.uint8)

    # seam check: dark (outline) pixels in the feather band must agree between idle and blink
    band = (soft > 0.05) & (soft < 0.95)
    s_ref = ref[..., :3].mean(-1)
    s_mov = shifted[..., :3].astype(np.int32).mean(-1)
    dark = band & ((s_ref < 110) | (s_mov < 110))
    # share of outline pixels in the feather band where the two lines do not coincide (= visible kink)
    seam = float(100 * (np.abs(s_ref - s_mov)[dark] > 60).mean()) if dark.any() else 0.0
    rep["seam_outline_err"] = round(seam, 1)
    rep["seam_dark_px"] = int(dark.sum())
    at_edge = max(abs(dx), abs(dy)) >= max_shift          # true offset is outside the search window
    if at_edge:
        rep["error"] = f"local shift hit the +-{max_shift}px limit (head moved/tilted too much)"
    rep["ok"] = bool(seam <= 15 and best[0] <= 16 and not at_edge)  # seam = % of band outline px that disagree
    pad = 12
    return patched, rep, (max(0, x0 - px - pad), max(0, y0 - py - pad), min(w, x1 + px + pad), min(h, y1 + py + pad))


# --------------------------------------------------------------------------------------
# 4. render + encode
# --------------------------------------------------------------------------------------
def render(img: Image.Image, scale: float, feet_cx: float, baseline: float) -> Image.Image:
    w, h = img.size
    sw, sh = max(1, round(w * scale)), max(1, round(h * scale))
    small = img.convert("RGBa").resize((sw, sh), Image.LANCZOS)
    kx, ky = sw / w, sh / h
    base_y = CANVAS * (1 - BASELINE_FRAC)
    canvas = Image.new("RGBa", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(small, (round(CANVAS / 2 - feet_cx * kx), round(base_y - baseline * ky)))
    return canvas.convert("RGBA")


def encode(img: Image.Image, max_kb: int, notes: list):
    buf = io.BytesIO()
    img.save(buf, "PNG", optimize=True)
    full = buf.getvalue()
    if len(full) <= max_kb * 1024:
        notes.append("png rgba")
        return full, False
    q = img.quantize(256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    back = np.array(q.convert("RGBA")).astype(int)
    ref = np.array(img).astype(int)
    edge = (ref[..., 3] > 0) & (ref[..., 3] < 255)
    a_err = float(np.abs(back[..., 3] - ref[..., 3])[edge].mean()) if edge.any() else 0.0
    solid = ref[..., 3] == 255
    c_err = float(np.abs(back[..., :3] - ref[..., :3])[solid].mean()) if solid.any() else 0.0
    buf = io.BytesIO()
    q.save(buf, "PNG", optimize=True)
    qb = buf.getvalue()
    if a_err <= 6 and c_err <= 4:
        notes.append(f"quantised 256c (edge err {a_err:.1f}, colour err {c_err:.1f})")
        return qb, len(qb) > max_kb * 1024
    notes.append(f"kept full RGBA: quantising hurt outline (edge err {a_err:.1f}, colour err {c_err:.1f})")
    return full, True


def encode_like(img: Image.Image, base_png: bytes, base_canvas: Image.Image, notes: list):
    """Encode `img` with the palette and pixel indices of an already-encoded paletted PNG
    (idle), re-mapping only pixels that really differ. Keeps blink bit-identical to idle
    outside the eyes so swapping frames cannot shimmer. Returns bytes or None."""
    base = Image.open(io.BytesIO(base_png))
    if base.mode != "P":
        return None
    rgb = np.array(base.getpalette("RGB")).reshape(-1, 3)
    trns = base.info.get("transparency", b"")
    alpha = np.full(len(rgb), 255)
    if isinstance(trns, bytes):
        alpha[:len(trns)] = np.frombuffer(trns, np.uint8)
    elif isinstance(trns, int):
        alpha[trns] = 0
    pal = np.column_stack([rgb, alpha]).astype(np.int32)
    idx = np.array(base).copy()
    cur = np.array(img).astype(np.int32)
    base_arr = np.array(base_canvas).astype(np.int32)
    # silhouette / edge pixels always stay idle's (only opaque interior may change)
    changed = (np.abs(cur - base_arr).max(-1) > 2) & (base_arr[..., 3] >= 250)
    px = cur[changed]
    near = np.empty(len(px), np.int64)
    for i in range(0, len(px), 4096):
        chunk = px[i:i + 4096]
        dd = chunk[:, None, :] - pal[None, :, :]
        near[i:i + 4096] = np.argmin((dd[..., :3] ** 2).sum(-1) + 100 * dd[..., 3] ** 2, axis=1)
    idx[changed] = near.astype(idx.dtype)
    err = float(np.abs(pal[near] - px).mean()) if len(px) else 0.0
    out = Image.fromarray(idx, "P")
    out.putpalette(rgb.astype(np.uint8).ravel().tolist(), "RGB")
    buf = io.BytesIO()
    out.save(buf, "PNG", optimize=True, transparency=bytes(alpha.astype(np.uint8)))
    notes.append(f"idle palette, {int(changed.sum())}px remapped (err {err:.1f})")
    return buf.getvalue()


# --------------------------------------------------------------------------------------
# main per-kind pipeline
# --------------------------------------------------------------------------------------
def process_kind(kind: str, args) -> dict:
    items = {}
    for mood in ALL_MOODS:
        p = os.path.join(args.raw, f"{kind}_{mood}.png")
        if os.path.isfile(p):
            it = Item(kind, mood, p)
            it.img = remove_background(Image.open(p), args.bg_tol, it.notes, keep_detached=mood in PROP_MOODS)
            measure(it)
            if it.bbox is None:
                it.flags.append("REGENERATE")
                it.notes.append("empty after bg removal")
                continue
            items[mood] = it
    if not items:
        return {}

    ref = items.get("idle") or next(iter(items.values()))
    if ref.mood != "idle":
        ref.notes.append("WARN no idle - using this as size reference")
    ref_h = ref.bbox[3] - ref.bbox[1]

    # per-image correction into the reference frame
    for it in items.values():
        if it is ref or it.mood == "blink":
            continue
        s = float(np.sqrt(ref.area / it.area))
        if it.mood in PROP_MOODS:
            s = 1.0
            it.notes.append("scale locked to idle (prop mood)")
        d_base = (it.baseline - ref.baseline) / ref_h
        d_cx = (it.feet_cx - ref.feet_cx) / ref_h
        if abs(s - 1) > args.tol:
            it.rel_scale = s
            it.flags.append("SIZE")
            it.notes.append(f"size {1 / s:.2f}x idle -> scaled x{s:.3f}")
        if abs(d_base) > args.tol or abs(d_cx) > args.tol:
            it.flags.append("BASELINE")
            it.notes.append(f"feet moved ({d_cx:+.1%} x, {d_base:+.1%} y) -> aligned")

    blink_rep = None
    blink = items.get("blink")
    if blink is not None and "idle" in items:
        aligned, diff, db, blink_rep = align_blink(ref, blink)
        blink.notes.append(f"blink vs idle: shift {blink_rep['shift_px']}, silhouette diff "
                           f"{blink_rep['silhouette_diff_pct']}%, pixel diff {blink_rep['pixel_diff_pct']}%")
        blink._diff = diff
        if blink_rep["ok"]:
            blink.img = Image.fromarray(patch_blink(np.array(ref.img), aligned, db), "RGBA")
            blink.notes.append("OK - eye patch composited onto idle")
        else:
            patched, lrep, eyebox = local_eye_patch(np.array(ref.img), aligned)
            blink_rep["local"] = lrep
            if patched is not None and lrep["ok"]:
                blink.img = Image.fromarray(patched, "RGBA")
                blink._eyebox = eyebox
                blink.flags.append("LOCAL")
                blink.notes.append(f"whole body redrawn -> local eye patch: shift {lrep['local_shift_px']}, "
                                   f"ring err {lrep['ring_err_after']}, seam {lrep['seam_outline_err']}")
            else:
                blink.img = Image.fromarray(aligned, "RGBA")
                if eyebox is not None:
                    blink._eyebox = eyebox
                blink.flags.append("REGENERATE")
                blink.notes.append("REGENERATE: blink does not overlay idle "
                                   f"({lrep.get('error') or 'seam %s' % lrep.get('seam_outline_err')})")
        blink.area, blink.bbox = ref.area, ref.bbox
        blink.baseline, blink.feet_cx, blink.rel_scale = ref.baseline, ref.feet_cx, 1.0
    elif blink is not None:
        blink.flags.append("REGENERATE")
        blink.notes.append("no idle to align against - skipped")

    # kind-wide scale: idle height -> 80% canvas, then shrink if anything would be clipped
    g = HEIGHT_FRAC * CANVAS / ref_h
    base_y = CANVAS * (1 - BASELINE_FRAC)
    limits = [g]
    for it in items.values():
        if it.mood in PROP_MOODS:
            continue
        s = it.rel_scale
        x0, y0, x1, y1 = it.bbox
        up = (it.baseline - y0) * s             # height above baseline (ref px)
        left = (it.feet_cx - x0) * s
        right = (x1 - it.feet_cx) * s
        limits.append((base_y - TOP_MARGIN) / max(up, 1))
        limits.append((CANVAS / 2 - SIDE_MARGIN) / max(left, right, 1))
    g_final = min(limits)
    kind_note = None
    if g_final < g * 0.999:
        kind_note = (f"kind scale reduced to {g_final / g:.1%} of target so every expression fits "
                     f"(idle height {HEIGHT_FRAC * g_final / g:.1%} of canvas)")

    for it in items.values():
        if it.mood not in PROP_MOODS:
            continue
        s = it.rel_scale * g_final
        x0, y0, x1, y1 = it.bbox
        box = (CANVAS / 2 - (it.feet_cx - x0) * s, base_y - (it.baseline - y0) * s,
               CANVAS / 2 + (x1 - it.feet_cx) * s, base_y)
        it.notes.append("canvas bbox x %.0f-%.0f, top %.0f" % (box[0], box[2], box[1]))
        if box[0] < 0 or box[2] > CANVAS or box[1] < 0:
            it.flags.append("CLIP")
            it.notes.append("CLIPPED by the kind scale - needs margin decision")

    os.makedirs(args.out, exist_ok=True)
    for it in items.values():
        it.final_scale = it.rel_scale * g_final
        it.canvas = render(it.img, it.final_scale, it.feet_cx, it.baseline)
        data = None
        if it.mood == "blink" and "idle" in items and getattr(items["idle"], "_png", None):
            data = encode_like(it.canvas, items["idle"]._png, items["idle"].canvas, it.notes)
            over = data is not None and len(data) > args.max_kb * 1024
        if data is None:
            data, over = encode(it.canvas, args.max_kb, it.notes)
        it._png = data
        it.out_bytes = len(data)
        if over:
            it.flags.append("KB")
            it.notes.append(f"{len(data) / 1024:.0f}KB > {args.max_kb}KB")
        skip = it.mood == "blink" and "REGENERATE" in it.flags and not args.force_blink
        dst = os.path.join(args.out, f"{kind}_{it.mood}.png")
        if skip:
            it.notes.append("not written to assets (widget skips blinking)")
            if os.path.exists(dst) and args.remove_stale:
                os.remove(dst)
        elif not args.dry_run:
            with open(dst, "wb") as fh:
                fh.write(data)
            it.written = True
    return {"items": items, "kind_note": kind_note, "blink": blink_rep}


# --------------------------------------------------------------------------------------
# 5. contact sheet
# --------------------------------------------------------------------------------------
def _font(size: int):
    for p in ("/System/Library/Fonts/Supplemental/Arial.ttf", "/System/Library/Fonts/SFNSMono.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default(size)


def _blink_strip(sheet, d, blinks, oy, W, pad, f, f_small):
    """idle | blink eye region at 3x (output pixels) side by side, per kind."""
    d.line([(pad, oy), (W - pad, oy)], fill=(180, 180, 190))
    d.text((pad, oy + 6), "blink check - eye region at 3x of the 512px asset: idle (left) | blink (right). "
           "Outline outside the eyes must not move.", fill=(40, 30, 90), font=f)
    x = pad
    for kind, idle, blink in blinks:
        x0, y0, x1, y1 = blink._eyebox
        S = blink.final_scale
        base_y = CANVAS * (1 - BASELINE_FRAC)
        box = [round(CANVAS / 2 + (x0 - idle.feet_cx) * S), round(base_y + (y0 - idle.baseline) * S),
               round(CANVAS / 2 + (x1 - idle.feet_cx) * S), round(base_y + (y1 - idle.baseline) * S)]
        cw_, ch_ = box[2] - box[0], box[3] - box[1]
        z = min(3.0, 300 / max(ch_, 1), (W / 2 - 3 * pad) / 2 / max(cw_, 1))
        panels = []
        for it in (idle, blink):
            bg = Image.new("RGBA", it.canvas.size, (255, 255, 255, 255))
            bg.alpha_composite(it.canvas)
            panels.append(bg.crop(box).resize((round(cw_ * z), round(ch_ * z)), Image.NEAREST).convert("RGB"))
        py = oy + 30
        for i, pnl in enumerate(panels):
            sheet.paste(pnl, (x + i * (pnl.width + 6), py))
            d.rectangle([x + i * (pnl.width + 6), py, x + i * (pnl.width + 6) + pnl.width - 1, py + pnl.height - 1],
                        outline=(80, 80, 80))
        status = "REGENERATE" if "REGENERATE" in blink.flags else ("LOCAL patch" if "LOCAL" in blink.flags else "OK")
        d.text((x, py + panels[0].height + 4), f"{kind}: idle | blink  [{status}]  zoom {z:.1f}x",
               fill=(220, 40, 40) if status == "REGENERATE" else (40, 40, 40), font=f_small)
        x += 2 * panels[0].width + 6 + 3 * pad


def contact_sheet(results: dict, path: str, args):
    cell, pad, text_h = 256, 12, 92
    cw, rh = cell + pad, cell + text_h + pad
    blinks = [(kind, (results.get(kind) or {}).get("items", {})) for kind in KINDS]
    blinks = [(kd, its["idle"], its["blink"]) for kd, its in blinks
              if "idle" in its and "blink" in its and getattr(its["blink"], "_eyebox", None)]
    strip_h = 360 if blinks else 0
    lab_cells = [(kind, m) for kind in KINDS for m in LAB_MOODS]
    W, H = pad + cw * max(len(MOODS), len(lab_cells)), 40 + rh * (len(KINDS) + 1) + strip_h
    sheet = Image.new("RGB", (W, H), (250, 250, 252))
    d = ImageDraw.Draw(sheet)
    f_title, f, f_small = _font(20), _font(14), _font(11)
    d.text((pad, 10), "MARU character assets - red: feet baseline (6%), blue: idle top (target 80%)  "
           "| blink inset: magenta = differs from idle", fill=(40, 30, 90), font=f_title)
    checker = Image.new("RGB", (cell, cell))
    cd = ImageDraw.Draw(checker)
    for y in range(0, cell, 16):
        for x in range(0, cell, 16):
            cd.rectangle([x, y, x + 15, y + 15], fill=(236, 236, 236) if (x + y) // 16 % 2 else (206, 206, 206))
    k = cell / CANVAS
    rows = [[(kind, m) for m in MOODS] for kind in KINDS] + [lab_cells]
    for r, row in enumerate(rows):
        oy = 40 + r * rh
        for c, (kind, mood) in enumerate(row):
            res = results.get(kind) or {}
            items = res.get("items", {})
            idle = items.get("idle")
            idle_top = None
            if idle is not None:
                a = np.array(idle.canvas)[..., 3]
                idle_top = _robust_bbox(a)[1]
            ox = pad + c * cw
            name = f"{kind}_{mood}.png"
            it = items.get(mood)
            if it is None:
                d.rectangle([ox, oy, ox + cell - 1, oy + cell - 1], fill=(225, 225, 230), outline=(180, 180, 190))
                d.text((ox + 80, oy + cell / 2 - 10), "missing", fill=(120, 120, 130), font=_font(22))
                d.text((ox, oy + cell + 4), name, fill=(40, 40, 40), font=f)
                fb = ("fallback: no blink" if mood == "blink" else
                      f"fallback: {kind}_lab_idle + motion" if mood.startswith("lab_") else "fallback: idle + motion")
                d.text((ox, oy + cell + 22), fb, fill=(110, 110, 110), font=f_small)
                continue
            tile = checker.copy()
            tile.paste(it.canvas.resize((cell, cell), Image.LANCZOS), (0, 0), it.canvas.resize((cell, cell), Image.LANCZOS))
            td = ImageDraw.Draw(tile)
            by = round(CANVAS * (1 - BASELINE_FRAC) * k)
            td.line([(0, by), (cell, by)], fill=(230, 30, 30), width=2)
            if idle_top is not None:
                td.line([(0, round(idle_top * k)), (cell, round(idle_top * k))], fill=(40, 90, 230), width=1)
            td.line([(cell // 2, by - 6), (cell // 2, by + 6)], fill=(230, 30, 30), width=1)
            if mood == "blink" and idle is not None:
                ia = np.array(idle.canvas).astype(int)
                ba = np.array(it.canvas).astype(int)
                dm = (np.abs(ia - ba).max(-1) > 40)
                ins = np.where(dm[..., None], [230, 0, 200], [255, 255, 255]).astype(np.uint8)
                ghost = (ia[..., 3] > 128)
                ins[ghost & ~dm] = [200, 200, 210]
                inset = Image.fromarray(ins).resize((96, 96), Image.BOX)
                tile.paste(inset, (cell - 98, 2))
                td.rectangle([cell - 99, 1, cell - 2, 98], outline=(80, 80, 80))
            border = (220, 40, 40) if ("REGENERATE" in it.flags) else (60, 60, 60)
            sheet.paste(tile, (ox, oy))
            d.rectangle([ox, oy, ox + cell - 1, oy + cell - 1], outline=border, width=3 if border[0] == 220 else 1)
            flag = (" [" + ",".join(it.flags) + "]") if it.flags else ""
            d.text((ox, oy + cell + 4), f"{name}  {it.out_bytes / 1024:.0f}KB",
                   fill=(40, 40, 40) if it.out_bytes <= args.max_kb * 1024 else (220, 40, 40), font=f)
            y = oy + cell + 22
            lines = [flag.strip()] if flag else []
            lines += [n for n in it.notes if not n.startswith(("png rgba", "alpha: provided"))]
            for line in lines[:5]:
                d.text((ox, y), line[:46], fill=(220, 40, 40) if ("REGEN" in line or "WARN" in line or "ERROR" in line) else (90, 90, 90), font=f_small)
                y += 13
        kind_notes = [f"{k}: {(results.get(k) or {}).get('kind_note')}" for k in dict.fromkeys(k for k, _ in row)
                      if (results.get(k) or {}).get("kind_note")]
        if kind_notes and r < len(KINDS):
            d.text((pad, oy + rh - 16), "  ".join(kind_notes), fill=(200, 110, 0), font=f_small)
    if blinks:
        _blink_strip(sheet, d, blinks, 40 + rh * (len(KINDS) + 1), W, pad, f, f_small)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    sheet.save(path, optimize=True)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--raw", default=DEFAULT_RAW)
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--sheet", default=DEFAULT_SHEET)
    ap.add_argument("--report", default=DEFAULT_REPORT)
    ap.add_argument("--kinds", nargs="*", default=KINDS)
    ap.add_argument("--tol", type=float, default=0.03, help="size/baseline deviation that triggers a fix (3%%)")
    ap.add_argument("--bg-tol", type=int, default=28, help="max channel distance counted as background")
    ap.add_argument("--max-kb", type=int, default=150)
    ap.add_argument("--force-blink", action="store_true", help="write blink even if it fails the overlay check")
    ap.add_argument("--remove-stale", action="store_true", help="delete an old blink in --out when it now fails")
    ap.add_argument("--dry-run", action="store_true", help="do not write assets (sheet + report only)")
    args = ap.parse_args(argv)

    results, report = {}, {}
    for kind in args.kinds:
        res = process_kind(kind, args)
        results[kind] = res
        if not res:
            print(f"[{kind}] no raw files")
            continue
        print(f"[{kind}]" + (f"  NOTE {res['kind_note']}" if res.get("kind_note") else ""))
        for mood in ALL_MOODS:
            it = res["items"].get(mood)
            if it is None:
                print(f"  {kind}_{mood:<9} missing")
                continue
            print(f"  {kind}_{mood:<9} {it.out_bytes / 1024:5.0f}KB  {'written' if it.written else 'NOT written':11} "
                  f"{' '.join(it.flags) or 'ok':12} | " + "; ".join(it.notes))
            report[f"{kind}_{mood}"] = {"kb": round(it.out_bytes / 1024, 1), "written": it.written,
                                        "flags": it.flags, "notes": it.notes}
        if res.get("blink"):
            report[f"{kind}_blink_check"] = res["blink"]
    contact_sheet(results, args.sheet, args)
    print(f"contact sheet: {args.sheet}")
    with open(args.report, "w") as fh:
        json.dump(report, fh, indent=1, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())
