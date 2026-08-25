# Canonical multiplayer world: a pure presentation + input layer over the
# server-authoritative simulation. It reuses the prototype's art (storybook
# backgrounds, hero/biter sprites, Chronicle HUD + hotbar) but owns no game
# state — it renders Snapshots and sends Intents.
extends Node2D

const NetworkClientScript := preload("res://scripts/network_client.gd")
const ChronicleButtonScript := preload("res://scripts/chronicle_button.gd")
const HudStripScript := preload("res://prototypes/combat_arena/chronicle_hud_strip.gd")
const CharacterPanelsScript := preload("res://prototypes/combat_arena/chronicle_character_panels.gd")
const OnboardingScene := "res://prototypes/onboarding/onboarding.tscn"

# Portal markers per zone, in screen space: [center_x, center_y, label].
const ZONE_PORTALS := {
    "sunlit_forest": [
        [1205, 500, "TO MOONLIT MARKET"],
        [75, 500, "TO BUTTONCAP HOLLOW"],
    ],
    "moonlit_market": [[70, 500, "TO SUNLIT FOREST"]],
    "buttoncap_hollow": [
        [75, 500, "TO SUNLIT FOREST"],
        [1205, 500, "TO THE GAUNTLET"],
    ],
    "the_gauntlet": [[3440, 420, "FINISH"]],
}
const ForestTexture := preload("res://assets/backgrounds/storybook-forest-battleground-v1.png")
const MarketTexture := preload("res://assets/backgrounds/storybook-moonlit-market-v1.png")
const HumanFrames := preload("res://assets/characters/human_m03/v1/human_m03_sprite_frames.tres")
const BiterFrames := preload("res://assets/characters/buttoncap_biter/v1/buttoncap_biter_sprite_frames.tres")

const INTENT_INTERVAL := 0.05
const SERVER_URL := "ws://127.0.0.1:8787"
const MAX_HEALTH := 100
const MAX_RESOURCE := 100

# Screen-space geometry mirrors, for painting the platforms/ledges (drawing only).
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

# Human home town (DESIGN-0014) — client-side mirrors of the server geometry,
# for drawing only. Platforms as [cx, cy, w]; doors as [cx, cy, label].
const TOWN_ZONES := [
    "wendmere_square", "wendmere_market", "wendmere_apothecary", "wendmere_trainers",
    "wendmere_inn", "wendmere_approach", "kingskeep_gatehouse", "kingskeep_barracks",
    "kingskeep_service", "kingskeep_great_hall", "kingskeep_kings_room", "kingskeep_treasury",
    "tower_base", "tower_stair", "tower_solar",
]
const TOWN_PLATFORMS := {
    "kingskeep_service": [Vector3(520, 470, 180), Vector3(820, 400, 180)],
    "tower_stair": [
        Vector3(320, 470, 170), Vector3(560, 390, 170), Vector3(800, 310, 170), Vector3(980, 235, 170),
    ],
}
const TOWN_DOORS := {
    "wendmere_square": [[70, 549, "ROAD"], [180, 549, "APOTHECARY"], [360, 549, "TRAINERS"], [900, 549, "MARKET"], [1150, 549, "APPROACH"]],
    "wendmere_market": [[90, 549, "SQUARE"]],
    "wendmere_apothecary": [[90, 549, "SQUARE"]],
    "wendmere_trainers": [[90, 549, "SQUARE"], [1150, 549, "INN"]],
    "wendmere_inn": [[90, 549, "TRAINERS"]],
    "wendmere_approach": [[90, 549, "SQUARE"], [1150, 549, "KEEP · LIGHT"]],
    "kingskeep_gatehouse": [[90, 549, "APPROACH"], [640, 549, "SERVICE"], [1150, 549, "BARRACKS"]],
    "kingskeep_barracks": [[90, 549, "GATEHOUSE"], [1150, 549, "GREAT HALL"]],
    "kingskeep_service": [[90, 549, "GATEHOUSE"]],
    "kingskeep_great_hall": [[90, 549, "BARRACKS"], [300, 549, "TREASURY"], [520, 549, "TOWER"], [1180, 549, "KING'S ROOM"]],
    "kingskeep_kings_room": [[90, 549, "GREAT HALL"]],
    "kingskeep_treasury": [[90, 549, "GREAT HALL"]],
    "tower_base": [[90, 549, "GREAT HALL"], [1150, 549, "STAIR"]],
    "tower_stair": [[90, 549, "BASE"], [980, 235, "SOLAR"]],
    "tower_solar": [[90, 549, "STAIR"]],
}
# Interior wash per ring.
const TOWN_TINT := {
    "village": Color("2a2620"), "keep": Color("241f2e"), "tower": Color("1c2436"),
}

