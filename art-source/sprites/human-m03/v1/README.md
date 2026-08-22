# Human M03 Gameplay Sprite Prototype — v1

This is the first sprite-scale validation set derived from the approved Human
M03 turnaround. It is intentionally limited to the Human sword-and-shield
loadout so scale, animation timing, readability, and Godot integration can be
validated before other Lineages or Weapon Families are produced.

## Source sheets

All sheets are 1536x1024 RGBA PNGs with eight poses arranged four columns by two
rows. They preserve the larger painted source before runtime frame normalization.

- `run.png`: eight-frame run cycle
- `core-actions.png`: idle A, idle B, jump takeoff, jump rise, fall, land, hurt,
  defeated
- `combat-interaction.png`: ready, attack windup, early slash, extended slash,
  follow-through, recovery, shield block, portal entry

## Runtime output

Godot-ready atlases are stored under
`client/assets/characters/human_m03/v1/`. Runtime cells are normalized to
448x512 with transparent padding, a common standing baseline, and intact source
resolution. `human_m03_sprite_frames.tres` maps those cells into named
animations.

The `AnimatedSprite2D` displays at scale `0.30`, yielding an approximately
100-pixel-tall hero against the 1280x720 gameplay viewport. Art faces right and
is flipped horizontally in Godot when the character faces left.

## Animation map

| Animation | Frames | Loop | Speed |
| --- | ---: | --- | ---: |
| `idle` | 2 | yes | 2 fps |
| `ready` | 1 | yes | 1 fps |
| `run` | 8 | yes | 10 fps |
| `jump` | 2 | no | 8 fps |
| `fall` | 1 | yes | 1 fps |
| `land` | 1 | no | 1 fps |
| `attack` | 5 | no | 12 fps |
| `block` | 1 | yes | 1 fps |
| `hurt` | 1 | no | 1 fps |
| `defeated` | 1 | no | 1 fps |
| `portal` | 1 | no | 1 fps |

## Generation and cleanup

- Built-in image generation mode: `stylized-concept`
- Identity authority: `art-source/concepts/lineage-turnarounds/v1/humans.png`
- Style authority: `art-source/style-references/cinematic-storybook-anime-v1.png`
- Backgrounds were converted to real alpha after generation and verified as
  RGBA rather than retaining a baked checkerboard or ivory field.

The next review gate is the running game: confirm displayed scale, silhouette
clarity, cape motion, weapon reach, foot stability, and collision alignment.
