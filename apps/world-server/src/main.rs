#![forbid(unsafe_code)]

mod identity;
mod wire;

use std::{
    collections::HashMap,
    env,
    error::Error,
    io,
    net::SocketAddr,
    sync::Arc,
    time::Duration,
};

use futures_util::{SinkExt, StreamExt};
use game_domain::{
    Allegiance, HeroDescriptor, PlayerId, PlayerIntent, WeaponId, World, ZoneId, zone_slug,
};
use game_protocol::{
    ClientMessage, DisconnectReason, JoinRejectionReason, MAX_CLIENT_MESSAGE_BYTES,
    PROTOCOL_VERSION, RejectionReason, ServerMessage, decode_client_message, encode_server_message,
};
use identity::AccountRegistry;
use tokio::{
    net::{TcpListener, TcpStream},
    sync::{Mutex, broadcast, mpsc},
    time::{self, Instant, MissedTickBehavior},
};
use tokio_tungstenite::{accept_async, tungstenite::Message};
use tracing::{info, warn};
use tracing_subscriber::EnvFilter;

const TICK_RATE_HZ: u16 = 20;
const MAX_INTENTS_PER_SECOND: u32 = 60;

type AnyError = Box<dyn Error + Send + Sync>;

/// A Lineage's Allegiance (DESIGN-0008), used for Stronghold gate checks.
fn allegiance_for(lineage: &str) -> Allegiance {
    match lineage {
        "crag_troll" | "deep_goblin" | "sunscour" | "rimeborn" => Allegiance::Dark,
        _ => Allegiance::Light,
    }
}

/// Sent from the simulation task to a connection when its hero changes zones,
/// so the connection can tell the client and re-subscribe to the new zone.
#[derive(Clone, Copy, Debug)]
enum ControlEvent {
    ZoneChanged {
        zone: ZoneId,
        spawn_x: i32,
        spawn_y: i32,
        facing: i8,
    },
}

struct SharedServer {
    world: Mutex<World>,
    registry: Mutex<AccountRegistry>,
    zone_tx: HashMap<ZoneId, broadcast::Sender<String>>,
    control: Mutex<HashMap<PlayerId, mpsc::UnboundedSender<ControlEvent>>>,
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

    let world = World::default();
    let mut zone_tx = HashMap::new();
    for zone in world.zone_ids() {
        zone_tx.insert(zone, broadcast::channel(64).0);
    }
    let shared = Arc::new(SharedServer {
        world: Mutex::new(world),
        registry: Mutex::new(AccountRegistry::new()),
        zone_tx,
        control: Mutex::new(HashMap::new()),
    });

    tokio::spawn(run_simulation(Arc::clone(&shared)));
    info!(bind_address, tick_rate_hz = TICK_RATE_HZ, "world server ready");

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
        let outcome = shared.world.lock().await.advance_tick();

        for snapshot in &outcome.snapshots {
            let Some(sender) = shared.zone_tx.get(&snapshot.zone) else {
                continue;
            };
            if sender.receiver_count() == 0 {
                continue;
            }
            match encode_server_message(&wire::snapshot_message(snapshot)) {
                Ok(json) => {
                    let _ = sender.send(json);
                }
                Err(error) => warn!(%error, "could not encode snapshot"),
            }
        }

