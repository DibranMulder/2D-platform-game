#![forbid(unsafe_code)]

use std::{
    env,
    error::Error,
    io,
    net::SocketAddr,
    sync::{
        Arc,
        atomic::{AtomicU64, Ordering},
    },
    time::Duration,
};

use futures_util::{SinkExt, StreamExt};
use game_domain::{IntentError, PlayerId, PlayerIntent, World, WorldSnapshot};
use game_protocol::{
    ClientMessage, DisconnectReason, MAX_CLIENT_MESSAGE_BYTES, PROTOCOL_VERSION, RejectionReason,
    ServerMessage, WireCharacterState, decode_client_message, encode_server_message,
};
use tokio::{
    net::{TcpListener, TcpStream},
    sync::{Mutex, broadcast},
    time::{self, Instant, MissedTickBehavior},
};
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{info, warn};
use tracing_subscriber::EnvFilter;

const TICK_RATE_HZ: u16 = 20;
const MAX_INTENTS_PER_SECOND: u32 = 60;

type AnyError = Box<dyn Error + Send + Sync>;

struct SharedServer {
    world: Mutex<World>,
    snapshots: broadcast::Sender<String>,
    next_player_id: AtomicU64,
}

struct IntentRateLimit {
    window_started: Instant,
    count: u32,
}

impl IntentRateLimit {
    fn new() -> Self {
        Self {
            window_started: Instant::now(),
            count: 0,
        }
    }

    fn allow(&mut self) -> bool {
        if self.window_started.elapsed() >= Duration::from_secs(1) {
            self.window_started = Instant::now();
            self.count = 0;
        }

        self.count = self.count.saturating_add(1);
        self.count <= MAX_INTENTS_PER_SECOND
    }
}

#[tokio::main]
async fn main() -> Result<(), AnyError> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")),
        )
        .json()
        .init();

    let bind_address = env::var("MMO_BIND_ADDR").unwrap_or_else(|_| "127.0.0.1:8787".to_owned());
    let listener = TcpListener::bind(&bind_address).await?;
    let (snapshot_sender, _) = broadcast::channel(64);
    let shared = Arc::new(SharedServer {
        world: Mutex::new(World::default()),
        snapshots: snapshot_sender,
        next_player_id: AtomicU64::new(1),
    });

    tokio::spawn(run_simulation(Arc::clone(&shared)));
    info!(
        bind_address,
        tick_rate_hz = TICK_RATE_HZ,
        "world server ready"
    );

    loop {
        tokio::select! {
            accepted = listener.accept() => {
                let (stream, peer) = accepted?;
                let connection_server = Arc::clone(&shared);
                tokio::spawn(async move {
                    if let Err(error) = handle_connection(stream, peer, connection_server).await {
                        warn!(%peer, %error, "connection ended with an error");
                    }
                });
            }
            result = tokio::signal::ctrl_c() => {
                result?;
                info!("shutdown requested");
                break;
            }
        }
    }

    Ok(())
}

async fn run_simulation(shared: Arc<SharedServer>) {
    let mut interval = time::interval(Duration::from_millis(1_000 / u64::from(TICK_RATE_HZ)));
    interval.set_missed_tick_behavior(MissedTickBehavior::Skip);

    loop {
        interval.tick().await;
        let snapshot = shared.world.lock().await.advance_tick();
        let message = snapshot_message(snapshot);

        match encode_server_message(&message) {
            Ok(json) => {
                let _ = shared.snapshots.send(json);
            }
            Err(error) => warn!(%error, "could not encode world snapshot"),
        }
    }
}

async fn handle_connection(
    stream: TcpStream,
    peer: SocketAddr,
    shared: Arc<SharedServer>,
) -> Result<(), AnyError> {
    let websocket = accept_async(stream).await?;
    let (mut sink, mut source) = websocket.split();

    let first_message = time::timeout(Duration::from_secs(5), source.next())
        .await
        .map_err(|_| io::Error::new(io::ErrorKind::TimedOut, "hello timed out"))?
        .ok_or_else(|| io::Error::new(io::ErrorKind::UnexpectedEof, "connection closed"))??;

    let Some(hello_text) = message_text(first_message) else {
        send_disconnect(&mut sink, DisconnectReason::ExpectedHello).await?;
        return Ok(());
    };

    if hello_text.len() > MAX_CLIENT_MESSAGE_BYTES {
        send_disconnect(&mut sink, DisconnectReason::MessageTooLarge).await?;
        return Ok(());
    }

    let Ok(ClientMessage::Hello {
        protocol_version,
        client_build,
    }) = decode_client_message(&hello_text)
    else {
        send_disconnect(&mut sink, DisconnectReason::ExpectedHello).await?;
        return Ok(());
    };

    if protocol_version != PROTOCOL_VERSION {
        send_disconnect(&mut sink, DisconnectReason::ProtocolMismatch).await?;
        return Ok(());
    }

    let player_id = PlayerId::new(shared.next_player_id.fetch_add(1, Ordering::Relaxed));
    shared
        .world
        .lock()
        .await
        .join(player_id)
        .map_err(|_| io::Error::new(io::ErrorKind::AlreadyExists, "player already joined"))?;

    let accepted = ServerMessage::HelloAccepted {
        protocol_version: PROTOCOL_VERSION,
        player_id: player_id.get().to_string(),
        tick_rate_hz: TICK_RATE_HZ,
    };
    sink.send(Message::Text(encode_server_message(&accepted)?.into()))
        .await?;

    let mut snapshots = shared.snapshots.subscribe();
    let mut rate_limit = IntentRateLimit::new();
    info!(%peer, player_id = player_id.get(), %client_build, "session joined");

    loop {
        tokio::select! {
            incoming = source.next() => {
                match incoming {
                    Some(Ok(message)) => {
                        if !handle_client_message(
                            message,
                            player_id,
                            &shared,
                            &mut sink,
                            &mut rate_limit,
                        ).await? {
                            break;
                        }
                    }
                    Some(Err(error)) => return Err(error.into()),
                    None => break,
                }
            }
            snapshot = snapshots.recv() => {
                match snapshot {
                    Ok(json) => sink.send(Message::Text(json.into())).await?,
                    Err(broadcast::error::RecvError::Lagged(skipped)) => {
                        warn!(player_id = player_id.get(), skipped, "snapshot receiver lagged");
                    }
                    Err(broadcast::error::RecvError::Closed) => break,
                }
            }
        }
    }

    shared.world.lock().await.leave(player_id);
    info!(%peer, player_id = player_id.get(), "session left");
    Ok(())
}

