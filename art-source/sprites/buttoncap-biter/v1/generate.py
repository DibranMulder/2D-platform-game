#!/usr/bin/env python3
"""Procedural sprite sheet renderer for the Buttoncap Biter enemy.

Renders an 8-pose runtime atlas of 448x512 cells (4 cols x 2 rows -> 1792x1024)
matching the human_m03 pipeline conventions. Each cell is drawn supersampled and
downscaled for smooth, cartoon-clean edges.
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SS = 3                       # supersample factor
CW, CH = 448, 512            # runtime cell size
W, H = CW * SS, CH * SS
COLS, ROWS = 4, 2

# ---- palette (from the concept art) -------------------------------------
BODY_HI   = (183, 152, 210)
BODY_MID  = (138, 111, 166)
BODY_SH   = (95, 77, 120)
BODY_LINE = (58, 46, 78)

CAP_HI    = (233, 200, 140)
CAP_MID   = (201, 154, 94)
CAP_SH    = (166, 118, 66)
CAP_LINE  = (92, 62, 34)
SPOT      = (240, 228, 196)
GILL      = (214, 194, 162)

EYE_WHITE = (247, 240, 222)
IRIS      = (232, 145, 47)
IRIS_SH   = (196, 108, 28)
PUPIL     = (40, 26, 22)

TEETH     = (250, 245, 233)
MOUTH_IN  = (86, 34, 51)
TONGUE    = (181, 85, 106)

SPRING_HI = (170, 152, 190)
SPRING_MID= (126, 108, 150)
SPRING_SH = (86, 70, 108)
CLAW      = (232, 220, 194)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def shaded_ellipse(d, cx, cy, rx, ry, base, hi, sh, light=(-0.4, -0.55), outline=None, ow=0):
    """Draw a soft, top-lit ellipse by stacking scaled ellipses base->hi."""
    steps = 22
    lx, ly = light
    for i in range(steps):
        t = i / (steps - 1)
        # shrink toward the light source to fake a highlight blob
        srx = rx * (1 - t * 0.9)
        sry = ry * (1 - t * 0.9)
        ox = lx * rx * 0.5 * t
        oy = ly * ry * 0.5 * t
        col = lerp(base, hi, t)
        d.ellipse([cx + ox - srx, cy + oy - sry, cx + ox + srx, cy + oy + sry], fill=col)
    # bottom shading
    for i in range(10):
        t = i / 9
        sry = ry * (0.55 - t * 0.5)
        srx = rx * (0.95 - t * 0.6)
        oy = ry * (0.42 + t * 0.35)
        col = lerp(base, sh, t * 0.9)
        d.ellipse([cx - srx, cy + oy - sry, cx + srx, cy + oy + sry], fill=col)
    if outline:
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=outline, width=ow)


def draw_spring(d, foot_x, foot_y, top_x, top_y, width, coils, line_col, hi, mid, sh):
    """A coiled spring drawn as stacked thin ellipses from foot up to body."""
    n = max(2, coils)
    for i in range(n + 1):
        t = i / n
        cx = foot_x + (top_x - foot_x) * t
        cy = foot_y + (top_y - foot_y) * t
        rx = width * (0.6 + 0.4 * (1 - t))
        ry = width * 0.34
        col = lerp(mid, hi, 0.5)
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=line_col, width=int(9 * SS / 3))
        # front shading arc
        d.arc([cx - rx, cy - ry, cx + rx, cy + ry], 10, 170, fill=sh, width=int(6 * SS / 3))
        d.arc([cx - rx, cy - ry, cx + rx, cy + ry], 190, 350, fill=hi, width=int(5 * SS / 3))


def draw_foot(d, fx, fy, w, flip=1):
    # rounded clawed foot
    shaded_ellipse(d, fx, fy, w, w * 0.62, BODY_MID, BODY_HI, BODY_SH)
    d.ellipse([fx - w, fy - w * 0.62, fx + w, fy + w * 0.62], outline=BODY_LINE, width=int(8 * SS / 3))
    for k in (-1, 0, 1):
        cxx = fx + k * w * 0.5
        d.polygon([(cxx - w * 0.16, fy + w * 0.3), (cxx + w * 0.16, fy + w * 0.3),
                   (cxx, fy + w * 0.72)], fill=CLAW, outline=CAP_LINE)


def draw_creature(pose):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    p = pose
    cx = W * 0.5 + p.get("dx", 0) * SS
    # body geometry
    body_ry = 118 * SS * p.get("sy", 1.0)
    body_rx = 118 * SS * p.get("sx", 1.0)
    body_cy = H * 0.52 + p.get("body_dy", 0) * SS
    tilt = p.get("tilt", 0)

    # ---- shadow on ground -------------------------------------------------
    if p.get("shadow", True):
        sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        gy = H - 34 * SS
        sw = body_rx * (1.05 + p.get("shadow_grow", 0))
        sd.ellipse([cx - sw, gy - 20 * SS, cx + sw, gy + 20 * SS], fill=(30, 20, 40, 90))
        sh = sh.filter(ImageFilter.GaussianBlur(6 * SS))
        img.alpha_composite(sh)

    # ---- spring leg -------------------------------------------------------
    foot_y = H - 46 * SS
    body_bottom = body_cy + body_ry * 0.72
    spring_top = body_bottom
    coils = p.get("coils", 4)
    spring_w = 42 * SS
    if p.get("spring", True):
        draw_foot(d, cx, foot_y, 30 * SS)
        draw_spring(d, cx, foot_y - 8 * SS, cx, spring_top, spring_w, coils,
                    SPRING_SH, SPRING_HI, SPRING_MID, SPRING_SH)

    # ---- body -------------------------------------------------------------
    shaded_ellipse(d, cx, body_cy, body_rx, body_ry, BODY_MID, BODY_HI, BODY_SH,
                   outline=BODY_LINE, ow=int(9 * SS / 3))

    # little arms
    arm_a = p.get("arm", 0.0)
    for side in (-1, 1):
        ax = cx + side * body_rx * 0.92
        ay = body_cy + 10 * SS - abs(arm_a) * 40 * SS
        aw = 30 * SS
        shaded_ellipse(d, ax, ay, aw, aw * 1.25, BODY_MID, BODY_HI, BODY_SH)
        d.ellipse([ax - aw, ay - aw * 1.25, ax + aw, ay + aw * 1.25], outline=BODY_LINE, width=int(7 * SS / 3))

    # ---- mushroom cap -----------------------------------------------------
    # sits like a domed hat on top of the head, rim just above the eyes
    cap_cy = body_cy - body_ry * 0.62
    cap_rx = body_rx * 1.28
    cap_ry = body_ry * 1.02
    rim_y = cap_cy                      # underside of the dome
    # gill band tucked just under the rim (mostly hidden behind the head)
    gill_h = cap_ry * 0.13
    d.chord([cx - cap_rx * 0.9, rim_y - gill_h, cx + cap_rx * 0.9, rim_y + gill_h * 2.0],
            0, 180, fill=GILL)
    for i in range(-5, 6):
        gx = cx + i * cap_rx * 0.15
        d.line([(cx, rim_y + gill_h * 0.35), (gx, rim_y + gill_h * 1.25)], fill=CAP_SH, width=max(1, int(2 * SS / 3)))
    # dome (upper half ellipse)
    dome = [cx - cap_rx, cap_cy - cap_ry, cx + cap_rx, cap_cy + cap_ry]
    d.pieslice(dome, 180, 360, fill=CAP_MID)
    # dome shading toward top-left light
    for i in range(18):
        t = i / 17
        rrx = cap_rx * (1 - t * 0.82)
        rry = cap_ry * (1 - t * 0.82)
        ox = -cap_rx * 0.24 * t
        oy = -cap_ry * 0.34 * t
        col = lerp(CAP_MID, CAP_HI, t)
        d.pieslice([cx + ox - rrx, cap_cy + oy - rry, cx + ox + rrx, cap_cy + oy + rry], 180, 360, fill=col)
    # spots (kept small & separated so they don't merge into a cloud)
    spots = [(-0.5, -0.4, 0.14), (0.02, -0.62, 0.16), (0.46, -0.42, 0.13),
             (-0.66, -0.12, 0.1), (0.28, -0.15, 0.11), (0.66, -0.1, 0.09),
             (-0.28, -0.2, 0.09)]
    for sxr, syr, sr in spots:
        sxp = cx + sxr * cap_rx
        syp = cap_cy + syr * cap_ry
        rr = sr * cap_rx
        d.ellipse([sxp - rr, syp - rr * 0.85, sxp + rr, syp + rr * 0.85], fill=SPOT)
    # cap outline (curved dome + curved rim)
    d.arc(dome, 180, 360, fill=CAP_LINE, width=int(6 * SS / 3))
    d.arc([cx - cap_rx, rim_y - gill_h * 1.2, cx + cap_rx, rim_y + gill_h * 2.4], 0, 180,
          fill=CAP_LINE, width=int(4 * SS / 3))

    # ---- face -------------------------------------------------------------
    face_cy = body_cy - body_ry * 0.05
    eye_state = p.get("eyes", "open")
    eye_dx = body_rx * 0.42
    eye_y = face_cy - body_ry * 0.05
    eye_r = 30 * SS
    for side in (-1, 1):
        ex = cx + side * eye_dx
        if eye_state in ("x", "defeated"):
            lw = int(9 * SS / 3)
            r = eye_r * 0.7
            d.line([(ex - r, eye_y - r), (ex + r, eye_y + r)], fill=BODY_LINE, width=lw)
            d.line([(ex - r, eye_y + r), (ex + r, eye_y - r)], fill=BODY_LINE, width=lw)
        else:
            d.ellipse([ex - eye_r, eye_y - eye_r * 1.15, ex + eye_r, eye_y + eye_r * 1.15], fill=EYE_WHITE, outline=BODY_LINE, width=int(6 * SS / 3))
            iris_r = eye_r * 0.66
            iy = eye_y + (eye_r * 0.25 if eye_state == "half" else 0)
            d.ellipse([ex - iris_r, iy - iris_r, ex + iris_r, iy + iris_r], fill=IRIS)
            d.ellipse([ex - iris_r, iy - iris_r * 0.2, ex + iris_r, iy + iris_r], fill=IRIS_SH)
            pr = iris_r * 0.55
            d.ellipse([ex - pr, iy - pr, ex + pr, iy + pr], fill=PUPIL)
            d.ellipse([ex - pr * 0.9, iy - pr * 0.9, ex - pr * 0.1, iy - pr * 0.1], fill=EYE_WHITE)
            if eye_state == "half":
                d.rectangle([ex - eye_r, eye_y - eye_r * 1.2, ex + eye_r, eye_y - eye_r * 0.1], fill=BODY_MID)
                d.line([(ex - eye_r, eye_y - eye_r * 0.1), (ex + eye_r, eye_y - eye_r * 0.1)], fill=BODY_LINE, width=int(6 * SS / 3))

    # brow ridge bumps (like concept)
    for side in (-1, 1):
        bx = cx + side * body_rx * 0.5
        by = eye_y - eye_r * 1.35
        d.ellipse([bx - 10 * SS, by - 7 * SS, bx + 10 * SS, by + 7 * SS], fill=BODY_HI)

    # ---- mouth ------------------------------------------------------------
    mouth = p.get("mouth", "grin")
    my = face_cy + body_ry * 0.42
    mw = body_rx * 0.62
    if mouth == "grin":
        mh = body_ry * 0.3
        d.chord([cx - mw, my - mh, cx + mw, my + mh], 8, 172, fill=MOUTH_IN, outline=BODY_LINE, width=int(7 * SS / 3))
        # teeth top row (triangles)
        nteeth = 6
        for i in range(nteeth):
            t0 = i / nteeth
            t1 = (i + 1) / nteeth
            x0 = cx - mw + (2 * mw) * t0
            x1 = cx - mw + (2 * mw) * t1
            top = my - mh * 0.15
            d.polygon([(x0, top), (x1, top), ((x0 + x1) / 2, my + mh * 0.45)], fill=TEETH, outline=CAP_LINE)
        # a couple bottom fangs
        for i in range(3):
            xb = cx - mw * 0.55 + i * mw * 0.55
            d.polygon([(xb - 9 * SS, my + mh * 0.55), (xb + 9 * SS, my + mh * 0.55), (xb, my - mh * 0.1)], fill=TEETH, outline=CAP_LINE)
    elif mouth == "open":
        mh = body_ry * 0.4
        d.ellipse([cx - mw * 0.8, my - mh * 0.6, cx + mw * 0.8, my + mh], fill=MOUTH_IN, outline=BODY_LINE, width=int(7 * SS / 3))
        d.ellipse([cx - mw * 0.4, my + mh * 0.2, cx + mw * 0.4, my + mh * 0.9], fill=TONGUE)
        for i in range(5):
            t0 = i / 5; t1 = (i + 1) / 5
            x0 = cx - mw * 0.8 + 1.6 * mw * 0.8 * t0
            x1 = cx - mw * 0.8 + 1.6 * mw * 0.8 * t1
            d.polygon([(x0, my - mh * 0.55), (x1, my - mh * 0.55), ((x0 + x1) / 2, my - mh * 0.05)], fill=TEETH, outline=CAP_LINE)
    elif mouth == "ouch":
        # gritted zigzag
        pts = []
        seg = 7
        for i in range(seg + 1):
            xx = cx - mw + (2 * mw) * (i / seg)
            yy = my + (10 * SS if i % 2 == 0 else -10 * SS)
            pts.append((xx, yy))
        d.line(pts, fill=BODY_LINE, width=int(9 * SS / 3))
    else:  # flat / defeated
        d.line([(cx - mw * 0.7, my), (cx + mw * 0.7, my)], fill=BODY_LINE, width=int(8 * SS / 3))

    # optional tilt for hurt
    if tilt:
        img = img.rotate(tilt, resample=Image.BICUBIC, center=(cx, body_cy))

    return img.resize((CW, CH), Image.LANCZOS)


POSES = [
    # 0 idle A
    dict(sx=1.0, sy=1.0, coils=4, eyes="open", mouth="grin"),
    # 1 idle B (breathe / squash)
    dict(sx=1.06, sy=0.94, coils=3, eyes="open", mouth="grin", body_dy=6),
    # 2 hop crouch (compressed, ready to spring)
    dict(sx=1.18, sy=0.82, coils=2, eyes="open", mouth="grin", body_dy=22, shadow_grow=0.15),
    # 3 hop launch (stretched up, arms up)
    dict(sx=0.9, sy=1.14, coils=6, eyes="open", mouth="open", body_dy=-30, arm=0.9, shadow_grow=-0.2),
    # 4 hop airborne
    dict(sx=1.0, sy=1.02, coils=6, eyes="wide" if False else "open", mouth="open", body_dy=-60, arm=0.6, shadow_grow=-0.45),
    # 5 hop land (impact squash)
    dict(sx=1.22, sy=0.78, coils=2, eyes="half", mouth="grin", body_dy=26, shadow_grow=0.2),
    # 6 hurt
    dict(sx=1.0, sy=1.0, coils=3, eyes="x", mouth="ouch", tilt=-9),
    # 7 defeated
    dict(sx=1.3, sy=0.6, coils=1, eyes="defeated", mouth="flat", body_dy=40, spring=True, shadow_grow=0.3),
]

sheet = Image.new("RGBA", (CW * COLS, CH * ROWS), (0, 0, 0, 0))
for i, pose in enumerate(POSES):
    cell = draw_creature(pose)
    col = i % COLS
    row = i // COLS
    sheet.paste(cell, (col * CW, row * CH), cell)

import sys
out = sys.argv[1] if len(sys.argv) > 1 else "buttoncap_biter.png"
sheet.save(out)
print("wrote", out, sheet.size)