var _network: NetworkClient
var _camera: Camera2D
var _background: TextureRect
var _hud_strip
var _character_panels
var _map_label: Label
var _hint_label: Label
var _local_player_id := ""
var _account_id := "local-account"
var _hero_name := ""
var _selected_hero: Dictionary = {}
var _current_zone := "sunlit_forest"

# entity_id -> { data, target: Vector2, pos: Vector2, sprite: AnimatedSprite2D|null }
var _entities: Dictionary = {}

var _intent_accumulator := 0.0
var _intent_sequence := 0
var _client_tick := 0
var _jump_edge := false
var _prev_jump_held := false
var _touch_guard := false
var _pending_action := 0
var _pending_weapon := ""


func _ready() -> void:
    _resolve_identity()

    _camera = Camera2D.new()
    _camera.position = Vector2(640, 360)
    add_child(_camera)
    _camera.make_current()

    _build_background()
    _build_hud()

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
        _selected_hero = (tree.get_meta("selected_hero") as Dictionary).duplicate(true)
        _hero_name = str(_selected_hero.get("name", ""))
    if _hero_name.is_empty():
        _hero_name = "Wanderer-%04d" % (randi() % 10000)
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--hero="):
            _hero_name = argument.trim_prefix("--hero=")
        elif argument.begins_with("--account="):
            _account_id = argument.trim_prefix("--account=")
    # Ensure the character panels always have a usable hero record.
    if _selected_hero.is_empty():
        _selected_hero = {
            "name": _hero_name,
            "lineage_id": "human",
            "lineage_name": "Human",
            "allegiance": "light",
        }


# --- scene construction ---

func _build_background() -> void:
    var layer := CanvasLayer.new()
    layer.layer = -10
    add_child(layer)
    _background = TextureRect.new()
    _background.texture = ForestTexture
    _background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(_background)


func _build_hud() -> void:
    var hud := CanvasLayer.new()
    add_child(hud)

    _hud_strip = HudStripScript.new()
    _hud_strip.position = Vector2(24, 20)
    hud.add_child(_hud_strip)
    if _hud_strip.has_method("configure"):
        _hud_strip.configure(_hero_name, 1)

    _map_label = Label.new()
    _map_label.position = Vector2(540, 22)
    _map_label.add_theme_font_size_override("font_size", 22)
    _map_label.add_theme_color_override("font_color", Color("f2e0a6"))
    _map_label.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.06, 0.9))
    _map_label.add_theme_constant_override("shadow_offset_x", 2)
    _map_label.add_theme_constant_override("shadow_offset_y", 2)
    hud.add_child(_map_label)

    _hint_label = Label.new()
    _hint_label.position = Vector2(24, 96)
    _hint_label.add_theme_color_override("font_color", Color("cdd6e4"))
    hud.add_child(_hint_label)

    # Weapon bar (top-right).
    var weapons := HBoxContainer.new()
    weapons.position = Vector2(760, 20)
    weapons.add_theme_constant_override("separation", 6)
    hud.add_child(weapons)
    for pair in [["SWORD", "sword"], ["AXE", "axe_shield"], ["BOW", "bow"], ["STAFF", "staff"], ["WAND", "wand"]]:
        var button := _make_button(pair[0])
        button.pressed.connect(_on_weapon_pressed.bind(pair[1]))
        weapons.add_child(button)

    # Logout (top-left, below the HUD strip).
    var logout := _make_button("LOG OUT")
    logout.position = Vector2(24, 150)
    logout.pressed.connect(_logout)
    hud.add_child(logout)

    # Hotbar (bottom) in slot order: 1 Attack, 2 Guard(held), 3 Power, 4 Whirl,
    # 5 Lunge, 6 Heal, then Jump.
    var hotbar := HBoxContainer.new()
    hotbar.position = Vector2(24, 640)
    hotbar.add_theme_constant_override("separation", 8)
    hud.add_child(hotbar)
    var attack := _make_button("1 ATTACK")
    attack.pressed.connect(_on_action_pressed.bind(1))
    hotbar.add_child(attack)
    var guard := _make_button("2 GUARD")
    guard.button_down.connect(func() -> void: _touch_guard = true)
    guard.button_up.connect(func() -> void: _touch_guard = false)
    hotbar.add_child(guard)
    for pair in [["3 POWER", 3], ["4 WHIRL", 4], ["5 LUNGE", 5], ["6 HEAL", 6]]:
        var button := _make_button(pair[0])
        button.pressed.connect(_on_action_pressed.bind(pair[1]))
        hotbar.add_child(button)
    var jump := _make_button("JUMP")
    jump.pressed.connect(func() -> void: _jump_edge = true)
    hotbar.add_child(jump)

    # Character panels: Hints quick button + item pouch / gear / talents /
    # world map windows (with their keyboard shortcuts), reused from the prototype.
    _character_panels = CharacterPanelsScript.new()
    hud.add_child(_character_panels)
    if _character_panels.has_method("configure_hero"):
        _character_panels.configure_hero(_selected_hero)


