#![forbid(unsafe_code)]

use serde::{Deserialize, Serialize};

pub const PROTOCOL_VERSION: u16 = 1;
pub const MAX_CLIENT_MESSAGE_BYTES: usize = 4 * 1024;

#[derive(Clone, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    Hello {
        protocol_version: u16,
        client_build: String,
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
        player_id: String,
        tick_rate_hz: u16,
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
pub enum DisconnectReason {
    ExpectedHello,
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
        let message = ServerMessage::HelloAccepted {
            protocol_version: PROTOCOL_VERSION,
            player_id: "9007199254740993".to_owned(),
            tick_rate_hz: 20,
        };

        let json = encode_server_message(&message).unwrap();

        assert!(json.contains(r#""player_id":"9007199254740993""#));
    }
}
