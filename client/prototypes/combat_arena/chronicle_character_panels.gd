# PROTOTYPE — Chronicle-styled character, inventory, progression, and world UI.
class_name PrototypeChronicleCharacterPanels
extends Control

const ProfileStateScript := preload("res://prototypes/combat_arena/hero_profile_state.gd")
const WorldMapScript := preload("res://prototypes/combat_arena/world_map_prototype.gd")
const ItemSlotScript := preload("res://prototypes/combat_arena/chronicle_item_slot.gd")
const TalentTreeScript := preload("res://prototypes/combat_arena/chronicle_talent_tree.gd")
const ChronicleButtonScript := preload("res://scripts/chronicle_button.gd")

const DISPLAY_FONT := preload("res://assets/fonts/alegreya/AlegreyaSC-Medium.ttf")
const BODY_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Regular.ttf")
const BODY_MEDIUM_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Medium.ttf")

const INK_NAVY := Color("101b2c")
const NIGHT_BLUE := Color("17283d")
const PARCHMENT := Color("f3e5be")
const AGED_PAPER := Color("d6bd84")
const ANTIQUE_BRASS := Color("c79b48")
const WARM_IVORY := Color("fff5d6")
const FOREST_TEAL := Color("2d756e")
const CRYSTAL_CYAN := Color("72d6e5")
const QUEST_GOLD := Color("f2c45f")
const EMBER_RED := Color("b85645")
const MUTED_STONE := Color("78808a")

const TAB_DEFINITIONS: Array[Dictionary] = [
    {"id": "overview", "text": "OVERVIEW", "key": "O"},
    {"id": "gear", "text": "GEAR & POUCH", "key": "B / C"},
    {"id": "disciplines", "text": "DISCIPLINES", "key": "L"},
    {"id": "talents", "text": "TALENT TREE", "key": "K"},
    {"id": "world_map", "text": "WORLD MAP", "key": "M"},
    {"id": "hints", "text": "HINTS", "key": "I"},
]

const EQUIPMENT_POSITIONS := {
    "head": Vector2(162.0, 16.0),
    "shoulders": Vector2(12.0, 82.0),
    "neck": Vector2(312.0, 82.0),
    "chest": Vector2(12.0, 151.0),
    "ring": Vector2(312.0, 151.0),
    "hands": Vector2(12.0, 220.0),
    "cape": Vector2(312.0, 220.0),
    "main_hand": Vector2(12.0, 289.0),
    "off_hand": Vector2(312.0, 289.0),
    "legs": Vector2(87.0, 372.0),
    "feet": Vector2(162.0, 372.0),
    "relic": Vector2(237.0, 372.0),
}

const STAT_PRESENTATION := {
    "damage": {"icon": "⚔", "name": "DAMAGE", "suffix": ""},
    "armor": {"icon": "⬟", "name": "ARMOR", "suffix": ""},
    "move_speed": {"icon": "➤", "name": "MOVE SPEED", "suffix": "%"},
    "attack_speed": {"icon": "◌", "name": "ATTACK SPEED", "suffix": "×"},
    "critical_chance": {"icon": "✦", "name": "CRITICAL", "suffix": "%"},
    "guard": {"icon": "◇", "name": "GUARD", "suffix": ""},
    "focus": {"icon": "◎", "name": "FOCUS", "suffix": ""},
    "willpower": {"icon": "✧", "name": "WILLPOWER", "suffix": ""},
}

const DISCIPLINE_ICONS := {
    "attack": "⚔", "strength": "◆", "defense": "⬟", "agility": "➤",
    "stamina": "♥", "focus": "◎", "willpower": "✧", "arcana": "✦",
    "survival": "♨", "gathering": "♣", "crafting": "⚒", "exploration": "⌖",
}

var _profile: PrototypeHeroProfileState
var _hero_data: Dictionary = {}
var _hero_runtime: Node
var _backdrop: ColorRect
var _window_content: VBoxContainer
var _header_summary: Label
var _tab_buttons: Dictionary = {}
var _current_panel := "overview"
var _selected_pouch_index := -1
var _last_message := "The Chronicle records every Hero-specific choice immediately."


func configure_hero(hero_data: Dictionary, hero_runtime: Node = null) -> void:
    _hero_data = hero_data.duplicate(true)
    _hero_runtime = hero_runtime
    var profile_key := str(_hero_data.get("name", "prototype_hero")).to_lower()
    var profiles := get_tree().get_meta("prototype_hero_profiles", {}) as Dictionary
    if profiles.has(profile_key):
        _profile = profiles[profile_key] as PrototypeHeroProfileState
    else:
        profiles[profile_key] = _profile
        get_tree().set_meta("prototype_hero_profiles", profiles)
    if is_node_ready():
        _refresh_header()


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _profile = ProfileStateScript.new() as PrototypeHeroProfileState
    _build_quick_buttons()
    _build_window()


func _exit_tree() -> void:
    if get_tree().paused:
        get_tree().paused = false