func _make_button(text: String) -> Button:
    var button := ChronicleButtonScript.new() as Button
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    return button


# --- per-frame input + interpolation ---

func _process(delta: float) -> void:
    _sample_edges()
    _intent_accumulator += delta
    if _intent_accumulator >= INTENT_INTERVAL:
        _intent_accumulator = fmod(_intent_accumulator, INTENT_INTERVAL)
        _send_intent()

    var weight := 1.0 - exp(-18.0 * delta)
    for id: String in _entities:
        var entry := _entities[id] as Dictionary
        entry["pos"] = (entry["pos"] as Vector2).lerp(entry["target"] as Vector2, weight)
        var sprite := entry.get("sprite") as AnimatedSprite2D
        if sprite != null:
            sprite.position = entry["pos"] as Vector2 + (entry["sprite_offset"] as Vector2)

    _update_camera()
    _update_hud()
    queue_redraw()


func _sample_edges() -> void:
    var jump_held := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    if jump_held and not _prev_jump_held:
        _jump_edge = true
    _prev_jump_held = jump_held
    for pair in [[KEY_1, 1], [KEY_3, 3], [KEY_4, 4], [KEY_5, 5], [KEY_6, 6]]:
        if Input.is_key_pressed(pair[0]):
            _pending_action = pair[1]
    # Weapon switching is via the top-right weapon bar buttons; letter keys are
    # reserved for the character panels (O/B-C/L/K/M/I).


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
    var climb_axis := 0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        climb_axis += 1
    var drop := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
    if drop:
        climb_axis -= 1
    var guard := _touch_guard or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_2)

    _intent_sequence += 1
    _client_tick += 1
    _network.submit_intent(_intent_sequence, _client_tick, move_axis, climb_axis, _jump_edge, drop, guard, _pending_action)
    _jump_edge = false
    _pending_action = 0


func _on_weapon_pressed(weapon: String) -> void:
    _pending_weapon = weapon


func _on_action_pressed(slot: int) -> void:
    _pending_action = slot


func _logout() -> void:
    var tree := get_tree()
    if tree.has_meta("selected_hero"):
        tree.remove_meta("selected_hero")
    if tree.has_meta("account_email"):
        tree.remove_meta("account_email")
    tree.change_scene_to_file(OnboardingScene)


func _update_camera() -> void:
    if _current_zone == "the_gauntlet" and _entities.has(_local_player_id):
        var pos := (_entities[_local_player_id] as Dictionary)["pos"] as Vector2
        _camera.position = Vector2(clampf(pos.x, 640.0, 3600.0 - 640.0), 360.0)
    else:
        _camera.position = Vector2(640, 360)


func _update_hud() -> void:
    _map_label.text = _current_zone.to_upper().replace("_", " ")
    if _entities.has(_local_player_id) and _hud_strip.has_method("set_values"):
        var data := (_entities[_local_player_id] as Dictionary)["data"] as Dictionary
        _hud_strip.set_values(
            int(data.get("health", 0)), MAX_HEALTH,
            float(data.get("mana", 0)), float(MAX_RESOURCE),
            int(data.get("stamina", 0)), MAX_RESOURCE,
        )
    var interact := _interact_hint()
    if interact.is_empty():
        _hint_label.text = "AD move · W jump/up · S drop · Shift guard · 1/3/4/5/6 actions · weapon bar top-right"
    else:
        _hint_label.text = "▲  W / Up:  %s" % interact


