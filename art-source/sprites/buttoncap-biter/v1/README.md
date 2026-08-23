# Buttoncap Biter Enemy Sprite — v1

First gameplay-scale sprite set for the **Buttoncap Biter**, a low-level hopping
enemy from the `levels-01-05` monster tier. It is a purple, round-bodied fungus
gremlin that wears a spotted mushroom cap and travels by bouncing on a single
coiled spring leg — a natural fit for a patrolling / hopping platformer enemy.

Identity authority: `apps/item-catalog/public/monsters/levels-01-05/buttoncap-biter.png`

## Source sheet

`buttoncap-biter.png` is a 1792x1024 RGBA PNG holding eight poses arranged four
columns by two rows. Cells are 448x512 with transparent padding and a shared
standing baseline, matching the `human_m03` runtime-cell convention so the sheet
drops straight into a Godot `SpriteFrames` resource with no re-slicing.

| Cell | Pose | Used by |
| ---: | --- | --- |
| 0 | idle A (settled) | `idle` |
| 1 | idle B (breathe / squash) | `idle` |
| 2 | hop crouch (spring compressed) | `hop` |
| 3 | hop launch (stretched, mouth open) | `hop` |
| 4 | hop airborne | `hop` |
| 5 | hop land (impact squash) | `hop` |
| 6 | hurt | `hurt` |
| 7 | defeated (flattened) | `defeated` |

## Runtime output

Godot-ready copy and the `SpriteFrames` resource live under
`client/assets/characters/buttoncap_biter/v1/`. Art faces the viewer and is
symmetric, so no horizontal flip is required when the enemy reverses its patrol
direction (flip is still safe if desired). Recommended display scale is `0.30`
against the 1280x720 gameplay viewport, giving an enemy roughly 110 px tall —
shorter than the ~100 px hero but visually chunkier.

## Animation map

| Animation | Frames | Loop | Speed | Notes |
| --- | ---: | --- | ---: | --- |
| `idle` | 2 | yes | 2 fps | gentle breathing bob |
| `hop` | 4 | yes | 9 fps | crouch → launch → air → land movement cycle |
| `hurt` | 1 | no | 1 fps | tilt + X eyes, play on taking damage |
| `defeated` | 1 | no | 1 fps | flattened, play on death |

## Generation

- Rendering: procedural, supersampled cartoon vectors via `generate.py`
  (Pillow). Re-run to regenerate the sheet:
  `python generate.py buttoncap-biter.png`
- Palette and silhouette derived from the approved concept art listed above:
  spotted tan cap, purple body, orange eyes, toothy grin, coiled spring leg.

The next review gate is the running game: confirm displayed scale against the
hero, silhouette clarity at gameplay distance, spring-bounce timing, and
collision-box alignment for the round body versus the spring foot.
