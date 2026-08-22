class_name ChronicleItemSlot
extends Button

signal item_dropped(pouch_index: int, equipment_slot: String)

const INK_NAVY := Color("101b2c")
const ANTIQUE_BRASS := Color("c79b48")
const WARM_IVORY := Color("fff5d6")
const CRYSTAL_CYAN := Color("72d6e5")
const EMBER_RED := Color("b85645")

var _drag_payload: Dictionary = {}
var _accepted_equipment_slot := ""
var _resting_style: StyleBoxFlat
var _resting_text := ""


func configure_drag_source(payload: Dictionary) -> void:
    _drag_payload = payload.duplicate(true)


func configure_drop_target(equipment_slot: String) -> void:
    _accepted_equipment_slot = equipment_slot


func remember_resting_state() -> void:
    _resting_style = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
    _resting_text = text


func _get_drag_data(_at_position: Vector2) -> Variant:
    if _drag_payload.is_empty() or disabled:
        return null
    if _resting_text.is_empty():
        remember_resting_state()
    var preview := PanelContainer.new()
    preview.custom_minimum_size = Vector2(92.0, 72.0)
    preview.modulate = Color(1.0, 1.0, 1.0, 0.82)
    preview.add_theme_stylebox_override(
        "panel",
        _style(Color(0.06, 0.13, 0.20, 0.98), CRYSTAL_CYAN, 2),
    )
    var label := Label.new()
    label.text = str(_drag_payload.get("preview_text", text))
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", WARM_IVORY)
    preview.add_child(label)
    set_drag_preview(preview)
    text = "· · ·\nVACATED"
    return _drag_payload.duplicate(true)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if _accepted_equipment_slot.is_empty() or not data is Dictionary:
        return false
    var payload := data as Dictionary
    if str(payload.get("kind", "")) != "pouch_item":
        return false
    var compatible := (
        str(payload.get("equipment_slot", "")) == _accepted_equipment_slot
        and bool(payload.get("can_equip", true))
    )
    _show_drop_state(compatible)
    return compatible


func _drop_data(_at_position: Vector2, data: Variant) -> void:
    if not data is Dictionary:
        return
    var payload := data as Dictionary
    item_dropped.emit(int(payload.get("pouch_index", -1)), _accepted_equipment_slot)
    _restore_resting_state()


func _notification(what: int) -> void:
    if what == NOTIFICATION_DRAG_END:
        _restore_resting_state()


func _show_drop_state(compatible: bool) -> void:
    if _resting_style == null:
        remember_resting_state()
    var border := CRYSTAL_CYAN if compatible else EMBER_RED
    add_theme_stylebox_override("normal", _style(INK_NAVY.lightened(0.05), border, 3))
    if not _accepted_equipment_slot.is_empty():
        text = "DROP TO EQUIP" if compatible else "INCOMPATIBLE"


func _restore_resting_state() -> void:
    if _resting_style != null:
        add_theme_stylebox_override("normal", _resting_style)
    if not _resting_text.is_empty():
        text = _resting_text


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(6)
    style.content_margin_left = 7.0
    style.content_margin_right = 7.0
    style.content_margin_top = 6.0
    style.content_margin_bottom = 6.0
    return style
