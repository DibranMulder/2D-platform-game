class_name PrototypeHero
extends CharacterBody2D

signal combat_event(message: String)
signal defeated

const MAX_HEALTH := 100
const MAX_STAMINA := 100.0
const MAX_MANA := 100.0
const GENERAL_EXP_GOAL := 1000
const MOVE_SPEED := 270.0
const GROUND_ACCELERATION := 1800.0
const AIR_ACCELERATION := 850.0
const GRAVITY := 1850.0
const JUMP_VELOCITY := -670.0
const LINEAGE_IDS: Array[String] = [
    "human",
    "tidekin",
    "grove_centaur",
    "aeralith",
    "crag_troll",
    "deep_goblin",
    "sunscour",
    "rimeborn",
]

var health := MAX_HEALTH
var stamina := MAX_STAMINA
var mana := MAX_MANA
var general_exp := 350
var level := 7
var current_action := "Ready"
var facing := 1
var is_blocking := false
var is_alive := true
var lineage_id := "human"
var _move_axis := 0.0
var _jump_queued := false
var _action_lock := 0.0
var _attack_flash := 0.0
var _hurt_flash := 0.0
var _target: Node2D
var _cooldowns := {
    "attack": 0.0,
    "power_strike": 0.0,
    "whirlwind": 0.0,
    "lunge": 0.0,
    "second_wind": 0.0,
}


func configure_hero(hero_data: Dictionary) -> void:
    var requested_lineage := str(hero_data.get("lineage_id", "human"))
    lineage_id = requested_lineage if LINEAGE_IDS.has(requested_lineage) else "human"
    level = clampi(int(hero_data.get("level", level)), 1, 99)
    queue_redraw()


func set_target(target: Node2D) -> void:
    _target = target


func set_move_axis(axis: float) -> void:
    _move_axis = clampf(axis, -1.0, 1.0)


func queue_jump() -> void:
    _jump_queued = true


func set_guard(guarding: bool) -> void:
    if not is_alive:
        return
    is_blocking = guarding and stamina > 0.0
    if is_blocking:
        current_action = "Guarding"
    elif current_action == "Guarding":
        current_action = "Ready"
    queue_redraw()


func try_action(action: String) -> void:
    if not is_alive or _action_lock > 0.0 or float(_cooldowns.get(action, 0.0)) > 0.0:
        return

    match action:
        "attack":
            _perform_strike("Sword Attack", 14, 86.0, 0.45, 0.18, false)
        "power_strike":
            _perform_strike("Power Strike", 32, 100.0, 3.0, 0.55, false)
        "whirlwind":
            _perform_strike("Whirlwind", 22, 112.0, 5.0, 0.65, true)
        "lunge":
            facing = _target_direction_or_facing()
            velocity.x = float(facing) * 760.0
            _perform_strike("Lunge", 18, 128.0, 4.0, 0.32, false)
        "second_wind":
            if health >= MAX_HEALTH:
                combat_event.emit("Second Wind is ready, but health is already full.")
                return
            health = mini(MAX_HEALTH, health + 30)
            _cooldowns[action] = 12.0
            _action_lock = 0.35
            current_action = "Second Wind"
            combat_event.emit("Second Wind restores 30 health.")
            queue_redraw()


func receive_damage(amount: int, attacker_side: int) -> void:
    if not is_alive:
        return

    var final_damage := amount
    var frontal_attack := attacker_side == facing
    if is_blocking and frontal_attack and stamina >= 18.0:
        stamina -= 18.0
        final_damage = maxi(1, ceili(float(amount) * 0.3))
        combat_event.emit("Guard absorbs %s damage; %s gets through." % [amount - final_damage, final_damage])
    else:
        combat_event.emit("Monster hits for %s damage." % final_damage)

    health = maxi(0, health - final_damage)
    _hurt_flash = 0.18
    velocity.x = float(-attacker_side) * 260.0
    if health == 0:
        is_alive = false
        is_blocking = false
        current_action = "Defeated"
        defeated.emit()
    queue_redraw()


