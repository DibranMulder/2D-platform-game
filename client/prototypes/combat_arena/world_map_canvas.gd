# PROTOTYPE — procedural, interactive world-map canvas.
class_name PrototypeWorldMapCanvas
extends Control

signal territory_selected(territory_id: String)
signal view_changed(zoom_level: float, pan_offset: Vector2)

const MAP_SIZE := Vector2(760.0, 470.0)

var territories: Array[Dictionary] = []
var dungeons: Array[Dictionary] = []
var routes: Array[Dictionary] = []
var variant := "A"
var selected_id := "open_lands"
var marker_filter := "all"
var zoom_level := 1.0
var pan_offset := Vector2.ZERO

var _dragging := false
var _press_position := Vector2.ZERO
var _last_pointer := Vector2.ZERO
var _drag_distance := 0.0
var _hovered_id := ""


func configure(
    territory_data: Array[Dictionary],
    dungeon_data: Array[Dictionary],
    route_data: Array[Dictionary],
    variant_id: String,
    selected_territory_id: String,
    filter_id: String,
    initial_zoom: float,
    initial_pan: Vector2,
) -> void:
    territories = territory_data
    dungeons = dungeon_data
    routes = route_data
    variant = variant_id
    selected_id = selected_territory_id
    marker_filter = filter_id
    zoom_level = initial_zoom
    pan_offset = initial_pan
    queue_redraw()


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    queue_redraw()


func adjust_zoom(amount: float) -> void:
    zoom_level = clampf(zoom_level + amount, 0.72, 1.75)
    _clamp_pan()
    view_changed.emit(zoom_level, pan_offset)
    queue_redraw()


func reset_view() -> void:
    zoom_level = 1.0
    pan_offset = Vector2.ZERO
    view_changed.emit(zoom_level, pan_offset)
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_button := event as InputEventMouseButton
        if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
            adjust_zoom(0.12)
            accept_event()
        elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
            adjust_zoom(-0.12)
            accept_event()
        elif mouse_button.button_index == MOUSE_BUTTON_LEFT:
            if mouse_button.pressed:
                _begin_drag(mouse_button.position)
            else:
                _finish_drag(mouse_button.position)
            accept_event()
    elif event is InputEventMouseMotion:
        var mouse_motion := event as InputEventMouseMotion
        _hovered_id = _territory_at(mouse_motion.position)
        if _dragging:
            _drag_to(mouse_motion.position)
        queue_redraw()
    elif event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            _begin_drag(touch.position)
        else:
            _finish_drag(touch.position)
        accept_event()
    elif event is InputEventScreenDrag:
        _drag_to((event as InputEventScreenDrag).position)
        accept_event()


func _begin_drag(position: Vector2) -> void:
    _dragging = true
    _press_position = position
    _last_pointer = position
    _drag_distance = 0.0


func _drag_to(position: Vector2) -> void:
    if not _dragging:
        return
    var movement := position - _last_pointer
    _drag_distance += movement.length()
    pan_offset += movement
    _last_pointer = position
    _clamp_pan()
    view_changed.emit(zoom_level, pan_offset)
    queue_redraw()


func _finish_drag(position: Vector2) -> void:
    if not _dragging:
        return
    _dragging = false
    if _drag_distance <= 10.0 and position.distance_to(_press_position) <= 12.0:
        var territory_id := _territory_at(position)
        if not territory_id.is_empty():
            selected_id = territory_id
            territory_selected.emit(territory_id)
            queue_redraw()


func _territory_at(screen_point: Vector2) -> String:
    var map_point := (screen_point - _map_origin()) / _map_scale()
    for index in range(territories.size() - 1, -1, -1):
        var territory := territories[index]
        if Geometry2D.is_point_in_polygon(map_point, territory["polygon"] as PackedVector2Array):
            return str(territory["id"])
    return ""


func _clamp_pan() -> void:
    var overflow := (MAP_SIZE * _map_scale() - size) * 0.5
    overflow.x = maxf(0.0, overflow.x)
    overflow.y = maxf(0.0, overflow.y)
    var limit := overflow + Vector2(55.0, 40.0)
    pan_offset.x = clampf(pan_offset.x, -limit.x, limit.x)
    pan_offset.y = clampf(pan_offset.y, -limit.y, limit.y)


func _map_origin() -> Vector2:
    return (size - MAP_SIZE * _map_scale()) * 0.5 + pan_offset


func _map_scale() -> float:
    var fit_scale := minf(size.x / MAP_SIZE.x, size.y / MAP_SIZE.y)
    return fit_scale * zoom_level


func _to_screen(map_point: Vector2) -> Vector2:
    return _map_origin() + map_point * _map_scale()


func _screen_polygon(map_polygon: PackedVector2Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    for point: Vector2 in map_polygon:
        result.append(_to_screen(point))
    return result


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("101b2b"), true)
    _draw_water_and_grid()
    if variant == "B":
        _draw_routes(true)
    for territory: Dictionary in territories:
        _draw_territory(territory)
    if variant != "B":
        _draw_routes(false)
    _draw_markers()
    draw_rect(Rect2(Vector2.ZERO, size), Color("64758b"), false, 2.0)


