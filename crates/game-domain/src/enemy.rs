//! Server-authoritative enemies: the Sunlit Forest Monster and the Buttoncap
//! Hollow Biters, ported from `monster_controller.gd` / `buttoncap_biter.gd`.
//! Each advances one tick against the heroes currently in its zone and emits
//! [`DamageRequest`]s the zone applies.

use std::collections::BTreeMap;

use crate::entity::EntityId;
use crate::fixed::{GRAVITY, TERMINAL_FALL, accel_per_tick, move_toward, speed_per_tick};
use crate::geometry::{EnemyKind, EnemySpawn, ZoneGeometry};
use crate::hero::Hero;
use crate::PlayerId;

// Monster
const MONSTER_MAX_HEALTH: i32 = 120;
const MONSTER_MOVE: i32 = speed_per_tick(120); // 600
const MONSTER_REACH: i32 = 78 * 100; // 7_800
const MONSTER_HIT_REACH: i32 = (78 + 18) * 100; // 9_600
const MONSTER_VERTICAL: i32 = 90 * 100; // 9_000
const MONSTER_DAMAGE: i32 = 18;
const MONSTER_TELEGRAPH: u16 = 8; // ~0.42s
const MONSTER_ATTACK_COOLDOWN: u16 = 27; // 1.35s
const MONSTER_DEAD_DECEL: i32 = accel_per_tick(600); // 150
const MONSTER_STAGGER_DECEL: i32 = accel_per_tick(900); // 225

// Biter
const BITER_MAX_HEALTH: i32 = 40;
const BITER_HOP_VY: i32 = speed_per_tick(430); // 2_150 (up-positive)
const BITER_HOP_VX: i32 = speed_per_tick(92); // 460
const BITER_SETTLE_DECEL: i32 = accel_per_tick(420); // 105
const BITER_TOUCH_RANGE: i32 = 62 * 100; // 6_200
const BITER_TOUCH_DAMAGE: i32 = 9;
const BITER_HOP_INTERVAL: u16 = 21; // 1.05s
const BITER_TOUCH_COOLDOWN: u16 = 18; // 0.9s

const RESPAWN_TICKS: u16 = 60;

/// A hit an enemy wants to land on a hero this tick.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DamageRequest {
    pub target: PlayerId,
    pub amount: i32,
    pub attacker_x: i32,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Ai {
    Monster {
        attack_cooldown: u16,
        telegraph: u16,
        stagger: u16,
    },
    Biter {
        hop_timer: u16,
        touch_cooldown: u16,
    },
}

#[derive(Clone, Debug)]
pub struct Enemy {
    pub id: EntityId,
    pub kind: EnemyKind,
    pub pos_x: i32,
    pub pos_y: i32,
    pub vel_x: i32,
    pub vel_y: i32,
    pub facing: i8,
    pub grounded: bool,
    pub health: i32,
    pub max_health: i32,
    pub respawn_timer: u16,
    ai: Ai,
    spawn: EnemySpawn,
}

impl Enemy {
    pub fn from_spawn(id: EntityId, spawn: EnemySpawn) -> Self {
        let (max_health, ai) = match spawn.kind {
            EnemyKind::Monster => (
                MONSTER_MAX_HEALTH,
                Ai::Monster {
                    attack_cooldown: 16,
                    telegraph: 0,
                    stagger: 0,
                },
            ),
            EnemyKind::ButtoncapBiter => (
                BITER_MAX_HEALTH,
                Ai::Biter {
                    hop_timer: (id.0 as u16).wrapping_mul(7) % BITER_HOP_INTERVAL,
                    touch_cooldown: 0,
                },
            ),
        };
        Self {
            id,
            kind: spawn.kind,
            pos_x: spawn.x,
            pos_y: spawn.y,
            vel_x: 0,
            vel_y: 0,
            facing: spawn.facing,
            grounded: false,
            health: max_health,
            max_health,
            respawn_timer: 0,
            ai,
            spawn,
        }
    }

