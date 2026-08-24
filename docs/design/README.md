# Design Record Index

Every design record has a status and is expected to change through review. The
records separate settled constraints from later creative decisions so races,
themes, and content can be added without reshaping the runtime.

| Record | Status | Purpose |
| --- | --- | --- |
| [Product constraints](0001-product-constraints.md) | Accepted foundation | Scope and non-negotiable platform qualities |
| [System architecture](0002-system-architecture.md) | Accepted foundation | Runtime shape, module seams, and data flow |
| [Security and anti-cheat](0003-security-and-anti-cheat.md) | Initial threat model | Trust model, controls, and staged protections |
| [Delivery roadmap](0004-delivery-roadmap.md) | Proposed | Thin vertical slices toward production |
| [Combat mechanics prototype](0005-combat-mechanics-prototype.md) | Exploring | Static arena controls, moves, skills, and evaluation questions |
| [Account and hero onboarding](0006-account-and-hero-onboarding.md) | Exploring | Account flow, naming rules, and eight playable Lineages |
| [Progression, Talents, and equipment](0007-progression-talents-and-equipment.md) | Exploring | Generic Discipline levels, Hero-specific Talent Trees, Item Pouch, and equipment |
| [Playable Lineage art direction](0008-playable-lineage-art-direction.md) | Exploring | Designer handoff for silhouettes, materials, palettes, movement, and Homelands |
| [Exchange and Lineage Strongholds](0009-exchange-and-strongholds.md) | Proposed | Central player market, protected Strongholds, open Outer Villages, and Guardian rules |
| [Interactive world map](0010-interactive-world-map.md) | Exploring | Eight Homelands, four Frontiers, Dungeon Sites, routes, access, and three interactive layouts |
| [Creature roster](0011-creature-roster.md) | Exploring | Level 1–120 creatures by Homeland biome, dispositions, and named low-level foes |
| [Combat classes and equipment tiers](0012-combat-classes-and-equipment-tiers.md) | Exploring | Six Combat Classes, weapon families, armor slots, and 12 equipment tiers |
| [Class talent trees](0013-class-talent-trees.md) | Exploring | Three talent branches per Combat Class and baseline Class actions |
| [Home-town maps](0014-hometown-maps.md) | Exploring | Per-Lineage Outer Village + Stronghold + Story Site clusters, NPC template, and art prompts |
| [World map layout](0015-world-map-layout.md) | Exploring | Light/Dark halves, neutral Frontier seam, the City of Babylon and Tower, and the featured dungeon |

Durable decisions whose reversal would be expensive are recorded separately in
[`docs/adr`](../adr/). Project-specific terminology is defined in
[`CONTEXT.md`](../../CONTEXT.md).

## Update rule

When a requirement changes, update its design record and add a dated entry to
the record's change log. If the change reverses an ADR, add a superseding ADR;
do not rewrite history.
