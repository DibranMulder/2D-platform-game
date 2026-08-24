# Canonical multiplayer world: a pure presentation + input layer over the
# server-authoritative simulation. It renders whatever zone the server places
# the local hero in, draws every entity from Snapshots, and turns local input
# into Intents. It owns no game state.
extends Node2D

const NetworkClientScript := preload("res://scripts/network_client.gd")
const INTENT_INTERVAL := 0.05
const SERVER_URL := "ws://127.0.0.1:8787"

# Client-side copies of each zone's geometry, in screen space (y-down, matching
# the server's authored pixels). Used only for drawing — never for collision.
const HOLLOW_PLATFORMS := [
    Vector3(300, 470, 240), Vector3(640, 388, 220), Vector3(980, 300, 240), Vector3(500, 240, 180),
]
const PARKOUR_PLATFORMS := [
    Vector3(360, 500, 170), Vector3(600, 440, 150), Vector3(900, 250, 180), Vector3(1120, 330, 150),
    Vector3(1300, 410, 150), Vector3(1440, 400, 90), Vector3(1540, 340, 90), Vector3(1640, 280, 90),
    Vector3(1740, 220, 90), Vector3(1900, 220, 180), Vector3(2160, 470, 150), Vector3(2360, 400, 150),
    Vector3(2640, 180, 180), Vector3(2860, 260, 150), Vector3(3060, 330, 120), Vector3(3180, 380, 100),
    Vector3(3300, 430, 100), Vector3(3440, 470, 220),
]
const PARKOUR_GOAL := Vector2(3440, 455)

var _network: NetworkClient
var _camera: Camera2D
var _status: Label
var _local_player_id := ""
var _account_id := "local-account"
var _hero_name := ""
var _current_zone := "sunlit_forest"

# entity_id -> { data: Dictionary, pos: Vector2 (display screen pos) }
var _entities: Dictionary = {}

var _intent_accumulator := 0.0
var _intent_sequence := 0
var _client_tick := 0
var _jump_edge := false
var _prev_jump_held := false
var _pending_action := 0
var _pending_weapon := ""


func _ready() -> void:
    _resolve_identity()

    _camera = Camera2D.new()
    _camera.position = Vector2(640, 360)
    add_child(_camera)
    _camera.make_current()

    var hud := CanvasLayer.new()
    add_child(hud)
    _status = Label.new()
    _status.position = Vector2(16, 12)
    _status.add_theme_color_override("font_color", Color("f2e9d0"))
    _status.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.9))
    _status.add_theme_constant_override("shadow_offset_x", 2)
    _status.add_theme_constant_override("shadow_offset_y", 2)
    hud.add_child(_status)

    _network = NetworkClientScript.new() as NetworkClient
    add_child(_network)
    _network.connection_changed.connect(_on_connection_changed)
    _network.negotiated.connect(_on_negotiated)
    _network.world_joined.connect(_on_world_joined)
    _network.join_rejected.connect(_on_join_rejected)
    _network.snapshot_received.connect(_on_snapshot)
    _network.zone_changed.connect(_on_zone_changed)

    _network.connect_to_world(SERVER_URL)
    queue_redraw()


func _resolve_identity() -> void:
    var tree := get_tree()
    if tree.has_meta("account_email"):
        _account_id = str(tree.get_meta("account_email"))
    if tree.has_meta("selected_hero"):
        var hero := tree.get_meta("selected_hero") as Dictionary
        _hero_name = str(hero.get("name", ""))
    if _hero_name.is_empty():
        _hero_name = "Wanderer-%04d" % (randi() % 10000)
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--hero="):
            _hero_name = argument.trim_prefix("--hero=")
        elif argument.begins_with("--account="):
            _account_id = argument.trim_prefix("--account=")


func _process(delta: float) -> void:
    _sample_edges()
    _intent_accumulator += delta
    if _intent_accumulator >= INTENT_INTERVAL:
        _intent_accumulator = fmod(_intent_accumulator, INTENT_INTERVAL)
        _send_intent()

    # Smoothly interpolate every entity toward its latest server position.
    var weight := 1.0 - exp(-18.0 * delta)
    for id: String in _entities:
        var entry := _entities[id] as Dictionary
        entry["pos"] = (entry["pos"] as Vector2).lerp(entry["target"] as Vector2, weight)

    _update_camera()
    _update_status()
    queue_redraw()


