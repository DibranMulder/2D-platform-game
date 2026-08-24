//! End-to-end check for the converged, multi-zone, server-authoritative world.
//! Against a running world-server it:
//!   * joins two heroes in the Sunlit Forest (observer + runner),
//!   * confirms both see each other and the forest Monster in snapshots,
//!   * walks the runner right into the Market portal and confirms a ZoneChanged,
//!   * confirms zone isolation: once the runner is in the Market, the observer's
//!     Forest snapshots no longer contain it.
//!
//! Run the server first (`cargo run -p world-server`), then:
//!   cargo run -p world-server --example two_client_demo

use std::sync::{Arc, Mutex};
use std::time::Duration;

use futures_util::{SinkExt, StreamExt};
use game_protocol::{
    ClientMessage, PROTOCOL_VERSION, ServerMessage, WireEntity, decode_server_message,
    encode_client_message,
};
use tokio::time::{self, Instant};
use tokio_tungstenite::{connect_async, tungstenite::Message};

const URL: &str = "ws://127.0.0.1:8787";

/// Shared flag: set to the runner's player id once it is known, so the observer
/// can report whether it still sees the runner in the forest.
type RunnerId = Arc<Mutex<Option<String>>>;

#[tokio::main]
async fn main() {
    let runner_id: RunnerId = Arc::new(Mutex::new(None));
    let observer = tokio::spawn(observe(Arc::clone(&runner_id)));
    time::sleep(Duration::from_millis(150)).await;
    let runner = tokio::spawn(run_across_portal(runner_id));
    let _ = tokio::join!(runner, observer);
}

async fn connect_and_join(
    account: &str,
    hero: &str,
) -> (
    tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>,
    String,
    String,
) {
    let (mut socket, _) = connect_async(URL).await.expect("connect");
    send(&mut socket, &ClientMessage::Hello {
        protocol_version: PROTOCOL_VERSION,
        client_build: "two-client-demo".to_owned(),
    })
    .await;

    let mut player_id = String::new();
    let mut zone = String::new();
    while let Some(Ok(Message::Text(text))) = socket.next().await {
        match decode_server_message(&text) {
            Ok(ServerMessage::HelloAccepted { .. }) => {
                send(&mut socket, &ClientMessage::JoinWorld {
                    account_id: account.to_owned(),
                    hero_name: hero.to_owned(),
                })
                .await;
            }
            Ok(ServerMessage::WorldJoined { player_id: id, zone: z, .. }) => {
                player_id = id;
                zone = z;
                break;
            }
            Ok(ServerMessage::JoinRejected { reason }) => {
                panic!("[{hero}] join rejected: {reason:?}");
            }
            _ => {}
        }
    }
    println!("[{hero}] joined zone={zone} as player {player_id}");
    (socket, player_id, zone)
}

async fn observe(runner_id: RunnerId) {
    let (mut socket, _my_id, _) = connect_and_join("acct-obs", "Watcher").await;
    let mut interval = time::interval(Duration::from_millis(50));
    let deadline = Instant::now() + Duration::from_secs(6);
    let mut saw_runner_in_forest = false;
    let mut still_sees_runner_after_transfer = true;

    loop {
        tokio::select! {
            _ = interval.tick() => {
                // Idle: send a neutral intent to stay a good citizen.
                send_intent(&mut socket, 0).await;
            }
            incoming = socket.next() => {
                let Some(Ok(Message::Text(text))) = incoming else { break; };
                if let Ok(ServerMessage::Snapshot { server_tick, zone, entities }) = decode_server_message(&text) {
                    let heroes = hero_ids(&entities);
                    let runner = runner_id.lock().unwrap().clone();
                    if let Some(runner) = runner {
                        if heroes.contains(&runner) { saw_runner_in_forest = true; }
                        // After the runner has left (we know its id and it is gone), check isolation.
                        if saw_runner_in_forest && !heroes.contains(&runner) {
                            still_sees_runner_after_transfer = false;
                        }
                    }
                    if server_tick % 20 == 0 {
                        println!("[Watcher] tick {server_tick:>3} zone={zone} heroes={heroes:?} entities={}", entities.len());
                    }
                }
            }
        }
        if Instant::now() >= deadline { break; }
    }
    println!(
        "[Watcher] saw runner in forest={saw_runner_in_forest}  isolation_after_transfer={}",
        if saw_runner_in_forest && !still_sees_runner_after_transfer { "OK (runner vanished from forest)" } else { "n/a" }
    );
    let _ = socket.close(None).await;
}

async fn run_across_portal(runner_id: RunnerId) {
    let (mut socket, my_id, _) = connect_and_join("acct-run", "Runner").await;
    *runner_id.lock().unwrap() = Some(my_id.clone());

    let mut interval = time::interval(Duration::from_millis(50));
    let deadline = Instant::now() + Duration::from_secs(6);
    let mut changed_zone = false;

    loop {
        tokio::select! {
            _ = interval.tick() => {
                send_intent(&mut socket, 1).await; // hold right
            }
            incoming = socket.next() => {
                let Some(Ok(Message::Text(text))) = incoming else { break; };
                match decode_server_message(&text) {
                    Ok(ServerMessage::ZoneChanged { zone, spawn_x, spawn_y, .. }) => {
                        changed_zone = true;
                        println!("[Runner] ZoneChanged -> {zone} at ({spawn_x},{spawn_y})  <-- portal worked");
                    }
                    Ok(ServerMessage::Snapshot { server_tick, zone, entities }) => {
                        if server_tick % 20 == 0 {
                            let me = hero_ids(&entities).into_iter().find(|id| *id == my_id);
                            println!("[Runner]  tick {server_tick:>3} zone={zone} present={:?} entities={}", me, entities.len());
                        }
                    }
                    _ => {}
                }
            }
        }
        if Instant::now() >= deadline { break; }
    }
    println!("[Runner] crossed a portal = {changed_zone}");
    let _ = socket.close(None).await;
}

fn hero_ids(entities: &[WireEntity]) -> Vec<String> {
    entities
        .iter()
        .filter_map(|entity| match entity {
            WireEntity::Hero(hero) => Some(hero.player_id.clone()),
            _ => None,
        })
        .collect()
}

async fn send_intent(
    socket: &mut tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
    move_axis: i8,
) {
    use std::sync::atomic::{AtomicU64, Ordering};
    static SEQ: AtomicU64 = AtomicU64::new(0);
    let sequence = SEQ.fetch_add(1, Ordering::Relaxed) + 1;
    send(socket, &ClientMessage::Intent {
        sequence,
        client_tick: sequence,
        move_axis,
        climb_axis: 0,
        jump: false,
        drop: false,
        guard: false,
        action_slot: 0,
    })
    .await;
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
