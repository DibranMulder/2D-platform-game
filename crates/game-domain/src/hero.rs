//! The player-controlled entity. Holds authoritative hero state and advances
//! it one tick from latched intent: movement + climbing here, combat actions
//! emitted as [`HeroEffect`]s for [`crate::zone::Zone`] to resolve against the
//! other entities it can see.

use std::collections::BTreeMap;

use crate::combat::{ActionKind, ProjectileSpec, slot_action};
use crate::fixed::{
    GRAVITY, HERO_AIR_ACCEL, HERO_CLIMB_SNAP_SPEED, HERO_CLIMB_SPEED, HERO_GROUND_ACCEL,
    HERO_JUMP_IMPULSE, HERO_MOVE_SPEED, HIT_VERTICAL_TOLERANCE, TERMINAL_FALL, move_toward,
};
use crate::geometry::{SpawnPoint, ZoneGeometry};
use crate::intent::{IntentError, PlayerIntent};
use crate::PlayerId;

pub const MAX_HEALTH: i32 = 100;
pub const MAX_RESOURCE_MILLI: i32 = 100_000;
const CLIMB_GRAB_DISTANCE: i32 = 35 * 100;
const CLIMB_EXIT_MARGIN: i32 = 7 * 100;
const RESPAWN_TICKS: u16 = 60;
const KNOCKBACK: i32 = crate::fixed::speed_per_tick(260);
const HURT_KNOCKBACK_LOCK: u16 = 4;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum WeaponId {
    Sword,
    AxeShield,
    Bow,
    Staff,
    Wand,
}

impl WeaponId {
    pub fn slug(self) -> &'static str {
        match self {
            WeaponId::Sword => "sword",
            WeaponId::AxeShield => "axe_shield",
            WeaponId::Bow => "bow",
            WeaponId::Staff => "staff",
            WeaponId::Wand => "wand",
        }
    }

    pub fn from_slug(slug: &str) -> Option<Self> {
        match slug {
            "sword" => Some(WeaponId::Sword),
            "axe_shield" => Some(WeaponId::AxeShield),
            "bow" => Some(WeaponId::Bow),
            "staff" => Some(WeaponId::Staff),
            "wand" => Some(WeaponId::Wand),
            _ => None,
        }
    }

    fn is_magic(self) -> bool {
        matches!(self, WeaponId::Staff | WeaponId::Wand)
    }
}

/// Persistent identity + loadout of a hero, chosen at the login/onboarding tier.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct HeroDescriptor {
    pub hero_name: String,
    pub lineage: String,
    pub weapon: WeaponId,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ClimbState {
    pub center_x: i32,
    pub top_exit_y: i32,
    pub bottom_exit_y: i32,
}

/// A combat consequence of a hero action, resolved by the owning zone.
#[derive(Clone, Debug, PartialEq)]
pub enum HeroEffect {
    /// A melee strike originating at (x, y) facing `facing`.
    Melee {
        damage: i32,
        reach: i32,
        vertical: i32,
        omni: bool,
        stagger_ticks: u16,
        x: i32,
        y: i32,
        facing: i8,
    },
    /// Spawn projectiles from this hero.
    SpawnProjectiles {
        spec: ProjectileSpec,
        x: i32,
        y: i32,
        facing: i8,
    },
}

#[derive(Clone, Debug)]
pub struct Hero {
    pub player_id: PlayerId,
    pub descriptor: HeroDescriptor,
    pub pos_x: i32,
    pub pos_y: i32,
    pub vel_x: i32,
    pub vel_y: i32,
    pub facing: i8,
    pub grounded: bool,
    pub climbing: Option<ClimbState>,
    pub health: i32,
    pub stamina_milli: i32,
    pub mana_milli: i32,
    pub current_action: &'static str,
    pub action_lock: u16,
    pub respawn_timer: u16,
    /// Ticks until this hero may trigger a portal again; carries across zones.
    pub portal_cooldown: u16,
    pub last_processed_intent: u64,
    cooldowns: BTreeMap<&'static str, u16>,
    // latched input
    move_axis: i8,
    climb_axis: i8,
    jump_queued: bool,
    drop_held: bool,
    guard_held: bool,
    queued_action: u8,
    // respawn anchor
    spawn_x: i32,
    spawn_y: i32,
    spawn_facing: i8,
}