    pub fn is_alive(&self) -> bool {
        self.health > 0
    }

    pub fn receive_damage(&mut self, amount: i32) {
        if !self.is_alive() {
            return;
        }
        self.health = (self.health - amount).max(0);
        if self.health == 0 {
            self.respawn_timer = RESPAWN_TICKS;
        }
    }

    pub fn apply_stagger(&mut self, ticks: u16) {
        if let Ai::Monster { stagger, .. } = &mut self.ai {
            *stagger = (*stagger).max(ticks);
        }
    }

    /// Human-readable state for the wire (drives client animation).
    pub fn ai_state(&self) -> &'static str {
        if !self.is_alive() {
            return "defeated";
        }
        match self.ai {
            Ai::Monster {
                telegraph, stagger, ..
            } => {
                if stagger > 0 {
                    "staggered"
                } else if telegraph > 0 {
                    "winding_up"
                } else if self.vel_x != 0 {
                    "approaching"
                } else {
                    "watching"
                }
            }
            Ai::Biter { .. } => {
                if self.grounded {
                    "patrolling"
                } else {
                    "hopping"
                }
            }
        }
    }

    pub fn telegraph_ticks(&self) -> u16 {
        match self.ai {
            Ai::Monster { telegraph, .. } => telegraph,
            Ai::Biter { .. } => 0,
        }
    }

    pub fn advance(
        &mut self,
        heroes: &BTreeMap<PlayerId, Hero>,
        geom: &ZoneGeometry,
    ) -> Vec<DamageRequest> {
        if !self.is_alive() {
            self.respawn_timer = self.respawn_timer.saturating_sub(1);
            if self.respawn_timer == 0 {
                self.reset();
            } else {
                self.apply_gravity_and_land(geom);
            }
            return Vec::new();
        }
        match self.kind {
            EnemyKind::Monster => self.advance_monster(heroes, geom),
            EnemyKind::ButtoncapBiter => self.advance_biter(heroes, geom),
        }
    }

    fn advance_monster(
        &mut self,
        heroes: &BTreeMap<PlayerId, Hero>,
        geom: &ZoneGeometry,
    ) -> Vec<DamageRequest> {
        let mut damage = Vec::new();
        let Ai::Monster {
            attack_cooldown,
            telegraph,
            stagger,
        } = &mut self.ai
        else {
            unreachable!("monster kind carries monster ai");
        };
        *attack_cooldown = attack_cooldown.saturating_sub(1);
        *stagger = stagger.saturating_sub(1);

        let target = nearest_living_hero(heroes, self.pos_x);
        if *stagger > 0 {
            self.vel_x = move_toward(self.vel_x, 0, MONSTER_STAGGER_DECEL);
        } else if *telegraph > 0 {
            self.vel_x = 0;
            *telegraph -= 1;
            if *telegraph == 0 {
                // Resolve the attack against the still-nearest hero.
                if let Some((target_id, tx, ty)) = target {
                    if (tx - self.pos_x).abs() <= MONSTER_HIT_REACH
                        && (ty - self.pos_y).abs() <= MONSTER_VERTICAL
                    {
                        damage.push(DamageRequest {
                            target: target_id,
                            amount: MONSTER_DAMAGE,
                            attacker_x: self.pos_x,
                        });
                    }
                }
                *attack_cooldown = MONSTER_ATTACK_COOLDOWN;
            }
        } else if let Some((_, tx, _)) = target {
            self.facing = (tx - self.pos_x).signum() as i8;
            if self.facing == 0 {
                self.facing = 1;
            }
            if (tx - self.pos_x).abs() > MONSTER_REACH {
                self.vel_x = self.facing as i32 * MONSTER_MOVE;
            } else {
                self.vel_x = 0;
                if *attack_cooldown == 0 {
                    *telegraph = MONSTER_TELEGRAPH;
                }
            }
        } else {
            self.vel_x = move_toward(self.vel_x, 0, MONSTER_DEAD_DECEL);
        }

        self.apply_gravity_and_land(geom);
        damage
    }

    fn advance_biter(
        &mut self,
        heroes: &BTreeMap<PlayerId, Hero>,
        geom: &ZoneGeometry,
    ) -> Vec<DamageRequest> {
        let mut damage = Vec::new();
        // Patrol turnaround at span edges.
        if self.pos_x <= self.spawn.patrol_min_x {
            self.facing = 1;
        } else if self.pos_x >= self.spawn.patrol_max_x {
            self.facing = -1;
        }

        let Ai::Biter {
            hop_timer,
            touch_cooldown,
        } = &mut self.ai
        else {
            unreachable!("biter kind carries biter ai");
        };
        *hop_timer = hop_timer.saturating_sub(1);
        *touch_cooldown = touch_cooldown.saturating_sub(1);

        if self.grounded {
            if *hop_timer == 0 {
                self.vel_y = BITER_HOP_VY;
                self.vel_x = self.facing as i32 * BITER_HOP_VX;
                *hop_timer = BITER_HOP_INTERVAL;
                self.grounded = false;
            } else {
                self.vel_x = move_toward(self.vel_x, 0, BITER_SETTLE_DECEL);
            }
        }

        self.apply_gravity_and_land(geom);
        self.pos_x = self
            .pos_x
            .clamp(self.spawn.patrol_min_x, self.spawn.patrol_max_x);

        // Contact damage against any hero within touch range.
        let Ai::Biter { touch_cooldown, .. } = &mut self.ai else {
            unreachable!();
        };
        if *touch_cooldown == 0 {
            let range_sq = (BITER_TOUCH_RANGE as i64) * (BITER_TOUCH_RANGE as i64);
            for (player_id, hero) in heroes {
                if !hero.is_alive() {
                    continue;
                }
                let dx = (hero.pos_x - self.pos_x) as i64;
                let dy = (hero.pos_y - self.pos_y) as i64;
                if dx * dx + dy * dy <= range_sq {
                    damage.push(DamageRequest {
                        target: *player_id,
                        amount: BITER_TOUCH_DAMAGE,
                        attacker_x: self.pos_x,
                    });
                    *touch_cooldown = BITER_TOUCH_COOLDOWN;
                    break;
                }
            }
        }
        damage
    }

    fn apply_gravity_and_land(&mut self, geom: &ZoneGeometry) {
        if !self.grounded {
            self.vel_y = (self.vel_y - GRAVITY).max(-TERMINAL_FALL);
        }
        self.pos_x = (self.pos_x + self.vel_x).clamp(geom.min_x, geom.max_x);
        let prev_y = self.pos_y;
        let new_y = self.pos_y + self.vel_y;
        let (resolved_y, grounded) = geom.resolve_landing(self.pos_x, prev_y, new_y, self.vel_y, false);
        self.pos_y = resolved_y;
        self.grounded = grounded;
        if grounded {
            self.vel_y = 0;
        }
    }

    fn reset(&mut self) {
        let fresh = Enemy::from_spawn(self.id, self.spawn);
        self.pos_x = fresh.pos_x;
        self.pos_y = fresh.pos_y;
        self.vel_x = 0;
        self.vel_y = 0;
        self.facing = fresh.facing;
        self.grounded = false;
        self.health = fresh.max_health;
        self.respawn_timer = 0;
        self.ai = fresh.ai;
    }
}

/// Nearest living hero to `x`, returning (id, x, y).
fn nearest_living_hero(
    heroes: &BTreeMap<PlayerId, Hero>,
    x: i32,
) -> Option<(PlayerId, i32, i32)> {
    heroes
        .values()
        .filter(|hero| hero.is_alive())
        .min_by_key(|hero| (hero.pos_x - x).abs())
        .map(|hero| (hero.player_id, hero.pos_x, hero.pos_y))
}
