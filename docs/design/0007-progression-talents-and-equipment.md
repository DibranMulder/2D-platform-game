---
id: DESIGN-0007
title: Progression, Talents, and equipment
status: exploring
updated: 2026-08-22
---

# Progression, Talents, and equipment

## Question

Does a system of universally available RuneScape-inspired Disciplines, a
derived Overall Level, and Hero-specific Talent allocation create satisfying
long-term breadth without erasing individual Hero builds?

The interactive implementation is a local prototype. Training buttons simulate
server-awarded XP so the formulas, equipment movement, and Talent prerequisites
can be inspected quickly.

## Canonical progression model

Each Hero owns XP and levels in the same twelve **Disciplines**. “Generic” means
the catalog and formulas apply to every Lineage and future Combat Class; levels
are not Account-wide in this proposal. Each Discipline begins at level 1 and is
capped at 99.

| Family | Discipline | Primary meaning |
| --- | --- | --- |
| Martial | Attack | Weapon control, accuracy, and weapon requirements |
| Martial | Strength | Physical force, melee output, and carrying power |
| Martial | Defense | Armor use, mitigation, and Guard stability |
| Martial | Agility | Traversal, attack recovery, evasion, and air control |
| Martial | Stamina | Health, endurance, sprinting, and sustained Guard |
| Mystic | Focus | Resource control, concentration, and ability reliability |
| Mystic | Willpower | Resistance to fear, control, corruption, and interruption |
| Mystic | Arcana | Understanding and shaping supernatural effects |
| World | Survival | Food, recovery, hazards, tracking, and fieldcraft |
| World | Gathering | Harvesting natural and magical resources |
| World | Crafting | Producing, repairing, and improving items |
| World | Exploration | Discovering routes, secrets, portals, and distant places |

Precision is derived from Attack plus Agility rather than becoming a thirteenth
Discipline. Health is derived primarily from Stamina. These derived values avoid
creating nearly synonymous XP tracks.

## Level formulas

For Discipline level `L`, where `1 ≤ L ≤ 99`, the cumulative XP threshold is:

```text
XP(L) = 75 × (L - 1)² + 25 × (L - 1)
```

The curve is deliberately easy to inspect in the prototype and should be tuned
against real session length before production.

```text
Total Level   = sum of all 12 Discipline levels
Overall Level = floor(Total Level ÷ 12), capped at 99
Talent Points earned = Overall Level - 1
Unspent Talent Points = earned - points committed to Talents
```

Using the floor of the average makes Overall Level understandable and rewards a
broad Hero: repeatedly training only one easy Discipline cannot carry the whole
Overall Level. Every increase remains valuable because it advances Total Level,
even when the average has not yet crossed the next integer.

## Hero-specific Talent Tree

Talent allocation belongs to one Hero. Another Hero on the same Account has its
own points and choices even though both use the same generic Disciplines.

The first visible tree has three sword-prototype branches:

| Branch | Identity | Example path |
| --- | --- | --- |
| Blade | Direct offense | Keen Edge → Decisive Blow → Sweeping Arc → Executioner |
| Guardian | Guard and counterplay | Firm Guard → Counterstance → Iron Wall → Last Stand |
| Wayfarer | Traversal and sustain | Fleet Step → Aerial Control → Relentless Lunge → Renewing Wind |

Nodes require an Overall Level, a prerequisite Talent, and one or more Talent
Points. The sword tree is only a mechanics scaffold; later trees may derive
from Combat Class, Lineage, weapon mastery, or a combination after those seams
are designed.

## Item Pouch and equipment proposal

- The Item Pouch begins with 24 slots; stack limits remain item-specific.
- Equipped items do not occupy Item Pouch slots.
- Prototype Equipment Slots are Head, Shoulders, Chest, Hands, Main Hand, Off
  Hand, Legs, Feet, Neck, Ring, Cape, and Relic.
- Equipping from the Item Pouch moves the previous item in that Equipment Slot
  back to the first free pouch slot as one atomic operation.
- Unequipping requires one free pouch slot.
- The Bank, trading, durability, binding, weight, loadouts, and item requirements
  are intentionally deferred.

The server must eventually own all item moves and validate them atomically;
client UI only requests a move and renders the result.

## Weapon and Shield vocabulary

Weapon Family and Grip are separate properties. Family determines the shared
handling, animation, and future progression vocabulary; Grip determines whether
the other hand remains available. This avoids treating one- and two-handed
versions of the same weapon as unrelated concepts.

| Weapon Family | Supported Grip | Working examples |
| --- | --- | --- |
| Sword | One-Handed, Two-Handed | Arming sword, greatsword |
| Axe | One-Handed, Two-Handed | Hand axe, greataxe |
| Spear | One-Handed, Two-Handed | Shield spear, long spear |
| Polearm | Two-Handed | Glaive, halberd |
| Crossbow | Two-Handed | Crossbow |
| Bow | Two-Handed | Shortbow, longbow |
| Wand | One-Handed | Wand |
| Staff | Two-Handed | Combat or magical staff |
| Dagger | One-Handed | Dagger |
| Blunt | One-Handed, Two-Handed | Mace, club, hammer, maul |

A Shield is off-hand Combat Equipment rather than a Weapon Family. Any
One-Handed Weapon may be equipped with a Shield when the Hero's Combat Class
permits Shields; it may also be used with an empty off hand. Equipping a
Two-Handed Weapon reserves both hands and excludes a Shield.

Dual Wield is approved specifically for the Duelist Combat Class. A Duelist may
equip one permitted One-Handed Weapon in Main Hand and another in Off Hand. This
does not grant dual wielding to other Combat Classes, and an Off-Hand Weapon and
a Shield remain mutually exclusive.

The prototype's `rusty_sword` is a One-Handed Sword and its
`driftwood_buckler` is a Shield. Other families are approved gameplay vocabulary
but still need named item definitions and combat behavior before implementation.

## Prototype boundary

The current implementation keeps a separate in-memory profile for each selected
Hero name during the running client session. Equipment bonuses and purchased
Talent effects are not yet applied to combat calculations; this slice validates
the information hierarchy, progression math, prerequisites, and item movement
before those rules move into the authoritative simulation.

## Evaluation prompts

- Should Overall Level use all twelve Disciplines equally, or only a Hero's best
  Disciplines so specialists are not forced into Crafting and Gathering?
- Is one Talent Point per Overall Level too generous for the intended tree size?
- Should respecialization be free, time-gated, currency-gated, or unavailable?
- Does each Combat Class own one tree, or does every Hero combine Lineage,
  Combat Class, and weapon trees?
- Are pouch slots sufficient, or is weight also strategically important?
- Should equipment change appearance immediately when the final art system exists?

## Validation log

| Check | Result | Date |
| --- | --- | --- |
| Initial aggregate | Total Level 93, Overall Level 7, six unspent Talent Points | 2026-08-22 |
| Combined progression | +1,500 XP to all Disciplines advanced Overall Level to 8 | 2026-08-22 |
| Talent prerequisite | Tier-two purchase rejected without level and prerequisite | 2026-08-22 |
| Root Talent purchase | Point deducted and node marked unlocked | 2026-08-22 |
| Pouch/equipment swap | Bronze Helm equipped and unequipped atomically | 2026-08-22 |
| Four panel layouts | Pouch, Equipment, Disciplines, and Talent Tree rendered through Metal | 2026-08-22 |

## Change log

- 2026-08-22: Initial twelve-Discipline model, formulas, sword Talent Tree,
  Item Pouch, Equipment Slots, interactive panels, and state verification completed.