func open_panel(panel_id: String) -> void:
    _current_panel = _normalize_panel_id(panel_id)
    _backdrop.visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    get_tree().paused = true
    _rebuild_panel()


func close_panel() -> void:
    _backdrop.visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    get_tree().paused = false


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    match key_event.keycode:
        KEY_O:
            _toggle_panel("overview")
        KEY_B, KEY_C:
            _toggle_panel("gear")
        KEY_L:
            _toggle_panel("disciplines")
        KEY_K:
            _toggle_panel("talents")
        KEY_M:
            _toggle_panel("world_map")
        KEY_I:
            _toggle_panel("hints")
        KEY_ESCAPE:
            if _backdrop.visible:
                close_panel()


func _toggle_panel(panel_id: String) -> void:
    if _backdrop.visible and _current_panel == panel_id:
        close_panel()
    else:
        open_panel(panel_id)


func _normalize_panel_id(panel_id: String) -> String:
    if panel_id in ["pouch", "equipment"]:
        return "gear"
    if panel_id in ["levels", "disciplines"]:
        return "disciplines"
    if panel_id in ["talent_tree", "talents"]:
        return "talents"
    return panel_id if panel_id in ["overview", "gear", "world_map", "hints"] else "overview"


func _build_quick_buttons() -> void:
    var quick_bar := HBoxContainer.new()
    quick_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    quick_bar.position = Vector2(-680.0, 238.0)
    quick_bar.size = Vector2(660.0, 40.0)
    quick_bar.add_theme_constant_override("separation", 6)
    quick_bar.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(quick_bar)

    for definition: Dictionary in TAB_DEFINITIONS:
        var button := _button("%s · %s" % [definition["key"], definition["text"]], NIGHT_BLUE)
        button.custom_minimum_size = Vector2(104.0, 40.0)
        button.add_theme_font_size_override("font_size", 12)
        button.pressed.connect(open_panel.bind(str(definition["id"])))
        quick_bar.add_child(button)


func _build_window() -> void:
    _backdrop = ColorRect.new()
    _backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _backdrop.color = Color(0.015, 0.025, 0.045, 0.93)
    _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    _backdrop.visible = false
    add_child(_backdrop)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _backdrop.add_child(center)

    var window := PanelContainer.new()
    window.custom_minimum_size = Vector2(1240.0, 700.0)
    window.add_theme_stylebox_override("panel", _style(INK_NAVY, ANTIQUE_BRASS, 2, 10, 0.0))
    center.add_child(window)

    var frame := MarginContainer.new()
    frame.add_theme_constant_override("margin_left", 18)
    frame.add_theme_constant_override("margin_top", 12)
    frame.add_theme_constant_override("margin_right", 18)
    frame.add_theme_constant_override("margin_bottom", 14)
    window.add_child(frame)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    frame.add_child(column)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 44.0
    header.add_theme_constant_override("separation", 12)
    column.add_child(header)
    var title := _label("THE ENCHANTED CHRONICLE", 28, QUEST_GOLD, true)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(title)
    _header_summary = _label("", 14, WARM_IVORY)
    _header_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(_header_summary)
    var close := _button("CLOSE · ESC", Color("604049"))
    close.set("variant", 3)
    close.custom_minimum_size = Vector2(132.0, 40.0)
    close.pressed.connect(close_panel)
    header.add_child(close)

    var tab_frame := PanelContainer.new()
    tab_frame.add_theme_stylebox_override("panel", _style(NIGHT_BLUE, ANTIQUE_BRASS.darkened(0.24), 1, 7, 3.0))
    column.add_child(tab_frame)
    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 4)
    tab_frame.add_child(tabs)
    for definition: Dictionary in TAB_DEFINITIONS:
        var tab := _button("%s\n[%s]" % [definition["text"], definition["key"]], NIGHT_BLUE.lightened(0.04))
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.custom_minimum_size.y = 47.0
        tab.add_theme_font_size_override("font_size", 12)
        tab.pressed.connect(open_panel.bind(str(definition["id"])))
        tabs.add_child(tab)
        _tab_buttons[str(definition["id"])] = tab

    _window_content = VBoxContainer.new()
    _window_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _window_content.add_theme_constant_override("separation", 8)
    column.add_child(_window_content)


func _rebuild_panel() -> void:
    for child: Node in _window_content.get_children():
        _window_content.remove_child(child)
        child.queue_free()
    _refresh_header()
    _refresh_tabs()
    match _current_panel:
        "gear":
            _build_gear_panel()
        "disciplines":
            _build_disciplines_panel()
        "talents":
            _build_talents_panel()
        "world_map":
            _build_world_map_panel()
        "hints":
            _build_hints_panel()
        _:
            _build_overview_panel()


func _refresh_header() -> void:
    if _header_summary == null or _profile == null:
        return
    _header_summary.text = "%s  ·  OVERALL %s  ·  TOTAL %s  ·  %s POINTS     " % [
        str(_hero_data.get("name", "Prototype Hero")).to_upper(),
        _profile.overall_level(),
        _profile.total_level(),
        _profile.unspent_talent_points(),
    ]


