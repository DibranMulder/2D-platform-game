# Village Square modular construction kits v1

These transparent atlases replace complete painted structures with reusable world-space pieces. Build floors, walls, stairs, ladders, and the east watchtower to match `layouts/01-village-square-layout-v1.svg`; keep collision in Godot rather than deriving it from image opacity.

## Atlas grids

| File | Grid | Cell size | Contents |
|---|---:|---:|---|
| `01-village-square-stair-modules-v1.png` | 2×2 | 768×512 | Clean, worn, mossy, and heavy-cap single-step modules |
| `01-village-square-ladder-modules-v1.png` | 3×1 | 627×836 | Top, repeatable middle, and bottom ladder segments |
| `01-village-square-floor-modules-v1.png` | 2×2 | 887×444 | Clean, cracked, grassy, and finished-end floor modules |
| `01-village-square-wall-modules-v1.png` | 3×2 | 512×512 | Plain, cracked, mossy, ivy, left-edge, and right-edge wall tiles |
| `01-village-square-tower-modules-v1.png` | 3×2 | 512×512 | Shaft wall, arched window, arrow slit, cornice, parapet, and corner pier |

All atlases are RGBA with genuine transparency and large gutters between sprites.

## Assembly rules

- Build stairs by offsetting individual stair modules horizontally and vertically; mirror only when the stone lighting remains acceptable.
- Build ladders as `top + middle × N + bottom`. Match the rail centerlines and let the middle segment repeat for any climb height.
- Tile floor centers horizontally and finish visible ends with the end-cap cell.
- Tile square wall modules without scaling. Mix plain variants before adding the moss or ivy accents.
- Assemble the east watchtower from shaft tiles. Insert window/slit cells at selected floors, cornice bands between major stages, and the parapet at the top. The tower kit deliberately contains no complete tower.
- Portal facades, NPCs, ladders, and collectible sprites remain separate scene nodes above the wall construction.

The original `01-village-square-platform-kit-v1.png` is retained as an art reference for its bridge, awning, cart, balcony, and bell-deck assets. Its complete stair and ladder regions are legacy-only; new layouts should use the modular atlases above.

