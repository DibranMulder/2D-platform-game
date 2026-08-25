# Hometown tutorial illustration set — v1

Ten text-free, input-agnostic sprites for the first-visit hometown tutorial.
The image carries the idea; Godot should layer localized copy and the active
keyboard, controller, or touch glyph separately.

| Step | Texture | Completion event | Starter item |
| --- | --- | --- | --- |
| Move | `01-move.png` | `hero_moved` | Leather Boots |
| Jump | `02-jump.png` | `hero_jumped` | Dried Rations |
| Loot | `03-loot.png` | `loot_collected` | Crag Ore |
| Consume potion | `04-consume-potion.png` | `item_consumed` | Redleaf Potion |
| Equip armor | `05-equip-armor.png` | `armor_equipped` | Traveler Tunic |
| Equip weapon | `06-equip-weapon.png` | `weapon_equipped` | Rusty Sword |
| Basic combat | `07-basic-combat.png` | `attack_guard_completed` | Driftwood Buckler |
| Combat skill | `08-combat-skill.png` | `combat_skill_used` | Sky Feather |
| Disciplines | `09-disciplines.png` | `disciplines_opened` | Frog Pearl |
| Talent Tree | `10-talent-tree.png` | `talent_unlocked` | Bronze Helm |

Runtime data lives in `res://data/tutorial.json` and is loaded through
`GameTutorialCatalog`. The starter kit deliberately reuses ten real entries from
the main item catalogue; it does not introduce a second source of item truth.

## Rendering notes

- Preserve alpha and render with `expand_mode = EXPAND_IGNORE_SIZE` plus
  `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED` in a `TextureRect`.
- Recommended display size is 96–160 px. The high-resolution PNGs are retained
  as source-quality runtime assets so platform-specific import settings can set
  their texture size and compression without another art pass.
- Put the sprites on Chronicle parchment or night-glass panels. Their loose cyan,
  gold, or teal glows are designed for both surfaces.
- Never bake key names into the PNGs. Pair them with the current input-map glyph.

## Generation provenance

Generated with the built-in ImageGen workflow. Shared prompt direction:

> Polished hand-painted fantasy game tutorial UI sprite, crisp dark ink outline,
> gentle storybook-anime influence, readable at 96 px, centered compact subject,
> strong silhouette and genuinely transparent background. Match the existing
> item atlas and Enchanted Chronicle palette. No frame, text, keys, controllers,
> logos, or watermark.

The ten subject prompts were: worn boots following a two-way path; one boot
jumping a mossy ledge; an open satchel receiving a coin, potion, and crystal; a
tilted Redleaf Potion with a healing-heart swirl; starter armor snapping into its
slot silhouette; the Roadworn Blade snapping into its Main Hand silhouette; a
sword meeting a driftwood buckler; a sword releasing a controlled skill wave; an
open chronicle presenting Martial, Mystic, and World emblems; and a sword-rooted,
three-branch Talent graph. The weapon-equip image received one background-only
extraction pass to replace a baked checkerboard with genuine alpha.

Validate the data and texture imports from the repository root:

```sh
godot --headless --path client --script res://scripts/tutorial_catalog_smoke.gd
```