func _refresh_tabs() -> void:
    for panel_id in _tab_buttons:
        var button := _tab_buttons[panel_id] as Button
        var active := str(panel_id) == _current_panel
        button.set("variant", 0 if active else 1)


func _build_overview_panel() -> void:
    _window_content.add_child(_section_title(
        "CHARACTER OVERVIEW",
        "Live combat resources, progression, equipment bonuses, and field-readiness at a glance.",
    ))
    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 12)
    _window_content.add_child(columns)

    var identity := _paper_panel(270.0)
    columns.add_child(identity)
    var identity_column := _panel_column(identity, 12)
    var crest := _label("♙", 82, FOREST_TEAL, true)
    crest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crest.custom_minimum_size.y = 106.0
    identity_column.add_child(crest)
    var hero_name := _label(str(_hero_data.get("name", "Prototype Hero")).to_upper(), 28, INK_NAVY, true)
    hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    identity_column.add_child(hero_name)
    var lineage := _label(str(_hero_data.get("lineage_name", "Human")), 18, FOREST_TEAL, true)
    lineage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    identity_column.add_child(lineage)
    var allegiance := str(_hero_data.get("allegiance", "unaligned")).to_upper()
    var allegiance_badge := _label("✦  %s ALLEGIANCE  ✦" % allegiance, 14, Color("744f21"), true)
    allegiance_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    identity_column.add_child(allegiance_badge)
    identity_column.add_child(_rule(INK_NAVY, 0.28))
    identity_column.add_child(_value_pair("OVERALL LEVEL", str(_profile.overall_level()), INK_NAVY))
    identity_column.add_child(_value_pair("TOTAL LEVEL", str(_profile.total_level()), INK_NAVY))
    identity_column.add_child(_value_pair("TALENT POINTS", str(_profile.unspent_talent_points()), Color("805d18")))
    var open_gear := _button("OPEN GEAR & POUCH", FOREST_TEAL.darkened(0.1))
    open_gear.set("variant", 0)
    open_gear.pressed.connect(open_panel.bind("gear"))
    identity_column.add_child(open_gear)

    var vitals := _night_panel(430.0)
    columns.add_child(vitals)
    var vitals_column := _panel_column(vitals, 11)
    vitals_column.add_child(_panel_heading("VITAL ESSENCE", "Current battlefield condition"))
    vitals_column.add_child(_resource_bar("♥", "HEALTH", _runtime_value("health", 100.0), 100.0, EMBER_RED))
    vitals_column.add_child(_resource_bar("✦", "MANA", _runtime_value("mana", 100.0), 100.0, Color("3b79b8")))
    vitals_column.add_child(_resource_bar("➤", "STAMINA", _runtime_value("stamina", 100.0), 100.0, FOREST_TEAL))
    vitals_column.add_child(_rule(WARM_IVORY, 0.16))
    var level := int(_hero_runtime.get("level")) if _hero_runtime != null else _profile.overall_level()
    var general_exp := float(_hero_runtime.get("general_exp")) if _hero_runtime != null else 350.0
    vitals_column.add_child(_resource_bar("✧", "ADVENTURE XP · LEVEL %s" % level, general_exp, 1000.0, QUEST_GOLD))
    vitals_column.add_child(_panel_heading("EQUIPMENT LOADOUT", "%s of %s slots filled" % [
        _equipped_count(_profile.equipment()),
        PrototypeHeroProfileState.EQUIPMENT_SLOTS.size(),
    ]))
    vitals_column.add_child(_equipment_summary_grid())

    var stats_panel := _paper_panel(468.0)
    stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    columns.add_child(stats_panel)
    var stats_column := _panel_column(stats_panel, 9)
    stats_column.add_child(_paper_heading("FIELD ATTRIBUTES", "Icons show the combat role of each derived value."))
    var stats_grid := GridContainer.new()
    stats_grid.columns = 2
    stats_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stats_grid.add_theme_constant_override("h_separation", 8)
    stats_grid.add_theme_constant_override("v_separation", 8)
    stats_column.add_child(stats_grid)
    var stats := _profile.derived_stats()
    for stat_id: String in ["damage", "armor", "move_speed", "attack_speed", "critical_chance", "guard", "focus", "willpower"]:
        stats_grid.add_child(_stat_card(stat_id, stats[stat_id]))


