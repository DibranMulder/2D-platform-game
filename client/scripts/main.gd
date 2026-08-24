extends Node2D

const PlayerAvatarScene := preload("res://scripts/player_avatar.gd")
const NetworkClientScene := preload("res://scripts/network_client.gd")
const INTENT_INTERVAL_SECONDS := 0.05

@onready var status_label: Label = $Hud/StatusPanel/Status
@onready var left_button: Button = $Hud/LeftButton
@onready var right_button: Button = $Hud/RightButton
@onready var jump_button: Button = $Hud/JumpButton

var _network: NetworkClient
var _avatars: Dictionary = {}
var _local_player_id := ""
var _account_id := "local-account"
var _hero_name := ""
var _left_touch_held := false
var _right_touch_held := false
var _jump_queued := false
var _keyboard_jump_was_held := false
var _intent_accumulator := 0.0
var _intent_sequence := 0
var _client_tick := 0


func _ready() -> void:
    _network = NetworkClientScene.new() as NetworkClient
    add_child(_network)
    _network.connection_changed.connect(_on_connection_changed)
    _network.negotiated.connect(_on_negotiated)
    _network.world_joined.connect(_on_world_joined)
    _network.join_rejected.connect(_on_join_rejected)
    _network.snapshot_received.connect(_on_snapshot_received)
    _network.intent_rejected.connect(_on_intent_rejected)

    _resolve_identity()

    left_button.button_down.connect(func() -> void: _left_touch_held = true)
    left_button.button_up.connect(func() -> void: _left_touch_held = false)
    right_button.button_down.connect(func() -> void: _right_touch_held = true)
    right_button.button_up.connect(func() -> void: _right_touch_held = false)
    jump_button.button_down.connect(func() -> void: _jump_queued = true)

    queue_redraw()
    _network.connect_to_world("ws://127.0.0.1:8787")


func _process(delta: float) -> void:
    var keyboard_jump_held := (
        Input.is_key_pressed(KEY_SPACE)
        or Input.is_key_pressed(KEY_W)
        or Input.is_key_pressed(KEY_UP)
    )
    if keyboard_jump_held and not _keyboard_jump_was_held:
        _jump_queued = true
    _keyboard_jump_was_held = keyboard_jump_held

    _intent_accumulator += delta
    if _intent_accumulator < INTENT_INTERVAL_SECONDS:
        return
    _intent_accumulator = fmod(_intent_accumulator, INTENT_INTERVAL_SECONDS)

    var horizontal := 0
    if _left_touch_held or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        horizontal -= 1
    if _right_touch_held or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        horizontal += 1

    _intent_sequence += 1
    _client_tick += 1
    _network.submit_intent(_intent_sequence, _client_tick, horizontal, _jump_queued)
    _jump_queued = false


func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("18263d"), true)
    draw_circle(Vector2(1080.0, 130.0), 68.0, Color("d8e6ff"))
    draw_rect(Rect2(0.0, 560.0, 1280.0, 160.0), Color("263d2c"), true)
    draw_line(Vector2(0.0, 560.0), Vector2(1280.0, 560.0), Color("7ca36b"), 6.0)


func _on_connection_changed(state: String) -> void:
    status_label.text = state


func _resolve_identity() -> void:
    # A hero name unique per launched instance, so two clients on one machine
    # do not collide on the same Hero. Override with `-- --hero=Name --account=Id`.
    _hero_name = "Wanderer-%04d" % (randi() % 10000)
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--hero="):
            _hero_name = argument.trim_prefix("--hero=")
        elif argument.begins_with("--account="):
            _account_id = argument.trim_prefix("--account=")


func _on_negotiated(tick_rate_hz: int) -> void:
    status_label.text = "Negotiated at %s Hz; joining as %s" % [tick_rate_hz, _hero_name]
    _network.join_world(_account_id, _hero_name)


func _on_world_joined(player_id: String, hero_name: String, lineage: String) -> void:
    _local_player_id = player_id
    status_label.text = "Playing %s (%s) as player %s" % [hero_name, lineage, player_id]
    for avatar_id: String in _avatars:
        (_avatars[avatar_id] as PlayerAvatar).configure(avatar_id == _local_player_id)


func _on_join_rejected(reason: String) -> void:
    if reason == "hero_already_online":
        # This instance's hero name is taken; pick another and retry.
        _hero_name = "Wanderer-%04d" % (randi() % 10000)
        status_label.text = "Hero taken; retrying as %s" % _hero_name
        _network.join_world(_account_id, _hero_name)
        return
    status_label.text = "Join rejected: %s" % reason


func _on_snapshot_received(server_tick: int, characters: Array) -> void:
    var observed_ids := {}

    for value: Variant in characters:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var character := value as Dictionary
        var player_id := str(character.get("player_id", ""))
        if player_id.is_empty():
            continue

        observed_ids[player_id] = true
        if not _avatars.has(player_id):
            var avatar := PlayerAvatarScene.new() as PlayerAvatar
            avatar.configure(player_id == _local_player_id)
            _avatars[player_id] = avatar
            add_child(avatar)

        (_avatars[player_id] as PlayerAvatar).apply_world_position(
            int(character.get("position_x", 0)),
            int(character.get("position_y", 0)),
        )

    for player_id: String in _avatars.keys():
        if not observed_ids.has(player_id):
            (_avatars[player_id] as PlayerAvatar).queue_free()
            _avatars.erase(player_id)

    status_label.text = "Player %s · server tick %s · %s online" % [
        _local_player_id,
        server_tick,
        characters.size(),
    ]


func _on_intent_rejected(sequence: int, reason: String) -> void:
    status_label.text = "Intent %s rejected: %s" % [sequence, reason]

