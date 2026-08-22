# Reusable button from the Enchanted Chronicle UI system board.
class_name ChronicleButton
extends Button

enum Variant {
    PRIMARY,
    SECONDARY,
    QUIET,
    DANGER,
}

const BODY_MEDIUM_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Medium.ttf")

const INK_NAVY := Color("101b2c")
const BOOK_BLUE := Color("183454")
const ANTIQUE_BRASS := Color("c79b48")
const WARM_IVORY := Color("fff5d6")
const CRYSTAL_CYAN := Color("72d6e5")
const QUEST_GOLD := Color("f2c45f")
const EMBER_RED := Color("b85645")
const MUTED_STONE := Color("78808a")

@export var variant := Variant.PRIMARY:
    set(value):
        variant = clampi(value, Variant.PRIMARY, Variant.DANGER)
        _refresh_visuals()
@export var touch_safe := true:
    set(value):
        touch_safe = value
        _apply_minimum_size()
@export var ornate := true:
    set(value):
        ornate = value
        _refresh_visuals()

var _face: Control


func _ready() -> void:
    focus_mode = Control.FOCUS_ALL
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    _apply_minimum_size()
    _apply_transparent_button_theme()
    _build_face()
    _connect_visual_signals()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED or what == NOTIFICATION_DRAW:
        _refresh_visuals()


func set_variant(next_variant: Variant) -> void:
    variant = next_variant


func adopt_color_hint(color: Color) -> void:
    if color.r > 0.42 and color.g > 0.28 and color.b < 0.30:
        variant = Variant.PRIMARY
    elif color.r > color.g * 1.28 and color.r > color.b * 1.12:
        variant = Variant.DANGER
    elif color.b > color.r * 1.12 or color.b > color.g * 1.16:
        variant = Variant.SECONDARY
    else:
        variant = Variant.QUIET


func _apply_minimum_size() -> void:
    var minimum_height := 48.0 if touch_safe else 34.0
    custom_minimum_size = Vector2(
        custom_minimum_size.x,
        maxf(custom_minimum_size.y, minimum_height),
    )


func _apply_transparent_button_theme() -> void:
    if not has_theme_font_override("font"):
        add_theme_font_override("font", BODY_MEDIUM_FONT)
    if not has_theme_font_size_override("font_size"):
        add_theme_font_size_override("font_size", 17 if touch_safe else 15)
    add_theme_color_override("font_color", WARM_IVORY)
    add_theme_color_override("font_hover_color", WARM_IVORY)
    add_theme_color_override("font_pressed_color", WARM_IVORY)
    add_theme_color_override("font_focus_color", WARM_IVORY)
    add_theme_color_override("font_hover_pressed_color", WARM_IVORY)
    add_theme_color_override("font_disabled_color", Color(MUTED_STONE.lightened(0.34), 0.72))
    add_theme_color_override("font_outline_color", Color(0.025, 0.04, 0.05, 0.78))
    add_theme_constant_override("outline_size", 1)

    for state: String in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
        var empty := StyleBoxEmpty.new()
        empty.content_margin_left = 19.0
        empty.content_margin_right = 19.0
        empty.content_margin_top = 6.0
        empty.content_margin_bottom = 6.0
        add_theme_stylebox_override(state, empty)


func _build_face() -> void:
    _face = Control.new()
    _face.name = "ChronicleFace"
    _face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _face.show_behind_parent = true
    _face.draw.connect(_draw_face)
    add_child(_face)
    move_child(_face, 0)
    _refresh_visuals()


func _connect_visual_signals() -> void:
    mouse_entered.connect(_refresh_visuals)
    mouse_exited.connect(_refresh_visuals)
    focus_entered.connect(_refresh_visuals)
    focus_exited.connect(_refresh_visuals)
    button_down.connect(_refresh_visuals)
    button_up.connect(_refresh_visuals)
    toggled.connect(func(_pressed: bool) -> void: _refresh_visuals())


func _refresh_visuals() -> void:
    if is_instance_valid(_face):
        _face.queue_redraw()


