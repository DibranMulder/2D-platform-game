# PROTOTYPE — three interactive world-map layouts for evaluation.
class_name PrototypeWorldMap
extends Control

const MapCanvasScript := preload("res://prototypes/combat_arena/world_map_canvas.gd")
const ChronicleButtonScript := preload("res://scripts/chronicle_button.gd")

const VARIANTS: Array[Dictionary] = [
    {"id": "A", "name": "Illustrated Atlas"},
    {"id": "B", "name": "Expedition Network"},
    {"id": "C", "name": "Allegiance Control"},
]

var _territories: Array[Dictionary] = [
    {
        "id": "broken_mountains",
        "name": "The Broken Mountains",
        "short_name": "Broken Mtns",
        "kind": "homeland",
        "lineage": "Crag Trolls",
        "allegiance": "dark",
        "terrain": "Storm peaks, quarries, and sheer passes",
        "control_label": "DARK · CRAG TROLL",
        "description": "Monumental passes and quarry roads climb toward a storm-hardened mountain hold.",
        "stronghold": "Crag Troll Stronghold",
        "village": "Cliffside Outer Village",
        "color": Color("515c58"),
        "polygon": PackedVector2Array([Vector2(25, 40), Vector2(220, 30), Vector2(245, 92), Vector2(212, 174), Vector2(92, 190), Vector2(18, 122)]),
        "center": Vector2(125, 108),
        "stronghold_position": Vector2(105, 78),
        "village_position": Vector2(174, 145),
    },
    {
        "id": "ice_lands",
        "name": "The Ice Lands",
        "short_name": "Ice Lands",
        "kind": "homeland",
        "lineage": "Rimeborn",
        "allegiance": "dark",
        "terrain": "Glaciers, black ridges, and aurora fields",
        "control_label": "DARK · RIMEBORN",
        "description": "A long frozen night surrounds insulated halls built over precious geothermal warmth.",
        "stronghold": "Rimeborn Stronghold",
        "village": "Thermal Outer Village",
        "color": Color("7899aa"),
        "polygon": PackedVector2Array([Vector2(220, 30), Vector2(450, 18), Vector2(500, 96), Vector2(425, 145), Vector2(300, 132), Vector2(245, 92)]),
        "center": Vector2(357, 77),
        "stronghold_position": Vector2(363, 57),
        "village_position": Vector2(425, 112),
    },
    {
        "id": "sky_reaches",
        "name": "The Sky Reaches",
        "short_name": "Sky Reaches",
        "kind": "homeland",
        "lineage": "Aeralith",
        "allegiance": "light",
        "terrain": "Floating mesas, wind bridges, and cloud forests",
        "control_label": "LIGHT · AERALITH",
        "description": "Controlled lifts and wind passages connect high settlements above the cloud line.",
        "stronghold": "Aeralith Stronghold",
        "village": "Lower Sky-Dock Village",
        "color": Color("7697b8"),
        "polygon": PackedVector2Array([Vector2(500, 42), Vector2(708, 58), Vector2(752, 128), Vector2(660, 184), Vector2(520, 146), Vector2(480, 96)]),
        "center": Vector2(620, 108),
        "stronghold_position": Vector2(650, 82),
        "village_position": Vector2(574, 142),
    },
    {
        "id": "gloamfen",
        "name": "Gloamfen Frontier",
        "short_name": "Gloamfen",
        "kind": "frontier",
        "lineage": "None",
        "allegiance": "none",
        "terrain": "Mist swamp, drowned roads, and luminous reeds",
        "control_label": "UNCLAIMED FRONTIER",
        "description": "Flooded ruins and shifting causeways make this wetland valuable, dangerous, and difficult to hold.",
        "stronghold": "None",
        "village": "Reedwake Free Camp",
        "color": Color("496f62"),
        "polygon": PackedVector2Array([Vector2(212, 174), Vector2(300, 132), Vector2(354, 150), Vector2(362, 220), Vector2(296, 252), Vector2(220, 214)]),
        "center": Vector2(286, 192),
    },
    {
        "id": "ashen_scar",
        "name": "The Ashen Scar",
        "short_name": "Ashen Scar",
        "kind": "frontier",
        "lineage": "None",
        "allegiance": "none",
        "terrain": "Volcanic badlands, glass fields, and fumaroles",
        "control_label": "UNCLAIMED FRONTIER",
        "description": "A broken volcanic corridor rich in rare ore and unstable passages beneath the crust.",
        "stronghold": "None",
        "village": "Cinderwatch Free Camp",
        "color": Color("885a45"),
        "polygon": PackedVector2Array([Vector2(354, 150), Vector2(425, 145), Vector2(520, 146), Vector2(535, 205), Vector2(466, 252), Vector2(362, 220)]),
        "center": Vector2(444, 192),
    },
    {
        "id": "open_lands",
        "name": "The Open Lands",
        "short_name": "Open Lands",
        "kind": "homeland",
        "lineage": "Humans",
        "allegiance": "light",
        "terrain": "Meadows, rivers, old roads, and hill keeps",
        "control_label": "LIGHT · HUMAN",
        "description": "Broad roads and river crossings connect farms, market towns, and the central Human keep.",
        "stronghold": "Human Stronghold",
        "village": "Crossroads Outer Village",
        "color": Color("618054"),
        "polygon": PackedVector2Array([Vector2(35, 225), Vector2(92, 190), Vector2(212, 174), Vector2(220, 214), Vector2(296, 252), Vector2(258, 326), Vector2(112, 340), Vector2(35, 280)]),
        "center": Vector2(152, 259),
        "stronghold_position": Vector2(145, 236),
        "village_position": Vector2(215, 296),
    },
    {
        "id": "shattered_march",
        "name": "The Shattered March",
        "short_name": "Shattered March",
        "kind": "frontier",
        "lineage": "None",
        "allegiance": "none",
        "terrain": "Ancient ruins, fractured roads, and open scrub",
        "control_label": "UNCLAIMED FRONTIER",
        "description": "Collapsed observatories and old causeways form the main overland crossroads between Allegiances.",
        "stronghold": "None",
        "village": "Wayfarer's Free Camp",
        "color": Color("877750"),
        "polygon": PackedVector2Array([Vector2(362, 220), Vector2(466, 252), Vector2(520, 318), Vector2(450, 340), Vector2(390, 300), Vector2(296, 252)]),
        "center": Vector2(411, 278),
    },
    {
        "id": "underdeep",
        "name": "The Underdeep",
        "short_name": "Underdeep",
        "kind": "homeland",
        "lineage": "Deep Goblins",
        "allegiance": "dark",
        "terrain": "Fungal caverns, machine rails, and crystal seams",
        "control_label": "DARK · DEEP GOBLIN",
        "description": "Surface elevators descend into a fortified network of rails, pumps, and glowing fungal farms.",
        "stronghold": "Deep Goblin Stronghold",
        "village": "Trade-Tunnel Outer Village",
        "color": Color("544968"),
        "polygon": PackedVector2Array([Vector2(535, 205), Vector2(660, 184), Vector2(742, 266), Vector2(680, 344), Vector2(520, 318), Vector2(466, 252)]),
        "center": Vector2(619, 264),
        "stronghold_position": Vector2(650, 245),
        "village_position": Vector2(572, 302),
    },
    {
        "id": "sea",
        "name": "The Tidekin Sea",
        "short_name": "Tidekin Sea",
        "kind": "homeland",
        "lineage": "Tidekin",
        "allegiance": "light",
        "terrain": "Reefs, tidal terraces, mangroves, and flooded halls",
        "control_label": "LIGHT · TIDEKIN",
        "description": "Tidal gates protect an amphibious coral citadel beyond the coastal trade routes.",
        "stronghold": "Tidekin Stronghold",
        "village": "Amphibious Dock Village",
        "color": Color("267b86"),
        "polygon": PackedVector2Array([Vector2(12, 320), Vector2(112, 340), Vector2(184, 424), Vector2(78, 462), Vector2(10, 412)]),
        "center": Vector2(90, 397),
        "stronghold_position": Vector2(72, 385),
        "village_position": Vector2(132, 420),
    },
    {
        "id": "verdant_maw",
        "name": "The Verdant Maw",
        "short_name": "Verdant Maw",
        "kind": "frontier",
        "lineage": "None",
        "allegiance": "none",
        "terrain": "Dense jungle, sinkholes, giant flora, and lost temples",
        "control_label": "UNCLAIMED FRONTIER",
        "description": "An overgrown jungle frontier where routes vanish quickly and ancient structures surface beneath roots.",
        "stronghold": "None",
        "village": "Canopy Free Camp",
        "color": Color("39704a"),
        "polygon": PackedVector2Array([Vector2(258, 326), Vector2(296, 252), Vector2(390, 300), Vector2(450, 340), Vector2(400, 390), Vector2(310, 405), Vector2(184, 424)]),
        "center": Vector2(323, 346),
    },
    {
        "id": "elder_forests",
        "name": "The Elder Forests",
        "short_name": "Elder Forests",
        "kind": "homeland",
        "lineage": "Grove Centaurs",
        "allegiance": "light",
        "terrain": "Ancient canopy, root roads, and luminous clearings",
        "control_label": "LIGHT · GROVE CENTAUR",
        "description": "Living paths converge on a protected elder grove built for swift four-legged travel.",
        "stronghold": "Grove Centaur Stronghold",
        "village": "Root-Road Outer Village",
        "color": Color("43643d"),
        "polygon": PackedVector2Array([Vector2(184, 424), Vector2(310, 405), Vector2(400, 390), Vector2(438, 450), Vector2(286, 466)]),
        "center": Vector2(340, 432),
        "stronghold_position": Vector2(352, 416),
        "village_position": Vector2(408, 438),
    },
    {
        "id": "ember_desert",
        "name": "The Ember Desert",
        "short_name": "Ember Desert",
        "kind": "homeland",
        "lineage": "Sunscour",
        "allegiance": "dark",
        "terrain": "Dunes, basalt canyons, salt flats, and cistern roads",
        "control_label": "DARK · SUNSCOUR",
        "description": "Fortified water routes cross the desert toward a shaded bastion beyond the salt flats.",
        "stronghold": "Sunscour Stronghold",
        "village": "Caravan Outer Village",
        "color": Color("a06b3c"),
        "polygon": PackedVector2Array([Vector2(450, 340), Vector2(520, 318), Vector2(680, 344), Vector2(750, 410), Vector2(708, 466), Vector2(470, 454), Vector2(438, 450), Vector2(400, 390)]),
        "center": Vector2(615, 401),
        "stronghold_position": Vector2(646, 388),
        "village_position": Vector2(552, 429),
    },
]

