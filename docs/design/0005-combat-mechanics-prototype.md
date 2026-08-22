---
id: DESIGN-0005
title: Combat mechanics prototype
status: exploring
updated: 2026-08-22
---

# Combat mechanics prototype

## Question

Does a keyboard-and-touch side-scrolling combat loop—move, jump, Sword Attack,
Guard, and four hotbar Combat Skills—feel readable enough to become the basis
of the first online traversal and combat slice?

The implementation under `client/prototypes/combat_arena/` is deliberately
throwaway. It has no networking or persistence and should not be promoted to
production unchanged.

## Encounter

- The Hero spawns on the left side of one bounded platform with a sword.
- One horned Monster spawns on the right, approaches, telegraphs a melee attack,
  and attacks until either combatant reaches zero health.
- The Hero has health and stamina. Guard mitigates frontal damage and consumes
  stamina; stamina recovers while Guard is released.
- A restart action immediately resets the encounter.

## Controls under evaluation

| Purpose | Keyboard | Touch |
| --- | --- | --- |
| Move | Left/Right arrows; A/D secondary | Drag the left movement knob |
| Jump | Space or Up arrow | Jump action button; upward knob flick |
| Sword Attack | `1` | Attack action button |
| Guard | Hold `2` or Shift | Hold Guard action button |
| Power Strike | `3` | Skill button 3 |
| Whirlwind | `4` | Skill button 4 |
| Lunge | `5` | Skill button 5 |
| Second Wind | `6` | Skill button 6 |
| Restart | `R` | Restart button after victory/defeat |

The numbered action bar follows the familiar MMO convention where abilities
are activated by their numbered slot or by clicking/tapping the slot. Blizzard's
[official introduction to WoW combat](https://worldofwarcraft.blizzard.com/en-us/news/20151231)
describes this interaction. Side-scrolling arrows remain primary because the
movement model is not WoW's camera-relative 3D movement.

## Prototype values

| Action | Effect | Cooldown |
| --- | --- | --- |
| Sword Attack | 14 damage, short frontal reach | 0.45 s |
| Guard | 70% frontal mitigation, 18 stamina per hit | Held |
| Power Strike | 32 damage, long recovery | 3.0 s |
| Whirlwind | 22 damage in either direction | 5.0 s |
| Lunge | Forward burst plus 18 damage | 4.0 s |
| Second Wind | Restore 30 health | 12.0 s |

These numbers exist only to expose timing and feedback. They are not balance
commitments.

## Evaluation prompts

- Should Jump remain a separate Basic Move button on touch, or only use an
  upward knob flick?
- Is held Guard more satisfying than a timed parry window?
- Should Sword Attack occupy hotbar slot 1 or have a permanent dedicated button?
- Does Lunge create useful positioning, or undermine platform traversal?
- How many visible Combat Skills fit comfortably on a phone without hiding play?
- Should taking damage interrupt attacks, movement, both, or neither?

## Validation log

| Check | Result | Date |
| --- | --- | --- |
| Godot 4.7.1 project import and script parse | Passed without errors | 2026-08-22 |
| macOS GPU render using Metal on Apple M1 | Five-frame visual capture passed | 2026-08-22 |
| Fixed-time encounter simulation | 1,200 frames / 20 game-seconds passed without runtime errors | 2026-08-22 |
| Eight Lineage battle silhouettes | Pairwise-distinct rendered Hero regions verified through Metal | 2026-08-22 |
| Existing Rust workspace regression | Six tests passed | 2026-08-22 |
| Physical iPad/iPhone/Android touch feel | Not yet tested on device | — |

## Change log

- 2026-08-22: First static Hero-versus-Monster arena specified, implemented,
  rendered on Metal, and smoke-tested.
- 2026-08-22: Connected selected Lineage data to eight distinct procedural
  battle silhouettes without changing the shared combat collider or rules.
