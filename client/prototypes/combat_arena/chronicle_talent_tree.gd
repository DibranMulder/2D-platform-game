class_name ChronicleTalentTree
extends Control

signal purchase_requested(talent_id: String)

const DISPLAY_FONT := preload("res://assets/fonts/alegreya/AlegreyaSC-Medium.ttf")
const BODY_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Regular.ttf")
const BODY_MEDIUM_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Medium.ttf")

const INK_NAVY := Color("101b2c")
const PARCHMENT := Color("f3e5be")
const AGED_PAPER := Color("d6bd84")
const ANTIQUE_BRASS := Color("c79b48")
const WARM_IVORY := Color("fff5d6")
const FOREST_TEAL := Color("2d756e")
const CRYSTAL_CYAN := Color("72d6e5")
const QUEST_GOLD := Color("f2c45f")
const MUTED_STONE := Color("78808a")

const NODE_SIZE := Vector2(166.0, 66.0)
const ROOT_RECT := Rect2(452.0, 388.0, 196.0, 52.0)
const NODE_POSITIONS := {
    "keen_edge": Vector2(182.0, 304.0),
    "decisive_blow": Vector2(62.0, 204.0),
    "sweeping_arc": Vector2(248.0, 130.0),
    "executioner": Vector2(138.0, 26.0),
    "firm_guard": Vector2(467.0, 278.0),
    "counterstance": Vector2(354.0, 178.0),
    "iron_wall": Vector2(548.0, 108.0),
    "last_stand": Vector2(452.0, 10.0),
    "fleet_step": Vector2(752.0, 304.0),
    "aerial_control": Vector2(654.0, 204.0),
    "relentless_lunge": Vector2(848.0, 130.0),
    "renewing_wind": Vector2(758.0, 26.0),
}
const BRANCH_ROOTS := ["keen_edge", "firm_guard", "fleet_step"]

var _profile: PrototypeHeroProfileState


func configure(profile: PrototypeHeroProfileState) -> void:
    _profile = profile
    if is_node_ready():
        _rebuild()


func _ready() -> void:
    custom_minimum_size = Vector2(1100.0, 452.0)
    mouse_filter = Control.MOUSE_FILTER_PASS
    if _profile != null:
        _rebuild()


func _rebuild() -> void:
    for child: Node in get_children():
        remove_child(child)
        child.queue_free()

    var root := PanelContainer.new()
    root.position = ROOT_RECT.position
    root.size = ROOT_RECT.size
    root.add_theme_stylebox_override("panel", _style(INK_NAVY, ANTIQUE_BRASS, 2, 8))
    add_child(root)
    var root_label := _label("SWORD MASTERY", 22, WARM_IVORY, true)
    root_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    root_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    root.add_child(root_label)

    _add_branch_banner("BLADE", Vector2(257.0, 374.0), Color("8a4e42"))
    _add_branch_banner("GUARDIAN", Vector2(475.0, 360.0), Color("31556b"))
    _add_branch_banner("WAYFARER", Vector2(736.0, 374.0), Color("35664f"))

    for talent: Dictionary in PrototypeHeroProfileState.TALENTS:
        var talent_id := str(talent["id"])
        var node := Button.new()
        node.position = NODE_POSITIONS[talent_id]
        node.size = NODE_SIZE
        node.focus_mode = Control.FOCUS_ALL
        node.add_theme_font_override("font", BODY_MEDIUM_FONT)
        node.add_theme_font_size_override("font_size", 14)
        node.add_theme_color_override("font_color", WARM_IVORY)
        node.add_theme_color_override("font_disabled_color", WARM_IVORY)
        node.tooltip_text = str(talent["description"])

        var owned := _profile.owns_talent(talent_id)
        var available := _is_available(talent)
        if owned:
            node.text = "%s\nUNLOCKED" % talent["name"]
            node.add_theme_stylebox_override("normal", _style(FOREST_TEAL.darkened(0.18), FOREST_TEAL.lightened(0.22), 2, 10))
            node.add_theme_stylebox_override("hover", _style(FOREST_TEAL, CRYSTAL_CYAN, 2, 10))
        elif available:
            node.text = "%s\nLV %s · %s POINT%s" % [
                talent["name"],
                talent["level"],
                talent["cost"],
                "S" if int(talent["cost"]) != 1 else "",
            ]
            node.add_theme_stylebox_override("normal", _style(Color("765721"), QUEST_GOLD, 2, 10))
            node.add_theme_stylebox_override("hover", _style(Color("916c2b"), CRYSTAL_CYAN, 2, 10))
            node.pressed.connect(_request_purchase.bind(talent_id))
        else:
            node.text = "%s\nLOCKED · LV %s" % [talent["name"], talent["level"]]
            node.add_theme_stylebox_override("normal", _style(Color("34383a"), MUTED_STONE.darkened(0.15), 1, 10))
            node.add_theme_stylebox_override("hover", _style(Color("42484b"), MUTED_STONE, 2, 10))
            node.pressed.connect(_request_purchase.bind(talent_id))

        node.add_theme_stylebox_override("pressed", _style(INK_NAVY, QUEST_GOLD, 2, 10))
        node.add_theme_stylebox_override("focus", _style(INK_NAVY.lightened(0.08), CRYSTAL_CYAN, 3, 10))
        add_child(node)

    queue_redraw()


