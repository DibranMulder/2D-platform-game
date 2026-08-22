---
id: DESIGN-0004
title: Delivery roadmap
status: proposed
updated: 2026-08-22
---

# Delivery roadmap

Each milestone is a playable vertical slice with an exit condition. Creative
work can begin in parallel after the foundation without coupling lore to
transport or persistence.

| Milestone | Slice | Exit condition |
| --- | --- | --- |
| 0. Foundation | Cross-platform debug client, authoritative movement server, protocol, tests, design records | Two local clients see the same server-owned movement |
| 1. Traversal | Tile collision, ladders, portals, client prediction/reconciliation, touch controls | Representative Zone plays well at target latency on desktop and tablet |
| 2. Identity | Accounts, Characters, Session admission, reconnect, persistence | Character state survives restart and cannot be claimed by another Account |
| 3. Combat | Abilities, creatures, loot, cooldowns, lag rules | Complete server-authoritative encounter with exploit tests |
| 4. Progression | Independent Progression Skills, equipment requirements, content rewards | One gathering-to-crafting-to-combat loop is durable and balanced enough to test |
| 5. Social conflict | Parties, clans, reputation, eligible conflict, death consequences | Consequential conflict loop works without trivial griefing exploits |
| 6. World scale | Zone handoff, instancing, chat/moderation, observability, load tests | Measured concurrency target passes soak and recovery tests |
| 7. Distribution | Steamworks adapter, store builds, signing, patching, crash reporting | Certified builds install, update, authenticate, and recover on every target |

## Decisions needed before Milestone 1 closes

- Minimum supported devices and graphics tiers.
- Camera composition, coordinate scale, and target on-screen player count.
- Keyboard/controller/touch interaction principles.
- Target regions and latency envelope.
- Whether combat is twitch, tab-targeted, or a deliberate hybrid.

## Change log

- 2026-08-22: Initial milestone sequence proposed.

