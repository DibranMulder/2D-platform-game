//! Transport-free, fixed-point, server-authoritative world rules.
//!
//! The [`World`] owns every [`zone::Zone`] (one per map) and advances them on a
//! fixed 20 Hz tick from validated [`PlayerIntent`]. All positions are integers
//! in y-up world units (see [`fixed`]). Nothing here knows about sockets or
//! JSON; the `game-protocol` crate maps the snapshot types onto the wire.

#![forbid(unsafe_code)]

pub mod catalog;
pub mod combat;
pub mod entity;
pub mod enemy;
pub mod fixed;
pub mod geometry;
pub mod hero;
pub mod intent;
pub mod projectile;
pub mod world;
pub mod zone;

pub use catalog::ZoneCatalog;
pub use combat::ProjectileKind;
pub use entity::{
    EnemySnapshot, EntityId, EntitySnapshot, HeroSnapshot, ProjectileSnapshot, ZoneSnapshot,
};
pub use fixed::WORLD_UNITS_PER_PIXEL;
pub use geometry::{
    Allegiance, BUTTONCAP_HOLLOW, EnemyKind, MOONLIT_MARKET, SUNLIT_FOREST, THE_GAUNTLET, ZoneId,
    zone_by_slug, zone_slug,
};
pub use hero::{Hero, HeroDescriptor, WeaponId};
pub use intent::{IntentError, JoinError, PlayerIntent, WeaponSelect};
pub use world::{TickOutcome, World, ZoneTransfer};

/// Stable identity of a connected player, assigned by the identity tier.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct PlayerId(u64);

impl PlayerId {
    pub const fn new(value: u64) -> Self {
        Self(value)
    }

    pub const fn get(self) -> u64 {
        self.0
    }
}