func _build_gear_panel() -> void:
    _window_content.add_child(_section_title(
        "GEAR & ITEM POUCH",
        "Drag a wearable item onto its matching slot. A displaced item returns to the same pouch cell.",
    ))
    var split := HBoxContainer.new()
    split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.add_theme_constant_override("separation", 10)
    _window_content.add_child(split)

    var pouch_panel := _paper_panel(416.0)
    split.add_child(pouch_panel)
    var pouch_column := _panel_column(pouch_panel, 7)
    pouch_column.add_child(_paper_heading(
        "ITEM POUCH",
        "%s / %s slots used · Select an item to compare" % [_profile.pouch_used_slots(), PrototypeHeroProfileState.POUCH_SIZE],
    ))
    var pouch_grid := GridContainer.new()
    pouch_grid.columns = 6
    pouch_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    pouch_grid.add_theme_constant_override("h_separation", 5)
    pouch_grid.add_theme_constant_override("v_separation", 5)
    pouch_column.add_child(pouch_grid)
    var pouch := _profile.pouch()
    for index in pouch.size():
        var slot := ItemSlotScript.new() as ChronicleItemSlot
        slot.custom_minimum_size = Vector2(59.0, 70.0)
        slot.focus_mode = Control.FOCUS_ALL
        slot.add_theme_font_override("font", BODY_MEDIUM_FONT)
        slot.add_theme_font_size_override("font_size", 11)
        slot.add_theme_color_override("font_color", INK_NAVY)
        var selected := index == _selected_pouch_index
        slot.add_theme_stylebox_override("normal", _style(
            Color("ead8aa") if selected else Color("e1cca0"),
            CRYSTAL_CYAN.darkened(0.22) if selected else Color("a77c39"),
            3 if selected else 1,
            5,
            4.0,
        ))
        slot.add_theme_stylebox_override("hover", _style(PARCHMENT, CRYSTAL_CYAN, 2, 5, 4.0))
        slot.add_theme_stylebox_override("pressed", _style(AGED_PAPER, QUEST_GOLD.darkened(0.15), 2, 5, 4.0))
        slot.add_theme_stylebox_override("focus", _style(PARCHMENT, CRYSTAL_CYAN, 3, 5, 4.0))
        if pouch[index] == null:
            slot.text = "·\nEMPTY"
            slot.disabled = true
            slot.add_theme_color_override("font_disabled_color", Color("887b64"))
        else:
            var entry := pouch[index] as Dictionary
            var item_definition := _profile.item(str(entry["item_id"]))
            var quantity := int(entry["quantity"])
            slot.text = "%s\n%s" % [
                str(item_definition.get("icon", "◇")),
                "×%s" % quantity if quantity > 1 else _short_name(str(item_definition["name"])),
            ]
            slot.tooltip_text = "%s\n%s" % [item_definition["name"], item_definition["description"]]
            slot.pressed.connect(_select_pouch_item.bind(index))
            var equipment_slot := str(item_definition.get("slot", ""))
            if not equipment_slot.is_empty():
                var validation := _profile.can_equip_from_pouch(index, equipment_slot)
                slot.configure_drag_source({
                    "kind": "pouch_item",
                    "pouch_index": index,
                    "equipment_slot": equipment_slot,
                    "can_equip": bool(validation["ok"]),
                    "preview_text": "%s\n%s" % [item_definition.get("icon", "◇"), item_definition["name"]],
                })
        pouch_grid.add_child(slot)
        slot.remember_resting_state()

    var gear_panel := _paper_panel(444.0)
    split.add_child(gear_panel)
    var gear_column := _panel_column(gear_panel, 5)
    gear_column.add_child(_paper_heading("GEAR OVERVIEW", "Drop targets glow cyan when compatible"))
    var gear_canvas := Control.new()
    gear_canvas.custom_minimum_size = Vector2(424.0, 449.0)
    gear_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
    gear_column.add_child(gear_canvas)
    _populate_equipment_canvas(gear_canvas)

    var compare_panel := _night_panel(310.0)
    compare_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    split.add_child(compare_panel)
    _build_item_compare(_panel_column(compare_panel, 8))


