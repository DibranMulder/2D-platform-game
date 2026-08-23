# Buttoncap Biter — Runtime Sprite (v1)

Godot-ready sprite assets for the Buttoncap Biter hopping enemy. Source of truth
and full documentation: `art-source/sprites/buttoncap-biter/v1/`.

## Files

- `buttoncap-biter.png` — 1792x1024 atlas, eight 448x512 cells (4 cols x 2 rows).
- `buttoncap_biter_sprite_frames.tres` — `SpriteFrames` mapping cells to the
  `idle`, `hop`, `hurt`, and `defeated` animations.

## Usage

Attach the resource to an `AnimatedSprite2D`:

```gdscript
var biter := AnimatedSprite2D.new()
biter.sprite_frames = load(
    "res://assets/characters/buttoncap_biter/v1/buttoncap_biter_sprite_frames.tres"
)
biter.scale = Vector2(0.30, 0.30)   # ~110 px tall against the 1280x720 viewport
biter.play("idle")
add_child(biter)
```

Drive `hop` while patrolling, `hurt` on damage, and `defeated` on death. The art
is symmetric, so `flip_h` is optional when the enemy turns around.

Note: the checked-in `.png.import` uid/hash are placeholders — Godot rewrites
them on first import when the project is opened in the editor.
