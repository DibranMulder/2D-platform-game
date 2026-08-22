# PROTOTYPE — local-only merchant transaction UI.
class_name PrototypeMerchantShop
extends Control

signal shop_closed

const STARTING_GOLD := 300
const STOCK_IDS := [
    "iron_longsword",
    "moonwood_bow",
    "lantern_staff",
    "ruin_guard",
    "redleaf_potion",
    "wayfarer_rations",
]

var _gold := STARTING_GOLD
var _quantities: Dictionary = {}
var _catalog := GameItemCatalog.new()
var _items: Array[Dictionary] = []
var _gold_label: Label
var _status_label: Label
var _item_buttons: Dictionary = {}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    for item_id: String in STOCK_IDS:
        var definition := _catalog.item(item_id)
        if not definition.is_empty():
            definition["category"] = _shop_category(definition)
            _items.append(definition)
    _build_shop()


func open_shop() -> void:
    visible = true
    _status_label.text = "Select an item to purchase. Everything is held in memory for this prototype."
    _refresh()


func close_shop() -> void:
    if not visible:
        return
    visible = false
    shop_closed.emit()


func gold() -> int:
    return _gold


func quantity(item_id: String) -> int:
    return int(_quantities.get(item_id, 0))


func purchase(item_id: String) -> bool:
    var item := _item(item_id)
    if item.is_empty():
        return false
    var price := int(item["price"])
    var repeatable := str(item["category"]) == "SUPPLY"
    if not repeatable and quantity(item_id) > 0:
        _status_label.text = "%s is already in your inventory." % item["name"]
        return false
    if _gold < price:
        _status_label.text = "You need %s more gold for %s." % [price - _gold, item["name"]]
        return false
    _gold -= price
    _quantities[item_id] = quantity(item_id) + 1
    _status_label.text = "Purchased %s for %s gold." % [item["name"], price]
    _refresh()
    return true


func _build_shop() -> void:
    var backdrop := ColorRect.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color(0.015, 0.025, 0.055, 0.9)
    add_child(backdrop)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.add_child(center)

    var window := PanelContainer.new()
    window.custom_minimum_size = Vector2(930.0, 625.0)
    window.add_theme_stylebox_override("panel", _style(Color("101b2c"), Color("d3ab54"), 2))
    center.add_child(window)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_bottom", 22)
    window.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)

    var header := HBoxContainer.new()
    column.add_child(header)
    var titles := VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(titles)
    titles.add_child(_label("MIRA'S MOONLIT MARKET", 28, Color("f3d88c")))
    titles.add_child(_label("Weapons, armor, and supplies for the road ahead", 15, Color("a9bfd4")))
    _gold_label = _label("", 20, Color("f5c95b"))
    _gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(_gold_label)
    var close := _button("CLOSE · E / ESC", Color("5d4356"))
    close.custom_minimum_size = Vector2(155.0, 48.0)
    close.pressed.connect(close_shop)
    header.add_child(close)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 14)
    grid.add_theme_constant_override("v_separation", 12)
    column.add_child(grid)

    for item: Dictionary in _items:
        var button := _button("", _category_color(str(item["category"])))
        button.custom_minimum_size = Vector2(425.0, 118.0)
        button.pressed.connect(_on_item_pressed.bind(str(item["id"])))
        _item_buttons[str(item["id"])] = button
        grid.add_child(button)

    _status_label = _label("", 15, Color("f1c978"))
    _status_label.custom_minimum_size.y = 44.0
    _status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_status_label)
    _refresh()


func _on_item_pressed(item_id: String) -> void:
    purchase(item_id)


func _refresh() -> void:
    if _gold_label == null:
        return
    _gold_label.text = "GOLD  %s     " % _gold
    for item: Dictionary in _items:
        var item_id := str(item["id"])
        var owned := quantity(item_id)
        var owned_text := "OWNED ×%s" % owned if owned > 0 else "BUY"
        var button := _item_buttons[item_id] as Button
        button.text = "%s · %s GOLD\n%s\n%s\n%s" % [
            item["category"],
            item["price"],
            item["name"],
            item["description"],
            owned_text,
        ]
        button.disabled = (
            (str(item["category"]) != "SUPPLY" and owned > 0)
            or _gold < int(item["price"])
        )


func _item(item_id: String) -> Dictionary:
    for item: Dictionary in _items:
        if item["id"] == item_id:
            return item
    return {}


func _shop_category(item: Dictionary) -> String:
    var category := str(item.get("category", ""))
    if category == "weapon":
        return "WEAPON"
    if category in ["armor", "shield", "cape", "accessory"]:
        return "ARMOR"
    return "SUPPLY"


func _category_color(category: String) -> Color:
    match category:
        "WEAPON":
            return Color("374c73")
        "ARMOR":
            return Color("42634f")
        _:
            return Color("624b6f")


func _label(text: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    return label


func _button(text: String, color: Color) -> Button:
    var button := Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 14)
    button.add_theme_color_override("font_color", Color("f4e9c8"))
    button.add_theme_stylebox_override("normal", _style(color, color.lightened(0.25), 1))
    button.add_theme_stylebox_override("hover", _style(color.lightened(0.1), Color("f2d787"), 2))
    button.add_theme_stylebox_override("pressed", _style(color.darkened(0.12), Color("fff0b2"), 2))
    return button


func _style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(9)
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    style.content_margin_top = 9.0
    style.content_margin_bottom = 9.0
    return style