func _populate_equipment_canvas(canvas: Control) -> void:
    var silhouette := PanelContainer.new()
    silhouette.position = Vector2(138.0, 103.0)
    silhouette.size = Vector2(148.0, 252.0)
    silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    silhouette.add_theme_stylebox_override("panel", _style(NIGHT_BLUE, ANTIQUE_BRASS, 2, 72, 8.0))
    canvas.add_child(silhouette)
    var hero_block := VBoxContainer.new()
    hero_block.alignment = BoxContainer.ALIGNMENT_CENTER
    silhouette.add_child(hero_block)
    var hero_mark := _label("♙", 76, CRYSTAL_CYAN, true)
    hero_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hero_block.add_child(hero_mark)
    var hero_name := _label(str(_hero_data.get("name", "HERO")).to_upper(), 17, WARM_IVORY, true)
    hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hero_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hero_block.add_child(hero_name)
    var lineage := _label(str(_hero_data.get("lineage_name", "Human")).to_upper(), 12, AGED_PAPER)
    lineage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hero_block.add_child(lineage)

    var equipment := _profile.equipment()
    for definition: Dictionary in PrototypeHeroProfileState.EQUIPMENT_SLOTS:
        var slot_id := str(definition["id"])
        var item_id := str(equipment.get(slot_id, ""))
        var slot := ItemSlotScript.new() as ChronicleItemSlot
        slot.position = EQUIPMENT_POSITIONS[slot_id]
        slot.size = Vector2(100.0 if slot_id not in ["legs", "feet", "relic"] else 72.0, 62.0)
        slot.focus_mode = Control.FOCUS_ALL
        slot.add_theme_font_override("font", BODY_MEDIUM_FONT)
        slot.add_theme_font_size_override("font_size", 10)
        slot.add_theme_color_override("font_color", WARM_IVORY)
        slot.add_theme_stylebox_override("normal", _style(NIGHT_BLUE, ANTIQUE_BRASS.darkened(0.15), 1, 6, 4.0))
        slot.add_theme_stylebox_override("hover", _style(NIGHT_BLUE.lightened(0.08), CRYSTAL_CYAN, 2, 6, 4.0))
        slot.add_theme_stylebox_override("pressed", _style(FOREST_TEAL.darkened(0.15), QUEST_GOLD, 2, 6, 4.0))
        slot.add_theme_stylebox_override("focus", _style(NIGHT_BLUE, CRYSTAL_CYAN, 3, 6, 4.0))
        slot.text = "%s\n— EMPTY —" % str(definition["name"]).to_upper()
        if not item_id.is_empty():
            var item_definition := _profile.item(item_id)
            slot.text = "%s\n%s  %s" % [
                str(definition["name"]).to_upper(),
                item_definition.get("icon", "◇"),
                _short_name(str(item_definition["name"])),
            ]
            slot.tooltip_text = "%s\nClick to return this item to the pouch." % item_definition["description"]
            slot.pressed.connect(_unequip_item.bind(slot_id))
        slot.configure_drop_target(slot_id)
        slot.item_dropped.connect(_on_item_dropped)
        canvas.add_child(slot)
        slot.remember_resting_state()


func _build_item_compare(column: VBoxContainer) -> void:
    column.add_child(_panel_heading("ITEM INSPECTION", "Equipment preview and stat changes"))
    var preview := _profile.preview_equip_stats(_selected_pouch_index)
    if preview.is_empty():
        var prompt := _label(
            "SELECT AN ITEM\n\nClick any pouch item to inspect it. Drag wearable items directly onto the illustrated gear overview.",
            17,
            AGED_PAPER,
            true,
        )
        prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
        column.add_child(prompt)
        column.add_child(_message_label())
        return

    var item := preview["item"] as Dictionary
    var item_title := _label("%s  %s" % [item.get("icon", "◇"), item["name"]], 22, QUEST_GOLD, true)
    item_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(item_title)
    var description := _label(str(item["description"]), 14, WARM_IVORY)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(description)
    var slot_id := str(preview.get("slot", ""))
    column.add_child(_value_pair("SLOT", _equipment_slot_name(slot_id) if not slot_id.is_empty() else "POUCH ITEM", WARM_IVORY))

    var stats := item.get("stats", {}) as Dictionary
    if stats.is_empty():
        column.add_child(_label("No direct attribute bonuses.", 14, MUTED_STONE))
    else:
        for stat_id in stats:
            column.add_child(_value_pair(str(stat_id).replace("_", " ").to_upper(), _signed_value(stats[stat_id]), CRYSTAL_CYAN))

    if not slot_id.is_empty():
        column.add_child(_rule(WARM_IVORY, 0.18))
        column.add_child(_label("EQUIP COMPARISON", 16, AGED_PAPER, true))
        var before := preview["before"] as Dictionary
        var after := preview["after"] as Dictionary
        for stat_id: String in ["damage", "armor", "move_speed", "attack_speed", "guard"]:
            var delta := float(after[stat_id]) - float(before[stat_id])
            if not is_zero_approx(delta):
                column.add_child(_compare_row(stat_id, before[stat_id], after[stat_id]))
        var equip := _button("EQUIP TO %s" % _equipment_slot_name(slot_id).to_upper(), FOREST_TEAL.darkened(0.08))
        equip.set("variant", 0)
        equip.pressed.connect(_equip_selected_item)
        column.add_child(equip)
    column.add_child(_message_label())


func _select_pouch_item(index: int) -> void:
    _selected_pouch_index = index
    var pouch := _profile.pouch()
    if index >= 0 and index < pouch.size() and pouch[index] != null:
        var entry := pouch[index] as Dictionary
        _last_message = "Selected %s." % _profile.item(str(entry["item_id"]))["name"]
    _rebuild_panel()


func _equip_selected_item() -> void:
    if _selected_pouch_index < 0:
        return
    var result := _profile.equip_from_pouch(_selected_pouch_index)
    _last_message = str(result["message"])
    if bool(result["ok"]):
        _selected_pouch_index = -1
    _rebuild_panel()