var _dungeons: Array[Dictionary] = [
    {"id": "mireglass_catacombs", "name": "Mireglass Catacombs", "territory_id": "gloamfen", "position": Vector2(320, 214), "danger": "Veteran"},
    {"id": "cinder_vault", "name": "Cinder Vault", "territory_id": "ashen_scar", "position": Vector2(475, 190), "danger": "Elite"},
    {"id": "fallen_observatory", "name": "Fallen Observatory", "territory_id": "shattered_march", "position": Vector2(424, 302), "danger": "Group"},
    {"id": "coilroot_depths", "name": "Coilroot Depths", "territory_id": "verdant_maw", "position": Vector2(342, 397), "danger": "Group"},
]

var _routes: Array[Dictionary] = [
    {"from": "broken_mountains", "to": "ice_lands"},
    {"from": "ice_lands", "to": "sky_reaches"},
    {"from": "broken_mountains", "to": "open_lands"},
    {"from": "sky_reaches", "to": "underdeep"},
    {"from": "open_lands", "to": "gloamfen"},
    {"from": "gloamfen", "to": "ashen_scar"},
    {"from": "ashen_scar", "to": "underdeep"},
    {"from": "gloamfen", "to": "shattered_march"},
    {"from": "ashen_scar", "to": "shattered_march"},
    {"from": "open_lands", "to": "sea"},
    {"from": "open_lands", "to": "verdant_maw"},
    {"from": "shattered_march", "to": "verdant_maw"},
    {"from": "shattered_march", "to": "ember_desert"},
    {"from": "verdant_maw", "to": "elder_forests"},
    {"from": "underdeep", "to": "ember_desert"},
]