# In town, report the door or NPC the local hero is standing next to.
func _interact_hint() -> String:
    if not (_current_zone in TOWN_ZONES and _entities.has(_local_player_id)):
        return ""
    var hero := (_entities[_local_player_id] as Dictionary)["pos"] as Vector2
    for spec: Array in TOWN_DOORS.get(_current_zone, []):
        if absf(hero.x - float(spec[0])) <= 44.0 and absf(hero.y - float(spec[1])) <= 80.0:
            return "enter %s" % str(spec[2])
    for id: String in _entities:
        var data := (_entities[id] as Dictionary)["data"] as Dictionary
        if str(data.get("entity", "")) != "npc":
            continue
        var pos := (_entities[id] as Dictionary)["pos"] as Vector2
        if absf(hero.x - pos.x) <= 48.0:
            return "talk to %s" % str(data.get("name", "someone"))
    return ""


# --- snapshots ---

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
        var target := _world_to_screen(float(data.get("position_x", 0)), float(data.get("position_y", 0)))
        if _entities.has(id):
            var entry := _entities[id] as Dictionary
            entry["data"] = data
            entry["target"] = target
            _update_sprite(entry)
        else:
            var entry := {"data": data, "target": target, "pos": target, "sprite": null, "sprite_offset": Vector2.ZERO}
            _spawn_sprite(entry, data)
            _entities[id] = entry
    for id: String in _entities.keys():
        if not seen.has(id):
            var sprite := (_entities[id] as Dictionary).get("sprite") as AnimatedSprite2D
            if sprite != null:
                sprite.queue_free()
            _entities.erase(id)


func _spawn_sprite(entry: Dictionary, data: Dictionary) -> void:
    match str(data.get("entity", "")):
        "hero":
            var sprite := AnimatedSprite2D.new()
            sprite.sprite_frames = HumanFrames
            sprite.scale = Vector2(0.3, 0.3)
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            entry["sprite"] = sprite
            entry["sprite_offset"] = Vector2(0, -58)
            add_child(sprite)
        "biter":
            var sprite := AnimatedSprite2D.new()
            sprite.sprite_frames = BiterFrames
            sprite.scale = Vector2(0.3, 0.3)
            entry["sprite"] = sprite
            entry["sprite_offset"] = Vector2(0, -22)
            add_child(sprite)
        _:
            entry["sprite"] = null
    _update_sprite(entry)


func _update_sprite(entry: Dictionary) -> void:
    var sprite := entry.get("sprite") as AnimatedSprite2D
    if sprite == null:
        return
    var data := entry["data"] as Dictionary
    var facing := int(data.get("facing", 1))
    sprite.flip_h = facing < 0
    var anim := ""
    match str(data.get("entity", "")):
        "hero":
            anim = _hero_anim(data)
        "biter":
            anim = _biter_anim(data)
    if anim != "" and sprite.sprite_frames.has_animation(anim) and sprite.animation != anim:
        sprite.play(anim)
    elif not sprite.is_playing():
        sprite.play(anim)


func _hero_anim(data: Dictionary) -> String:
    var state := str(data.get("action_state", "ready"))
    if state == "defeated":
        return "defeated"
    if state == "hurt":
        return "hurt"
    if not (state == "ready" or state == "jump" or state == "climbing"):
        return "attack"
    if bool(data.get("climbing", false)):
        return "idle"
    if not bool(data.get("grounded", true)):
        return "jump" if int(data.get("velocity_y", 0)) > 0 else "fall"
    if absi(int(data.get("velocity_x", 0))) > 200:
        return "run"
    return "idle"


func _biter_anim(data: Dictionary) -> String:
    if int(data.get("health", 1)) <= 0:
        return "defeated"
    if not bool(data.get("grounded", true)):
        return "hop"
    return "idle"


func _on_zone_changed(zone: String, _spawn_x: int, _spawn_y: int, _facing: int) -> void:
    _set_zone(zone)


