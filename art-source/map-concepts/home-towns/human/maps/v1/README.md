# Human hometown map artwork v1

This directory is the single source-art set for the playable Human hometown maps described in `docs/design/0014-hometown-maps.md`. One viewport is 1280×720.

## Artwork structure

- `layouts/` — numbered gameplay-layout SVGs for maps 01–15 and their deterministic generator.
- `npcs/` — transparent standalone NPC artwork, beginning with the three Village Square roles.
- `parallax/` — numbered/shared RGB viewport backgrounds, including Village Square, the King's Keep, and the Princess's Tower.
- `platform-kits/` — transparent world-environment atlases, currently beginning with Village Square.
- `portal-facades/` — transparent decorative door, arch, and gate atlases, currently beginning with Village Square.
- `props/` — transparent decorative settlement, armory, and foliage atlases for filling out world-space compositions.
- [01-village-square.md](01-village-square.md) — detailed assembly and runtime contract for the first playable map.

The separate `human/v1/` directory remains the illustrated region-map underlay. It is atlas/navigation artwork rather than playable-map artwork.

## Gameplay layouts

The Village Square blueprint is the visual and notation reference for the other fourteen large, scrollable map blueprints.

The SVGs separate the static environment composition from runtime interaction:

- Brown shapes are themed walkable platforms.
- Pale-gold lines show the intended critical traversal route.
- Brown rung shapes are climbable ladders.
- Blue rounded markers identify map-transfer portal positions. Door and gate artwork remains part of the static background; the runtime `PortalVolume` is placed over it.
- Turquoise markers identify NPC, shop, quest, loot, or other interactable sprite positions. They are layout markers, not baked game art.
- Pink markers identify locked or quest-gated portal positions.
- Dashed lines show 1280×720 viewport boundaries and named tower floors.

The layouts use the matching [Village Square, King's Keep, and Princess's Tower parallax backgrounds](parallax/README.md). These remain viewport-sized decorative art rather than map-sized collision layers.

## Region maps

| # | Map | Size | Viewports | Main connections |
|---|---|---:|---:|---|
| 01 | [Village Square](layouts/01-village-square-layout-v1.svg) | 5120×2880 | 4×4 | Market Row, Apothecary Lane, Trainers' Yard, Stronghold Approach |
| 02 | [Market Row](layouts/02-market-row-layout-v1.svg) | 7680×2160 | 6×3 | Village Square |
| 03 | [Apothecary Lane](layouts/03-apothecary-lane-layout-v1.svg) | 3840×3600 | 3×5 | Village Square |
| 04 | [Trainers' Yard](layouts/04-trainers-yard-layout-v1.svg) | 6400×2880 | 5×4 | Village Square, Hearth Inn |
| 05 | [Hearth Inn](layouts/05-hearth-inn-layout-v1.svg) | 3840×2880 | 3×4 | Trainers' Yard |
| 06 | [Stronghold Approach](layouts/06-stronghold-approach-layout-v1.svg) | 6400×3600 | 5×5 | Village Square, Gatehouse Court |
| 07 | [Gatehouse Court](layouts/07-gatehouse-court-layout-v1.svg) | 5120×3600 | 4×5 | Stronghold Approach, Warden Barracks, Service District |
| 08 | [Warden Barracks](layouts/08-warden-barracks-layout-v1.svg) | 5120×2880 | 4×4 | Gatehouse Court, Great Hall |
| 09 | [Service District](layouts/09-service-district-layout-v1.svg) | 6400×2880 | 5×4 | Gatehouse Court |
| 10 | [Great Hall](layouts/10-great-hall-layout-v1.svg) | 5120×3600 | 4×5 | Warden Barracks, King's Room, Treasury & Archive, Tower Base |
| 11 | [King's Room](layouts/11-kings-room-layout-v1.svg) | 3840×2160 | 3×3 | Great Hall |
| 12 | [Treasury & Archive](layouts/12-treasury-archive-layout-v1.svg) | 5120×4320 | 4×6 | Great Hall |
| 13 | [Princess's Tower: Tower Base](layouts/13-tower-base-layout-v1.svg) | 2560×4320 | 2×6 | Great Hall, Winding Stair |
| 14 | [Princess's Tower: Winding Stair](layouts/14-winding-stair-layout-v1.svg) | 2560×5760 | 2×8 | Tower Base, The Solar |
| 15 | [Princess's Tower: The Solar](layouts/15-the-solar-layout-v1.svg) | 2560×3600 | 2×5 | Winding Stair, return portal to Tower Base |

## Princess's Tower continuity

The tower is one continuous ascent presented as three maps:

1. Great Hall's quest-gated portal enters **Tower Base, floor 1**.
2. Tower Base climbs through **floors 1–6** and exits upward into **Winding Stair, floor 7**.
3. Winding Stair climbs through **floors 7–14** and exits upward into **The Solar, floor 15**.
4. The Solar climbs through **floors 15–19** to the summit encounter and a return portal to Tower Base.

Preserve the arrival direction and vertical momentum cue at each handoff so the player experiences a continuous climb rather than three unrelated rooms.

## Regeneration

Run `python3 layouts/generate_layout_svgs.py` from this directory to regenerate maps 02–15. Village Square is intentionally excluded because it has its own layered source set and specification.