        if !outcome.transfers.is_empty() {
            let control = shared.control.lock().await;
            for transfer in &outcome.transfers {
                if let Some(sender) = control.get(&transfer.player_id) {
                    let _ = sender.send(ControlEvent::ZoneChanged {
                        zone: transfer.to,
                        spawn_x: transfer.spawn_x,
                        spawn_y: transfer.spawn_y,
                        facing: transfer.facing,
                    });
                }
            }
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

    // --- Phase 1: protocol negotiation ---
    let first = time::timeout(Duration::from_secs(5), source.next())
        .await
        .map_err(|_| io::Error::new(io::ErrorKind::TimedOut, "hello timed out"))?
        .ok_or_else(|| io::Error::new(io::ErrorKind::UnexpectedEof, "connection closed"))??;

    let Some(hello_text) = message_text(first) else {
        send_disconnect(&mut sink, DisconnectReason::ExpectedHello).await?;
        return Ok(());
    };
    if hello_text.len() > MAX_CLIENT_MESSAGE_BYTES {
        send_disconnect(&mut sink, DisconnectReason::MessageTooLarge).await?;
        return Ok(());
    }
    let Ok(ClientMessage::Hello { protocol_version, client_build }) = decode_client_message(&hello_text) else {
        send_disconnect(&mut sink, DisconnectReason::ExpectedHello).await?;
        return Ok(());
    };
    if protocol_version != PROTOCOL_VERSION {
        send_disconnect(&mut sink, DisconnectReason::ProtocolMismatch).await?;
        return Ok(());
    }
    sink.send(Message::Text(
        encode_server_message(&ServerMessage::HelloAccepted {
            protocol_version: PROTOCOL_VERSION,
            tick_rate_hz: TICK_RATE_HZ,
        })?
        .into(),
    ))
    .await?;

    // --- Phase 2: session admission (JoinWorld) ---
    let (player_id, hero_name, current_zone) = loop {
        let message = time::timeout(Duration::from_secs(30), source.next())
            .await
            .map_err(|_| io::Error::new(io::ErrorKind::TimedOut, "join timed out"))?
            .ok_or_else(|| io::Error::new(io::ErrorKind::UnexpectedEof, "connection closed"))??;
        if message.is_close() {
            return Ok(());
        }
        let Some(text) = message_text(message) else {
            continue;
        };
        if text.len() > MAX_CLIENT_MESSAGE_BYTES {
            send_disconnect(&mut sink, DisconnectReason::MessageTooLarge).await?;
            return Ok(());
        }
        match decode_client_message(&text) {
            Ok(ClientMessage::JoinWorld { account_id, hero_name }) => {
                let admitted = shared.registry.lock().await.admit(&account_id, &hero_name);
                match admitted {
                    Ok(admission) => {
                        let descriptor = HeroDescriptor {
                            hero_name: admission.hero_name.clone(),
                            lineage: admission.lineage.clone(),
                            weapon: WeaponId::Sword,
                            allegiance: allegiance_for(&admission.lineage),
                        };
                        let zone = match shared.world.lock().await.join(admission.player_id, descriptor) {
                            Ok(zone) => zone,
                            Err(_) => {
                                shared.registry.lock().await.release(admission.player_id);
                                send_join_rejected(&mut sink, JoinRejectionReason::HeroAlreadyOnline).await?;
                                continue;
                            }
                        };
                        sink.send(Message::Text(
                            encode_server_message(&ServerMessage::WorldJoined {
                                player_id: admission.player_id.get().to_string(),
                                hero_name: admission.hero_name.clone(),
                                lineage: admission.lineage.clone(),
                                zone: zone_slug(zone).to_owned(),
                            })?
                            .into(),
                        ))
                        .await?;
                        break (admission.player_id, admission.hero_name, zone);
                    }
                    Err(reason) => send_join_rejected(&mut sink, reason).await?,
                }
            }
            Ok(ClientMessage::Ping { nonce }) => {
                sink.send(Message::Text(
                    encode_server_message(&ServerMessage::Pong { nonce })?.into(),
                ))
                .await?;
            }
            Ok(_) => {
                send_disconnect(&mut sink, DisconnectReason::ExpectedJoin).await?;
                return Ok(());
            }
            Err(_) => {
                send_disconnect(&mut sink, DisconnectReason::MalformedMessage).await?;
                return Ok(());
            }
        }
    };

    // Register a control channel and subscribe to the starting zone.
    let (control_tx, mut control_rx) = mpsc::unbounded_channel::<ControlEvent>();
    shared.control.lock().await.insert(player_id, control_tx);
    let mut snapshots = shared
        .zone_tx
        .get(&current_zone)
        .expect("zone channel exists")
        .subscribe();
    let mut rate_limit = IntentRateLimit::new();
    info!(%peer, player_id = player_id.get(), hero = %hero_name, %client_build, zone = zone_slug(current_zone), "session joined");

    loop {
        tokio::select! {
            incoming = source.next() => {
                match incoming {
                    Some(Ok(message)) => {
                        if !handle_client_message(message, player_id, &shared, &mut sink, &mut rate_limit).await? {
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
            event = control_rx.recv() => {
                match event {
                    Some(ControlEvent::ZoneChanged { zone, spawn_x, spawn_y, facing }) => {
                        sink.send(Message::Text(
                            encode_server_message(&ServerMessage::ZoneChanged {
                                zone: zone_slug(zone).to_owned(),
                                spawn_x, spawn_y, facing,
                            })?
                            .into(),
                        )).await?;
                        // Re-subscribe so only the new zone's snapshots arrive.
                        snapshots = shared.zone_tx.get(&zone).expect("zone channel exists").subscribe();
                    }
                    None => break,
                }
            }
        }
    }

    shared.world.lock().await.leave(player_id);
    shared.registry.lock().await.release(player_id);
    shared.control.lock().await.remove(&player_id);
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
            move_axis,
            climb_axis,
            jump,
            drop,
            guard,
            action_slot,
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
                    move_axis,
                    climb_axis,
                    jump,
                    drop,
                    guard,
                    action_slot,
                },
            );
            if let Err(error) = result {
                use game_domain::IntentError;
                let reason = match error {
                    IntentError::StaleSequence => RejectionReason::StaleSequence,
                    IntentError::MalformedIntent | IntentError::UnknownPlayer => {
                        RejectionReason::InvalidIntent
                    }
                };
                send_rejection(sink, sequence, reason).await?;
            }
        }
        ClientMessage::SelectWeapon { weapon } => {
            shared.world.lock().await.set_weapon(player_id, wire::weapon_from_wire(weapon));
        }
        ClientMessage::UsePortal { .. } => {
            // Portals are resolved positionally by the simulation; nothing to do.
        }
        ClientMessage::Ping { nonce } => {
            sink.send(Message::Text(
                encode_server_message(&ServerMessage::Pong { nonce })?.into(),
            ))
            .await?;
        }
        ClientMessage::Hello { .. } | ClientMessage::JoinWorld { .. } => {
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

async fn send_rejection<S>(sink: &mut S, sequence: u64, reason: RejectionReason) -> Result<(), AnyError>
where
    S: futures_util::Sink<Message> + Unpin,
    S::Error: Error + Send + Sync + 'static,
{
    let json = encode_server_message(&ServerMessage::IntentRejected { sequence, reason })?;
    sink.send(Message::Text(json.into())).await?;
    Ok(())
}

async fn send_join_rejected<S>(sink: &mut S, reason: JoinRejectionReason) -> Result<(), AnyError>
where
    S: futures_util::Sink<Message> + Unpin,
    S::Error: Error + Send + Sync + 'static,
{
    let json = encode_server_message(&ServerMessage::JoinRejected { reason })?;
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
