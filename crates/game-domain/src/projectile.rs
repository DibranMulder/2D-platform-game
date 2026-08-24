//! Hero projectiles (arrows, bolts, sparks, orbs). Movement is a simple
//! horizontal sweep; hit resolution lives in [`crate::zone::Zone`] because it
//! needs the other entities.

use crate::combat::ProjectileKind;
use crate::entity::EntityId;
use crate::PlayerId;

/// How long a projectile lives before expiring (3 s at 20 Hz).
pub const PROJECTILE_LIFETIME: u16 = 60;
/// Vertical tolerance for a projectile hit (96 px).
pub const PROJECTILE_VERTICAL: i32 = 96 * 100;
/// Half-width of a projectile's hit box along x (34 px), used for the sweep.
pub const PROJECTILE_HALF_WIDTH: i32 = 34 * 100;

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Projectile {
    pub id: EntityId,
    pub owner: PlayerId,
    pub kind: ProjectileKind,
    pub pos_x: i32,
    pub pos_y: i32,
    pub vel_x: i32,
    pub facing: i8,
    pub damage: i32,
    pub remaining: u16,
    /// Set once the projectile has hit something or expired; the zone reaps it.
    pub spent: bool,
}

impl Projectile {
    /// Advance one tick. Returns the previous x so the zone can sweep the
    /// segment [prev_x, pos_x] for hits (projectiles move faster than a hit box).
    pub fn advance(&mut self, min_x: i32, max_x: i32) -> i32 {
        let prev_x = self.pos_x;
        self.pos_x += self.vel_x;
        self.remaining = self.remaining.saturating_sub(1);
        if self.remaining == 0 || self.pos_x < min_x || self.pos_x > max_x {
            self.spent = true;
        }
        prev_x
    }
}
