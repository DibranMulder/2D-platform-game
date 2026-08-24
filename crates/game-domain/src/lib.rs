#![forbid(unsafe_code)]

use std::collections::BTreeMap;

pub const WORLD_UNITS_PER_PIXEL: i32 = 100;

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

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerIntent {
    pub sequence: u64,
    pub client_tick: u64,
    pub horizontal: i8,
    pub jump: bool,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CharacterState {
    pub player_id: PlayerId,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub velocity_y: i32,
    pub grounded: bool,
    pub last_processed_intent: u64,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorldSnapshot {
    pub server_tick: u64,
    pub characters: Vec<CharacterState>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum JoinError {
    AlreadyJoined,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IntentError {
    UnknownPlayer,
    InvalidHorizontal,
    StaleSequence,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WorldConfig {
    pub run_speed: i32,
    pub jump_impulse: i32,
    pub gravity: i32,
    pub terminal_velocity: i32,
    pub minimum_x: i32,
    pub maximum_x: i32,
}

impl Default for WorldConfig {
    fn default() -> Self {
        Self {
            run_speed: 6 * WORLD_UNITS_PER_PIXEL,
            jump_impulse: 10 * WORLD_UNITS_PER_PIXEL,
            gravity: 70,
            terminal_velocity: 12 * WORLD_UNITS_PER_PIXEL,
            minimum_x: -2_000 * WORLD_UNITS_PER_PIXEL,
            maximum_x: 2_000 * WORLD_UNITS_PER_PIXEL,
        }
    }
}

#[derive(Debug)]
pub struct World {
    config: WorldConfig,
    server_tick: u64,
    characters: BTreeMap<PlayerId, SimulatedCharacter>,
}

#[derive(Debug)]
struct SimulatedCharacter {
    state: CharacterState,
    desired_horizontal: i8,
    jump_queued: bool,
    last_client_tick: u64,
}

impl Default for World {
    fn default() -> Self {
        Self::new(WorldConfig::default())
    }
}

impl World {
    pub fn new(config: WorldConfig) -> Self {
        assert!(config.minimum_x < config.maximum_x);
        assert!(config.run_speed >= 0);
        assert!(config.gravity > 0);
        assert!(config.terminal_velocity > 0);

        Self {
            config,
            server_tick: 0,
            characters: BTreeMap::new(),
        }
    }

    pub fn join(&mut self, player_id: PlayerId) -> Result<(), JoinError> {
        if self.characters.contains_key(&player_id) {
            return Err(JoinError::AlreadyJoined);
        }

        self.characters.insert(
            player_id,
            SimulatedCharacter {
                state: CharacterState {
                    player_id,
                    position_x: 0,
                    position_y: 0,
                    velocity_x: 0,
                    velocity_y: 0,
                    grounded: true,
                    last_processed_intent: 0,
                },
                desired_horizontal: 0,
                jump_queued: false,
                last_client_tick: 0,
            },
        );
        Ok(())
    }

    pub fn leave(&mut self, player_id: PlayerId) -> bool {
        self.characters.remove(&player_id).is_some()
    }

    pub fn submit_intent(
        &mut self,
        player_id: PlayerId,
        intent: PlayerIntent,
    ) -> Result<(), IntentError> {
        if !(-1..=1).contains(&intent.horizontal) {
            return Err(IntentError::InvalidHorizontal);
        }

        let character = self
            .characters
            .get_mut(&player_id)
            .ok_or(IntentError::UnknownPlayer)?;

        if intent.sequence <= character.state.last_processed_intent {
            return Err(IntentError::StaleSequence);
        }

        character.desired_horizontal = intent.horizontal;
        character.jump_queued |= intent.jump;
        character.state.last_processed_intent = intent.sequence;
        character.last_client_tick = intent.client_tick;
        Ok(())
    }

    pub fn advance_tick(&mut self) -> WorldSnapshot {
        self.server_tick = self.server_tick.saturating_add(1);

        for character in self.characters.values_mut() {
            character.state.velocity_x =
                i32::from(character.desired_horizontal) * self.config.run_speed;

            if character.jump_queued && character.state.grounded {
                character.state.velocity_y = self.config.jump_impulse;
                character.state.grounded = false;
            }
            character.jump_queued = false;

            if !character.state.grounded {
                character.state.velocity_y = (character.state.velocity_y - self.config.gravity)
                    .max(-self.config.terminal_velocity);
            }

            character.state.position_x = (character.state.position_x + character.state.velocity_x)
                .clamp(self.config.minimum_x, self.config.maximum_x);
            character.state.position_y += character.state.velocity_y;

            if character.state.position_y <= 0 {
                character.state.position_y = 0;
                character.state.velocity_y = 0;
                character.state.grounded = true;
            }
        }

        self.snapshot()
    }

    pub fn snapshot(&self) -> WorldSnapshot {
        WorldSnapshot {
            server_tick: self.server_tick,
            characters: self
                .characters
                .values()
                .map(|character| character.state)
                .collect(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn intent(sequence: u64, horizontal: i8, jump: bool) -> PlayerIntent {
        PlayerIntent {
            sequence,
            client_tick: sequence,
            horizontal,
            jump,
        }
    }

    #[test]
    fn movement_is_created_by_ticks_from_directional_intent() {
        let player = PlayerId::new(7);
        let mut world = World::default();
        world.join(player).unwrap();
        world.submit_intent(player, intent(1, 1, false)).unwrap();

        let snapshot = world.advance_tick();

        assert_eq!(snapshot.server_tick, 1);
        assert_eq!(snapshot.characters[0].position_x, 600);
        assert_eq!(snapshot.characters[0].position_y, 0);
    }

    #[test]
    fn stale_and_impossible_intent_is_rejected() {
        let player = PlayerId::new(9);
        let mut world = World::default();
        world.join(player).unwrap();
        world.submit_intent(player, intent(2, -1, false)).unwrap();

        assert_eq!(
            world.submit_intent(player, intent(2, 1, false)),
            Err(IntentError::StaleSequence)
        );
        assert_eq!(
            world.submit_intent(player, intent(3, 2, false)),
            Err(IntentError::InvalidHorizontal)
        );
    }

    #[test]
    fn jumping_returns_to_authoritative_ground() {
        let player = PlayerId::new(11);
        let mut world = World::default();
        world.join(player).unwrap();
        world.submit_intent(player, intent(1, 0, true)).unwrap();

        let first = world.advance_tick();
        assert!(first.characters[0].position_y > 0);
        assert!(!first.characters[0].grounded);

        for _ in 0..40 {
            world.advance_tick();
        }

        let final_state = world.snapshot().characters[0];
        assert_eq!(final_state.position_y, 0);
        assert!(final_state.grounded);
    }

    #[test]
    fn world_bounds_are_enforced_by_the_simulation() {
        let config = WorldConfig {
            minimum_x: -500,
            maximum_x: 500,
            ..WorldConfig::default()
        };
        let player = PlayerId::new(13);
        let mut world = World::new(config);
        world.join(player).unwrap();
        world.submit_intent(player, intent(1, 1, false)).unwrap();

        let snapshot = world.advance_tick();

        assert_eq!(snapshot.characters[0].position_x, 500);
    }
}