impl Hero {
    pub fn new(player_id: PlayerId, descriptor: HeroDescriptor, spawn: SpawnPoint) -> Self {
        Self {
            player_id,
            descriptor,
            pos_x: spawn.x,
            pos_y: spawn.y,
            vel_x: 0,
            vel_y: 0,
            facing: spawn.facing,
            grounded: true,
            climbing: None,
            health: MAX_HEALTH,
            stamina_milli: MAX_RESOURCE_MILLI,
            mana_milli: MAX_RESOURCE_MILLI,
            current_action: "ready",
            action_lock: 0,
            respawn_timer: 0,
            portal_cooldown: 0,
            last_processed_intent: 0,
            cooldowns: BTreeMap::new(),
            move_axis: 0,
            climb_axis: 0,
            jump_queued: false,
            drop_held: false,
            guard_held: false,
            queued_action: 0,
            spawn_x: spawn.x,
            spawn_y: spawn.y,
            spawn_facing: spawn.facing,
        }
    }

    pub fn is_alive(&self) -> bool {
        self.health > 0
    }

    pub fn is_blocking(&self) -> bool {
        self.guard_held && !self.descriptor.weapon.eq(&WeaponId::Bow) && self.is_alive()
    }

    pub fn is_aiming(&self) -> bool {
        self.guard_held && self.descriptor.weapon == WeaponId::Bow && self.is_alive()
    }

    pub fn set_weapon(&mut self, weapon: WeaponId) {
        self.descriptor.weapon = weapon;
    }

    /// Latch one intent. Rejects a stale sequence or malformed shape.
    pub fn apply_intent(&mut self, intent: PlayerIntent) -> Result<(), IntentError> {
        if !intent.is_shape_valid() {
            return Err(IntentError::MalformedIntent);
        }
        if intent.sequence <= self.last_processed_intent {
            return Err(IntentError::StaleSequence);
        }
        self.last_processed_intent = intent.sequence;
        self.move_axis = intent.move_axis;
        self.climb_axis = intent.climb_axis;
        self.jump_queued |= intent.jump;
        self.drop_held = intent.drop;
        self.guard_held = intent.guard;
        if intent.action_slot != 0 {
            self.queued_action = intent.action_slot;
        }
        Ok(())
    }

    /// Advance one tick. Returns combat effects for the zone to resolve.
    pub fn advance(&mut self, geom: &ZoneGeometry) -> Vec<HeroEffect> {
        self.tick_timers();

        if !self.is_alive() {
            self.advance_dead(geom);
            self.queued_action = 0;
            self.jump_queued = false;
            return Vec::new();
        }

        let effects = self.resolve_action(geom);

        if self.climbing.is_some() {
            self.advance_climb(geom);
        } else {
            self.try_start_climb(geom);
            if self.climbing.is_some() {
                self.advance_climb(geom);
            } else {
                self.advance_grounded(geom);
            }
        }

        self.regen();
        self.queued_action = 0;
        self.jump_queued = false;
        self.update_action_label();
        effects
    }

    fn tick_timers(&mut self) {
        self.action_lock = self.action_lock.saturating_sub(1);
        self.respawn_timer = self.respawn_timer.saturating_sub(1);
        self.portal_cooldown = self.portal_cooldown.saturating_sub(1);
        for remaining in self.cooldowns.values_mut() {
            *remaining = remaining.saturating_sub(1);
        }
        self.cooldowns.retain(|_, remaining| *remaining > 0);
    }

    fn advance_dead(&mut self, geom: &ZoneGeometry) {
        if self.respawn_timer == 0 {
            self.respawn();
            return;
        }
        self.vel_x = move_toward(self.vel_x, 0, HERO_GROUND_ACCEL);
        if !self.grounded {
            self.vel_y = (self.vel_y - GRAVITY).max(-TERMINAL_FALL);
        }
        self.integrate(geom);
    }

