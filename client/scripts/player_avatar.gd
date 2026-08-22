class_name PlayerAvatar
extends Node2D

var _is_local := false
var _target_position := Vector2.ZERO
var _initialized := false


func configure(is_local: bool) -> void:
    _is_local = is_local
    queue_redraw()


func apply_world_position(world_x: int, world_y: int) -> void:
    _target_position = Vector2(
        640.0 + float(world_x) / 100.0,
        560.0 - float(world_y) / 100.0,
    )
    if not _initialized:
        position = _target_position
        _initialized = true


func _process(delta: float) -> void:
    var interpolation_weight := 1.0 - exp(-18.0 * delta)
    position = position.lerp(_target_position, interpolation_weight)


func _draw() -> void:
    var body_color := Color("64d8ff") if _is_local else Color("e5a6ff")
    draw_circle(Vector2(0.0, -38.0), 13.0, Color("f2d0a7"))
    draw_rect(Rect2(-14.0, -25.0, 28.0, 38.0), body_color, true)
    draw_line(Vector2(-10.0, 13.0), Vector2(-13.0, 30.0), body_color, 7.0)
    draw_line(Vector2(10.0, 13.0), Vector2(13.0, 30.0), body_color, 7.0)
    if _is_local:
        draw_arc(Vector2(0.0, -38.0), 18.0, 0.0, TAU, 24, Color.WHITE, 2.0)

