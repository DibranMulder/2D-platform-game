class_name PrototypeMonster
extends CharacterBody2D

signal combat_event(message: String)
signal defeated

const MAX_HEALTH := 120
const MOVE_SPEED := 120.0
const GRAVITY := 1850.0
const ATTACK_REACH := 78.0

var health := MAX_HEALTH
var current_intent := "Watching"
var is_alive := true
var facing := -1
var _target: Node2D
var _attack_cooldown := 0.8
var _telegraph_remaining := 0.0
var _hurt_flash := 0.0
var _knockback_remaining := 0.0
var _forced_stagger_remaining := 0.0


func set_target(target: Node2D) -> void:
    _target = target


func receive_damage(amount: int, source_x: float) -> void:
    if not is_alive:
        return
    health = maxi(0, health - amount)
    _hurt_flash = 0.18
    _knockback_remaining = 0.16
    velocity.x = signf(global_position.x - source_x) * 310.0
    current_intent = "Staggered"
    if health == 0:
        is_alive = false
        current_intent = "Defeated"
        defeated.emit()
        combat_event.emit("The monster is defeated.")
    queue_redraw()


func apply_stagger(seconds: float) -> void:
    if not is_alive:
        return
    _forced_stagger_remaining = maxf(_forced_stagger_remaining, seconds)
    _telegraph_remaining = 0.0
    current_intent = "Staggered"


func _physics_process(delta: float) -> void:
    _attack_cooldown = maxf(0.0, _attack_cooldown - delta)
    _hurt_flash = maxf(0.0, _hurt_flash - delta)
    _knockback_remaining = maxf(0.0, _knockback_remaining - delta)
    _forced_stagger_remaining = maxf(0.0, _forced_stagger_remaining - delta)

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    if not is_alive or not is_instance_valid(_target):
        velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
    elif _knockback_remaining > 0.0 or _forced_stagger_remaining > 0.0:
        velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
        current_intent = "Staggered"
    elif _telegraph_remaining > 0.0:
        velocity.x = 0.0
        _telegraph_remaining -= delta
        current_intent = "Attack in %.1f s" % maxf(0.0, _telegraph_remaining)
        if _telegraph_remaining <= 0.0:
            _resolve_attack()
    else:
        var offset := _target.global_position - global_position
        facing = 1 if offset.x > 0.0 else -1
        if absf(offset.x) > ATTACK_REACH:
            velocity.x = float(facing) * MOVE_SPEED
            current_intent = "Approaching"
        else:
            velocity.x = 0.0
            current_intent = "In melee range"
            if _attack_cooldown <= 0.0:
                _telegraph_remaining = 0.42
                current_intent = "Winding up"
                combat_event.emit("Monster raises its claws—Guard now!")

    move_and_slide()
    position.x = clampf(position.x, 44.0, 1236.0)
    queue_redraw()


func _resolve_attack() -> void:
    _attack_cooldown = 1.35
    if not is_instance_valid(_target) or not _target.has_method("receive_damage"):
        return
    var offset := _target.global_position - global_position
    if absf(offset.x) <= ATTACK_REACH + 18.0 and absf(offset.y) <= 90.0:
        var attacker_side := signi(int(global_position.x - _target.global_position.x))
        _target.receive_damage(18, attacker_side)
        current_intent = "Recovering"
    else:
        combat_event.emit("Monster attack misses.")
        current_intent = "Missed"


func _draw() -> void:
    var tint := Color("ffffff") if _hurt_flash <= 0.0 else Color("ff8b8b")
    var body := Color("7f3f71") * tint
    var direction := float(facing)

    var health_width := 84.0
    var health_ratio := clampf(float(health) / float(MAX_HEALTH), 0.0, 1.0)
    draw_rect(Rect2(-health_width * 0.5, -119.0, health_width, 9.0), Color(0.08, 0.04, 0.06, 0.9), true)
    draw_rect(
        Rect2(-health_width * 0.5 + 1.0, -118.0, (health_width - 2.0) * health_ratio, 7.0),
        Color("c52232"),
        true,
    )
    draw_rect(Rect2(-health_width * 0.5, -119.0, health_width, 9.0), Color("f0c66d"), false, 1.0)

    draw_circle(Vector2(0.0, -49.0), 30.0, body)
    draw_polygon(
        PackedVector2Array([
            Vector2(-27.0, -44.0),
            Vector2(27.0, -44.0),
            Vector2(22.0, -5.0),
            Vector2(-22.0, -5.0),
        ]),
        PackedColorArray([body]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(-21.0, -72.0), Vector2(-35.0, -99.0), Vector2(-4.0, -77.0)]),
        PackedColorArray([Color("d8c6a5") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(21.0, -72.0), Vector2(35.0, -99.0), Vector2(4.0, -77.0)]),
        PackedColorArray([Color("d8c6a5") * tint]),
    )
    draw_circle(Vector2(direction * 10.0, -56.0), 5.0, Color("ffd45c"))
    draw_circle(Vector2(direction * 12.0, -57.0), 2.0, Color("2a152a"))
    draw_line(Vector2(-18.0, -5.0), Vector2(-23.0, 0.0), Color("4e254b"), 11.0)
    draw_line(Vector2(18.0, -5.0), Vector2(23.0, 0.0), Color("4e254b"), 11.0)

    if _telegraph_remaining > 0.0:
        draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 32, Color("ff655f"), 6.0)
