//! Weapon action table and combat math, ported from the client prototype's
//! `hero_controller.gd`. Durations are in ticks, resource costs in milli-units
//! (x1000, matching [`crate::hero::Hero`] stamina/mana storage), reaches and
//! speeds in world units.

use crate::fixed::{WORLD_UNITS_PER_PIXEL, speed_per_tick};
use crate::hero::WeaponId;

/// Round a duration in centiseconds to whole 20 Hz ticks.
pub const fn ticks_from_cs(centiseconds: i32) -> u16 {
    ((centiseconds * 20 + 50) / 100) as u16
}

const fn reach(px: i32) -> i32 {
    px * WORLD_UNITS_PER_PIXEL
}

/// A projectile archetype fired by an action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProjectileSpec {
    pub kind: ProjectileKind,
    pub damage: i32,
    pub speed: i32,
    /// One entry per projectile spawned; the value is a y offset in world units.
    pub height_offsets: &'static [i32],
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ProjectileKind {
    Arrow,
    Fireball,
    Spark,
    Orb,
}

impl ProjectileKind {
    pub fn slug(self) -> &'static str {
        match self {
            ProjectileKind::Arrow => "arrow",
            ProjectileKind::Fireball => "fireball",
            ProjectileKind::Spark => "spark",
            ProjectileKind::Orb => "orb",
        }
    }
}

/// What an activated hotbar action does.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ActionKind {
    /// Melee strike; `dash_impulse` (world units/tick, forward) is applied first
    /// for lunge/charge; `stagger_ticks` briefly locks a hit enemy.
    Melee {
        damage: i32,
        reach: i32,
        omni: bool,
        dash_impulse: i32,
        stagger_ticks: u16,
    },
    /// Fire one or more projectiles.
    Projectiles(ProjectileSpec),
    /// Pure horizontal dash with no strike (backstep). `impulse` is signed
    /// relative to facing at apply time.
    Dash { impulse: i32, away: bool },
    /// Instant reposition forward by `distance` world units, clamped to bounds.
    Teleport { distance: i32 },
    /// Restore `amount` health.
    Heal { amount: i32 },
}

/// A fully specified hotbar action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ActionSpec {
    /// Stable label surfaced as the hero's `action_state` on the wire.
    pub id: &'static str,
    pub kind: ActionKind,
    pub cooldown_ticks: u16,
    pub recovery_ticks: u16,
    pub stamina_cost_milli: i32,
    pub mana_cost_milli: i32,
}

const fn strike(
    id: &'static str,
    damage: i32,
    reach_px: i32,
    cd_cs: i32,
    rec_cs: i32,
    omni: bool,
    dash_impulse: i32,
    stagger_cs: i32,
) -> ActionSpec {
    ActionSpec {
        id,
        kind: ActionKind::Melee {
            damage,
            reach: reach(reach_px),
            omni,
            dash_impulse,
            stagger_ticks: ticks_from_cs(stagger_cs),
        },
        cooldown_ticks: ticks_from_cs(cd_cs),
        recovery_ticks: ticks_from_cs(rec_cs),
        stamina_cost_milli: 0,
        mana_cost_milli: 0,
    }
}