func _on_item_dropped(pouch_index: int, equipment_slot: String) -> void:
    var result := _profile.equip_from_pouch_to_slot(pouch_index, equipment_slot)
    _last_message = str(result["message"])
    if bool(result["ok"]):
        _selected_pouch_index = -1
    _rebuild_panel()


func _unequip_item(slot_id: String) -> void:
    var result := _profile.unequip(slot_id)
    _last_message = str(result["message"])
    _rebuild_panel()


func _build_disciplines_panel() -> void:
    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 10)
    _window_content.add_child(top)
    var heading := _section_title(
        "DISCIPLINES · LEVEL 1–99",
        "Twelve paths shape the hero. Overall Level is the average of every Discipline.",
    )
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(heading)
    for pair: Array in [
        ["OVERALL", _profile.overall_level()],
        ["TOTAL", _profile.total_level()],
        ["POINTS", _profile.unspent_talent_points()],
    ]:
        top.add_child(_summary_seal(str(pair[0]), str(pair[1])))

    var families := HBoxContainer.new()
    families.size_flags_vertical = Control.SIZE_EXPAND_FILL
    families.add_theme_constant_override("separation", 12)
    _window_content.add_child(families)
    for family: String in ["Martial", "Mystic", "World"]:
        var family_panel := _paper_panel(0.0)
        family_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        families.add_child(family_panel)
        var family_column := _panel_column(family_panel, 7)
        family_column.add_child(_paper_heading("%s DISCIPLINES" % family.to_upper(), _family_motto(family)))
        for discipline: Dictionary in PrototypeHeroProfileState.DISCIPLINES:
            if str(discipline["family"]) != family:
                continue
            family_column.add_child(_discipline_row(discipline, family))


func _discipline_row(discipline: Dictionary, family: String) -> PanelContainer:
    var discipline_id := str(discipline["id"])
    var level := _profile.discipline_level(discipline_id)
    var xp := _profile.discipline_xp(discipline_id)
    var lower := _profile.xp_threshold(level)
    var next := _profile.xp_threshold(mini(PrototypeHeroProfileState.MAX_DISCIPLINE_LEVEL, level + 1))
    var progress := float(xp - lower) / maxf(1.0, float(next - lower)) * 100.0
    var panel := PanelContainer.new()
    panel.tooltip_text = str(discipline["description"])
    panel.add_theme_stylebox_override("panel", _style(_family_color(family), _family_accent(family), 1, 7, 7.0))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    panel.add_child(row)
    var icon := _label(str(DISCIPLINE_ICONS.get(discipline_id, "◇")), 25, WARM_IVORY, true)
    icon.custom_minimum_size.x = 34.0
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(icon)
    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    details.add_theme_constant_override("separation", 2)
    row.add_child(details)
    var title_row := HBoxContainer.new()
    details.add_child(title_row)
    var name := _label(str(discipline["name"]).to_upper(), 15, WARM_IVORY, true)
    name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_child(name)
    title_row.add_child(_label("LV %s" % level, 17, QUEST_GOLD, true))
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 8.0
    bar.show_percentage = false
    bar.value = progress
    bar.add_theme_stylebox_override("background", _style(Color(0.04, 0.07, 0.10, 0.65), Color.TRANSPARENT, 0, 4, 0.0))
    bar.add_theme_stylebox_override("fill", _style(_family_accent(family), Color.TRANSPARENT, 0, 4, 0.0))
    details.add_child(bar)
    var xp_label := _label("%s / %s XP" % [xp, next], 11, AGED_PAPER)
    details.add_child(xp_label)
    return panel


func _build_talents_panel() -> void:
    var heading_row := HBoxContainer.new()
    heading_row.add_theme_constant_override("separation", 10)
    _window_content.add_child(heading_row)
    var heading := _section_title(
        "SWORD MASTERY · TALENT TREE",
        "Follow a branch from the shared mastery root. Gold nodes are available; teal nodes are unlocked.",
    )
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading_row.add_child(heading)
    heading_row.add_child(_summary_seal("AVAILABLE", str(_profile.unspent_talent_points())))
    heading_row.add_child(_summary_seal("SPENT", str(_profile.spent_talent_points())))

    var tree_center := CenterContainer.new()
    tree_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _window_content.add_child(tree_center)
    var tree := TalentTreeScript.new() as ChronicleTalentTree
    tree.configure(_profile)
    tree.purchase_requested.connect(_purchase_talent)
    tree_center.add_child(tree)
    _window_content.add_child(_message_label())


func _purchase_talent(talent_id: String) -> void:
    var result := _profile.purchase_talent(talent_id)
    _last_message = str(result["message"])
    _rebuild_panel()


func _build_world_map_panel() -> void:
    var world_map: Control = WorldMapScript.new()
    world_map.call("configure_hero", _hero_data)
    _window_content.add_child(world_map)