func _sample_edges() -> void:
    var jump_held := (
        Input.is_key_pressed(KEY_SPACE)
        or Input.is_key_pressed(KEY_W)
        or Input.is_key_pressed(KEY_UP)
    )
    if jump_held and not _prev_jump_held:
        _jump_edge = true
    _prev_jump_held = jump_held

    for pair in [[KEY_1, 1], [KEY_3, 3], [KEY_4, 4], [KEY_5, 5], [KEY_6, 6]]:
        if Input.is_key_pressed(pair[0]):
            _pending_action = pair[1]
    for pair in [[KEY_Z, "sword"], [KEY_X, "axe_shield"], [KEY_C, "bow"], [KEY_V, "staff"], [KEY_B, "wand"]]:
        if Input.is_key_pressed(pair[0]):
            _pending_weapon = pair[1]


func _send_intent() -> void:
    if not _network.is_in_world():
        return

    if not _pending_weapon.is_empty():
        _network.select_weapon(_pending_weapon)
        _pending_weapon = ""

    var move_axis := 0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        move_axis -= 1
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        move_axis += 1

    # Climb axis is y-up (+1 = up). Down doubles as drop-through.
    var climb_axis := 0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        climb_axis += 1
    var drop := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    if drop:
        climb_axis -= 1
    var guard := Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_2)

    _intent_sequence += 1
    _client_tick += 1
    _network.submit_intent(
        _intent_sequence, _client_tick, move_axis, climb_axis, _jump_edge, drop, guard, _pending_action
    )
    _jump_edge = false
    _pending_action = 0


func _update_camera() -> void:
    if _current_zone == "the_gauntlet" and _entities.has(_local_player_id):
        var pos := (_entities[_local_player_id] as Dictionary)["pos"] as Vector2
        _camera.position = Vector2(clampf(pos.x, 640.0, 3600.0 - 640.0), 360.0)
    else:
        _camera.position = Vector2(640, 360)


func _update_status() -> void:
    var line := "%s  ·  %s" % [_hero_name, _current_zone.to_upper().replace("_", " ")]
    if _entities.has(_local_player_id):
        var data := (_entities[_local_player_id] as Dictionary)["data"] as Dictionary
        line += "\nHP %s/%s   MP %s   SP %s   [%s] %s" % [
            data.get("health", 0), data.get("max_health", 100),
            data.get("mana", 0), data.get("stamina", 0),
            str(data.get("weapon", "sword")).to_upper(), str(data.get("action_state", "")),
        ]
    line += "\nAD/←→ move · W jump · S drop/down · Shift guard · 1/3/4/5/6 actions · Z X C V B weapons"
    _status.text = line


# --- coordinate + snapshot handling ---

func _world_to_screen(wx: float, wy: float) -> Vector2:
    return Vector2(wx / 100.0, 720.0 - wy / 100.0)


func _on_snapshot(_server_tick: int, zone: String, entities: Array) -> void:
    if zone != _current_zone:
        return
    var seen := {}
    for value: Variant in entities:
        if typeof(value) != TYPE_DICTIONARY:
            continue
        var data := value as Dictionary
        var id := str(data.get("entity_id", ""))
        if id.is_empty():
            continue
        seen[id] = true
        var target := _world_to_screen(
            float(data.get("position_x", 0)), float(data.get("position_y", 0))
        )
        if _entities.has(id):
            var entry := _entities[id] as Dictionary
            entry["data"] = data
            entry["target"] = target
        else:
            _entities[id] = {"data": data, "target": target, "pos": target}
    for id: String in _entities.keys():
        if not seen.has(id):
            _entities.erase(id)


func _on_zone_changed(zone: String, _spawn_x: int, _spawn_y: int, _facing: int) -> void:
    _current_zone = zone
    _entities.clear()


func _on_connection_changed(state: String) -> void:
    if _status != null:
        _status.text = state


func _on_negotiated(_tick_rate_hz: int) -> void:
    _network.join_world(_account_id, _hero_name)


func _on_world_joined(player_id: String, hero_name: String, _lineage: String, zone: String) -> void:
    _local_player_id = player_id
    _hero_name = hero_name
    _current_zone = zone
    _entities.clear()


func _on_join_rejected(reason: String) -> void:
    if reason == "hero_already_online":
        _hero_name = "Wanderer-%04d" % (randi() % 10000)
        _network.join_world(_account_id, _hero_name)
        return
    if _status != null:
        _status.text = "Join rejected: %s" % reason


# --- drawing ---

func _draw() -> void:
    _draw_zone_backdrop()
    for id: String in _entities:
        var entry := _entities[id] as Dictionary
        _draw_entity(entry["data"] as Dictionary, entry["pos"] as Vector2, id == _local_player_id)