    fn resolve_action(&mut self, geom: &ZoneGeometry) -> Vec<HeroEffect> {
        let slot = self.queued_action;
        if slot == 0 || self.climbing.is_some() || self.action_lock > 0 {
            return Vec::new();
        }
        let Some(spec) = slot_action(self.descriptor.weapon, slot) else {
            return Vec::new();
        };
        if self.cooldowns.contains_key(spec.id) {
            return Vec::new();
        }
        // Heal actions no-op at full health (matches prototype) without cost.
        if let ActionKind::Heal { .. } = spec.kind {
            if self.health >= MAX_HEALTH {
                return Vec::new();
            }
        }
        if self.stamina_milli < spec.stamina_cost_milli || self.mana_milli < spec.mana_cost_milli {
            return Vec::new();
        }
        self.stamina_milli -= spec.stamina_cost_milli;
        self.mana_milli -= spec.mana_cost_milli;
        self.cooldowns.insert(spec.id, spec.cooldown_ticks.max(1));
        self.action_lock = spec.recovery_ticks;
        self.current_action = spec.id;

        match spec.kind {
            ActionKind::Melee {
                damage,
                reach,
                omni,
                dash_impulse,
                stagger_ticks,
            } => {
                if dash_impulse != 0 {
                    self.vel_x = self.facing as i32 * dash_impulse;
                }
                vec![HeroEffect::Melee {
                    damage,
                    reach,
                    vertical: HIT_VERTICAL_TOLERANCE,
                    omni,
                    stagger_ticks,
                    x: self.pos_x,
                    y: self.pos_y,
                    facing: self.facing,
                }]
            }
            ActionKind::Projectiles(mut spec) => {
                // Bow quick_shot gains damage while aiming.
                if self.descriptor.weapon == WeaponId::Bow && self.is_aiming() {
                    spec.damage += 6;
                }
                vec![HeroEffect::SpawnProjectiles {
                    spec,
                    x: self.pos_x,
                    y: self.pos_y,
                    facing: self.facing,
                }]
            }
            ActionKind::Dash { impulse, away } => {
                let dir = if away { -self.facing } else { self.facing } as i32;
                self.vel_x = dir * impulse;
                Vec::new()
            }
            ActionKind::Teleport { distance } => {
                self.pos_x = (self.pos_x + self.facing as i32 * distance)
                    .clamp(geom.min_x, geom.max_x);
                Vec::new()
            }
            ActionKind::Heal { amount } => {
                self.health = (self.health + amount).min(MAX_HEALTH);
                Vec::new()
            }
        }
    }

    fn advance_grounded(&mut self, geom: &ZoneGeometry) {
        if !self.grounded {
            self.vel_y = (self.vel_y - GRAVITY).max(-TERMINAL_FALL);
        }
        if self.move_axis != 0 {
            self.facing = self.move_axis.signum();
        }
        let speed_scale = if self.is_blocking() {
            38
        } else if self.is_aiming() {
            58
        } else {
            100
        };
        let desired = self.move_axis as i32 * HERO_MOVE_SPEED * speed_scale / 100;
        let accel = if self.grounded {
            HERO_GROUND_ACCEL
        } else {
            HERO_AIR_ACCEL
        };
        // A hurt knockback briefly overrides input control.
        if self.action_lock == 0 || self.current_action != "hurt" {
            self.vel_x = move_toward(self.vel_x, desired, accel);
        }
        if self.jump_queued && self.grounded {
            self.vel_y = HERO_JUMP_IMPULSE;
            self.grounded = false;
            self.current_action = "jump";
        }
        self.integrate(geom);
    }

    /// Integrate position and resolve horizontal bounds + vertical landing.
    fn integrate(&mut self, geom: &ZoneGeometry) {
        let prev_y = self.pos_y;
        self.pos_x = (self.pos_x + self.vel_x).clamp(geom.min_x, geom.max_x);

        let new_y = self.pos_y + self.vel_y;
        let (resolved_y, grounded) =
            geom.resolve_landing(self.pos_x, prev_y, new_y, self.vel_y, self.drop_held);
        self.pos_y = resolved_y;
        self.grounded = grounded;
        if grounded {
            self.vel_y = 0;
        }
    }

    fn try_start_climb(&mut self, geom: &ZoneGeometry) {
        if self.climb_axis == 0 {
            return;
        }
        let mut nearest: Option<&crate::geometry::ClimbVolume> = None;
        let mut best = i32::MAX;
        for volume in &geom.climbs {
            let distance = (self.pos_x - volume.center_x).abs();
            if distance < best && distance <= CLIMB_GRAB_DISTANCE {
                best = distance;
                nearest = Some(volume);
            }
        }
        let Some(volume) = nearest else {
            return;
        };
        // Do not grab if already at the edge you are pushing toward.
        if self.climb_axis > 0 && self.pos_y >= volume.top_exit_y - CLIMB_EXIT_MARGIN {
            return;
        }
        if self.climb_axis < 0 && self.pos_y <= volume.bottom_exit_y + CLIMB_EXIT_MARGIN {
            return;
        }
        self.climbing = Some(ClimbState {
            center_x: volume.center_x,
            top_exit_y: volume.top_exit_y,
            bottom_exit_y: volume.bottom_exit_y,
        });
        self.vel_x = 0;
        self.vel_y = 0;
    }

