//! Entity identity and the transport-free snapshot types the simulation emits.
//! [`crate::game_protocol`-side code](crate) maps these to the JSON wire shapes.

use crate::combat::ProjectileKind;
use crate::geometry::{EnemyKind, ZoneId};
use crate::hero::WeaponId;
use crate::PlayerId;

/// Identifies any entity within a zone. Heroes derive theirs from `PlayerId`;
/// enemies and projectiles draw from a per-zone counter.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct EntityId(pub u64);

/// A hero's renderable + authoritative state at a tick.
#[derive(Clone, Debug, PartialEq)]
pub struct HeroSnapshot {
    pub entity_id: EntityId,
    pub player_id: PlayerId,
    pub hero_name: String,
    pub lineage: String,
    pub weapon: WeaponId,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub velocity_y: i32,
    pub facing: i8,
    pub grounded: bool,
    pub climbing: bool,
    pub health: i32,
    pub max_health: i32,
    /// 0..=100.
    pub stamina: i32,
    /// 0..=100.
    pub mana: i32,
    pub action_state: &'static str,
    pub last_processed_intent: u64,
}

#[derive(Clone, Debug, PartialEq)]
pub struct EnemySnapshot {
    pub entity_id: EntityId,
    pub kind: EnemyKind,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub velocity_y: i32,
    pub facing: i8,
    pub health: i32,
    pub max_health: i32,
    pub ai_state: &'static str,
    pub telegraph_ticks: u16,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ProjectileSnapshot {
    pub entity_id: EntityId,
    pub owner: PlayerId,
    pub kind: ProjectileKind,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub facing: i8,
}

#[derive(Clone, Debug, PartialEq)]
pub enum EntitySnapshot {
    Hero(HeroSnapshot),
    Enemy(EnemySnapshot),
    Projectile(ProjectileSnapshot),
}

/// The full observable state of one zone at a tick.
#[derive(Clone, Debug, PartialEq)]
pub struct ZoneSnapshot {
    pub zone: ZoneId,
    pub server_tick: u64,
    pub entities: Vec<EntitySnapshot>,
}