func _draw_water_and_grid() -> void:
    var origin := _map_origin()
    var extent := MAP_SIZE * _map_scale()
    draw_rect(Rect2(origin, extent), Color("173149"), true)
    if variant == "B":
        for x in range(0, 761, 76):
            draw_line(_to_screen(Vector2(x, 0)), _to_screen(Vector2(x, 470)), Color(0.5, 0.7, 0.8, 0.1), 1.0)
        for y in range(0, 471, 47):
            draw_line(_to_screen(Vector2(0, y)), _to_screen(Vector2(760, y)), Color(0.5, 0.7, 0.8, 0.1), 1.0)
    else:
        for y in range(32, 470, 42):
            for x in range(18 + (y % 3) * 8, 760, 78):
                draw_arc(_to_screen(Vector2(x, y)), 10.0 * _map_scale(), 0.15, 2.95, 10, Color(0.55, 0.78, 0.9, 0.12), 1.5)


func _draw_territory(territory: Dictionary) -> void:
    var polygon := _screen_polygon(territory["polygon"] as PackedVector2Array)
    var fill: Color = territory["color"]
    if variant == "B":
        fill = Color(fill.r, fill.g, fill.b, 0.42)
    elif variant == "C":
        match str(territory["allegiance"]):
            "light":
                fill = Color("376f9d")
            "dark":
                fill = Color("70476f")
            _:
                fill = Color("88733f")

    var territory_id := str(territory["id"])
    if territory_id == selected_id:
        fill = fill.lightened(0.2)
    elif territory_id == _hovered_id:
        fill = fill.lightened(0.1)

    draw_colored_polygon(polygon, fill)
    var outline := Color("efcf7b") if territory_id == selected_id else Color(0.65, 0.75, 0.84, 0.55)
    var closed := polygon.duplicate()
    if not closed.is_empty():
        closed.append(closed[0])
    draw_polyline(closed, outline, 3.0 if territory_id == selected_id else 1.5, true)

    var center := _to_screen(territory["center"] as Vector2)
    var label_color := Color("fff0bf") if territory_id == selected_id else Color("e4edf5")
    var title := str(territory["short_name"])
    draw_string(
        ThemeDB.fallback_font,
        center + Vector2(-62.0, -3.0),
        title.to_upper(),
        HORIZONTAL_ALIGNMENT_CENTER,
        124.0,
        12 if variant == "B" else 13,
        label_color,
    )
    if variant == "C":
        draw_string(
            ThemeDB.fallback_font,
            center + Vector2(-52.0, 13.0),
            str(territory["control_label"]),
            HORIZONTAL_ALIGNMENT_CENTER,
            104.0,
            10,
            Color(0.9, 0.92, 0.95, 0.75),
        )


func _draw_routes(emphasized: bool) -> void:
    for route: Dictionary in routes:
        var from_territory := _territory(str(route["from"]))
        var to_territory := _territory(str(route["to"]))
        if from_territory.is_empty() or to_territory.is_empty():
            continue
        var color := Color("e4bd69") if emphasized else Color(0.9, 0.75, 0.42, 0.34)
        var width := 3.0 if emphasized else 1.4
        draw_dashed_line(
            _to_screen(from_territory["center"] as Vector2),
            _to_screen(to_territory["center"] as Vector2),
            color,
            width,
            10.0,
        )


func _draw_markers() -> void:
    if marker_filter != "dungeons":
        for territory: Dictionary in territories:
            if str(territory["kind"]) != "homeland":
                continue
            var stronghold := _to_screen(territory["stronghold_position"] as Vector2)
            var village := _to_screen(territory["village_position"] as Vector2)
            var marker_color := Color("93d8ff") if territory["allegiance"] == "light" else Color("e297cd")
            draw_polygon(
                PackedVector2Array([
                    stronghold + Vector2(0.0, -9.0),
                    stronghold + Vector2(9.0, 7.0),
                    stronghold + Vector2(-9.0, 7.0),
                ]),
                PackedColorArray([marker_color]),
            )
            draw_rect(Rect2(village - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color("e7dfbd"), true)

    if marker_filter != "strongholds":
        for dungeon: Dictionary in dungeons:
            var point := _to_screen(dungeon["position"] as Vector2)
            var diamond := PackedVector2Array([
                point + Vector2(0.0, -8.0),
                point + Vector2(8.0, 0.0),
                point + Vector2(0.0, 8.0),
                point + Vector2(-8.0, 0.0),
            ])
            draw_colored_polygon(diamond, Color("ef815f"))
            if variant == "B":
                draw_string(
                    ThemeDB.fallback_font,
                    point + Vector2(10.0, 4.0),
                    str(dungeon["name"]),
                    HORIZONTAL_ALIGNMENT_LEFT,
                    -1.0,
                    11,
                    Color("ffd8b8"),
                )


func _territory(territory_id: String) -> Dictionary:
    for territory: Dictionary in territories:
        if territory["id"] == territory_id:
            return territory
    return {}