func cooldown(action: String) -> float:
    return float(_cooldowns.get(action, 0.0))


func _physics_process(delta: float) -> void:
    for action: String in _cooldowns:
        _cooldowns[action] = maxf(0.0, float(_cooldowns[action]) - delta)
    _action_lock = maxf(0.0, _action_lock - delta)
    _attack_flash = maxf(0.0, _attack_flash - delta)
    _hurt_flash = maxf(0.0, _hurt_flash - delta)

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    if is_alive:
        if absf(_move_axis) > 0.1:
            facing = 1 if _move_axis > 0.0 else -1
        var speed_scale := 0.38 if is_blocking else 1.0
        var desired_velocity := _move_axis * MOVE_SPEED * speed_scale
        var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
        velocity.x = move_toward(velocity.x, desired_velocity, acceleration * delta)

        if _jump_queued and is_on_floor():
            velocity.y = JUMP_VELOCITY
            current_action = "Jump"
            combat_event.emit("Hero jumps.")

        if not is_blocking:
            stamina = minf(MAX_STAMINA, stamina + 22.0 * delta)
            if _action_lock <= 0.0 and current_action != "Jump":
                current_action = "Ready"
    else:
        velocity.x = move_toward(velocity.x, 0.0, GROUND_ACCELERATION * delta)

    _jump_queued = false
    move_and_slide()
    position.x = clampf(position.x, 44.0, 1236.0)
    queue_redraw()


func _perform_strike(
    display_name: String,
    damage: int,
    reach: float,
    cooldown_seconds: float,
    recovery_seconds: float,
    omnidirectional: bool,
) -> void:
    is_blocking = false
    current_action = display_name
    _cooldowns[_action_key(display_name)] = cooldown_seconds
    _action_lock = recovery_seconds
    _attack_flash = recovery_seconds

    var hit := false
    if is_instance_valid(_target) and _target.has_method("receive_damage"):
        var offset := _target.global_position - global_position
        var facing_target := signf(offset.x) == float(facing)
        if absf(offset.x) <= reach and absf(offset.y) <= 90.0 and (omnidirectional or facing_target):
            _target.receive_damage(damage, global_position.x)
            hit = true

    combat_event.emit(
        "%s deals %s damage." % [display_name, damage]
        if hit
        else "%s misses." % display_name
    )
    queue_redraw()


func _action_key(display_name: String) -> String:
    match display_name:
        "Sword Attack":
            return "attack"
        "Power Strike":
            return "power_strike"
        "Whirlwind":
            return "whirlwind"
        "Lunge":
            return "lunge"
        _:
            return display_name.to_snake_case()


func _target_direction_or_facing() -> int:
    if is_instance_valid(_target):
        var direction := signi(int(_target.global_position.x - global_position.x))
        if direction != 0:
            return direction
    return facing


func _draw() -> void:
    var tint := Color("ffffff") if _hurt_flash <= 0.0 else Color("ff6b6b")
    var direction := float(facing)

    match lineage_id:
        "tidekin":
            _draw_tidekin(tint)
        "grove_centaur":
            _draw_grove_centaur(tint)
        "aeralith":
            _draw_aeralith(tint)
        "crag_troll":
            _draw_crag_troll(tint)
        "deep_goblin":
            _draw_deep_goblin(tint)
        "sunscour":
            _draw_sunscour(tint)
        "rimeborn":
            _draw_rimeborn(tint)
        _:
            _draw_human(tint)

    _draw_sword_and_guard(direction)