    fn advance_climb(&mut self, geom: &ZoneGeometry) {
        let climb = self.climbing.expect("advance_climb requires a climb state");
        // Jump-off cancels the climb with an upward burst.
        if self.jump_queued {
            self.climbing = None;
            self.vel_y = HERO_JUMP_IMPULSE * 78 / 100;
            self.vel_x = self.facing as i32 * HERO_MOVE_SPEED * 72 / 100;
            self.grounded = false;
            return;
        }
        self.pos_x = move_toward(self.pos_x, climb.center_x, HERO_CLIMB_SNAP_SPEED);
        self.vel_y = self.climb_axis as i32 * HERO_CLIMB_SPEED;
        self.pos_y += self.vel_y;
        self.current_action = "climbing";
        // Exit at either end.
        if self.pos_y >= climb.top_exit_y {
            self.pos_y = climb.top_exit_y;
            self.climbing = None;
            self.vel_y = 0;
            self.grounded = false;
        } else if self.pos_y <= climb.bottom_exit_y {
            self.pos_y = climb.bottom_exit_y.max(geom.ground_top_y);
            self.climbing = None;
            self.vel_y = 0;
            self.grounded = self.pos_y <= geom.ground_top_y;
        }
    }

    fn regen(&mut self) {
        if self.climbing.is_some() {
            self.stamina_milli = (self.stamina_milli + 600).min(MAX_RESOURCE_MILLI);
            self.mana_milli = (self.mana_milli + 250).min(MAX_RESOURCE_MILLI);
            return;
        }
        if self.is_aiming() {
            self.stamina_milli = (self.stamina_milli - 400).max(0);
        } else if !self.is_blocking() {
            self.stamina_milli = (self.stamina_milli + 1_100).min(MAX_RESOURCE_MILLI);
        }
        if !self.is_blocking() {
            let regen = if self.descriptor.weapon == WeaponId::Staff {
                500
            } else {
                350
            };
            self.mana_milli = (self.mana_milli + regen).min(MAX_RESOURCE_MILLI);
        }
    }

    fn update_action_label(&mut self) {
        if self.action_lock > 0 {
            return;
        }
        if self.climbing.is_some() {
            self.current_action = "climbing";
        } else if !self.grounded {
            self.current_action = "jump";
        } else {
            self.current_action = "ready";
        }
    }

    /// Take damage from an attacker at world-x `attacker_x`, applying guard
    /// mitigation, knockback, and death.
    pub fn receive_damage(&mut self, amount: i32, attacker_x: i32) {
        if !self.is_alive() {
            return;
        }
        self.climbing = None;
        let attacker_side = (attacker_x - self.pos_x).signum();
        let frontal = attacker_side as i8 == self.facing || attacker_side == 0;
        let magic_ward = self.descriptor.weapon.is_magic();
        let mut final_damage = amount;

        if self.is_blocking() && (frontal || magic_ward) {
            if magic_ward && self.mana_milli >= 16_000 {
                self.mana_milli -= 16_000;
                final_damage = (amount * 35 / 100).max(1);
            } else if !magic_ward {
                let guard_cost = if self.descriptor.weapon == WeaponId::AxeShield {
                    11_000
                } else {
                    20_000
                };
                if self.stamina_milli >= guard_cost {
                    self.stamina_milli -= guard_cost;
                    let ratio = if self.descriptor.weapon == WeaponId::AxeShield {
                        18
                    } else {
                        45
                    };
                    final_damage = (amount * ratio / 100).max(1);
                }
            }
        }

        self.health = (self.health - final_damage).max(0);
        self.vel_x = -attacker_side * KNOCKBACK;
        self.action_lock = self.action_lock.max(HURT_KNOCKBACK_LOCK);
        self.current_action = if self.health == 0 { "defeated" } else { "hurt" };
        if self.health == 0 {
            self.respawn_timer = RESPAWN_TICKS;
        }
    }

    fn respawn(&mut self) {
        self.pos_x = self.spawn_x;
        self.pos_y = self.spawn_y;
        self.vel_x = 0;
        self.vel_y = 0;
        self.facing = self.spawn_facing;
        self.grounded = true;
        self.climbing = None;
        self.health = MAX_HEALTH;
        self.stamina_milli = MAX_RESOURCE_MILLI;
        self.mana_milli = MAX_RESOURCE_MILLI;
        self.current_action = "ready";
        self.action_lock = 0;
    }

    /// Move this hero to a new zone's spawn (used on portal transfer).
    pub fn relocate(&mut self, spawn: SpawnPoint) {
        self.pos_x = spawn.x;
        self.pos_y = spawn.y;
        self.vel_x = 0;
        self.vel_y = 0;
        self.facing = spawn.facing;
        self.grounded = false;
        self.climbing = None;
        self.spawn_x = spawn.x;
        self.spawn_y = spawn.y;
        self.spawn_facing = spawn.facing;
    }
}
