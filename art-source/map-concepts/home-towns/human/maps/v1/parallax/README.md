# Human hometown parallax backgrounds v1

These are decorative RGB viewport backgrounds for the Human hometown maps. All are 1672×941 and share the same child-friendly storybook treatment.

## Assets

- `01-village-square-parallax-background-v1.png` — Village Square and the visual reference for the Human outdoor maps.
- `07-12-kings-keep-interior-parallax-background-v1.png` — shared by Gatehouse Court, Warden Barracks, Service District, Great Hall, the King's Room, and Treasury & Archive.
- `13-15-princess-tower-interior-parallax-background-v1.png` — shared by Tower Base, Winding Stair, and The Solar.

The Village Square image establishes the sunny countryside palette. The castle image uses warm daylight, ivory limestone, royal-blue fabric, muted gold, and small oxblood accents. The tower image keeps the same materials while shifting to lavender dusk and candlelight so the three-map ascent feels like one connected place.

## Layer contract

- Treat these paintings as far-background art only. They never own collisions or interactions.
- Scale or crop to cover the 1280×720 viewport; do not stretch either image across the full logical map.
- Keep them fixed or move them at very slow parallax. Suggested camera factors are `0.03–0.06` horizontally and `0.02–0.05` vertically.
- Castle and tower platform kits, portal facades, NPCs, shops, doors, ladders, and foreground cover remain separate world-space assets.
- The imagery deliberately avoids prominent doors, ladders, platforms, and props so background decoration cannot be confused with gameplay.

## Art direction

Child-friendly cinematic storybook-anime with simplified, readable fantasy architecture. The existing Human village background supplies the softness and palette density; the project's Age of Wonders reference contributes only broad, easily read fantasy shapes and color grouping. No reference UI or exact designs are copied.