func _draw_human(tint: Color) -> void:
    var skin := Color("efc59b") * tint
    draw_circle(Vector2(0.0, -62.0), 15.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-19.0, -48.0),
            Vector2(19.0, -48.0),
            Vector2(15.0, -10.0),
            Vector2(-15.0, -10.0),
        ]),
        PackedColorArray([Color("3d78c5") * tint]),
    )
    draw_line(Vector2(-10.0, -10.0), Vector2(-13.0, 0.0), Color("263148"), 9.0)
    draw_line(Vector2(10.0, -10.0), Vector2(13.0, 0.0), Color("263148"), 9.0)
    draw_line(Vector2(-17.0, -42.0), Vector2(-28.0, -24.0), skin, 7.0)
    draw_line(Vector2(17.0, -42.0), Vector2(30.0, -31.0), skin, 7.0)
    draw_line(Vector2(-10.0, -71.0), Vector2(10.0, -71.0), Color("6b3f2b") * tint, 5.0)


func _draw_tidekin(tint: Color) -> void:
    var skin := Color("72b86c") * tint
    var cloth := Color("226c82") * tint
    draw_circle(Vector2(0.0, -59.0), 19.0, skin)
    draw_circle(Vector2(-10.0, -74.0), 7.0, Color("e9f2c7") * tint)
    draw_circle(Vector2(10.0, -74.0), 7.0, Color("e9f2c7") * tint)
    draw_circle(Vector2(-10.0, -74.0), 2.5, Color("18352f"))
    draw_circle(Vector2(10.0, -74.0), 2.5, Color("18352f"))
    draw_polygon(
        PackedVector2Array([
            Vector2(-21.0, -44.0),
            Vector2(21.0, -44.0),
            Vector2(16.0, -12.0),
            Vector2(-16.0, -12.0),
        ]),
        PackedColorArray([cloth]),
    )
    draw_line(Vector2(-12.0, -12.0), Vector2(-25.0, 0.0), skin, 12.0)
    draw_line(Vector2(12.0, -12.0), Vector2(25.0, 0.0), skin, 12.0)
    draw_line(Vector2(-18.0, -40.0), Vector2(-32.0, -23.0), skin, 8.0)
    draw_line(Vector2(18.0, -40.0), Vector2(31.0, -31.0), skin, 8.0)
    draw_arc(Vector2.ZERO, 30.0, 3.55, 5.15, 12, Color("65c7ba") * tint, 5.0)


func _draw_grove_centaur(tint: Color) -> void:
    var coat := Color("95643f") * tint
    var cloth := Color("4e743e") * tint
    _draw_oval(Vector2(-1.0, -21.0), Vector2(35.0, 14.0), coat)
    draw_polygon(
        PackedVector2Array([
            Vector2(-17.0, -67.0),
            Vector2(17.0, -67.0),
            Vector2(15.0, -29.0),
            Vector2(-15.0, -29.0),
        ]),
        PackedColorArray([cloth]),
    )
    draw_circle(Vector2(0.0, -79.0), 13.0, Color("d2aa7b") * tint)
    for leg_x: float in [-24.0, -8.0, 13.0, 27.0]:
        draw_line(Vector2(leg_x, -18.0), Vector2(leg_x - 2.0, 0.0), coat, 7.0)
    draw_line(Vector2(-32.0, -23.0), Vector2(-47.0, -31.0), Color("4e743e") * tint, 5.0)
    draw_line(Vector2(-14.0, -56.0), Vector2(-27.0, -39.0), Color("d2aa7b") * tint, 7.0)
    draw_line(Vector2(14.0, -56.0), Vector2(30.0, -42.0), Color("d2aa7b") * tint, 7.0)
    draw_line(Vector2(-8.0, -90.0), Vector2(-14.0, -99.0), Color("d8b463") * tint, 3.0)
    draw_line(Vector2(8.0, -90.0), Vector2(14.0, -99.0), Color("d8b463") * tint, 3.0)


