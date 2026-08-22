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
