# 2D Platform MMORPG Foundation

This repository contains the first architecture slice for a cross-platform,
side-scrolling MMORPG. It intentionally uses neutral debug art until the races,
world, and visual language are defined.

## What runs today

- A static Godot 4 combat prototype under `client/prototypes/combat_arena/`.
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

The current Godot main scene is the offline combat prototype, so it can be run
without the server:

```sh
godot --path client
```

To exercise the earlier multiplayer foundation instead, open
`client/scenes/main.tscn` in the editor while the server is running.

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