func _draw_zone_backdrop() -> void:
    match _current_zone:
        "the_gauntlet":
            draw_rect(Rect2(0, 0, 3600, 720), Color("bfe0e6"), true)
            draw_rect(Rect2(0, 550, 3600, 200), Color(0.16, 0.29, 0.18), true)
            draw_rect(Rect2(0, 550, 3600, 10), Color("8fb25a"), true)
            for platform: Vector3 in PARKOUR_PLATFORMS:
                _draw_ledge(platform.x, platform.y, platform.z, Color("6a5b45"), Color("9a8560"))
            _draw_goal(PARKOUR_GOAL)
        "buttoncap_hollow":
            draw_rect(Rect2(0, 0, 1280, 720), Color("233524"), true)
            _draw_ground(Color(0.035, 0.11, 0.075, 1.0), Color("a9c564"))
            for platform: Vector3 in HOLLOW_PLATFORMS:
                _draw_ledge(platform.x, platform.y, platform.z, Color("3a4a2c"), Color("a7c360"))
        "moonlit_market":
            draw_rect(Rect2(0, 0, 1280, 720), Color("1a2338"), true)
            _draw_ground(Color(0.035, 0.05, 0.13, 1.0), Color("7d85bf"))
        _:
            draw_rect(Rect2(0, 0, 1280, 720), Color("223a2b"), true)
            _draw_ground(Color(0.035, 0.11, 0.075, 1.0), Color("a9c564"))
            # Forest jump ledge + ladder.
            _draw_ledge(590, 450, 210, Color("344a35"), Color("a7c360"))
            draw_rect(Rect2(583, 438, 14, 111), Color("6a4f2c"), true)


func _draw_ground(fill: Color, edge: Color) -> void:
    var width := 1280.0
    draw_rect(Rect2(0, 550, width, 170), fill, true)
    draw_rect(Rect2(0, 550, width, 9), edge, true)


func _draw_ledge(cx: float, cy: float, w: float, body: Color, top: Color) -> void:
    var left := cx - w * 0.5
    var y := cy - 11.0
    draw_rect(Rect2(left, y, w, 22), body, true)
    draw_rect(Rect2(left, y, w, 7), top, true)


func _draw_goal(base: Vector2) -> void:
    draw_line(base + Vector2(0, 60), base + Vector2(0, -46), Color("4a3722"), 5.0)
    draw_colored_polygon(
        PackedVector2Array([base + Vector2(2, -46), base + Vector2(74, -32), base + Vector2(2, -14)]),
        Color("d94f45")
    )


func _draw_entity(data: Dictionary, pos: Vector2, is_local: bool) -> void:
    match str(data.get("entity", "")):
        "hero":
            _draw_hero(data, pos, is_local)
        "monster":
            _draw_blob(pos, 26.0, Color("b6472f"), data)
        "biter":
            _draw_blob(pos, 15.0, Color("6fa24a"), data)
        "projectile":
            draw_circle(pos + Vector2(0, -34), 6.0, Color("f2d27a"))


func _draw_hero(data: Dictionary, pos: Vector2, is_local: bool) -> void:
    var body_color := Color("64d8ff") if is_local else Color("e5a6ff")
    if not bool(data.get("grounded", true)):
        body_color = body_color.lerp(Color.WHITE, 0.15)
    draw_circle(pos + Vector2(0, -38), 13.0, Color("f2d0a7"))
    draw_rect(Rect2(pos.x - 14, pos.y - 25, 28, 38), body_color, true)
    draw_line(pos + Vector2(-10, 13), pos + Vector2(-13, 30), body_color, 7.0)
    draw_line(pos + Vector2(10, 13), pos + Vector2(13, 30), body_color, 7.0)
    if is_local:
        draw_arc(pos + Vector2(0, -38), 18.0, 0.0, TAU, 24, Color.WHITE, 2.0)
    _draw_health_bar(pos + Vector2(0, -66), data)
    var name_label := str(data.get("hero_name", ""))
    var font := ThemeDB.fallback_font
    if not name_label.is_empty() and font != null:
        draw_string(font, pos + Vector2(-28, -70), name_label, HORIZONTAL_ALIGNMENT_LEFT, 56, 12, Color("f4ecd6"))


func _draw_blob(pos: Vector2, radius: float, color: Color, data: Dictionary) -> void:
    draw_circle(pos + Vector2(0, -radius), radius, color)
    if int(data.get("telegraph_ticks", 0)) > 0:
        draw_arc(pos + Vector2(0, -radius), radius + 8.0, 0.0, TAU, 20, Color("ffe08a"), 3.0)
    _draw_health_bar(pos + Vector2(0, -radius * 2.0 - 10.0), data)


func _draw_health_bar(top: Vector2, data: Dictionary) -> void:
    var health := float(data.get("health", 0))
    var max_health := maxf(1.0, float(data.get("max_health", 100)))
    var ratio := clampf(health / max_health, 0.0, 1.0)
    draw_rect(Rect2(top.x - 16, top.y, 32, 4), Color(0, 0, 0, 0.5), true)
    draw_rect(Rect2(top.x - 16, top.y, 32.0 * ratio, 4), Color("6fdd7a"), true)
