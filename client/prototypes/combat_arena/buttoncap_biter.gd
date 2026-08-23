# PROTOTYPE — hopping Buttoncap Biter enemy. Throwaway mechanics actor.
# Bounces along its patrol span on the spring leg, using the v1 sprite set
# (idle / hop / hurt / defeated). Deals light contact damage to a target that
# exposes receive_damage(amount, attacker_side).
class_name PrototypeButtoncapBiter
extends CharacterBody2D

signal defeated

@onready var sprite: AnimatedSprite2D = $Sprite

const GRAVITY := 1850.0
const HOP_VELOCITY_Y := -430.0
const HOP_SPEED_X := 92.0
const SETTLE_DECEL := 420.0
const MAX_HEALTH := 40
const TOUCH_RANGE := 62.0
const TOUCH_DAMAGE := 9

@export var patrol_min_x := 0.0
@export var patrol_max_x := 0.0
@export var hop_interval := 1.05
@export var starts_facing := -1

var health := MAX_HEALTH
var is_alive := true
var facing := -1
var _hop_timer := 0.0
var _hurt_flash := 0.0
var _touch_cooldown := 0.0
var _target: Node2D
var _start_position := Vector2.ZERO


func set_target(target: Node2D) -> void:
    _target = target


func _ready() -> void:
    _start_position = position
    facing = -1 if starts_facing < 0 else 1
    if patrol_max_x <= patrol_min_x:
        patrol_min_x = position.x - 130.0
        patrol_max_x = position.x + 130.0
    # Stagger the first hop so a cluster of biters does not bounce in lockstep.
    _hop_timer = fmod(absf(position.x) * 0.013, hop_interval)


# Restore a fresh, living biter — used when the hero re-enters the hollow.
func reset() -> void:
    health = MAX_HEALTH
    is_alive = true
    facing = -1 if starts_facing < 0 else 1
    velocity = Vector2.ZERO
    position = _start_position
    _hop_timer = fmod(absf(position.x) * 0.013, hop_interval)
    _hurt_flash = 0.0
    _touch_cooldown = 0.0
    if is_instance_valid(sprite):
        sprite.play("idle")
    queue_redraw()


# Enable/disable physics and collision when this map is (in)active.
func set_active(active: bool) -> void:
    process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
    var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
    if shape != null:
        shape.set_deferred("disabled", not active)


func receive_damage(amount: int, source_x: float) -> void:
    if not is_alive:
        return
    health = maxi(0, health - amount)
    _hurt_flash = 0.24
    velocity.x = signf(global_position.x - source_x) * 190.0
    velocity.y = -235.0
    if health == 0:
        is_alive = false
        defeated.emit()
    queue_redraw()


func _physics_process(delta: float) -> void:
    _hurt_flash = maxf(0.0, _hurt_flash - delta)
    _touch_cooldown = maxf(0.0, _touch_cooldown - delta)

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    if not is_alive:
        velocity.x = move_toward(velocity.x, 0.0, SETTLE_DECEL * delta)
        move_and_slide()
        _update_animation()
        return

    if is_on_floor():
        velocity.x = move_toward(velocity.x, 0.0, SETTLE_DECEL * delta)
        if position.x <= patrol_min_x:
            facing = 1
        elif position.x >= patrol_max_x:
            facing = -1
        _hop_timer -= delta
        if _hop_timer <= 0.0:
            _hop_timer = hop_interval
            velocity.y = HOP_VELOCITY_Y
            velocity.x = float(facing) * HOP_SPEED_X

    move_and_slide()
    position.x = clampf(position.x, patrol_min_x, patrol_max_x)
    _apply_contact_damage()
    _update_animation()
    queue_redraw()


func _apply_contact_damage() -> void:
    if _touch_cooldown > 0.0 or not is_instance_valid(_target):
        return
    if not _target.has_method("receive_damage"):
        return
    if "is_alive" in _target and not _target.is_alive:
        return
    if global_position.distance_to(_target.global_position) <= TOUCH_RANGE:
        var attacker_side := signi(int(global_position.x - _target.global_position.x))
        _target.receive_damage(TOUCH_DAMAGE, attacker_side)
        _touch_cooldown = 0.9


func _update_animation() -> void:
    if not is_instance_valid(sprite):
        return
    sprite.flip_h = facing > 0
    var next := &"idle"
    if not is_alive:
        next = &"defeated"
    elif _hurt_flash > 0.0:
        next = &"hurt"
    elif not is_on_floor() or absf(velocity.x) > 12.0:
        next = &"hop"
    if sprite.animation != next or not sprite.is_playing():
        sprite.play(next)


func _draw() -> void:
    if not is_alive:
        return
    var width := 64.0
    var top := -150.0
    var ratio := clampf(float(health) / float(MAX_HEALTH), 0.0, 1.0)
    draw_rect(Rect2(-width * 0.5, top, width, 8.0), Color(0.08, 0.04, 0.06, 0.9), true)
    var fill := Color("ff8b8b") if _hurt_flash > 0.0 else Color("c52232")
    draw_rect(Rect2(-width * 0.5 + 1.0, top + 1.0, (width - 2.0) * ratio, 6.0), fill, true)
    draw_rect(Rect2(-width * 0.5, top, width, 8.0), Color("f0c66d"), false, 1.0)