var _hero_data: Dictionary = {}
var _variant_index := 0
var _selected_id := "open_lands"
var _marker_filter := "all"
var _zoom_level := 1.0
var _pan_offset := Vector2.ZERO
var _canvas: Control


func configure_hero(hero_data: Dictionary) -> void:
    _hero_data = hero_data.duplicate(true)
    var homeland_by_lineage := {
        "tidekin": "sea",
        "human": "open_lands",
        "grove_centaur": "elder_forests",
        "aeralith": "sky_reaches",
        "crag_troll": "broken_mountains",
        "deep_goblin": "underdeep",
        "sunscour": "ember_desert",
        "rimeborn": "ice_lands",
    }
    _selected_id = str(homeland_by_lineage.get(str(_hero_data.get("lineage_id", "human")), "open_lands"))


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--map-variant="):
            var requested := argument.trim_prefix("--map-variant=").to_upper()
            for index in VARIANTS.size():
                if VARIANTS[index]["id"] == requested:
                    _variant_index = index
    _rebuild()


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    match key_event.keycode:
        KEY_LEFT:
            _cycle_variant(-1)
            get_viewport().set_input_as_handled()
        KEY_RIGHT:
            _cycle_variant(1)
            get_viewport().set_input_as_handled()
        KEY_EQUAL:
            _canvas.call("adjust_zoom", 0.12)
            get_viewport().set_input_as_handled()
        KEY_MINUS:
            _canvas.call("adjust_zoom", -0.12)
            get_viewport().set_input_as_handled()


