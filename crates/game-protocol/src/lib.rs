#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};

pub const PROTOCOL_VERSION: u16 = 2;
pub const MAX_CLIENT_MESSAGE_BYTES: usize = 4 * 1024;

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
        horizontal: i8,
        jump: bool,
    },
    Ping {
        nonce: u64,
    },
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
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
    },
    JoinRejected {
        reason: JoinRejectionReason,
    },
    Snapshot {
        server_tick: u64,
        characters: Vec<WireCharacterState>,
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

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
pub struct WireCharacterState {
    pub player_id: String,
    pub position_x: i32,
    pub position_y: i32,
    pub velocity_x: i32,
    pub velocity_y: i32,
    pub grounded: bool,
    pub last_processed_intent: u64,
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
    /// The named hero is already controlled by another live Session.
    HeroAlreadyOnline,
    /// The account id or hero name was empty or otherwise unusable.
    InvalidHero,
    /// A JoinWorld arrived before a successful Hello negotiation.
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
    fn client_message_uses_a_stable_tagged_shape() {
        let message = ClientMessage::Intent {
            sequence: 3,
            client_tick: 8,
            horizontal: -1,
            jump: true,
        };

        let json = serde_json::to_string(&message).unwrap();

        assert_eq!(
            json,
            r#"{"type":"intent","sequence":3,"client_tick":8,"horizontal":-1,"jump":true}"#
        );
        assert_eq!(
            serde_json::from_str::<ClientMessage>(&json).unwrap(),
            message
        );
    }

    #[test]
    fn player_ids_are_strings_on_the_wire() {
        let message = ServerMessage::WorldJoined {
            player_id: "9007199254740993".to_owned(),
            hero_name: "Aria".to_owned(),
            lineage: "human".to_owned(),
        };

        let json = encode_server_message(&message).unwrap();

        assert!(json.contains(r#""player_id":"9007199254740993""#));
    }

    #[test]
    fn join_world_round_trips_account_and_hero() {
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
}
