# Village Square decorative prop atlases v1

These transparent atlases provide small reusable dressing pieces for the Village Square and adjacent Human hometown maps. They are intended to break up long empty surfaces without baking decorations into the parallax background or platform construction kits.

## Atlas grids

| File | Grid | Cell size | Contents, left-to-right then top-to-bottom |
|---|---:|---:|---|
| `01-village-square-settlement-props-v1.png` | 3×2 | 512×512 | Upright barrel, two-barrel stack, crate, grain sacks, produce basket, pottery cluster |
| `01-village-square-armory-props-v1.png` | 3×2 | 484×543 | Spear rack, bundled spears, shield rack, propped shield, training dummy, shield-and-helmet stand |
| `01-village-square-foliage-props-v1.png` | 3×2 | 512×512 | Apple tree, young tree, flowering shrub, fern cluster, wildflowers, grass-and-ivy cluster |

All three atlases are RGBA PNGs with genuine transparency and large gutters between sprites.

## Placement guidance

- Treat these as decorative world sprites. Interaction areas, pickups, collision, and animation belong to separate Godot nodes and data.
- Use the settlement pieces around market stalls, doors, tower storage ledges, cart stops, and the Apothecary Lane descent.
- Use armory pieces near the Trainers' Yard route, the sentry post, and upper watchtower platforms. Keep spear tips outside the Hero's main landing arc so their silhouettes remain readable.
- Use larger trees behind the traversal plane. Shrubs, flowers, and ivy can sit in the world layer or foreground-cover layer where they do not obscure ledge edges.
- Mix scale only modestly. Prefer mirroring, partial occlusion, and varied grouping over stretching sprites.
- Do not derive gameplay collision from image opacity. Add simple authored collision only where a prop is intentionally solid.

## Suggested density

For each 1280×720 viewport, start with one medium or large anchor prop and two to five small accents. Leave the critical route, ladder mouths, portal volumes, and NPC interaction spaces visually open.
