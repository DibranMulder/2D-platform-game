//! Player intent — the only thing a client is allowed to assert. The server
//! validates and applies it; it never accepts a position or a damage result.

use crate::hero::WeaponId;

/// One tick of player input, carrying a monotonically increasing `sequence`.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerIntent {
    pub sequence: u64,
    pub client_tick: u64,
    /// -1 / 0 / 1 horizontal movement.
    pub move_axis: i8,
    /// -1 / 0 / 1 climb axis (y-up: +1 = up a ladder).
    pub climb_axis: i8,
    /// Rising edge requests a jump this tick.
    pub jump: bool,
    /// Held to drop through a one-way platform.
    pub drop: bool,
    /// Held to guard/block with the current weapon.
    pub guard: bool,
    /// 0 = none; 1/3/4/5/6 activate that hotbar slot this tick (2 is guard).
    pub action_slot: u8,
}

impl PlayerIntent {
    pub fn is_shape_valid(&self) -> bool {
        (-1..=1).contains(&self.move_axis)
            && (-1..=1).contains(&self.climb_axis)
            && matches!(self.action_slot, 0 | 1 | 3 | 4 | 5 | 6)
    }
}

/// A weapon change request, kept out of the per-tick intent since it is rare.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WeaponSelect {
    pub weapon: WeaponId,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IntentError {
    UnknownPlayer,
    MalformedIntent,
    StaleSequence,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum JoinError {
    AlreadyJoined,
}
