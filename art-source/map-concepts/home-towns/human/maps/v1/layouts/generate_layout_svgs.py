#!/usr/bin/env python3
"""Generate deterministic gameplay-layout SVGs for the Human hometown maps."""

from __future__ import annotations

from dataclasses import dataclass
from html import escape
from math import hypot
from pathlib import Path
from typing import Callable, Iterable


VIEW_W = 1280
VIEW_H = 720
OUTPUT_DIR = Path(__file__).parent


@dataclass(frozen=True)
class Theme:
    sky_top: str
    sky_bottom: str
    distant: str
    ground: str
    platform: str
    route: str = "#eed58a"


OUTER = Theme("#c9e7ef", "#f6d99c", "#88a36b", "#405437", "#8d7b5a")
KEEP = Theme("#a9c8dc", "#ead2a2", "#71856c", "#3f4643", "#81745f")
INTERIOR = Theme("#73859d", "#c3a97d", "#4f5963", "#313944", "#74644f")
TOWER = Theme("#778aa8", "#d7bd91", "#5d6675", "#2d3541", "#756752")


class Canvas:
    def __init__(self, title: str, width: int, height: int, theme: Theme, subtitle: str) -> None:
        self.title = title
        self.width = width
        self.height = height
        self.theme = theme
        self.subtitle = subtitle
        self.parts: list[str] = []

    def rect(self, x: int, y: int, w: int, h: int, css: str, rx: int = 0) -> None:
        self.parts.append(f'<rect class="{css}" x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/>')

    def line(self, x1: int, y1: int, x2: int, y2: int, css: str) -> None:
        self.parts.append(f'<line class="{css}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/>')

    def path(self, d: str, css: str) -> None:
        self.parts.append(f'<path class="{css}" d="{d}"/>')

    def polyline(self, points: Iterable[tuple[int, int]], css: str = "route") -> None:
        point_list = list(points)
        joined = " ".join(f"{x},{y}" for x, y in point_list)
        if css == "route":
            half_width = 17
            for (x1, y1), (x2, y2) in zip(point_list, point_list[1:]):
                length = hypot(x2 - x1, y2 - y1)
                ox = -(y2 - y1) * half_width / length
                oy = (x2 - x1) * half_width / length
                corners = " ".join(
                    f"{x:.1f},{y:.1f}"
                    for x, y in (
                        (x1 + ox, y1 + oy), (x2 + ox, y2 + oy),
                        (x2 - ox, y2 - oy), (x1 - ox, y1 - oy),
                    )
                )
                self.parts.append(f'<polygon class="route" points="{corners}" fill="{self.theme.route}"/>')
            for x, y in point_list:
                self.parts.append(f'<circle class="route" cx="{x}" cy="{y}" r="{half_width}" fill="{self.theme.route}"/>')
        else:
            self.parts.append(f'<polyline class="{css}" points="{joined}"/>')

    def text(self, x: int, y: int, value: str, css: str = "small", anchor: str = "start") -> None:
        self.parts.append(
            f'<text class="{css}" x="{x}" y="{y}" text-anchor="{anchor}">{escape(value)}</text>'
        )

    def platform(self, x: int, y: int, w: int, h: int = 130) -> None:
        self.rect(x, y, w, h, "platform", 24)

    def ladder(self, x: int, y1: int, y2: int) -> None:
        top, bottom = sorted((y1, y2))
        self.parts.append(f'<rect class="ladder" x="{x - 48}" y="{top}" width="18" height="{bottom - top}" fill="#815d32"/>')
        self.parts.append(f'<rect class="ladder" x="{x + 30}" y="{top}" width="18" height="{bottom - top}" fill="#815d32"/>')
        for rung_y in range(top + 18, bottom, 66):
            self.parts.append(f'<rect class="ladder" x="{x - 48}" y="{rung_y}" width="96" height="16" rx="8" fill="#a57a43"/>')

    def portal(self, x: int, y: int, label: str, *, w: int = 260, h: int = 320, anchor: str = "start") -> None:
        self.rect(x, y, w, h, "portal", 72)
        tx = x + w + 40 if anchor == "start" else x - 40
        self.text(tx, y + h // 2, label, "small", anchor)

    def actor(self, x: int, y: int, label: str, *, shop: bool = False) -> None:
        if shop:
            self.rect(x - 120, y - 85, 240, 170, "interactive", 38)
        else:
            self.parts.append(f'<circle class="interactive" cx="{x}" cy="{y}" r="58"/>')
        self.text(x, y - 115, label, "tiny", "middle")

    def floor_label(self, y: int, label: str) -> None:
        self.line(120, y, self.width - 120, y, "floorline")
        self.text(170, y - 28, label, "floor")

    def svg(self) -> str:
        cols = self.width // VIEW_W
        rows = self.height // VIEW_H
        grid = []
        for x in range(VIEW_W, self.width, VIEW_W):
            grid.append(f'<line class="grid" x1="{x}" y1="0" x2="{x}" y2="{self.height}"/>')
        for y in range(VIEW_H, self.height, VIEW_H):
            grid.append(f'<line class="grid" x1="0" y1="{y}" x2="{self.width}" y2="{y}"/>')
        body = "\n  ".join(grid + self.parts)
        return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}">
  <defs>
    <linearGradient id="sky" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0" stop-color="{self.theme.sky_top}"/>
      <stop offset="1" stop-color="{self.theme.sky_bottom}"/>
    </linearGradient>
    <style>
      .grid {{ stroke:#fff; stroke-opacity:.22; stroke-width:8; stroke-dasharray:28 22 }}
      .platform {{ fill:{self.theme.platform}; stroke:#332d24; stroke-width:18 }}
      .route {{ fill:none; stroke:{self.theme.route}; stroke-width:34; stroke-linecap:round; stroke-linejoin:round }}
      .stairs {{ fill:none; stroke:#d5bd80; stroke-width:48; stroke-linecap:square; stroke-linejoin:miter }}
      .ladder {{ fill:none; stroke:#815d32; stroke-width:28; stroke-dasharray:22 18 }}
      .portal {{ fill:#233d61; stroke:#e3bd62; stroke-width:20 }}
      .locked {{ fill:#552e49; stroke:#e0a4c1; stroke-width:20 }}
      .interactive {{ fill:#77cbb7; stroke:#143f40; stroke-width:14 }}
      .hazard {{ fill:#bc654e; stroke:#51281f; stroke-width:14 }}
      .floorline {{ stroke:#fff8dd; stroke-opacity:.34; stroke-width:10; stroke-dasharray:36 30 }}
      .title {{ font-family:Arial,sans-serif; font-weight:700; font-size:72px; fill:#fff8dd; paint-order:stroke; stroke:#152133; stroke-width:18 }}
      .subtitle {{ font-family:Arial,sans-serif; font-weight:600; font-size:46px; fill:#fff8dd; paint-order:stroke; stroke:#152133; stroke-width:13 }}
      .small {{ font-family:Arial,sans-serif; font-weight:600; font-size:48px; fill:#fff8dd; paint-order:stroke; stroke:#152133; stroke-width:12 }}
      .tiny {{ font-family:Arial,sans-serif; font-weight:600; font-size:38px; fill:#fff8dd; paint-order:stroke; stroke:#152133; stroke-width:10 }}
      .floor {{ font-family:Arial,sans-serif; font-weight:700; font-size:42px; fill:#fff4c5; paint-order:stroke; stroke:#152133; stroke-width:10 }}
    </style>
  </defs>
  <rect width="{self.width}" height="{self.height}" fill="{self.theme.sky_bottom}"/>
  <rect width="{self.width}" height="{int(self.height * .38)}" fill="{self.theme.sky_top}" opacity=".76"/>
  <path d="M0 {int(self.height * .38)} Q{self.width // 4} {int(self.height * .2)} {self.width // 2} {int(self.height * .36)} T{self.width} {int(self.height * .32)} V{self.height} H0Z" fill="{self.theme.distant}" opacity=".48"/>
  <rect y="{int(self.height * .84)}" width="{self.width}" height="{int(self.height * .16)}" fill="{self.theme.ground}"/>
  {body}
  <text class="title" x="{self.width // 2}" y="105" text-anchor="middle">{escape(self.title)}</text>
  <text class="subtitle" x="{self.width // 2}" y="170" text-anchor="middle">{escape(self.subtitle)} · {self.width}×{self.height} · {cols}×{rows} viewports</text>
</svg>
'''


def save(filename: str, title: str, width: int, height: int, theme: Theme, subtitle: str,
         draw: Callable[[Canvas], None]) -> None:
    canvas = Canvas(title, width, height, theme, subtitle)
    draw(canvas)
    (OUTPUT_DIR / filename).write_text(canvas.svg(), encoding="utf-8")


def market_row(c: Canvas) -> None:
    c.platform(0, 1830, 7680, 330)
    for x, y, w in [(700, 1400, 800), (1800, 1190, 920), (3040, 1390, 820), (4200, 1080, 900), (5480, 1330, 850), (6500, 900, 880)]:
        c.platform(x, y, w)
    c.polyline([(120, 1750), (1500, 1750), (2200, 1300), (3450, 1750), (4650, 1180), (5900, 1750), (7040, 1030)])
    for x, y1, y2 in [(1480, 1760, 1450), (2680, 1760, 1240), (4100, 1760, 1130), (6360, 1760, 950)]:
        c.ladder(x, y1, y2)
    c.portal(40, 1510, "Village Square")
    c.actor(1550, 1710, "Weaponsmith", shop=True)
    c.actor(3500, 1710, "Armorer", shop=True)
    c.actor(5650, 1710, "Wandwright", shop=True)
    c.actor(7000, 840, "Roof cache")


def apothecary_lane(c: Canvas) -> None:
    levels = [(120, 730, 1100), (1420, 1320, 1160), (240, 1980, 1200), (1620, 2580, 1900), (0, 3300, 3840)]
    for x, y, w in levels:
        c.platform(x, y, w)
    c.polyline([(240, 650), (1180, 650), (1540, 1250), (2480, 1250), (2080, 1910), (420, 1910), (1450, 2510), (3450, 2510), (3000, 3230)])
    for x, y1, y2 in [(1240, 1260, 760), (2260, 1940, 1380), (1320, 2540, 2050), (3100, 3270, 2670)]:
        c.ladder(x, y1, y2)
    c.portal(90, 390, "Village Square")
    c.actor(2150, 2450, "Apothecary", shop=True)
    c.actor(3140, 3170, "Provisioner", shop=True)
    c.actor(620, 1840, "Herb garden")
    c.actor(950, 3200, "Brookskip Otter")


def trainers_yard(c: Canvas) -> None:
    c.platform(0, 2500, 6400, 380)
    for x, y, w in [(540, 1900, 920), (1740, 1580, 900), (2920, 1900, 900), (4120, 1450, 900), (5260, 1010, 900)]:
        c.platform(x, y, w)
    c.polyline([(100, 2410), (1200, 2410), (1000, 1830), (2200, 1830), (2140, 1510), (3340, 1830), (4550, 1380), (5700, 940), (6280, 940)])
    for x, y1, y2 in [(1480, 2450, 1950), (2680, 2450, 1640), (3860, 2450, 1960), (5080, 1450, 1070)]:
        c.ladder(x, y1, y2)
    c.portal(40, 2180, "Village Square")
    c.portal(6060, 690, "Hearth Inn", anchor="end")
    names = ["Vanguard", "Ravager", "Ranger", "Duelist", "Arcanist", "Warden"]
    positions = [(800, 2400), (1700, 2400), (2600, 2400), (3500, 2400), (4400, 2400), (5300, 2400)]
    for (x, y), name in zip(positions, names):
        c.actor(x, y, f"{name} Trainer")


def hearth_inn(c: Canvas) -> None:
    for y in [2480, 1770, 1060, 350]:
        c.platform(180, y, 3480, 140)
    c.polyline([(260, 2410), (1100, 2410), (1450, 1700), (2450, 1700), (2800, 990), (3450, 990), (3200, 280)])
    for x, y1, y2 in [(1280, 2420, 1830), (2600, 1710, 1120), (3350, 1000, 410)]:
        c.ladder(x, y1, y2)
    c.portal(70, 2160, "Trainers' Yard")
    c.actor(900, 2370, "Innkeeper", shop=True)
    c.actor(2200, 1660, "Quartermaster", shop=True)
    c.actor(2950, 930, "Guest rooms")
    c.actor(1600, 2370, "Respawn hearth")


def stronghold_approach(c: Canvas) -> None:
    terraces = [(0, 3220, 1500), (1100, 2700, 1500), (2300, 2150, 1450), (3450, 1560, 1500), (4700, 880, 1700)]
    for x, y, w in terraces:
        c.platform(x, y, w, 240)
    c.polyline([(100, 3120), (1280, 3120), (1550, 2600), (2550, 2600), (2850, 2050), (3700, 2050), (4050, 1460), (4950, 1460), (5350, 780), (6240, 780)])
    for x, y1, y2 in [(1450, 3080, 2750), (2700, 2560, 2200), (3900, 2010, 1610), (5180, 1420, 930)]:
        c.ladder(x, y1, y2)
    c.portal(40, 2890, "Village Square")
    c.portal(6040, 540, "Gatehouse Court", anchor="end")
    c.actor(5340, 700, "Waystone Guardian")
    c.actor(4400, 1380, "Gate Sentry")
    c.actor(3250, 1950, "Hillkeep Gargoyle")


def gatehouse_court(c: Canvas) -> None:
    for x, y, w in [(0, 3150, 5120), (360, 2460, 1400), (1880, 2100, 1360), (3400, 2460, 1380), (1040, 1350, 3040), (1720, 650, 1680)]:
        c.platform(x, y, w, 170)
    c.polyline([(240, 3060), (1000, 3060), (1100, 2380), (2200, 2380), (2560, 2020), (3760, 2380), (3940, 1310), (2600, 1310), (2550, 570)])
    for x, y1, y2 in [(900, 3070, 2520), (1780, 2420, 2150), (3330, 2420, 2150), (3980, 2400, 1420), (2550, 1300, 720)]:
        c.ladder(x, y1, y2)
    c.portal(80, 2820, "Stronghold Approach")
    c.portal(720, 1020, "Warden Barracks")
    c.portal(4100, 2130, "Service District", anchor="end")
    c.actor(2500, 1970, "Court Sentry")
    c.actor(2860, 1970, "Court Sentry")


def warden_barracks(c: Canvas) -> None:
    for x, y, w in [(0, 2460, 5120), (350, 1800, 1250), (1850, 2040, 1250), (3300, 1660, 1480), (1040, 1050, 1400), (2780, 760, 1700)]:
        c.platform(x, y, w, 150)
    c.polyline([(120, 2370), (1200, 2370), (980, 1730), (2200, 1730), (2480, 1980), (3650, 1590), (4200, 1590), (3900, 690), (3050, 690)])
    for x, y1, y2 in [(1550, 2420, 1870), (3100, 1980, 1710), (2450, 1660, 1110), (3600, 1550, 820)]:
        c.ladder(x, y1, y2)
    c.portal(50, 2130, "Gatehouse Court")
    c.portal(2760, 430, "Great Hall")
    c.actor(900, 1690, "Armory rack")
    c.actor(2450, 1940, "Barracks Captain")
    c.actor(3900, 1550, "Drill squad")


def service_district(c: Canvas) -> None:
    c.platform(0, 2480, 6400, 400)
    for x, y, w in [(500, 1800, 1100), (1900, 1450, 1150), (3300, 1850, 1200), (4750, 1240, 1200)]:
        c.platform(x, y, w, 150)
    c.polyline([(120, 2390), (1100, 2390), (1060, 1730), (2400, 1730), (2440, 1380), (3900, 1780), (5200, 1170), (6100, 1170)])
    for x, y1, y2 in [(1600, 2420, 1870), (3080, 2420, 1910), (4600, 1810, 1300)]:
        c.ladder(x, y1, y2)
    c.portal(40, 2150, "Gatehouse Court")
    c.actor(900, 2380, "Keep Kitchens", shop=True)
    c.actor(2500, 1340, "Smithy", shop=True)
    c.actor(3850, 1750, "Supply lift")
    c.actor(5400, 1140, "Steward")


def great_hall(c: Canvas) -> None:
    c.platform(0, 3220, 5120, 380)
    for x, y, w in [(420, 2460, 1300), (1900, 2640, 1320), (3420, 2460, 1300), (780, 1650, 1450), (2860, 1650, 1480), (1700, 820, 1720)]:
        c.platform(x, y, w, 160)
    c.polyline([(2350, 3140), (2350, 2560), (1100, 2390), (1500, 1580), (2500, 1580), (2500, 750), (3650, 1580), (4050, 2390)])
    for x, y1, y2 in [(1650, 2520, 1710), (3450, 2520, 1710), (2500, 1550, 880)]:
        c.ladder(x, y1, y2)
    c.portal(2220, 2890, "Warden Barracks")
    c.portal(2130, 490, "King's Room")
    c.portal(420, 1320, "Treasury & Archive")
    c.rect(4030, 1320, 280, 320, "locked", 72)
    c.text(3990, 1230, "Tower Base · quest gate", "small", "end")
    c.actor(2500, 2480, "Herald / Lorekeeper")
    c.actor(1220, 2320, "Court musician")


def kings_room(c: Canvas) -> None:
    c.platform(0, 1800, 3840, 360)
    c.platform(420, 1120, 900, 150)
    c.platform(2520, 1120, 900, 150)
    c.platform(1460, 780, 920, 180)
    c.polyline([(120, 1710), (1100, 1710), (900, 1050), (1920, 710), (2940, 1050), (3600, 1710)])
    c.ladder(1370, 1720, 1180)
    c.ladder(2470, 1720, 1180)
    c.portal(40, 1470, "Great Hall")
    c.actor(1920, 660, "The King")
    c.actor(950, 1020, "Royal Warden")
    c.actor(2900, 1020, "Councilor")


def treasury_archive(c: Canvas) -> None:
    floors = [3840, 3160, 2480, 1800, 1120, 440]
    for index, y in enumerate(floors, 1):
        x = 260 if index % 2 else 1180
        c.platform(x, y, 3600, 150)
        c.floor_label(y, f"Archive level {index}")
    points = [(300, 3760), (3800, 3760), (3900, 3090), (1300, 3090), (1180, 2410), (3900, 2410), (3900, 1730), (1300, 1730), (1180, 1050), (3900, 1050), (3900, 370), (1500, 370)]
    c.polyline(points)
    for x, y1, y2 in [(3960, 3800, 3220), (1120, 3120, 2540), (3960, 2440, 1860), (1120, 1760, 1180), (3960, 1080, 500)]:
        c.ladder(x, y1, y2)
    c.portal(80, 3510, "Great Hall")
    c.actor(1800, 3700, "Archivist")
    c.actor(3400, 2410, "Sealed archive door")
    c.actor(1800, 1020, "Treasury vault")


def tower_base(c: Canvas) -> None:
    floors = [3880, 3220, 2560, 1900, 1240, 580]
    for index, y in enumerate(floors, 1):
        c.platform(220, y, 2120, 140)
        c.floor_label(y, f"Tower floor {index}")
    points = [(300, 3800), (2200, 3800), (2200, 3140), (360, 3140), (360, 2480), (2200, 2480), (2200, 1820), (360, 1820), (360, 1160), (2200, 1160), (2200, 500), (1280, 500)]
    c.polyline(points)
    for x, y1, y2 in [(2200, 3820, 3290), (360, 3160, 2630), (2200, 2500, 1970), (360, 1840, 1310), (2200, 1180, 650)]:
        c.ladder(x, y1, y2)
    c.portal(100, 3550, "Great Hall · floor 1")
    c.portal(1150, 230, "Winding Stair · floor 7")
    c.actor(1780, 3140, "Lower winch")
    c.actor(760, 1820, "Warden memorial")


def winding_stair(c: Canvas) -> None:
    floors = [5320, 4660, 4000, 3340, 2680, 2020, 1360, 700]
    for local, y in enumerate(floors, 7):
        c.platform(220, y, 2120, 135)
        c.floor_label(y, f"Tower floor {local}")
    points: list[tuple[int, int]] = []
    for index, y in enumerate(floors):
        points.append((360 if index % 2 == 0 else 2200, y - 80))
        points.append((2200 if index % 2 == 0 else 360, y - 80))
    c.polyline(points)
    for index in range(len(floors) - 1):
        x = 2200 if index % 2 == 0 else 360
        c.ladder(x, floors[index] - 60, floors[index + 1] + 120)
    c.portal(100, 4990, "Tower Base · floor 6")
    c.portal(1140, 350, "The Solar · floor 15")
    c.actor(1280, 3920, "Broken clockwork")
    c.actor(1280, 1940, "Wind window")


def solar(c: Canvas) -> None:
    floors = [3160, 2500, 1840, 1180, 520]
    for local, y in enumerate(floors, 15):
        c.platform(220, y, 2120, 140)
        c.floor_label(y, f"Tower floor {local}")
    c.polyline([(360, 3080), (2200, 3080), (2200, 2420), (360, 2420), (360, 1760), (2200, 1760), (2200, 1100), (360, 1100), (360, 440), (1280, 440)])
    for x, y1, y2 in [(2200, 3100, 2570), (360, 2440, 1910), (2200, 1780, 1250), (360, 1120, 590)]:
        c.ladder(x, y1, y2)
    c.portal(100, 2830, "Winding Stair · floor 14")
    c.portal(1140, 190, "Return portal · Tower Base")
    c.actor(1280, 390, "The Solar · sealed archive")
    c.actor(780, 1080, "Astronomer's table")
    c.actor(1800, 1080, "Heir-Warden")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    specs = [
        ("02-market-row-layout-v1.svg", "Wendmere · Market Row", 7680, 2160, OUTER, "horizontal shop street and roof route", market_row),
        ("03-apothecary-lane-layout-v1.svg", "Wendmere · Apothecary Lane", 3840, 3600, OUTER, "descending herb terraces and cellar lane", apothecary_lane),
        ("04-trainers-yard-layout-v1.svg", "Wendmere · Trainers' Yard", 6400, 2880, OUTER, "six trainer stations and traversal circuit", trainers_yard),
        ("05-hearth-inn-layout-v1.svg", "Wendmere · Hearth Inn", 3840, 2880, INTERIOR, "four-level inn and respawn hearth", hearth_inn),
        ("06-stronghold-approach-layout-v1.svg", "King's Keep · Stronghold Approach", 6400, 3600, OUTER, "terraced farmland ascent and Guardian gate", stronghold_approach),
        ("07-gatehouse-court-layout-v1.svg", "King's Keep · Gatehouse Court", 5120, 3600, KEEP, "branching ramparts behind the Allegiance gate", gatehouse_court),
        ("08-warden-barracks-layout-v1.svg", "King's Keep · Warden Barracks", 5120, 2880, KEEP, "guard quarters, armory, and rampart climb", warden_barracks),
        ("09-service-district-layout-v1.svg", "King's Keep · Service District", 6400, 2880, KEEP, "kitchens, smithy, stores, and supply lifts", service_district),
        ("10-great-hall-layout-v1.svg", "King's Keep · Great Hall", 5120, 3600, INTERIOR, "central circulation hub with four portal branches", great_hall),
        ("11-kings-room-layout-v1.svg", "King's Keep · King's Room", 3840, 2160, INTERIOR, "three-level audience chamber", kings_room),
        ("12-treasury-archive-layout-v1.svg", "King's Keep · Treasury & Archive", 5120, 4320, INTERIOR, "six-level archive and sealed vault", treasury_archive),
        ("13-tower-base-layout-v1.svg", "Princess's Tower · Tower Base", 2560, 4320, TOWER, "continuous ascent · floors 1–6", tower_base),
        ("14-winding-stair-layout-v1.svg", "Princess's Tower · Winding Stair", 2560, 5760, TOWER, "continuous ascent · floors 7–14", winding_stair),
        ("15-the-solar-layout-v1.svg", "Princess's Tower · The Solar", 2560, 3600, TOWER, "continuous ascent · floors 15–19 and summit", solar),
    ]
    for spec in specs:
        save(*spec)


if __name__ == "__main__":
    main()