func _draw_aeralith(tint: Color) -> void:
    var skin := Color("d7e8e9") * tint
    draw_polygon(
        PackedVector2Array([
            Vector2(-13.0, -52.0),
            Vector2(-47.0, -79.0),
            Vector2(-35.0, -28.0),
        ]),
        PackedColorArray([Color("ccebf4") * tint]),
    )
    draw_polygon(
        PackedVector2Array([
            Vector2(13.0, -52.0),
            Vector2(47.0, -79.0),
            Vector2(35.0, -28.0),
        ]),
        PackedColorArray([Color("ccebf4") * tint]),
    )
    draw_circle(Vector2(0.0, -67.0), 14.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-17.0, -53.0),
            Vector2(17.0, -53.0),
            Vector2(12.0, -10.0),
            Vector2(-12.0, -10.0),
        ]),
        PackedColorArray([Color("6d7fc3") * tint]),
    )
    draw_line(Vector2(-8.0, -10.0), Vector2(-12.0, 0.0), Color("39445e") * tint, 8.0)
    draw_line(Vector2(8.0, -10.0), Vector2(12.0, 0.0), Color("39445e") * tint, 8.0)
    draw_line(Vector2(-15.0, -48.0), Vector2(-28.0, -29.0), skin, 6.0)
    draw_line(Vector2(15.0, -48.0), Vector2(31.0, -35.0), skin, 6.0)
    draw_polygon(
        PackedVector2Array([Vector2(-9.0, -78.0), Vector2(0.0, -95.0), Vector2(9.0, -78.0)]),
        PackedColorArray([Color("f2c96f") * tint]),
    )


func _draw_crag_troll(tint: Color) -> void:
    var skin := Color("78896a") * tint
    draw_circle(Vector2(0.0, -63.0), 22.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-30.0, -47.0),
            Vector2(30.0, -47.0),
            Vector2(23.0, -8.0),
            Vector2(-23.0, -8.0),
        ]),
        PackedColorArray([Color("5c4036") * tint]),
    )
    draw_line(Vector2(-18.0, -8.0), Vector2(-21.0, 0.0), Color("30342f") * tint, 13.0)
    draw_line(Vector2(18.0, -8.0), Vector2(21.0, 0.0), Color("30342f") * tint, 13.0)
    draw_line(Vector2(-28.0, -40.0), Vector2(-38.0, -14.0), skin, 12.0)
    draw_line(Vector2(28.0, -40.0), Vector2(37.0, -29.0), skin, 12.0)
    draw_polygon(
        PackedVector2Array([Vector2(-21.0, -68.0), Vector2(-28.0, -79.0), Vector2(-12.0, -73.0)]),
        PackedColorArray([Color("a6b098") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(21.0, -68.0), Vector2(28.0, -79.0), Vector2(12.0, -73.0)]),
        PackedColorArray([Color("a6b098") * tint]),
    )


func _draw_deep_goblin(tint: Color) -> void:
    var skin := Color("879b4c") * tint
    draw_polygon(
        PackedVector2Array([Vector2(-12.0, -52.0), Vector2(-35.0, -61.0), Vector2(-15.0, -41.0)]),
        PackedColorArray([skin]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(12.0, -52.0), Vector2(35.0, -61.0), Vector2(15.0, -41.0)]),
        PackedColorArray([skin]),
    )
    draw_circle(Vector2(0.0, -48.0), 15.0, skin)
    draw_circle(Vector2(-6.0, -51.0), 4.0, Color("c7e9d1") * tint)
    draw_circle(Vector2(6.0, -51.0), 4.0, Color("c7e9d1") * tint)
    draw_rect(Rect2(-16.0, -34.0, 32.0, 26.0), Color("684a76") * tint)
    draw_line(Vector2(-8.0, -8.0), Vector2(-12.0, 0.0), Color("292031") * tint, 8.0)
    draw_line(Vector2(8.0, -8.0), Vector2(12.0, 0.0), Color("292031") * tint, 8.0)
    draw_line(Vector2(-15.0, -29.0), Vector2(-28.0, -15.0), skin, 6.0)
    draw_line(Vector2(15.0, -29.0), Vector2(29.0, -22.0), skin, 6.0)
    draw_circle(Vector2(0.0, -30.0), 6.0, Color("d08342") * tint)