func _draw_face() -> void:
    if size.x < 8.0 or size.y < 8.0:
        return

    var mode := get_draw_mode()
    var pressed_state := mode in [BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED]
    var hover_state := mode in [BaseButton.DRAW_HOVER, BaseButton.DRAW_HOVER_PRESSED]
    var disabled_state := disabled or mode == BaseButton.DRAW_DISABLED
    var focus_state := has_focus() and not disabled_state
    var palette := _palette(disabled_state, hover_state, pressed_state)
    var press_offset := Vector2(0.0, 2.0) if pressed_state else Vector2.ZERO
    var face_rect := Rect2(Vector2(2.0, 2.0) + press_offset, size - Vector2(4.0, 6.0))
    var chamfer := clampf(face_rect.size.y * 0.22, 6.0, 10.0)

    var shadow_rect := Rect2(face_rect.position + Vector2(2.0, 3.0), face_rect.size)
    _face.draw_colored_polygon(_chamfered_points(shadow_rect, chamfer), Color(0.01, 0.02, 0.025, 0.62))

    var outer_points := _chamfered_points(face_rect, chamfer)
    _face.draw_colored_polygon(outer_points, palette["border"])

    var middle_rect := face_rect.grow(-2.0)
    var middle_points := _chamfered_points(middle_rect, maxf(3.0, chamfer - 2.0))
    _face.draw_colored_polygon(middle_points, palette["edge"])

    var inner_rect := face_rect.grow(-4.0)
    var inner_points := _chamfered_points(inner_rect, maxf(2.0, chamfer - 4.0))
    _face.draw_colored_polygon(inner_points, palette["fill"])
    _draw_closed_line(inner_points, Color(palette["highlight"], 0.76), 1.0)

    var shine_start := inner_rect.position + Vector2(chamfer, 2.0)
    var shine_end := Vector2(inner_rect.end.x - chamfer, inner_rect.position.y + 2.0)
    _face.draw_line(shine_start, shine_end, Color(palette["highlight"], 0.66), 1.0)

    if ornate:
        _draw_ornaments(face_rect, chamfer, palette["border"])

    if focus_state:
        var focus_points := _chamfered_points(Rect2(Vector2(0.5, 0.5), size - Vector2(1.0, 3.0)), chamfer + 1.5)
        _draw_closed_line(focus_points, Color(CRYSTAL_CYAN, 0.36), 5.0)
        _draw_closed_line(focus_points, CRYSTAL_CYAN, 2.0)


func _palette(disabled_state: bool, hover_state: bool, pressed_state: bool) -> Dictionary:
    if disabled_state:
        return {
            "fill": Color("31404b"),
            "edge": Color("222d35"),
            "border": Color(MUTED_STONE.darkened(0.18), 0.74),
            "highlight": Color(MUTED_STONE.lightened(0.14), 0.52),
        }

    var fill: Color
    match variant:
        Variant.SECONDARY:
            fill = BOOK_BLUE
        Variant.QUIET:
            fill = Color("5c4b36")
        Variant.DANGER:
            fill = Color("753326")
        _:
            fill = Color("967022")

    if hover_state:
        fill = fill.lightened(0.10)
    if pressed_state:
        fill = fill.darkened(0.15)

    var border := EMBER_RED.lightened(0.18) if variant == Variant.DANGER else ANTIQUE_BRASS
    if hover_state:
        border = QUEST_GOLD.lightened(0.08)
    return {
        "fill": fill,
        "edge": fill.darkened(0.25),
        "border": border,
        "highlight": fill.lightened(0.42),
    }


func _draw_ornaments(rect: Rect2, chamfer: float, color: Color) -> void:
    var top := rect.position.y
    var bottom := rect.end.y
    var left := rect.position.x
    var right := rect.end.x
    var line_color := Color(color.lightened(0.18), 0.92)
    var notch := minf(12.0, rect.size.x * 0.08)

    _face.draw_line(Vector2(left + chamfer + 2.0, top + 1.0), Vector2(left + chamfer + notch, top + 1.0), line_color, 1.4)
    _face.draw_line(Vector2(right - chamfer - notch, top + 1.0), Vector2(right - chamfer - 2.0, top + 1.0), line_color, 1.4)
    _face.draw_line(Vector2(left + chamfer + 2.0, bottom - 1.0), Vector2(left + chamfer + notch, bottom - 1.0), Color(color, 0.72), 1.2)
    _face.draw_line(Vector2(right - chamfer - notch, bottom - 1.0), Vector2(right - chamfer - 2.0, bottom - 1.0), Color(color, 0.72), 1.2)

    _draw_diamond(Vector2(left + 6.0, rect.get_center().y), 2.5, line_color)
    _draw_diamond(Vector2(right - 6.0, rect.get_center().y), 2.5, line_color)


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
    _face.draw_colored_polygon(PackedVector2Array([
        center + Vector2(0.0, -radius),
        center + Vector2(radius, 0.0),
        center + Vector2(0.0, radius),
        center + Vector2(-radius, 0.0),
    ]), color)


func _chamfered_points(rect: Rect2, chamfer: float) -> PackedVector2Array:
    var amount := minf(chamfer, minf(rect.size.x, rect.size.y) * 0.45)
    return PackedVector2Array([
        rect.position + Vector2(amount, 0.0),
        Vector2(rect.end.x - amount, rect.position.y),
        Vector2(rect.end.x, rect.position.y + amount),
        Vector2(rect.end.x, rect.end.y - amount),
        Vector2(rect.end.x - amount, rect.end.y),
        Vector2(rect.position.x + amount, rect.end.y),
        Vector2(rect.position.x, rect.end.y - amount),
        Vector2(rect.position.x, rect.position.y + amount),
    ])


func _draw_closed_line(points: PackedVector2Array, color: Color, width: float) -> void:
    var closed := points.duplicate()
    closed.append(points[0])
    _face.draw_polyline(closed, color, width, true)
