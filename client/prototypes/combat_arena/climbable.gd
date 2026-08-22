# PROTOTYPE — reusable ladder/rope trigger for vertical traversal.
class_name PrototypeClimbable
extends Area2D

enum VisualKind {
    LADDER,
    ROPE,
}

@export var visual_kind := VisualKind.LADDER
@export var top_exit_offset_y := -55.0
@export var bottom_exit_offset_y := 55.0
@export var show_hint := true

const WOOD_DARK := Color("49351f")
const WOOD_MID := Color("8e6535")
const WOOD_LIGHT := Color("d2a95c")
const ROPE_DARK := Color("4d3d28")
const ROPE_LIGHT := Color("d3b875")

var _hint: Label


func _ready() -> void:
    monitoring = true
    monitorable = true
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    _build_hint()
    queue_redraw()


func _exit_tree() -> void:
    for body: Node2D in get_overlapping_bodies():
        _unregister_from(body)


func set_climbing_enabled(enabled: bool) -> void:
    if monitoring == enabled:
        visible = enabled
        return
    if not enabled:
        for body: Node2D in get_overlapping_bodies():
            _unregister_from(body)
    set_deferred("monitoring", enabled)
    visible = enabled


func _on_body_entered(body: Node2D) -> void:
    if not body.has_method("register_climbable"):
        return
    body.call(
        "register_climbable",
        self,
        global_position.x,
        to_global(Vector2(0.0, top_exit_offset_y)).y,
        to_global(Vector2(0.0, bottom_exit_offset_y)).y,
    )


func _on_body_exited(body: Node2D) -> void:
    _unregister_from(body)


func _unregister_from(body: Node2D) -> void:
    if body.has_method("unregister_climbable"):
        body.call("unregister_climbable", self)


func _build_hint() -> void:
    _hint = Label.new()
    _hint.visible = show_hint
    _hint.z_index = 4
    _hint.position = Vector2(-108.0, top_exit_offset_y - 38.0)
    _hint.size = Vector2(216.0, 28.0)
    _hint.text = "W / S  ·  CLIMB    SPACE  ·  JUMP OFF"
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hint.add_theme_font_size_override("font_size", 12)
    _hint.add_theme_color_override("font_color", Color("fff1bd"))
    _hint.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.04, 0.96))
    _hint.add_theme_constant_override("shadow_offset_x", 2)
    _hint.add_theme_constant_override("shadow_offset_y", 2)
    add_child(_hint)


func _draw() -> void:
    if visual_kind == VisualKind.ROPE:
        _draw_rope()
    else:
        _draw_ladder()


func _draw_ladder() -> void:
    var top := top_exit_offset_y - 18.0
    var bottom := bottom_exit_offset_y + 4.0
    for rail_x: float in [-22.0, 22.0]:
        draw_line(Vector2(rail_x + 3.0, top), Vector2(rail_x + 3.0, bottom), Color(0.02, 0.03, 0.02, 0.45), 9.0)
        draw_line(Vector2(rail_x, top), Vector2(rail_x, bottom), WOOD_DARK, 9.0)
        draw_line(Vector2(rail_x - 2.0, top), Vector2(rail_x - 2.0, bottom), WOOD_MID, 4.0)

    var rung_y := top + 13.0
    while rung_y < bottom - 5.0:
        draw_line(Vector2(-24.0, rung_y + 3.0), Vector2(24.0, rung_y + 3.0), Color(0.02, 0.03, 0.02, 0.5), 9.0)
        draw_line(Vector2(-25.0, rung_y), Vector2(25.0, rung_y), WOOD_DARK, 9.0)
        draw_line(Vector2(-22.0, rung_y - 2.0), Vector2(22.0, rung_y - 2.0), WOOD_LIGHT, 3.0)
        rung_y += 18.0


func _draw_rope() -> void:
    var top := top_exit_offset_y - 20.0
    var bottom := bottom_exit_offset_y + 7.0
    var points := PackedVector2Array()
    var segment_count := 24
    for index in segment_count + 1:
        var ratio := float(index) / float(segment_count)
        var y := lerpf(top, bottom, ratio)
        var x := sin(ratio * PI * 2.5) * 3.5
        points.append(Vector2(x, y))
    draw_polyline(points, ROPE_DARK, 10.0, true)
    draw_polyline(points, ROPE_LIGHT, 5.0, true)
    for knot_y in range(int(top) + 18, int(bottom), 24):
        draw_circle(Vector2(sin(float(knot_y) * 0.08) * 3.5, float(knot_y)), 6.0, ROPE_DARK)
        draw_circle(Vector2(sin(float(knot_y) * 0.08) * 3.5, float(knot_y) - 1.0), 3.5, ROPE_LIGHT)
