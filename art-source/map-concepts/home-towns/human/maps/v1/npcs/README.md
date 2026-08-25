# Village Square NPC artwork v1

These are standalone idle characters and six-frame personality loops for the interactive NPCs instantiated in Wendmere Village Square. Every file is RGBA with genuine transparency and a shared right-facing three-quarter presentation.

## Assets and runtime roles

- `01-village-square-exchange-broker-idle-v1.png` — runtime NPC id `exchange_broker`; friendly market interface character carrying a closed ledger.
- `01-village-square-herald-idle-v1.png` — runtime NPC id `lorekeeper`; the Herald of Wendmere and Princess's Tower quest-giver.
- `01-village-square-gate-sentry-idle-v1.png` — runtime NPC id `sentry`; reuse or mirror for the road Gate Sentry and elevated Watch Sentry.

## Animation sheets

| File | Grid | Cell size | Loop character |
|---|---:|---:|---|
| `01-village-square-exchange-broker-idle-talk-v1.png` | 3×2 | 512×512 | Breathes, blinks, checks the ledger, then explains with one hand |
| `01-village-square-herald-idle-talk-v1.png` | 3×2 | 342×768 | Breathes, nods, lifts the scroll, then tells the story |
| `01-village-square-gate-sentry-idle-greet-v1.png` | 3×2 | 342×768 | Breathes, glances over, and gives a restrained greeting |

Frames read left-to-right and then top-to-bottom. For ambient idling, play frames 1–3 around 3–4 fps with a randomized pause between loops. Play frames 4–6 around 4–6 fps while the conversation UI is open, then return to frame 1. Keep the sentry's spear and every character's feet anchored when defining frame offsets.

The artwork uses the Human M03 proportions and the hometown palette: royal blue, warm ivory, muted gold, oxblood accents, and brown leather. The single idle images remain useful for portraits, loading, and static fallbacks. Keep nameplates, interaction prompts, quest markers, dialogue state, and collision shapes in runtime UI/data.

All six character assets were checked over a dark background. Their alpha channels span transparent to opaque without baked checkerboards.