func _draw_sunscour(tint: Color) -> void:
    var skin := Color("9a6344") * tint
    draw_circle(Vector2(0.0, -64.0), 15.0, skin)
    draw_arc(Vector2(0.0, -66.0), 17.0, PI, TAU, 16, Color("b73b31") * tint, 8.0)
    draw_line(Vector2(-12.0, -62.0), Vector2(12.0, -62.0), Color("e4c18b") * tint, 6.0)
    draw_polygon(
        PackedVector2Array([
            Vector2(-19.0, -49.0),
            Vector2(19.0, -49.0),
            Vector2(16.0, -9.0),
            Vector2(-16.0, -9.0),
        ]),
        PackedColorArray([Color("84332f") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(-18.0, -45.0), Vector2(-31.0, -6.0), Vector2(-6.0, -14.0)]),
        PackedColorArray([Color("34304c") * tint]),
    )
    draw_line(Vector2(-10.0, -9.0), Vector2(-13.0, 0.0), Color("3d2926") * tint, 9.0)
    draw_line(Vector2(10.0, -9.0), Vector2(13.0, 0.0), Color("3d2926") * tint, 9.0)
    draw_line(Vector2(-17.0, -42.0), Vector2(-28.0, -24.0), skin, 7.0)
    draw_line(Vector2(17.0, -42.0), Vector2(31.0, -31.0), skin, 7.0)


func _draw_rimeborn(tint: Color) -> void:
    var skin := Color("a9cbd5") * tint
    draw_circle(Vector2(0.0, -64.0), 18.0, Color("dcebf0") * tint)
    draw_circle(Vector2(0.0, -64.0), 13.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-24.0, -49.0),
            Vector2(24.0, -49.0),
            Vector2(19.0, -8.0),
            Vector2(-19.0, -8.0),
        ]),
        PackedColorArray([Color("385f85") * tint]),
    )
    draw_line(Vector2(-12.0, -8.0), Vector2(-15.0, 0.0), Color("243c55") * tint, 11.0)
    draw_line(Vector2(12.0, -8.0), Vector2(15.0, 0.0), Color("243c55") * tint, 11.0)
    draw_line(Vector2(-21.0, -42.0), Vector2(-31.0, -22.0), Color("dcebf0") * tint, 9.0)
    draw_line(Vector2(21.0, -42.0), Vector2(33.0, -31.0), Color("dcebf0") * tint, 9.0)
    draw_polygon(
        PackedVector2Array([Vector2(-17.0, -77.0), Vector2(-10.0, -91.0), Vector2(-4.0, -79.0)]),
        PackedColorArray([Color("b9efff") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(17.0, -77.0), Vector2(10.0, -91.0), Vector2(4.0, -79.0)]),
        PackedColorArray([Color("b9efff") * tint]),
    )


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for index in 24:
        var angle := TAU * float(index) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_polygon(points, PackedColorArray([color]))


func _weapon_origin() -> Vector2:
    match lineage_id:
        "grove_centaur":
            return Vector2(30.0, -42.0)
        "deep_goblin":
            return Vector2(29.0, -22.0)
        "crag_troll":
            return Vector2(37.0, -29.0)
        "aeralith":
            return Vector2(31.0, -35.0)
        _:
            return Vector2(31.0, -31.0)


func _draw_sword_and_guard(direction: float) -> void:
    var hand := _weapon_origin()
    hand.x *= direction

    var sword_reach := 72.0 if _attack_flash > 0.0 else 53.0
    var tip := Vector2(direction * sword_reach, hand.y - 24.0)
    draw_line(
        hand,
        tip,
        Color("dbe9ef"),
        7.0,
    )
    draw_line(
        hand + Vector2(-direction * 7.0, -6.0),
        hand + Vector2(direction * 7.0, 7.0),
        Color("d9a441"),
        5.0,
    )

    if is_blocking:
        draw_arc(hand, 31.0, -1.2, 1.2, 18, Color("80d7ff"), 7.0)
