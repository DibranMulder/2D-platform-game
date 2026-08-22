# Human M03 Runtime Sprite

This folder contains the Godot-ready Human M03 sword-and-shield animation
prototype. The normal game flow activates it after a player creates or selects
a Human Hero and enters the combat arena.

## Fastest gameplay test

From the repository root, launch the combat arena directly:

```sh
godot --path client \
  --scene res://prototypes/combat_arena/combat_arena.tscn
```

The direct arena uses a Human with the sword loadout by default.

- Move: `A`/`D` or Left/Right
- Jump: `Space`
- Basic sword attack: `1`
- Hold shield block: `2` or `Shift`
- Additional sword skills: `3`, `4`, and `5`
- Cycle weapons: `Tab`

Switching away from the sword deliberately returns the Human to the procedural
prototype art because only the sword-and-shield sprite set exists. Switching
back to the sword restores the M03 animation set. Other Lineages retain their
procedural silhouettes during this Human-only validation pass.

## Full player-flow test

Run the project normally:

```sh
godot --path client
```

Use the local demo account (`demo@realm.test` / `123`), create a Human Hero,
select it from the roster, and enter the world. The Human sprite should appear
in the first combat arena.

## Runtime contract

- Display scale: `0.30`, approximately 100 pixels tall at 1280x720
- Source orientation: right-facing; `flip_h` handles left-facing movement
- Character origin: feet aligned to the `CharacterBody2D` ground origin
- Collision: existing 38x74 capsule remains authoritative
- Animations: `idle`, `ready`, `run`, `jump`, `fall`, `land`, `attack`, `block`,
  `hurt`, `defeated`, and `portal`
- Painted sprites use linear filtering and genuine RGBA transparency

Validate the integration without rendering a window:

```sh
godot --headless --path client \
  --script res://prototypes/combat_arena/human_sprite_smoke.gd
```