func _request_purchase(talent_id: String) -> void:
    purchase_requested.emit(talent_id)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.95, 0.88, 0.69, 0.98), true)
    draw_rect(Rect2(1.0, 1.0, size.x - 2.0, size.y - 2.0), Color("b8893d"), false, 2.0)
    draw_rect(Rect2(7.0, 7.0, size.x - 14.0, size.y - 14.0), Color(0.35, 0.28, 0.16, 0.45), false, 1.0)
    if _profile == null:
        return

    var root_top := Vector2(ROOT_RECT.get_center().x, ROOT_RECT.position.y)
    for talent_id: String in BRANCH_ROOTS:
        _draw_connection(root_top, _node_bottom(talent_id), _connection_color(talent_id), 5.0)

    for talent: Dictionary in PrototypeHeroProfileState.TALENTS:
        var prerequisite := str(talent["requires"])
        if prerequisite.is_empty():
            continue
        var talent_id := str(talent["id"])
        _draw_connection(
            _node_top(prerequisite),
            _node_bottom(talent_id),
            _connection_color(talent_id),
            4.0,
        )


func _draw_connection(from: Vector2, to: Vector2, color: Color, width: float) -> void:
    var curve := Curve2D.new()
    var lift := maxf(28.0, absf(from.y - to.y) * 0.42)
    curve.add_point(from, Vector2.ZERO, Vector2(0.0, -lift))
    curve.add_point(to, Vector2(0.0, lift), Vector2.ZERO)
    draw_polyline(curve.get_baked_points(), Color(0.18, 0.12, 0.07, 0.55), width + 3.0, true)
    draw_polyline(curve.get_baked_points(), color, width, true)


func _connection_color(child_talent_id: String) -> Color:
    if _profile.owns_talent(child_talent_id):
        return FOREST_TEAL.lightened(0.22)
    var talent := _profile.talent_by_id(child_talent_id)
    if _is_available(talent):
        return QUEST_GOLD
    return Color(0.43, 0.34, 0.22, 0.78)


func _is_available(talent: Dictionary) -> bool:
    if talent.is_empty() or _profile.owns_talent(str(talent["id"])):
        return false
    if _profile.overall_level() < int(talent["level"]):
        return false
    var prerequisite := str(talent["requires"])
    if not prerequisite.is_empty() and not _profile.owns_talent(prerequisite):
        return false
    return _profile.unspent_talent_points() >= int(talent["cost"])


func _node_top(talent_id: String) -> Vector2:
    var position_value := NODE_POSITIONS[talent_id] as Vector2
    return position_value + Vector2(NODE_SIZE.x * 0.5, 0.0)


func _node_bottom(talent_id: String) -> Vector2:
    var position_value := NODE_POSITIONS[talent_id] as Vector2
    return position_value + Vector2(NODE_SIZE.x * 0.5, NODE_SIZE.y)


func _add_branch_banner(text: String, position_value: Vector2, accent: Color) -> void:
    var banner := PanelContainer.new()
    banner.position = position_value
    banner.size = Vector2(132.0, 32.0)
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.add_theme_stylebox_override("panel", _style(accent.darkened(0.18), ANTIQUE_BRASS, 1, 5))
    var label := _label(text, 16, WARM_IVORY, true)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.add_child(label)
    add_child(banner)


func _label(text: String, font_size: int, color: Color, display: bool = false) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_override("font", DISPLAY_FONT if display else BODY_FONT)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 7.0
    style.content_margin_right = 7.0
    style.content_margin_top = 5.0
    style.content_margin_bottom = 5.0
    return style
