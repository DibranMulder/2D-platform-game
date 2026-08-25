# Wendmere Village Square — layered map kit v1

This document designs the first playable Zone in the Human hometown from
DESIGN-0014. It is a side-scrolling game map, not a region-map illustration.

## Scale

- Logical map size: **5120 × 2880 px** (`4 × 4` viewports at 1280 × 720).
- Engine capacity target: up to **12800 × 7200 px** (`10 × 10` viewports).
- Camera: follows the Hero on both axes and clamps to the logical map bounds.
- The generated countryside background is viewport art. Scale/crop it to cover
  1280 × 720 and keep it fixed, or move it with very subtle parallax.
- The foreground map is assembled from reusable transparent modules. Do not
  stretch one foreground painting across the logical world.

## Layer contract

1. **Far background** — sky, Open Lands, river, orchards, distant King's Keep.
   Decorative only; fixed or slow parallax; never owns collision.
2. **World environment** — cobbles, terraces, walls, roofs, stairs, ladders,
   platforms, buildings, ordinary doors, arches, and road gates. This layer
   scrolls with the camera. Godot collision shapes follow its visible surfaces.
3. **Portal volumes** — invisible server-authored/gameplay overlays placed over
   the painted doors, arches, and edge roads. Doors and gates themselves do not
   react to input.
4. **Runtime sprites** — shops, NPCs, wildlife, the spawn waystone, and anything
   animated or interactable. Each remains an independent scene/sprite with its
   own interaction or animation area.
5. **Foreground cover** — foliage, banners, beams, and awning edges that can
   briefly overlap the Hero without hiding traversal.

## Village Square layout

See [01-village-square-layout-v1.svg](layouts/01-village-square-layout-v1.svg) for the full spatial blueprint.

- **Ground route:** Open Lands road → central square → Market Row arch.
- **Lower branch:** broad steps descend to the Apothecary Lane door.
- **West climb:** stairs, awnings, wall ledges, and two ladders reach the
  Trainers' Yard gate.
- **East climb:** the old watch/bell tower provides several floors of platform
  traversal before the elevated Stronghold Approach gate.
- **Optional traversal:** fountain rim, carts, balconies, rooftops, scaffold
  decks, and tower ledges create short loops and collectible spaces.
- **Spawn:** the central waystone has a full safe landing area around it.

The basic Exchange Broker, Lorekeeper, Open Lands exit, Market Row exit, and
Apothecary Lane exit remain reachable without precision platforming. The higher
routes teach stairs, ladders, and jumping before later hometown maps demand it.

## Runtime sprites for this Zone

- Exchange kiosk/shop frontage — interactive shop object.
- Exchange Broker — interactive market NPC.
- Lorekeeper/Herald — interactive quest NPC.
- Human gate sentry — interactive directions NPC; instance or mirror as needed.
- Spawn waystone — independent sprite so its location pulse can animate.
- Meadow Puffkin — independent ambient creature sprite.

## Portal facades

These are environment art, not interactive sprites:

- Far-left old-road gate → Open Lands.
- West upper-yard gate → Trainers' Yard.
- Lower-right ivy door → Apothecary Lane.
- Far-right market arch → Market Row.
- High east stone gate → Stronghold Approach.

All text, prompts, discovery state, access state, interaction radii, collisions,
and portal transfers belong to Godot/runtime data rather than the paintings.

## Current artifact status

- [01-village-square-parallax-background-v1.png](parallax/01-village-square-parallax-background-v1.png) is usable RGB background art.
- [01-village-square-layout-v1.svg](layouts/01-village-square-layout-v1.svg) is the authoritative first-pass spatial plan.
- [Village Square NPC artwork](npcs/README.md) provides transparent idle assets for the Exchange Broker, Herald, and reusable Gate Sentry.
- [Village Square modular construction kits](platform-kits/README.md) provide tileable stairs, ladders, floors, walls, and watchtower pieces.
- [Village Square decorative prop atlases](props/README.md) provide eighteen transparent settlement, armory, and foliage pieces for dressing empty spaces.
- [01-village-square-platform-kit-v1.png](platform-kits/01-village-square-platform-kit-v1.png) and
  [01-village-square-portal-facades-v1.png](portal-facades/01-village-square-portal-facades-v1.png) are genuine RGBA atlases. Their baked
  checkerboards were removed with the same local cleanup pattern used by the
  Human M03 action sheets: connected pale-background removal plus cleanup of
  enclosed neutral checker regions. Both were visually checked over a dark
  background and verified with alpha values spanning `0..1`.
