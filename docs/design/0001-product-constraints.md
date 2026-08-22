---
id: DESIGN-0001
title: Product constraints
status: accepted-foundation
updated: 2026-08-22
---

# Product constraints

## Confirmed direction

- A persistent, side-scrolling 2D MMORPG with platforming traversal.
- The eventual creative direction combines the high-fantasy strategy character
  of *Age of Wonders* with the wonder and mythic portal-fantasy character of
  *Narnia*. This is an inspiration boundary, not permission to reproduce either
  property's protected names, characters, story, art, or music.
- Progression should take inspiration from RuneScape's independently trained
  skills, while conflict should take inspiration from Lineage II's consequential
  open-world, clan, and siege play. Exact rules remain unresolved.
- First-class targets are macOS, iPadOS/iOS, Windows, and Android. Windows and
  macOS are also the initial Steam targets.
- Rendering must use modern native GPU paths. The client uses Godot's Mobile
  renderer, whose RenderingDevice backend selects Vulkan, Direct3D 12, or Metal
  by platform. A compatibility renderer may later be offered as a lower-end
  fallback, but it is not the baseline.
- Gameplay is server-authoritative. A modified client must not be able to award
  itself movement, combat results, items, currency, or progression.

## Quality attributes

| Attribute | Foundation target | Production target is set when |
| --- | --- | --- |
| Simulation | Fixed 20 Hz authoritative tick | A representative combat prototype is profiled |
| Rendering | 60 FPS baseline on supported devices | Minimum device tiers are chosen |
| Network | Intent up, snapshots down | Real latency/loss tests select the final transport |
| Availability | Single local World Instance | Persistence and regional topology are designed |
| Security | Never trust client-authored outcomes | Identity, economy, and combat vertical slices exist |
| Accessibility | Keyboard and touch input seams | UX and control requirements are defined |

## Explicitly deferred

Races, classes, cultures, world cosmology, final art direction, monetization,
economy design, exact skill formulas, exact conflict rules, target concurrency,
regions, minimum hardware, and launch operations are not yet decided.

## Primary technical references

- [Godot renderer overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
  documents the Vulkan, Direct3D 12, and Metal RenderingDevice paths.
- [Godot export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)
  documents Windows, macOS, Android, and iOS packages.
- [Godot feature tags](https://docs.godotengine.org/en/stable/tutorials/export/feature_tags.html)
  provide the platform selection seam for store and device adapters.

## Change log

- 2026-08-22: Initial constraints captured from the project brief.