/// Resolve the action bound to a hotbar `slot` (1,3,4,5,6) for a weapon. Slot 2
/// is the held secondary (guard/aim/ward) and has no entry here. Returns `None`
/// for an invalid slot.
pub fn slot_action(weapon: WeaponId, slot: u8) -> Option<ActionSpec> {
    use ProjectileKind::*;
    let spec = match (weapon, slot) {
        // --- Sword ---
        (WeaponId::Sword, 1) => strike("attack", 14, 86, 45, 18, false, 0, 0),
        (WeaponId::Sword, 3) => strike("power_strike", 32, 100, 300, 55, false, 0, 0),
        (WeaponId::Sword, 4) => strike("whirlwind", 22, 112, 500, 65, true, 0, 0),
        (WeaponId::Sword, 5) => strike(
            "lunge",
            18,
            128,
            400,
            32,
            false,
            speed_per_tick(760),
            0,
        ),
        (WeaponId::Sword, 6) => heal("second_wind", 30, 1200, 35, 0),

        // --- Axe + Shield ---
        (WeaponId::AxeShield, 1) => strike("axe_chop", 23, 94, 72, 34, false, 0, 0),
        (WeaponId::AxeShield, 3) => strike("sundering_cleave", 40, 116, 420, 68, false, 0, 0),
        (WeaponId::AxeShield, 4) => strike("shield_bash", 13, 82, 320, 28, false, 0, 90),
        (WeaponId::AxeShield, 5) => strike(
            "shield_charge",
            19,
            132,
            480,
            38,
            false,
            speed_per_tick(610),
            55,
        ),
        (WeaponId::AxeShield, 6) => heal("second_wind", 30, 1200, 35, 0),

        // --- Bow --- (quick_shot aiming bonus handled in Hero)
        (WeaponId::Bow, 1) => projectiles("quick_shot", Arrow, 13, 620, 48, 16, 0, 0, &[0]),
        (WeaponId::Bow, 3) => projectiles("piercing_shot", Arrow, 31, 760, 340, 38, 18_000, 0, &[0]),
        (WeaponId::Bow, 4) => projectiles(
            "volley",
            Arrow,
            10,
            580,
            520,
            45,
            24_000,
            0,
            &[-15 * WORLD_UNITS_PER_PIXEL, 0, 15 * WORLD_UNITS_PER_PIXEL],
        ),
        (WeaponId::Bow, 5) => ActionSpec {
            id: "backstep",
            kind: ActionKind::Dash {
                impulse: speed_per_tick(590),
                away: true,
            },
            cooldown_ticks: ticks_from_cs(300),
            recovery_ticks: ticks_from_cs(24),
            stamina_cost_milli: 0,
            mana_cost_milli: 0,
        },
        (WeaponId::Bow, 6) => heal("second_wind", 30, 1200, 35, 0),

        // --- Staff ---
        (WeaponId::Staff, 1) => projectiles("arcane_bolt", Orb, 17, 560, 62, 20, 0, 7_000, &[0]),
        (WeaponId::Staff, 3) => projectiles("fireball", Fireball, 38, 620, 380, 48, 0, 25_000, &[0]),
        (WeaponId::Staff, 4) => ActionSpec {
            id: "frost_nova",
            kind: ActionKind::Melee {
                damage: 24,
                reach: reach(155),
                omni: true,
                dash_impulse: 0,
                stagger_ticks: ticks_from_cs(120),
            },
            cooldown_ticks: ticks_from_cs(550),
            recovery_ticks: ticks_from_cs(50),
            stamina_cost_milli: 0,
            mana_cost_milli: 30_000,
        },
        (WeaponId::Staff, 5) => ActionSpec {
            id: "blink",
            kind: ActionKind::Teleport {
                distance: 215 * WORLD_UNITS_PER_PIXEL,
            },
            cooldown_ticks: ticks_from_cs(350),
            recovery_ticks: ticks_from_cs(20),
            stamina_cost_milli: 0,
            mana_cost_milli: 18_000,
        },
        (WeaponId::Staff, 6) => heal_mana("mend", 26, 900, 42, 32_000),

        // --- Wand ---
        (WeaponId::Wand, 1) => projectiles("magic_missile", Spark, 11, 500, 30, 10, 0, 4_000, &[0]),
        (WeaponId::Wand, 3) => projectiles(
            "twin_sparks",
            Spark,
            10,
            520,
            260,
            28,
            0,
            14_000,
            &[-8 * WORLD_UNITS_PER_PIXEL, 8 * WORLD_UNITS_PER_PIXEL],
        ),
        (WeaponId::Wand, 4) => projectiles("hex_bolt", Orb, 29, 590, 440, 34, 0, 22_000, &[0]),
        (WeaponId::Wand, 5) => ActionSpec {
            id: "phase_step",
            kind: ActionKind::Teleport {
                distance: 145 * WORLD_UNITS_PER_PIXEL,
            },
            cooldown_ticks: ticks_from_cs(280),
            recovery_ticks: ticks_from_cs(16),
            stamina_cost_milli: 0,
            mana_cost_milli: 12_000,
        },
        (WeaponId::Wand, 6) => heal_mana("mend", 26, 900, 42, 32_000),

        _ => return None,
    };
    Some(spec)
}