func _build_hints_panel() -> void:
    _window_content.add_child(_section_title(
        "CHRONICLE FIELD NOTES",
        "Keyboard shortcuts, interaction rules, and the current prototype loop.",
    ))
    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 12)
    _window_content.add_child(columns)
    var controls := VBoxContainer.new()
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_theme_constant_override("separation", 9)
    columns.add_child(controls)
    controls.add_child(_hint_block("MOVEMENT", "A / D or Left / Right to move · Space or Up to jump. Near a ladder or rope, use W / S, Up / Down, or the touch stick to climb; Space jumps away."))
    controls.add_child(_hint_block("COMBAT", "1 attacks · 2 or Shift holds stance · 3–5 use weapon abilities · 6 uses recovery · Tab cycles weapon loadouts."))
    controls.add_child(_hint_block("CHARACTER", "O opens Overview · B or C opens Gear & Pouch · L opens Disciplines · K opens the connected Talent Tree."))
    var world := VBoxContainer.new()
    world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    world.add_theme_constant_override("separation", 9)
    columns.add_child(world)
    world.add_child(_hint_block("ITEMS", "Drag wearable pouch items onto compatible equipment slots. Click equipped items to return them to the first free pouch slot."))
    world.add_child(_hint_block("WORLD", "M opens the Chronicle map. Walk through glowing portals to travel; approach Mira in the Moonlit Market and press E to trade."))
    world.add_child(_hint_block("RECOVERY", "Health, Mana, and Stamina shown in Overview reflect the live hero. Press R after victory or defeat to restart the encounter."))


func _equipment_summary_grid() -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 7)
    grid.add_theme_constant_override("v_separation", 6)
    var equipment := _profile.equipment()
    for slot_id: String in ["main_hand", "off_hand", "head", "chest", "cape", "feet"]:
        var item_id := str(equipment.get(slot_id, ""))
        var label_text := "%s · EMPTY" % _equipment_slot_name(slot_id).to_upper()
        if not item_id.is_empty():
            var item := _profile.item(item_id)
            label_text = "%s  %s" % [item.get("icon", "◇"), _short_name(str(item["name"]))]
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _style(Color(0.05, 0.10, 0.16, 0.72), Color("385268"), 1, 5, 5.0))
        var label := _label(label_text, 12, WARM_IVORY)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        card.add_child(label)
        grid.add_child(card)
    return grid


func _resource_bar(icon: String, title: String, value: float, maximum: float, fill: Color) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_theme_constant_override("separation", 3)
    var header := HBoxContainer.new()
    block.add_child(header)
    var name := _label("%s  %s" % [icon, title], 15, WARM_IVORY, true)
    name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(name)
    header.add_child(_label("%s / %s" % [roundi(value), roundi(maximum)], 14, WARM_IVORY))
    var bar := ProgressBar.new()
    bar.custom_minimum_size.y = 19.0
    bar.max_value = maximum
    bar.value = value
    bar.show_percentage = false
    bar.add_theme_stylebox_override("background", _style(Color("09111c"), Color("46566a"), 1, 7, 1.0))
    bar.add_theme_stylebox_override("fill", _style(fill, fill.lightened(0.18), 1, 7, 1.0))
    block.add_child(bar)
    return block


func _stat_card(stat_id: String, value: Variant) -> PanelContainer:
    var definition := STAT_PRESENTATION[stat_id] as Dictionary
    var card := PanelContainer.new()
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.add_theme_stylebox_override("panel", _style(Color("e0ca98"), Color("a77c39"), 1, 7, 7.0))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    card.add_child(row)
    var icon := _label(str(definition["icon"]), 27, FOREST_TEAL, true)
    icon.custom_minimum_size.x = 35.0
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    row.add_child(icon)
    var name := _label(str(definition["name"]), 13, INK_NAVY, true)
    name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(name)
    var formatted := "%.2f%s" % [float(value), definition["suffix"]] if stat_id == "attack_speed" else "%s%s" % [roundi(float(value)), definition["suffix"]]
    var value_label := _label(formatted, 23, Color("74531b"), true)
    value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(value_label)
    return card


func _compare_row(stat_id: String, before: Variant, after: Variant) -> HBoxContainer:
    var row := HBoxContainer.new()
    var definition := STAT_PRESENTATION[stat_id] as Dictionary
    var label := _label("%s  %s" % [definition["icon"], definition["name"]], 13, WARM_IVORY)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(label)
    var improved := float(after) > float(before)
    var value_color := CRYSTAL_CYAN if improved else EMBER_RED
    row.add_child(_label("%s  →  %s" % [_format_stat(stat_id, before), _format_stat(stat_id, after)], 14, value_color, true))
    return row


func _summary_seal(title: String, value: String) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(105.0, 56.0)
    panel.add_theme_stylebox_override("panel", _style(NIGHT_BLUE, ANTIQUE_BRASS, 2, 8, 5.0))
    var column := VBoxContainer.new()
    column.alignment = BoxContainer.ALIGNMENT_CENTER
    panel.add_child(column)
    var value_label := _label(value, 24, QUEST_GOLD, true)
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(value_label)
    var title_label := _label(title, 10, WARM_IVORY, true)
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title_label)
    return panel


