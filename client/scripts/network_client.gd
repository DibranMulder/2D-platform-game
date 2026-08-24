class_name NetworkClient
extends Node

# Presentation-layer transport for the converged, server-authoritative world.
# Speaks game-protocol v3: Hello -> HelloAccepted, JoinWorld -> WorldJoined,
# then a stream of per-zone, entity-tagged Snapshots. The client sends Intents
# and renders Snapshots; it owns no game state.

signal connection_changed(state: String)
signal negotiated(tick_rate_hz: int)
signal world_joined(player_id: String, hero_name: String, lineage: String, zone: String)
signal join_rejected(reason: String)
signal snapshot_received(server_tick: int, zone: String, entities: Array)
signal zone_changed(zone: String, spawn_x: int, spawn_y: int, facing: int)
signal intent_rejected(sequence: int, reason: String)

const PROTOCOL_VERSION := 3

var _socket := WebSocketPeer.new()
var _url := ""
var _hello_sent := false
var _joined := false


func connect_to_world(url: String) -> Error:
    _url = url
    _socket = WebSocketPeer.new()
    _hello_sent = false
    _joined = false
    var error := _socket.connect_to_url(url)
    if error != OK:
        connection_changed.emit("connection error: %s" % error_string(error))
    else:
        connection_changed.emit("connecting to %s" % url)
    return error


func is_negotiated() -> bool:
    return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN and _hello_sent


func is_in_world() -> bool:
    return is_negotiated() and _joined


func join_world(account_id: String, hero_name: String) -> void:
    if not is_negotiated():
        return
    _send({"type": "join_world", "account_id": account_id, "hero_name": hero_name})


func submit_intent(
    sequence: int,
    client_tick: int,
    move_axis: int,
    climb_axis: int,
    jump: bool,
    drop: bool,
    guard: bool,
    action_slot: int,
) -> void:
    if not is_in_world():
        return
    _send({
        "type": "intent",
        "sequence": sequence,
        "client_tick": client_tick,
        "move_axis": clampi(move_axis, -1, 1),
        "climb_axis": clampi(climb_axis, -1, 1),
        "jump": jump,
        "drop": drop,
        "guard": guard,
        "action_slot": action_slot,
    })


func select_weapon(weapon: String) -> void:
    if not is_in_world():
        return
    _send({"type": "select_weapon", "weapon": weapon})


func _process(_delta: float) -> void:
    _socket.poll()
    var state := _socket.get_ready_state()

    if state == WebSocketPeer.STATE_OPEN:
        if not _hello_sent:
            _send({
                "type": "hello",
                "protocol_version": PROTOCOL_VERSION,
                "client_build": "canonical-0.1.0",
            })
            _hello_sent = true
            connection_changed.emit("connected; negotiating protocol")
        while _socket.get_available_packet_count() > 0:
            _handle_packet(_socket.get_packet().get_string_from_utf8())
    elif state == WebSocketPeer.STATE_CLOSED and _hello_sent:
        _hello_sent = false
        _joined = false
        connection_changed.emit(
            "disconnected (code %s): %s" % [_socket.get_close_code(), _socket.get_close_reason()]
        )


func _send(message: Dictionary) -> void:
    var error := _socket.send_text(JSON.stringify(message))
    if error != OK:
        connection_changed.emit("send error: %s" % error_string(error))


func _handle_packet(packet: String) -> void:
    var value: Variant = JSON.parse_string(packet)
    if typeof(value) != TYPE_DICTIONARY:
        connection_changed.emit("server sent malformed JSON")
        return

    var message := value as Dictionary
    match message.get("type", ""):
        "hello_accepted":
            negotiated.emit(int(message.get("tick_rate_hz", 20)))
        "world_joined":
            _joined = true
            world_joined.emit(
                str(message.get("player_id", "")),
                str(message.get("hero_name", "")),
                str(message.get("lineage", "")),
                str(message.get("zone", "")),
            )
        "join_rejected":
            join_rejected.emit(str(message.get("reason", "unknown")))
        "snapshot":
            snapshot_received.emit(
                int(message.get("server_tick", 0)),
                str(message.get("zone", "")),
                message.get("entities", []) as Array,
            )
        "zone_changed":
            zone_changed.emit(
                str(message.get("zone", "")),
                int(message.get("spawn_x", 0)),
                int(message.get("spawn_y", 0)),
                int(message.get("facing", 1)),
            )
        "intent_rejected":
            intent_rejected.emit(
                int(message.get("sequence", 0)),
                str(message.get("reason", "unknown")),
            )
        "pong":
            pass
        "disconnect":
            connection_changed.emit("server refused session: %s" % message.get("reason", "unknown"))
            _socket.close()
        _:
            connection_changed.emit("server sent unknown message type")