func _rebuild() -> void:
    for child: Node in get_children():
        remove_child(child)
        child.queue_free()

    var root_column := VBoxContainer.new()
    root_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_column.add_theme_constant_override("separation", 7)
    add_child(root_column)
    root_column.add_child(_build_header())

    match str(VARIANTS[_variant_index]["id"]):
        "B":
            root_column.add_child(_build_expedition_variant())
        "C":
            root_column.add_child(_build_control_variant())
        _:
            root_column.add_child(_build_atlas_variant())
    root_column.add_child(_build_switcher())


func _build_header() -> Control:
    var header := HBoxContainer.new()
    var titles := VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(titles)
    titles.add_child(_label("WORLD MAP · THE VEILED REALMS", 22, Color("efd590")))
    titles.add_child(_label(
        "Drag to pan · scroll or use +/− to zoom · tap a Territory · diamonds mark Dungeons",
        13,
        Color("9eb1c6"),
    ))

    var zoom_out := _button("−", Color("354459"))
    zoom_out.set("variant", 2)
    zoom_out.custom_minimum_size = Vector2(42, 38)
    zoom_out.pressed.connect(_adjust_canvas_zoom.bind(-0.12))
    header.add_child(zoom_out)
    var reset := _button("RESET VIEW", Color("354459"))
    reset.set("variant", 2)
    reset.custom_minimum_size = Vector2(104, 38)
    reset.pressed.connect(_reset_canvas_view)
    header.add_child(reset)
    var zoom_in := _button("+", Color("354459"))
    zoom_in.set("variant", 2)
    zoom_in.custom_minimum_size = Vector2(42, 38)
    zoom_in.pressed.connect(_adjust_canvas_zoom.bind(0.12))
    header.add_child(zoom_in)
    return header


func _build_atlas_variant() -> Control:
    var split := HBoxContainer.new()
    split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.add_theme_constant_override("separation", 12)

    _canvas = _new_canvas(Vector2(760, 424), "A")
    split.add_child(_canvas)

    var detail := _panel()
    detail.custom_minimum_size = Vector2(318, 424)
    split.add_child(detail)
    var column := _detail_column(detail)
    column.add_child(_label("ILLUSTRATED ATLAS", 16, Color("8fc9ec")))
    _populate_region_detail(column, true)
    column.add_spacer(false)
    column.add_child(_legend())
    return split


func _build_expedition_variant() -> Control:
    var column := VBoxContainer.new()
    column.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 7)

    var tools := HBoxContainer.new()
    tools.add_child(_label("EXPEDITION NETWORK · ROUTES AND KNOWN SITES", 16, Color("efd590")))
    tools.add_spacer(false)
    for definition: Dictionary in [
        {"id": "all", "text": "ALL"},
        {"id": "strongholds", "text": "STRONGHOLDS"},
        {"id": "dungeons", "text": "DUNGEONS"},
    ]:
        var button := _button(
            "%s%s" % [definition["text"], " ✓" if _marker_filter == definition["id"] else ""],
            Color("50633f") if _marker_filter == definition["id"] else Color("354459"),
        )
        button.set("variant", 0 if _marker_filter == definition["id"] else 2)
        button.custom_minimum_size = Vector2(116, 35)
        button.pressed.connect(_set_marker_filter.bind(str(definition["id"])))
        tools.add_child(button)
    column.add_child(tools)

    _canvas = _new_canvas(Vector2(1090, 344), "B")
    column.add_child(_canvas)

    var expedition := _panel()
    expedition.custom_minimum_size.y = 64
    column.add_child(expedition)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    expedition.add_child(row)
    var territory := _territory(_selected_id)
    row.add_child(_summary_block("SELECTED", str(territory["name"]), Color("efd590")))
    row.add_child(_summary_block("TERRAIN", str(territory["terrain"]), Color("b9c8d7")))
    row.add_child(_summary_block("ACCESS", _access_for(territory), _access_color(territory)))
    row.add_child(_summary_block("KNOWN DUNGEONS", str(_dungeons_for(_selected_id).size()), Color("ef9a71")))
    return column


