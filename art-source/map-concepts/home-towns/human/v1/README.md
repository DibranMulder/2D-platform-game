# Human Home Town Region Map — v1

`human-home-town-region-map-v1.png` is the first illustrated region-map underlay
for the Human home town described by DESIGN-0014.

## Visual structure

- Lower-left: **Wendmere Crossroads**, with the Village Square as its central
  waystone and distinct market, apothecary, training, and inn landmarks.
- Upper-center: **the King's Keep**, reached through the guarded Stronghold
  Approach and represented as a multi-landmark Stronghold cluster.
- Right: **the Princess's Tower**, connected to the Keep by an elevated,
  quest-gated route rather than directly to the Outer Village.
- The surrounding Open Lands use orchards, terraced meadows, an old road,
  river crossings, chalk hills, and Meadow Puffkins for scale and local life.

The image intentionally contains no baked-in labels. Godot should render all
localized names, discovery states, current-location pulses, access rules, and
click targets over this underlay. Illustrated roads communicate Portal
adjacency, not fast travel or exact geographic distance.

## Art direction

- Map presentation authority:
  `art-source/map-concepts/selected/enchanted-chronicle-v1.png`
- Rendering authority:
  `art-source/style-references/cinematic-storybook-anime-v1.png`
- Palette: royal blue, warm ivory, field green, oxblood, and muted gold.
- Status: exploratory concept; geography and building-to-Zone assignments need
  review before the underlay is integrated into the interactive map.

## Generation

Generated with the built-in image tool as a 16:9 illuminated-paper region map.
The first pass was corrected so the Princess's Tower branches from the Keep,
matching the DESIGN-0014 Portal graph.
