//! Throwaway end-to-end check for the account/hero handshake and the shared
//! world. Against a running world-server it:
//!   * joins two heroes under different accounts (observer + runner),
//!   * has the runner run right and jump while the observer stays idle,
//!   * shows both clients observe the one authoritative world, and
//!   * proves a hero cannot be controlled by two Sessions at once.
//!
//! Run the server first (`cargo run -p world-server`), then:
//!   cargo run -p world-server --example two_client_demo

use std::time::Duration;

use futures_util::{SinkExt, StreamExt};
use game_protocol::{
    ClientMessage, PROTOCOL_VERSION, ServerMessage, decode_server_message, encode_client_message,
};
use tokio::time::{self, Instant};
use tokio_tungstenite::{connect_async, tungstenite::Message};

const URL: &str = "ws://127.0.0.1:8787";

#[tokio::main]
async fn main() {
    // The idle observer joins first so it is present when the runner moves.
    let observer = tokio::spawn(play("observer", "acct-obs", "Watcher", 0, false, 60));
    time::sleep(Duration::from_millis(150)).await;
    let runner = tokio::spawn(play("runner", "acct-run", "Runner", 1, true, 40));

    // While the runner is online, a second client tries to grab the same hero.
    time::sleep(Duration::from_millis(400)).await;
    let impostor = tokio::spawn(try_steal_hero("acct-run", "Runner"));

    let _ = tokio::join!(runner, observer, impostor);
}

/// Hello -> HelloAccepted -> JoinWorld -> WorldJoined, then stream intents.
async fn play(
    label: &'static str,
    account_id: &'static str,
    hero_name: &'static str,
    horizontal: i8,
    jump_once: bool,
    intents: u32,
) {
    let (mut socket, _) = connect_async(URL).await.expect("connect");
    send(&mut socket, &ClientMessage::Hello {
        protocol_version: PROTOCOL_VERSION,
        client_build: "two-client-demo".to_owned(),
    })
    .await;

    let mut player_id = String::new();
    let mut negotiated = false;
    let mut joined = false;
    let mut sequence = 0u64;
    let mut sent = 0u32;
    let mut jumped = false;
    let mut logged = 0;
    let mut interval = time::interval(Duration::from_millis(50));
    let deadline = Instant::now() + Duration::from_secs(3);

    loop {
        tokio::select! {
            _ = interval.tick() => {
                if joined && sent < intents {
                    sequence += 1;
                    sent += 1;
                    let jump = jump_once && !jumped && sent == 3;
                    jumped |= jump;
                    send(&mut socket, &ClientMessage::Intent {
                        sequence, client_tick: sequence, horizontal, jump,
                    }).await;
                }
            }
            incoming = socket.next() => {
                let Some(Ok(Message::Text(text))) = incoming else { break; };
                match decode_server_message(&text) {
                    Ok(ServerMessage::HelloAccepted { tick_rate_hz, .. }) => {
                        negotiated = true;
                        println!("[{label}] negotiated @ {tick_rate_hz} Hz; joining as {hero_name}");
                        send(&mut socket, &ClientMessage::JoinWorld {
                            account_id: account_id.to_owned(),
                            hero_name: hero_name.to_owned(),
                        }).await;
                    }
                    Ok(ServerMessage::WorldJoined { player_id: id, hero_name: hn, lineage }) => {
                        player_id = id;
                        joined = true;
                        println!("[{label}] world joined: hero {hn} ({lineage}) = player {player_id}");
                    }
                    Ok(ServerMessage::Snapshot { server_tick, characters }) => {
                        if server_tick % 12 == 0 && logged < 5 {
                            logged += 1;
                            let mut view: Vec<String> = characters.iter().map(|c| {
                                let me = if c.player_id == player_id { "*" } else { " " };
                                format!("{me}p{}=({},{})", c.player_id, c.position_x, c.position_y)
                            }).collect();
                            view.sort();
                            println!("[{label}] tick {server_tick:>3} | {}", view.join("  "));
                        }
                    }
                    _ => {}
                }
            }
        }
        let _ = negotiated;
        if Instant::now() >= deadline { break; }
    }
    let _ = socket.close(None).await;
    println!("[{label}] left (was player {player_id})");
}

/// Attempts to join a hero that is already online; expects a rejection.
async fn try_steal_hero(account_id: &'static str, hero_name: &'static str) {
    let (mut socket, _) = connect_async(URL).await.expect("connect");
    send(&mut socket, &ClientMessage::Hello {
        protocol_version: PROTOCOL_VERSION,
        client_build: "impostor".to_owned(),
    })
    .await;

    while let Some(Ok(Message::Text(text))) = socket.next().await {
        match decode_server_message(&text) {
            Ok(ServerMessage::HelloAccepted { .. }) => {
                send(&mut socket, &ClientMessage::JoinWorld {
                    account_id: account_id.to_owned(),
                    hero_name: hero_name.to_owned(),
                })
                .await;
            }
            Ok(ServerMessage::JoinRejected { reason }) => {
                println!("[impostor] join of live hero {hero_name} rejected: {reason:?}  <-- expected");
                break;
            }
            Ok(ServerMessage::WorldJoined { .. }) => {
                println!("[impostor] ERROR: was allowed to steal a live hero!");
                break;
            }
            _ => {}
        }
    }
    let _ = socket.close(None).await;
}

async fn send(
    socket: &mut tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
    message: &ClientMessage,
) {
    let text = encode_client_message(message).unwrap();
    socket.send(Message::Text(text.into())).await.unwrap();
}