func _set_zone(zone: String) -> void:
    _current_zone = zone
    for id: String in _entities:
        var sprite := (_entities[id] as Dictionary).get("sprite") as AnimatedSprite2D
        if sprite != null:
            sprite.queue_free()
    _entities.clear()
    if zone in TOWN_ZONES:
        _background.visible = false
        return
    match zone:
        "moonlit_market":
            _background.texture = MarketTexture
            _background.modulate = Color.WHITE
            _background.visible = true
        "buttoncap_hollow":
            _background.texture = ForestTexture
            _background.modulate = Color(0.72, 0.82, 0.78)
            _background.visible = true
        "the_gauntlet":
            _background.visible = false
        _:
            _background.texture = ForestTexture
            _background.modulate = Color.WHITE
            _background.visible = true


func _on_connection_changed(state: String) -> void:
    if _hint_label != null and not _network.is_in_world():
        _hint_label.text = state


func _on_negotiated(_tick_rate_hz: int) -> void:
    _network.join_world(_account_id, _hero_name)


func _on_world_joined(player_id: String, hero_name: String, _lineage: String, zone: String) -> void:
    _local_player_id = player_id
    _hero_name = hero_name
    if _hud_strip.has_method("configure"):
        _hud_strip.configure(hero_name, 1)
    _set_zone(zone)


func _on_join_rejected(reason: String) -> void:
    if reason == "hero_already_online":
        _hero_name = "Wanderer-%04d" % (randi() % 10000)
        _network.join_world(_account_id, _hero_name)
        return
    if _hint_label != null:
        _hint_label.text = "Join rejected: %s" % reason


# --- map painting (ground, ledges, portals) drawn under the sprites ---

func _draw() -> void:
    if _current_zone in TOWN_ZONES:
        _draw_town(_current_zone)
        _draw_entities()
        return
    match _current_zone:
        "the_gauntlet":
            draw_rect(Rect2(0, 0, 3600, 720), Color("bfe0e6"), true)
            draw_rect(Rect2(0, 300, 3600, 260), Color("d6ecec"), true)
            draw_rect(Rect2(0, 550, 3600, 200), Color(0.16, 0.29, 0.18), true)
            draw_rect(Rect2(0, 550, 3600, 10), Color("8fb25a"), true)
            for platform: Vector3 in PARKOUR_PLATFORMS:
                _draw_ledge(platform.x, platform.y, platform.z, Color("6a5b45"), Color("9a8560"))
            _draw_goal(PARKOUR_GOAL)
        "buttoncap_hollow":
            _draw_ground(Color(0.035, 0.11, 0.075, 0.58), Color("a9c564"))
            for platform: Vector3 in HOLLOW_PLATFORMS:
                _draw_ledge(platform.x, platform.y, platform.z, Color("3a4a2c"), Color("a7c360"))
        "moonlit_market":
            _draw_ground(Color(0.035, 0.05, 0.13, 0.5), Color("7d85bf"))
        _:
            _draw_ground(Color(0.035, 0.11, 0.075, 0.58), Color("a9c564"))
            _draw_ledge(590, 450, 210, Color("344a35"), Color("a7c360"))
            draw_rect(Rect2(583, 438, 14, 111), Color("6a4f2c"), true)
    # Portals for this zone.
    for portal: Array in ZONE_PORTALS.get(_current_zone, []):
        _draw_portal(Vector2(portal[0], portal[1]), str(portal[2]))

    _draw_entities()


# Entities without a sprite node (monster, projectiles, NPC placeholders) are
# painted here; heroes and biters render as their own AnimatedSprite2D children.
func _draw_entities() -> void:
    for id: String in _entities:
        var entry := _entities[id] as Dictionary
        var data := entry["data"] as Dictionary
        var pos := entry["pos"] as Vector2
        match str(data.get("entity", "")):
            "monster":
                _draw_monster(pos, data)
            "projectile":
                draw_circle(pos + Vector2(0, -34), 6.0, Color("f2d27a"))
            "npc":
                _draw_npc(pos, data)


func _draw_town(zone: String) -> void:
    var tint := TOWN_TINT["village"] as Color
    if zone.begins_with("kingskeep"):
        tint = TOWN_TINT["keep"]
    elif zone.begins_with("tower"):
        tint = TOWN_TINT["tower"]
    draw_rect(Rect2(0, 0, 1280, 720), tint, true)
    # Floor.
    draw_rect(Rect2(0, 550, 1280, 170), tint.lightened(0.06), true)
    draw_rect(Rect2(0, 550, 1280, 6), Color("c8b27a"), true)
    for platform: Vector3 in TOWN_PLATFORMS.get(zone, []):
        _draw_ledge(platform.x, platform.y, platform.z, Color("6a5b45"), Color("9a8560"))
    for spec: Array in TOWN_DOORS.get(zone, []):
        _draw_door(float(spec[0]), float(spec[1]), str(spec[2]))