func _build_control_variant() -> Control:
    var split := HBoxContainer.new()
    split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.add_theme_constant_override("separation", 12)

    var roster_panel := _panel()
    roster_panel.custom_minimum_size = Vector2(375, 424)
    split.add_child(roster_panel)
    var roster := _detail_column(roster_panel)
    roster.add_child(_label("ALLEGIANCE AND ACCESS", 16, Color("efd590")))
    roster.add_child(_label(
        "%s · %s ALLEGIANCE" % [
            str(_hero_data.get("name", "Prototype Hero")).to_upper(),
            str(_hero_data.get("allegiance", "light")).to_upper(),
        ],
        13,
        Color("a8bfd4"),
    ))
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    roster.add_child(grid)
    for territory: Dictionary in _territories:
        var selected: bool = territory["id"] == _selected_id
        var button := _button(
            "%s\n%s" % [territory["short_name"], _short_access(territory)],
            Color("685b39") if selected else _territory_button_color(territory),
        )
        button.set("variant", 0 if selected else 2)
        button.custom_minimum_size = Vector2(166, 49)
        button.pressed.connect(_select_region.bind(str(territory["id"])))
        grid.add_child(button)
    var territory := _territory(_selected_id)
    roster.add_child(_label(
        "%s\n%s" % [territory["name"], _access_for(territory)],
        14,
        _access_color(territory),
    ))

    _canvas = _new_canvas(Vector2(704, 424), "C")
    split.add_child(_canvas)
    return split


func _new_canvas(minimum_size: Vector2, variant_id: String) -> Control:
    var canvas: Control = MapCanvasScript.new()
    canvas.custom_minimum_size = minimum_size
    canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
    canvas.call(
        "configure",
        _territories,
        _dungeons,
        _routes,
        variant_id,
        _selected_id,
        _marker_filter,
        _zoom_level,
        _pan_offset,
    )
    canvas.connect("territory_selected", Callable(self, "_select_region"))
    canvas.connect("view_changed", Callable(self, "_store_view"))
    return canvas


func _build_switcher() -> Control:
    var center := CenterContainer.new()
    var bar := HBoxContainer.new()
    bar.add_theme_constant_override("separation", 8)
    center.add_child(bar)
    var previous := _button("◀", Color("5a4760"))
    previous.set("variant", 2)
    previous.custom_minimum_size = Vector2(48, 36)
    previous.pressed.connect(_cycle_variant.bind(-1))
    bar.add_child(previous)
    var definition := VARIANTS[_variant_index]
    var label := _label(
        "PROTOTYPE VARIANT %s — %s" % [definition["id"], definition["name"]],
        14,
        Color("f4dfa0"),
    )
    label.custom_minimum_size = Vector2(310, 36)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    bar.add_child(label)
    var next := _button("▶", Color("5a4760"))
    next.set("variant", 2)
    next.custom_minimum_size = Vector2(48, 36)
    next.pressed.connect(_cycle_variant.bind(1))
    bar.add_child(next)
    bar.add_child(_label("←/→ switch layouts", 12, Color("8ea1b6")))
    return center


func _populate_region_detail(column: VBoxContainer, include_description: bool) -> void:
    var territory := _territory(_selected_id)
    column.add_child(_label(str(territory["name"]), 23, Color("efd590")))
    column.add_child(_label(
        "%s\n%s" % [str(territory["control_label"]), str(territory["terrain"])],
        14,
        Color("b6c7d8"),
    ))
    if include_description:
        var description := _label(str(territory["description"]), 14, Color("9fb1c3"))
        description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        column.add_child(description)
    column.add_child(_divider())
    column.add_child(_label("ACCESS", 12, Color("8398ae")))
    var access := _label(_access_for(territory), 15, _access_color(territory))
    access.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(access)
    column.add_child(_label("STRONGHOLD · %s" % territory["stronghold"], 13, Color("c9d4df")))
    column.add_child(_label("SETTLEMENT · %s" % territory["village"], 13, Color("c9d4df")))
    var dungeon_list := _dungeons_for(_selected_id)
    column.add_child(_label("KNOWN DUNGEONS · %s" % dungeon_list.size(), 12, Color("8398ae")))
    if dungeon_list.is_empty():
        column.add_child(_label("No mapped Dungeon Sites", 13, Color("7f91a4")))
    else:
        for dungeon: Dictionary in dungeon_list:
            column.add_child(_label("◆ %s · %s" % [dungeon["name"], dungeon["danger"]], 13, Color("efaa82")))


