#![forbid(unsafe_code)]

//! Versioned JSON wire contract between the Godot client and the world server.
//! This crate is transport- and simulation-agnostic: it defines message shapes
//! and (de)serialization only. The server maps `game-domain` snapshots onto the
//! [`WireEntity`] types here.

use serde::{Deserialize, Serialize};

/// Protocol version. v3 introduces multi-zone, entity-tagged snapshots and a
/// richer intent (climb/drop/guard/action) alongside the account/hero
/// handshake from v2.
pub const PROTOCOL_VERSION: u16 = 3;
pub const MAX_CLIENT_MESSAGE_BYTES: usize = 8 * 1024;

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    Hello {
        protocol_version: u16,
        client_build: String,
    },
    JoinWorld {
        account_id: String,
        hero_name: String,
    },
    Intent {
        sequence: u64,
        client_tick: u64,
        /// -1 / 0 / 1
        move_axis: i8,
        /// -1 / 0 / 1 (wire is y-up: +1 = up a ladder)
        climb_axis: i8,
        jump: bool,
        drop: bool,
        guard: bool,
        /// 0 = none; 1/3/4/5/6 activate that hotbar slot.
        action_slot: u8,
    },
    SelectWeapon {
        weapon: WireWeapon,
    },
    UsePortal {
        portal_id: String,
    },
    Ping {
        nonce: u64,
    },
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    HelloAccepted {
        protocol_version: u16,
        tick_rate_hz: u16,
    },
    WorldJoined {
        player_id: String,
        hero_name: String,
        lineage: String,
        zone: String,
    },
    JoinRejected {
        reason: JoinRejectionReason,
    },
    Snapshot {
        server_tick: u64,
        zone: String,
        entities: Vec<WireEntity>,
    },
    ZoneChanged {
        zone: String,
        spawn_x: i32,
        spawn_y: i32,
        facing: i8,
    },
    IntentRejected {
        sequence: u64,
        reason: RejectionReason,
    },
    Pong {
        nonce: u64,
    },
    Disconnect {
        reason: DisconnectReason,
    },
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
// Tag is "entity" (not "kind") so it never collides with WireProjectile.kind.
#[serde(tag = "entity", rename_all = "snake_case")]
pub enum WireEntity {
    Hero(WireHero),
    Monster(WireEnemy),
    Biter(WireEnemy),
    Projectile(WireProjectile),
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
pub struct WireHero {
    pub entity_id: String,
    pub player_id: String,
    pub hero_name: String,
    pub lineage: String,
    pub weapon: WireWeapon,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub velocity_y: i32,
    pub facing: i8,
    pub grounded: bool,
    pub climbing: bool,
    pub health: i32,
    pub max_health: i32,
    pub stamina: i32,
    pub mana: i32,
    pub action_state: String,
    pub last_processed_intent: u64,
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
pub struct WireEnemy {
    pub entity_id: String,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub velocity_y: i32,
    pub facing: i8,
    pub health: i32,
    pub max_health: i32,
    pub ai_state: String,
    pub telegraph_ticks: u16,
}

#[derive(Clone, Debug, Deserialize, PartialEq, Serialize)]
pub struct WireProjectile {
    pub entity_id: String,
    pub owner: String,
    pub kind: String,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub facing: i8,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum WireWeapon {
    Sword,
    AxeShield,
    Bow,
    Staff,
    Wand,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum RejectionReason {
    InvalidIntent,
    StaleSequence,
    RateLimited,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum JoinRejectionReason {
    HeroAlreadyOnline,
    InvalidHero,
    NotNegotiated,
}

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum DisconnectReason {
    ExpectedHello,
    ExpectedJoin,
    MessageTooLarge,
    MalformedMessage,
    ProtocolMismatch,
    ServerShutdown,
}

pub fn encode_server_message(message: &ServerMessage) -> serde_json::Result<String> {
    serde_json::to_string(message)
}

pub fn decode_client_message(input: &str) -> serde_json::Result<ClientMessage> {
    serde_json::from_str(input)
}

pub fn encode_client_message(message: &ClientMessage) -> serde_json::Result<String> {
    serde_json::to_string(message)
}

pub fn decode_server_message(input: &str) -> serde_json::Result<ServerMessage> {
    serde_json::from_str(input)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn intent_has_a_stable_tagged_shape() {
        let message = ClientMessage::Intent {
            sequence: 3,
            client_tick: 8,
            move_axis: -1,
            climb_axis: 1,
            jump: true,
            drop: false,
            guard: false,
            action_slot: 4,
        };
        let json = encode_client_message(&message).unwrap();
        assert_eq!(
            json,
            r#"{"type":"intent","sequence":3,"client_tick":8,"move_axis":-1,"climb_axis":1,"jump":true,"drop":false,"guard":false,"action_slot":4}"#
        );
        assert_eq!(decode_client_message(&json).unwrap(), message);
    }

    #[test]
    fn join_world_round_trips() {
        let message = ClientMessage::JoinWorld {
            account_id: "acct-7".to_owned(),
            hero_name: "Aria".to_owned(),
        };
        let json = encode_client_message(&message).unwrap();
        assert_eq!(
            json,
            r#"{"type":"join_world","account_id":"acct-7","hero_name":"Aria"}"#
        );
        assert_eq!(decode_client_message(&json).unwrap(), message);
    }

    #[test]
    fn snapshot_carries_zone_and_tagged_entities() {
        let message = ServerMessage::Snapshot {
            server_tick: 42,
            zone: "sunlit_forest".to_owned(),
            entities: vec![
                WireEntity::Hero(WireHero {
                    entity_id: "1".to_owned(),
                    player_id: "1".to_owned(),
                    hero_name: "Aria".to_owned(),
                    lineage: "human".to_owned(),
                    weapon: WireWeapon::Sword,
                    position_x: 28_500,
                    position_y: 17_000,
                    velocity_x: 0,
                    velocity_y: 0,
                    facing: 1,
                    grounded: true,
                    climbing: false,
                    health: 100,
                    max_health: 100,
                    stamina: 100,
                    mana: 100,
                    action_state: "ready".to_owned(),
                    last_processed_intent: 5,
                }),
                WireEntity::Monster(WireEnemy {
                    entity_id: "1000000".to_owned(),
                    position_x: 76_000,
                    position_y: 17_000,
                    velocity_x: 0,
                    velocity_y: 0,
                    facing: -1,
                    health: 120,
                    max_health: 120,
                    ai_state: "watching".to_owned(),
                    telegraph_ticks: 0,
                }),
            ],
        };
        let json = encode_server_message(&message).unwrap();
        assert!(json.contains(r#""type":"snapshot""#));
        assert!(json.contains(r#""zone":"sunlit_forest""#));
        assert!(json.contains(r#""entity":"hero""#));
        assert!(json.contains(r#""entity":"monster""#));
        assert_eq!(decode_server_message(&json).unwrap(), message);
    }

    #[test]
    fn projectile_entity_round_trips() {
        let message = WireEntity::Projectile(WireProjectile {
            entity_id: "2000001".to_owned(),
            owner: "1".to_owned(),
            kind: "arrow".to_owned(),
            position_x: 30_000,
            position_y: 17_500,
            velocity_x: 3_100,
            facing: 1,
        });
        let json = serde_json::to_string(&message).unwrap();
        assert!(json.contains(r#""entity":"projectile""#));
        assert_eq!(serde_json::from_str::<WireEntity>(&json).unwrap(), message);
    }
}