async fn handle_client_message<S>(
    message: Message,
    player_id: PlayerId,
    shared: &SharedServer,
    sink: &mut S,
    rate_limit: &mut IntentRateLimit,
) -> Result<bool, AnyError>
where
    S: futures_util::Sink<Message> + Unpin,
    S::Error: Error + Send + Sync + 'static,
{
    if message.is_close() {
        return Ok(false);
    }

    let Some(text) = message_text(message) else {
        return Ok(true);
    };

    if text.len() > MAX_CLIENT_MESSAGE_BYTES {
        send_disconnect(sink, DisconnectReason::MessageTooLarge).await?;
        return Ok(false);
    }

    let client_message = match decode_client_message(&text) {
        Ok(message) => message,
        Err(_) => {
            send_disconnect(sink, DisconnectReason::MalformedMessage).await?;
            return Ok(false);
        }
    };

    match client_message {
        ClientMessage::Intent {
            sequence,
            client_tick,
            horizontal,
            jump,
        } => {
            if !rate_limit.allow() {
                send_rejection(sink, sequence, RejectionReason::RateLimited).await?;
                return Ok(true);
            }

            let result = shared.world.lock().await.submit_intent(
                player_id,
                PlayerIntent {
                    sequence,
                    client_tick,
                    horizontal,
                    jump,
                },
            );

            if let Err(error) = result {
                let reason = match error {
                    IntentError::StaleSequence => RejectionReason::StaleSequence,
                    IntentError::InvalidHorizontal | IntentError::UnknownPlayer => {
                        RejectionReason::InvalidIntent
                    }
                };
                send_rejection(sink, sequence, reason).await?;
            }
        }
        ClientMessage::Ping { nonce } => {
            let pong = encode_server_message(&ServerMessage::Pong { nonce })?;
            sink.send(Message::Text(pong.into())).await?;
        }
        ClientMessage::Hello { .. } => {
            send_disconnect(sink, DisconnectReason::MalformedMessage).await?;
            return Ok(false);
        }
    }

    Ok(true)
}

fn message_text(message: Message) -> Option<String> {
    match message {
        Message::Text(text) => Some(text.to_string()),
        _ => None,
    }
}

async fn send_rejection<S>(
    sink: &mut S,
    sequence: u64,
    reason: RejectionReason,
) -> Result<(), AnyError>
where
    S: futures_util::Sink<Message> + Unpin,
    S::Error: Error + Send + Sync + 'static,
{
    let json = encode_server_message(&ServerMessage::IntentRejected { sequence, reason })?;
    sink.send(Message::Text(json.into())).await?;
    Ok(())
}

async fn send_disconnect<S>(sink: &mut S, reason: DisconnectReason) -> Result<(), AnyError>
where
    S: futures_util::Sink<Message> + Unpin,
    S::Error: Error + Send + Sync + 'static,
{
    let json = encode_server_message(&ServerMessage::Disconnect { reason })?;
    sink.send(Message::Text(json.into())).await?;
    sink.send(Message::Close(None)).await?;
    Ok(())
}

fn snapshot_message(snapshot: WorldSnapshot) -> ServerMessage {
    ServerMessage::Snapshot {
        server_tick: snapshot.server_tick,
        characters: snapshot
            .characters
            .into_iter()
            .map(|state| WireCharacterState {
                player_id: state.player_id.get().to_string(),
                position_x: state.position_x,
                position_y: state.position_y,
                velocity_x: state.velocity_x,
                velocity_y: state.velocity_y,
                grounded: state.grounded,
                last_processed_intent: state.last_processed_intent,
            })
            .collect(),
    }
}
