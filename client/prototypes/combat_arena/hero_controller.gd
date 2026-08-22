class_name PrototypeHero
extends CharacterBody2D

signal combat_event(message: String)
signal defeated

const MAX_HEALTH := 100
const MAX_STAMINA := 100.0
const MOVE_SPEED := 270.0
const GROUND_ACCELERATION := 1800.0
const AIR_ACCELERATION := 850.0
const GRAVITY := 1850.0
const JUMP_VELOCITY := -670.0

var health := MAX_HEALTH
var stamina := MAX_STAMINA
var current_action := "Ready"
var facing := 1
var is_blocking := false
var is_alive := true
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

    draw_circle(Vector2(0.0, -62.0), 15.0, Color("efc59b") * tint)
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
    draw_line(Vector2(direction * 12.0, -42.0), Vector2(direction * 35.0, -31.0), Color("efc59b"), 7.0)

    var sword_reach := 72.0 if _attack_flash > 0.0 else 53.0
    draw_line(
        Vector2(direction * 31.0, -34.0),
        Vector2(direction * sword_reach, -55.0),
        Color("dbe9ef"),
        7.0,
    )
    draw_line(
        Vector2(direction * 25.0, -38.0),
        Vector2(direction * 38.0, -25.0),
        Color("d9a441"),
        5.0,
    )

    if is_blocking:
        draw_arc(Vector2(direction * 25.0, -38.0), 31.0, -1.2, 1.2, 18, Color("80d7ff"), 7.0)