func _draw_door(cx: float, cy: float, label: String) -> void:
    var top := cy - 70.0
    draw_rect(Rect2(cx - 24, top, 48, 70), Color(0.15, 0.5, 0.65, 0.32), true)
    draw_rect(Rect2(cx - 24, top, 48, 70), Color("86e5ff"), false, 2.0)
    # Up-arrow "enter here" cue.
    draw_colored_polygon(
        PackedVector2Array([Vector2(cx, top - 16), Vector2(cx - 9, top - 3), Vector2(cx + 9, top - 3)]),
        Color("b991ff")
    )
    var font := ThemeDB.fallback_font
    if font != null:
        draw_string(font, Vector2(cx - 70, top - 22), label, HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color("cbe6ff"))


func _draw_npc(pos: Vector2, data: Dictionary) -> void:
    var role := str(data.get("role", ""))
    var color := _npc_color(role)
    draw_rect(Rect2(pos.x - 13, pos.y - 46, 26, 46), color, true)
    draw_rect(Rect2(pos.x - 13, pos.y - 46, 26, 46), Color(0, 0, 0, 0.5), false, 1.0)
    draw_circle(pos + Vector2(0, -52), 9.0, Color("f2d0a7"))
    var font := ThemeDB.fallback_font
    var label := str(data.get("name", ""))
    if font != null and not label.is_empty():
        draw_string(font, pos + Vector2(-70, -66), label, HORIZONTAL_ALIGNMENT_CENTER, 140, 11, Color("f4ecd6"))


func _npc_color(role: String) -> Color:
    if role == "guardian":
        return Color("b6472f")
    if role == "sentry" or role == "captain":
        return Color("6d86b0")
    if role.begins_with("trainer"):
        return Color("8a7bb0")
    if role == "weaponsmith" or role == "armorer" or role == "wandwright":
        return Color("b58b4c")
    if role == "apothecary" or role == "provisioner":
        return Color("5fa06a")
    if role == "king" or role == "princess":
        return Color("d9b25a")
    return Color("9aa0a8")


func _draw_ground(fill: Color, edge: Color) -> void:
    draw_rect(Rect2(0, 550, 1280, 170), fill, true)
    draw_rect(Rect2(0, 550, 1280, 9), edge, true)


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


func _draw_portal(center: Vector2, label: String) -> void:
    var outer := PackedVector2Array()
    var inner := PackedVector2Array()
    for index in 33:
        var angle := TAU * float(index) / 32.0
        outer.append(center + Vector2(cos(angle) * 35.0, sin(angle) * 61.0))
        inner.append(center + Vector2(cos(angle) * 25.0, sin(angle) * 50.0))
    draw_colored_polygon(inner, Color(0.2, 0.8, 0.95, 0.22))
    draw_polyline(outer, Color("86e5ff"), 7.0, true)
    draw_polyline(inner, Color("b991ff"), 4.0, true)
    draw_circle(center, 9.0, Color(0.9, 0.96, 1.0, 0.72))
    var font := ThemeDB.fallback_font
    if font != null:
        draw_string(font, center + Vector2(-84, -74), label, HORIZONTAL_ALIGNMENT_CENTER, 168, 14, Color("cbe6ff"))


func _draw_monster(pos: Vector2, data: Dictionary) -> void:
    var color := Color("b6472f")
    draw_circle(pos + Vector2(0, -30), 30.0, color)
    draw_circle(pos + Vector2(-10, -36), 4.0, Color("2a120c"))
    draw_circle(pos + Vector2(10, -36), 4.0, Color("2a120c"))
    if int(data.get("telegraph_ticks", 0)) > 0:
        draw_arc(pos + Vector2(0, -30), 40.0, 0.0, TAU, 24, Color("ffe08a"), 3.0)
    var ratio := clampf(float(data.get("health", 0)) / maxf(1.0, float(data.get("max_health", 120))), 0.0, 1.0)
    draw_rect(Rect2(pos.x - 24, pos.y - 76, 48, 5), Color(0, 0, 0, 0.5), true)
    draw_rect(Rect2(pos.x - 24, pos.y - 76, 48.0 * ratio, 5), Color("df6b52"), true)
