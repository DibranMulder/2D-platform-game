# 2D Platform MMORPG Foundation

This repository contains the first architecture slice for a cross-platform,
side-scrolling MMORPG. It intentionally uses neutral debug art until the races,
world, and visual language are defined.

## What runs today

- A local account and Hero onboarding prototype with eight Lineages under
  `client/prototypes/onboarding/`.
- A static Godot 4 combat prototype under `client/prototypes/combat_arena/`.
- In-combat Item Pouch, Equipment, Discipline Level, and Hero-specific Talent
  Tree panels with inspectable in-memory state.
- A private, searchable Item Chronicle for reviewing item art, metadata, balance,
  paper-doll compatibility, and hidden-item status.
- The earlier network client foundation under `client/scenes/`.
- A Rust world server under `apps/world-server/`.
- A deterministic, fixed-tick game simulation under `crates/game-domain/`.
- A versioned wire contract under `crates/game-protocol/`.
- Architecture, terminology, security, and roadmap records under `docs/`.

The server owns movement and collision truth. The client sends intent only and
renders server snapshots.

## Run locally

Requirements: Rust 1.85+ and Godot 4.4+.

```sh
cargo run -p world-server
```

The current Godot main scene is the local onboarding prototype. Create or log in
to an in-memory Account, create a Hero, and select **Enter World** to open the
combat arena. It runs without the server:

```sh
godot --path client
```

To exercise the earlier multiplayer foundation instead, open
`client/scenes/main.tscn` in the editor while the server is running.

## Item Chronicle

Open the private catalogue at
[The Enchanted Archive · Item Chronicle](https://enchanted-archive-items.caesar-groep-1154.chatgpt.site).
It contains the current equipment, consumables, and crafting materials with
search and filters. Review status, curator notes, and hidden-item flags are
stored in its private database.

Godot reads the canonical item definitions from
[`client/data/items.json`](client/data/items.json). The hosted catalogue uses
the deployable snapshot at
[`apps/item-catalog/content/items.json`](apps/item-catalog/content/items.json);
update that snapshot whenever the canonical records change.

The Human equipment renderer is structured as a layered paper doll: body,
hair, armor, shoes, headwear, cape, off-hand, and main-hand visuals share one
animation clock. One-handed weapons may be combined with a shield; two-handed
weapons reserve both hands.

Run the catalogue locally with:

```sh
cd apps/item-catalog
npm install
npm run dev
```

The local onboarding state smoke test is:

```sh
godot --headless --path client \
  --script res://prototypes/onboarding/onboarding_state_smoke.gd
```

```sh
cargo test --workspace
cargo fmt --all --check
cargo clippy --workspace --all-targets -- -D warnings
```

## Design index

Start at [docs/design/README.md](docs/design/README.md). Domain language lives in
[CONTEXT.md](CONTEXT.md), while durable decisions live in [docs/adr](docs/adr).

This is an architecture foundation, not a production-ready MMO backend. Auth,
persistence, content streaming, moderation, live operations, sharding, and
production anti-cheat telemetry are deliberately staged in the roadmap.