const fn heal(id: &'static str, amount: i32, cd_cs: i32, rec_cs: i32, mana_cost: i32) -> ActionSpec {
    ActionSpec {
        id,
        kind: ActionKind::Heal { amount },
        cooldown_ticks: ticks_from_cs(cd_cs),
        recovery_ticks: ticks_from_cs(rec_cs),
        stamina_cost_milli: 0,
        mana_cost_milli: mana_cost,
    }
}

const fn heal_mana(
    id: &'static str,
    amount: i32,
    cd_cs: i32,
    rec_cs: i32,
    mana_cost: i32,
) -> ActionSpec {
    heal(id, amount, cd_cs, rec_cs, mana_cost)
}

#[allow(clippy::too_many_arguments)]
const fn projectiles(
    id: &'static str,
    kind: ProjectileKind,
    damage: i32,
    speed_px_s: i32,
    cd_cs: i32,
    rec_cs: i32,
    stamina_cost: i32,
    mana_cost: i32,
    height_offsets: &'static [i32],
) -> ActionSpec {
    ActionSpec {
        id,
        kind: ActionKind::Projectiles(ProjectileSpec {
            kind,
            damage,
            speed: speed_per_tick(speed_px_s),
            height_offsets,
        }),
        cooldown_ticks: ticks_from_cs(cd_cs),
        recovery_ticks: ticks_from_cs(rec_cs),
        stamina_cost_milli: stamina_cost,
        mana_cost_milli: mana_cost,
    }
}

/// Does a strike from `from` (feet) facing `facing` reach `target`?
pub fn strike_hits(
    from_x: i32,
    from_y: i32,
    facing: i8,
    target_x: i32,
    target_y: i32,
    reach: i32,
    vertical: i32,
    omni: bool,
) -> bool {
    let dx = target_x - from_x;
    let dy = target_y - from_y;
    let facing_ok = omni || dx.signum() as i8 == facing || dx == 0;
    dx.abs() <= reach && dy.abs() <= vertical && facing_ok
}

/// Apply `amount` damage to `health`, clamping at zero. Returns damage applied.
pub fn apply_damage(health: &mut i32, amount: i32) -> i32 {
    let applied = amount.min(*health).max(0);
    *health -= applied;
    applied
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tick_rounding_matches_expected() {
        assert_eq!(ticks_from_cs(45), 9); // 0.45s
        assert_eq!(ticks_from_cs(18), 4); // 0.18s -> 3.6 rounds to 4
        assert_eq!(ticks_from_cs(300), 60); // 3.0s
    }

    #[test]
    fn every_weapon_has_five_activatable_slots() {
        for weapon in [
            WeaponId::Sword,
            WeaponId::AxeShield,
            WeaponId::Bow,
            WeaponId::Staff,
            WeaponId::Wand,
        ] {
            for slot in [1u8, 3, 4, 5, 6] {
                assert!(slot_action(weapon, slot).is_some(), "{weapon:?} slot {slot}");
            }
            assert!(slot_action(weapon, 2).is_none(), "slot 2 is the secondary");
            assert!(slot_action(weapon, 7).is_none());
        }
    }

    #[test]
    fn strike_respects_reach_facing_and_vertical() {
        // facing right (+1), target 50 units to the right, within reach.
        assert!(strike_hits(0, 0, 1, 5_000, 0, 8_600, 9_000, false));
        // target behind: blocked unless omni.
        assert!(!strike_hits(0, 0, 1, -5_000, 0, 8_600, 9_000, false));
        assert!(strike_hits(0, 0, 1, -5_000, 0, 8_600, 9_000, true));
        // out of reach.
        assert!(!strike_hits(0, 0, 1, 9_000, 0, 8_600, 9_000, false));
        // too high vertically.
        assert!(!strike_hits(0, 0, 1, 1_000, 10_000, 8_600, 9_000, false));
    }

    #[test]
    fn apply_damage_clamps_at_zero() {
        let mut hp = 30;
        assert_eq!(apply_damage(&mut hp, 18), 18);
        assert_eq!(hp, 12);
        assert_eq!(apply_damage(&mut hp, 40), 12);
        assert_eq!(hp, 0);
    }
}