func _legend() -> Control:
    var column := VBoxContainer.new()
    column.add_child(_label("MAP LEGEND", 12, Color("8398ae")))
    column.add_child(_label("▲ Stronghold    ■ Outer Village    ◆ Dungeon", 12, Color("d9e2eb")))
    column.add_child(_label("BLUE Light    VIOLET Dark    GOLD Unclaimed", 12, Color("d9e2eb")))
    return column


func _summary_block(title: String, value: String, color: Color) -> Control:
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_child(_label(title, 10, Color("7f93a8")))
    var value_label := _label(value, 13, color)
    value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(value_label)
    return column


func _select_region(territory_id: String) -> void:
    _selected_id = territory_id
    _rebuild()


func _store_view(new_zoom: float, new_pan: Vector2) -> void:
    _zoom_level = new_zoom
    _pan_offset = new_pan


func _adjust_canvas_zoom(amount: float) -> void:
    if _canvas != null:
        _canvas.call("adjust_zoom", amount)
    else:
        _set_zoom(amount)


func _reset_canvas_view() -> void:
    if _canvas != null:
        _canvas.call("reset_view")
    else:
        _reset_view()


func _cycle_variant(direction: int) -> void:
    _variant_index = posmod(_variant_index + direction, VARIANTS.size())
    _rebuild()


func _set_marker_filter(filter_id: String) -> void:
    _marker_filter = filter_id
    _rebuild()


func _set_zoom(amount: float) -> void:
    _zoom_level = clampf(_zoom_level + amount, 0.72, 1.75)


func _reset_view() -> void:
    _zoom_level = 1.0
    _pan_offset = Vector2.ZERO


func _territory(territory_id: String) -> Dictionary:
    for territory: Dictionary in _territories:
        if territory["id"] == territory_id:
            return territory
    return _territories[5]


func _dungeons_for(territory_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for dungeon: Dictionary in _dungeons:
        if dungeon["territory_id"] == territory_id:
            result.append(dungeon)
    return result


func _access_for(territory: Dictionary) -> String:
    if territory["kind"] == "frontier":
        return "OPEN FRONTIER · NO LINEAGE CLAIM"
    if territory["allegiance"] == str(_hero_data.get("allegiance", "light")):
        return "STRONGHOLD ENTRY ALLOWED"
    return "OUTER VILLAGE OPEN · STRONGHOLD DENIED"


func _short_access(territory: Dictionary) -> String:
    if territory["kind"] == "frontier":
        return "UNCLAIMED"
    if territory["allegiance"] == str(_hero_data.get("allegiance", "light")):
        return "ALLIED · OPEN"
    return "VILLAGE ONLY"


func _access_color(territory: Dictionary) -> Color:
    if territory["kind"] == "frontier":
        return Color("e2bf6b")
    if territory["allegiance"] == str(_hero_data.get("allegiance", "light")):
        return Color("79d59e")
    return Color("ef8c89")


func _territory_button_color(territory: Dictionary) -> Color:
    match str(territory["allegiance"]):
        "light":
            return Color("34556d")
        "dark":
            return Color("5c405c")
        _:
            return Color("665b3c")


func _detail_column(panel: PanelContainer) -> VBoxContainer:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 7)
    margin.add_child(column)
    return column


func _panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _style(Color("111d2d"), Color("42546b"), 1))
    return panel


func _divider() -> HSeparator:
    var divider := HSeparator.new()
    divider.add_theme_constant_override("separation", 5)
    return divider


func _label(text: String, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    return label


func _button(text: String, color: Color) -> Button:
    var button := ChronicleButtonScript.new() as Button
    button.text = text
    button.set("touch_safe", false)
    button.call("adopt_color_hint", color)
    return button


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(5)
    style.content_margin_left = 8.0
    style.content_margin_right = 8.0
    style.content_margin_top = 5.0
    style.content_margin_bottom = 5.0
    return style