func _hint_block(title: String, body: String) -> PanelContainer:
    var panel := _night_panel(0.0)
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var column := _panel_column(panel, 7)
    column.add_child(_label(title, 19, QUEST_GOLD, true))
    var description := _label(body, 15, WARM_IVORY)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(description)
    return panel


func _section_title(title: String, subtitle: String) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_theme_constant_override("separation", 0)
    block.add_child(_label(title, 23, QUEST_GOLD, true))
    block.add_child(_label(subtitle, 13, AGED_PAPER))
    return block


func _panel_heading(title: String, subtitle: String) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_theme_constant_override("separation", 1)
    block.add_child(_label(title, 21, QUEST_GOLD, true))
    var detail := _label(subtitle, 12, AGED_PAPER)
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    block.add_child(detail)
    return block


func _paper_heading(title: String, subtitle: String) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_theme_constant_override("separation", 1)
    block.add_child(_label(title, 21, INK_NAVY, true))
    var detail := _label(subtitle, 12, Color("665c4b"))
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    block.add_child(detail)
    return block


func _paper_panel(minimum_width: float) -> PanelContainer:
    var panel := PanelContainer.new()
    if minimum_width > 0.0:
        panel.custom_minimum_size.x = minimum_width
    panel.add_theme_stylebox_override("panel", _style(PARCHMENT, ANTIQUE_BRASS, 2, 8, 0.0))
    return panel


func _night_panel(minimum_width: float) -> PanelContainer:
    var panel := PanelContainer.new()
    if minimum_width > 0.0:
        panel.custom_minimum_size.x = minimum_width
    panel.add_theme_stylebox_override("panel", _style(NIGHT_BLUE, ANTIQUE_BRASS.darkened(0.08), 2, 8, 0.0))
    return panel


func _panel_column(panel: PanelContainer, separation: int) -> VBoxContainer:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", separation)
    margin.add_child(column)
    return column


func _value_pair(title: String, value: String, color: Color) -> HBoxContainer:
    var row := HBoxContainer.new()
    var title_label := _label(title, 13, color, true)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(title_label)
    row.add_child(_label(value, 18, color, true))
    return row


func _message_label() -> Label:
    var message := _label(_last_message, 13, QUEST_GOLD)
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.custom_minimum_size.y = 32.0
    return message


func _rule(color: Color, alpha: float) -> HSeparator:
    var rule := HSeparator.new()
    rule.add_theme_color_override("separator", Color(color, alpha))
    return rule


func _label(text_value: String, font_size: int, color: Color, display: bool = false) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_override("font", DISPLAY_FONT if display else BODY_FONT)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _button(text_value: String, color: Color) -> Button:
    var button := ChronicleButtonScript.new() as Button
    button.text = text_value
    button.set("touch_safe", false)
    button.call("adopt_color_hint", color)
    return button


func _style(fill: Color, border: Color, width: int, radius: int, content_margin: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = content_margin
    style.content_margin_right = content_margin
    style.content_margin_top = content_margin
    style.content_margin_bottom = content_margin
    return style


func _runtime_value(property_name: String, fallback: float) -> float:
    if _hero_runtime == null:
        return fallback
    return float(_hero_runtime.get(property_name))


func _equipped_count(equipment: Dictionary) -> int:
    var count := 0
    for item_id_value in equipment.values():
        if not str(item_id_value).is_empty():
            count += 1
    return count


func _equipment_slot_name(slot_id: String) -> String:
    for definition: Dictionary in PrototypeHeroProfileState.EQUIPMENT_SLOTS:
        if str(definition["id"]) == slot_id:
            return str(definition["name"])
    return slot_id.replace("_", " ").capitalize()


func _short_name(item_name: String) -> String:
    var words := item_name.split(" ", false)
    if words.size() <= 1:
        return item_name.left(8).to_upper()
    return (str(words[0]).left(1) + str(words[1]).left(3)).to_upper()


func _signed_value(value: Variant) -> String:
    var number := float(value)
    return "+%s" % roundi(number) if number >= 0.0 else str(roundi(number))


func _format_stat(stat_id: String, value: Variant) -> String:
    if stat_id == "attack_speed":
        return "%.2f×" % float(value)
    var suffix := "%" if stat_id in ["move_speed", "critical_chance"] else ""
    return "%s%s" % [roundi(float(value)), suffix]


func _family_color(family: String) -> Color:
    match family:
        "Mystic":
            return Color("493c66")
        "World":
            return Color("315b49")
        _:
            return Color("694742")


func _family_accent(family: String) -> Color:
    match family:
        "Mystic":
            return Color("9c82c1")
        "World":
            return Color("67a47b")
        _:
            return Color("c57863")


func _family_motto(family: String) -> String:
    match family:
        "Mystic":
            return "Mind, resolve, and arcane understanding"
        "World":
            return "Survive, shape, and uncover the wilds"
        _:
            return "Body, blade, armor, and motion"
