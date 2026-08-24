//! Fixed-point conventions shared by the whole domain.
//!
//! All world state is stored as integers in units of `px * WORLD_UNITS_PER_PIXEL`
//! and advanced on a fixed 20 Hz tick. The domain is entirely **y-up**: larger
//! `y` is higher, jumping adds to `y`, gravity subtracts from it, and a one-way
//! platform only catches a body that is descending. The Godot client authors
//! its maps y-down (ground near the bottom of a 720px viewport); that flip
//! happens once, in [`from_client_y`], and never leaks into the rules.

/// World units per screen pixel. A hero standing on the ground at screen y=550
/// has `position_y = (720 - 550) * 100 = 17_000`.
pub const WORLD_UNITS_PER_PIXEL: i32 = 100;

/// Fixed simulation rate. One tick is `1/20` s.
pub const TICK_RATE_HZ: i32 = 20;

/// Screen height the client authors against; used only to flip y at load time.
pub const VIEWPORT_BASELINE_PX: i32 = 720;

/// Convert a per-second speed (px/s) into world units advanced per tick.
///
/// `units_per_tick = px_per_s * WORLD_UNITS_PER_PIXEL / TICK_RATE_HZ`.
pub const fn speed_per_tick(px_per_second: i32) -> i32 {
    px_per_second * WORLD_UNITS_PER_PIXEL / TICK_RATE_HZ
}

/// Convert a per-second-squared acceleration (px/s^2) into the world-units
/// velocity change applied each tick.
///
/// `accel_per_tick = px_per_s2 * WORLD_UNITS_PER_PIXEL / TICK_RATE_HZ^2`.
pub const fn accel_per_tick(px_per_second_sq: i32) -> i32 {
    px_per_second_sq * WORLD_UNITS_PER_PIXEL / (TICK_RATE_HZ * TICK_RATE_HZ)
}

/// Convert a client-authored (y-down, pixels) vertical coordinate into the
/// domain's y-up world units. Solid ground top of screen-y 550 becomes 17_000.
pub const fn from_client_y(client_y_px: i32) -> i32 {
    (VIEWPORT_BASELINE_PX - client_y_px) * WORLD_UNITS_PER_PIXEL
}

/// Convert a client-authored horizontal coordinate (pixels) into world units.
pub const fn from_client_x(client_x_px: i32) -> i32 {
    client_x_px * WORLD_UNITS_PER_PIXEL
}

/// Move `current` toward `target` by at most `max_delta` (all in world units).
/// Integer analogue of Godot's `move_toward`, used for acceleration ramps.
pub fn move_toward(current: i32, target: i32, max_delta: i32) -> i32 {
    debug_assert!(max_delta >= 0);
    if (target - current).abs() <= max_delta {
        target
    } else if target > current {
        current + max_delta
    } else {
        current - max_delta
    }
}

// --- Hero movement constants, converted from the client float prototype. ---

/// Top run speed (270 px/s).
pub const HERO_MOVE_SPEED: i32 = speed_per_tick(270); // 1_350
/// Ground horizontal acceleration (1800 px/s^2).
pub const HERO_GROUND_ACCEL: i32 = accel_per_tick(1800); // 450
/// Airborne horizontal acceleration (850 px/s^2 -> 212.5, truncated to 212).
pub const HERO_AIR_ACCEL: i32 = accel_per_tick(850); // 212
/// Gravity pull per tick (1850 px/s^2 -> 462.5, truncated to 462).
pub const GRAVITY: i32 = accel_per_tick(1850); // 462
/// Upward jump impulse (670 px/s), applied as a positive velocity.
pub const HERO_JUMP_IMPULSE: i32 = speed_per_tick(670); // 3_350
/// Climb speed along ladders/ropes (185 px/s).
pub const HERO_CLIMB_SPEED: i32 = speed_per_tick(185); // 925
/// Horizontal snap toward a climbable's center (520 px/s).
pub const HERO_CLIMB_SNAP_SPEED: i32 = speed_per_tick(520); // 2_600
/// One-tick horizontal burst for a lunge (760 px/s).
pub const HERO_LUNGE_IMPULSE: i32 = speed_per_tick(760); // 3_800
/// Terminal downward speed. The client had no clamp; chosen to avoid runaway
/// fall speeds on long gauntlet drops. Tunable.
pub const TERMINAL_FALL: i32 = speed_per_tick(1400); // 7_000

/// Vertical tolerance for melee/contact hits (90 px).
pub const HIT_VERTICAL_TOLERANCE: i32 = 90 * WORLD_UNITS_PER_PIXEL; // 9_000

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn speed_and_accel_conversions_match_hand_computed_values() {
        assert_eq!(speed_per_tick(270), 1_350);
        assert_eq!(speed_per_tick(670), 3_350);
        assert_eq!(accel_per_tick(1800), 450);
        // 850 * 100 / 400 = 212.5, integer division truncates to 212.
        assert_eq!(accel_per_tick(850), 212);
        // 1850 * 100 / 400 = 462.5 -> 462.
        assert_eq!(accel_per_tick(1850), 462);
    }

    #[test]
    fn client_y_flip_puts_ground_above_zero_and_higher_is_larger() {
        // Screen ground top y=550 -> 17_000; a platform higher on screen (y=439)
        // must map to a *larger* world y.
        assert_eq!(from_client_y(550), 17_000);
        assert_eq!(from_client_y(439), 28_100);
        assert!(from_client_y(439) > from_client_y(550));
    }

    #[test]
    fn move_toward_ramps_and_clamps() {
        assert_eq!(move_toward(0, 1_350, 450), 450);
        assert_eq!(move_toward(450, 1_350, 450), 900);
        assert_eq!(move_toward(1_300, 1_350, 450), 1_350); // clamp, no overshoot
        assert_eq!(move_toward(500, 0, 450), 50);
        assert_eq!(move_toward(50, 0, 450), 0);
    }
}
