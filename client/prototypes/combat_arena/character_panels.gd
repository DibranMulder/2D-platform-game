# PROTOTYPE — interactive shell for progression and item-state decisions.
class_name PrototypeCharacterPanels
extends Control

const ProfileStateScript := preload("res://prototypes/combat_arena/hero_profile_state.gd")

var _profile: PrototypeHeroProfileState
var _hero_data: Dictionary = {}
var _backdrop: ColorRect
var _window_content: VBoxContainer
var _header_summary: Label
var _current_panel := "pouch"
var _last_message := "Choose an item, Discipline, or Talent to inspect the state change."


func configure_hero(hero_data: Dictionary) -> void:
    _hero_data = hero_data.duplicate(true)
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
    _current_panel = panel_id
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
        KEY_B:
            _toggle_panel("pouch")
        KEY_C:
            _toggle_panel("equipment")
        KEY_L:
            _toggle_panel("disciplines")
        KEY_K:
            _toggle_panel("talents")
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


func _build_quick_buttons() -> void:
    var quick_bar := HBoxContainer.new()
    quick_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    quick_bar.position = Vector2(-615.0, 238.0)
    quick_bar.size = Vector2(595.0, 42.0)
    quick_bar.add_theme_constant_override("separation", 7)
    quick_bar.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(quick_bar)

    for definition: Dictionary in [
        {"id": "pouch", "text": "B · POUCH"},
        {"id": "equipment", "text": "C · GEAR"},
        {"id": "disciplines", "text": "L · LEVELS"},
        {"id": "talents", "text": "K · TALENTS"},
        {"id": "hints", "text": "I · HINTS"},
    ]:
        var button := _button(str(definition["text"]), Color("354459"))
        button.custom_minimum_size = Vector2(110.0, 42.0)
        button.pressed.connect(open_panel.bind(str(definition["id"])))
        quick_bar.add_child(button)


func _build_window() -> void:
    _backdrop = ColorRect.new()
    _backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _backdrop.color = Color(0.015, 0.025, 0.045, 0.9)
    _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    _backdrop.visible = false
    add_child(_backdrop)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _backdrop.add_child(center)

    var window := PanelContainer.new()
    window.custom_minimum_size = Vector2(1160.0, 690.0)
    window.add_theme_stylebox_override("panel", _style(Color("0b1321"), Color("52627a"), 2))
    center.add_child(window)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_bottom", 12)
    window.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var header := HBoxContainer.new()
    column.add_child(header)
    var title := _label("HERO OVERVIEW", 27, Color("efd590"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    _header_summary = _label("", 15, Color("a9bed2"))
    _header_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(_header_summary)
    var close := _button("CLOSE · ESC", Color("5c4651"))
    close.custom_minimum_size = Vector2(135.0, 42.0)
    close.pressed.connect(close_panel)
    header.add_child(close)

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 8)
    column.add_child(tabs)
    for definition: Dictionary in [
        {"id": "pouch", "text": "ITEM POUCH [B]"},
        {"id": "equipment", "text": "EQUIPMENT [C]"},
        {"id": "disciplines", "text": "DISCIPLINES [L]"},
        {"id": "talents", "text": "TALENT TREE [K]"},
        {"id": "hints", "text": "HINTS [I]"},
    ]:
        var tab := _button(str(definition["text"]), Color("34455f"))
        tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tab.pressed.connect(open_panel.bind(str(definition["id"])))
        tabs.add_child(tab)

    _window_content = VBoxContainer.new()
    _window_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _window_content.add_theme_constant_override("separation", 10)
    column.add_child(_window_content)


func _rebuild_panel() -> void:
    for child: Node in _window_content.get_children():
        _window_content.remove_child(child)
        child.queue_free()
    _refresh_header()
    match _current_panel:
        "equipment":
            _build_equipment_panel()
        "disciplines":
            _build_disciplines_panel()
        "talents":
            _build_talents_panel()
        "hints":
            _build_hints_panel()
        _:
            _build_pouch_panel()


func _refresh_header() -> void:
    if _header_summary == null:
        return
    _header_summary.text = "%s · OVERALL %s · TOTAL %s · %s TALENT POINTS     " % [
        str(_hero_data.get("name", "Prototype Hero")).to_upper(),
        _profile.overall_level(),
        _profile.total_level(),
        _profile.unspent_talent_points(),
    ]


func _build_hints_panel() -> void:
    _window_content.add_child(_section_title(
        "BATTLE HINTS",
        "Press I again to return to the fight, or use Esc to close any open section.",
    ))

    var columns := HBoxContainer.new()
    columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
    columns.add_theme_constant_override("separation", 28)
    _window_content.add_child(columns)

    var controls := VBoxContainer.new()
    controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls.add_theme_constant_override("separation", 14)
    columns.add_child(controls)
    controls.add_child(_hint_block(
        "MOVEMENT",
        "Move with Left / Right or A / D. On touch, drag the movement knob.\n"
        + "The movement knob appears after your first touch. Jump with Space or Up; "
        + "on touch, tap Jump or flick the movement knob upward.",
    ))
    controls.add_child(_hint_block(
        "COMBAT ACTIONS",
        "1  Sword Attack\n"
        + "2 or Shift  Hold Guard\n"
        + "3  Power Strike\n"
        + "4  Whirlwind\n"
        + "5  Lunge\n"
        + "6  Second Wind",
    ))
    controls.add_child(_hint_block(
        "HERO SECTIONS",
        "B  Item Pouch     C  Equipment     L  Discipline Levels\n"
        + "K  Talent Tree     I  Battle Hints     E  Merchant Trade",
    ))
    controls.add_child(_hint_block(
        "PORTALS & MERCHANTS",
        "Walk into a glowing portal to travel between maps. In the Moonlit Market, "
        + "approach Mira and press E or tap Trade to buy weapons, armor, and supplies.",
    ))

    var tactics := VBoxContainer.new()
    tactics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tactics.add_theme_constant_override("separation", 14)
    columns.add_child(tactics)
    tactics.add_child(_hint_block(
        "READ THE ENCOUNTER",
        "Close the distance, watch the Monster state, and react to its red wind-up. "
        + "Guard only reduces frontal damage, so face the attacker.",
    ))
    tactics.add_child(_hint_block(
        "MANAGE YOUR RESOURCES",
        "Guard consumes stamina when it blocks a hit. Release Guard to recover stamina. "
        + "Second Wind restores health but has a long cooldown.",
    ))
    tactics.add_child(_hint_block(
        "RECOVERY",
        "After victory or defeat, press R or use the on-screen restart button to fight again.",
    ))


func _hint_block(title: String, body: String) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", _style(Color("152238"), Color("3c526d"), 1))
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 8)
    panel.add_child(content)
    content.add_child(_label(title, 18, Color("efd590")))
    var description := _label(body, 15, Color("c4d2e0"))
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(description)
    return panel


func _build_pouch_panel() -> void:
    _window_content.add_child(_section_title("ITEM POUCH · 24 SLOTS", "Tap equipment to wear it; materials stay in the pouch."))
    var split := HBoxContainer.new()
    split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.add_theme_constant_override("separation", 18)
    _window_content.add_child(split)

    var grid := GridContainer.new()
    grid.columns = 6
    grid.custom_minimum_size.x = 730.0
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    split.add_child(grid)

    var pouch := _profile.pouch()
    for index in pouch.size():
        var slot := _button("EMPTY", Color("192332"))
        slot.custom_minimum_size = Vector2(114.0, 93.0)
        if pouch[index] == null:
            slot.disabled = true
        else:
            var entry := pouch[index] as Dictionary
            var item_definition := _profile.item(str(entry["item_id"]))
            slot.text = "%s\n%s\n%s" % [
                item_definition["icon"],
                item_definition["name"],
                "×%s" % entry["quantity"] if int(entry["quantity"]) > 1 else "EQUIP" if not str(item_definition["slot"]).is_empty() else "ITEM",
            ]
            slot.tooltip_text = str(item_definition["description"])
            slot.pressed.connect(_equip_item.bind(index))
        grid.add_child(slot)

    var information := VBoxContainer.new()
    information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    split.add_child(information)
    information.add_child(_label("POUCH RULE", 19, Color("efd590")))
    var rule := _label(
        "Equipping is an atomic swap: the previous item returns to the same pouch slot. Consumables and materials cannot be equipped.",
        16,
        Color("b7c5d5"),
    )
    rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    information.add_child(rule)
    information.add_child(_message_label())


func _equip_item(index: int) -> void:
    var result := _profile.equip_from_pouch(index)
    _last_message = str(result["message"])
    _rebuild_panel()


func _build_equipment_panel() -> void:
    _window_content.add_child(_section_title("EQUIPMENT OVERVIEW", "Tap an equipped item to return it to the first free pouch slot."))
    var split := HBoxContainer.new()
    split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    split.add_theme_constant_override("separation", 20)
    _window_content.add_child(split)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.custom_minimum_size.x = 760.0
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    split.add_child(grid)
    var equipment := _profile.equipment()
    for slot_definition: Dictionary in PrototypeHeroProfileState.EQUIPMENT_SLOTS:
        var slot_id := str(slot_definition["id"])
        var item_id := str(equipment[slot_id])
        var slot := _button("%s\n— EMPTY —" % slot_definition["name"], Color("1b2736"))
        slot.custom_minimum_size = Vector2(245.0, 98.0)
        if not item_id.is_empty():
            var item_definition := _profile.item(item_id)
            slot.text = "%s\n%s · %s" % [slot_definition["name"], item_definition["icon"], item_definition["name"]]
            slot.tooltip_text = str(item_definition["description"])
            slot.pressed.connect(_unequip_item.bind(slot_id))
        else:
            slot.disabled = true
        grid.add_child(slot)

    var summary := VBoxContainer.new()
    summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    split.add_child(summary)
    summary.add_child(_label(str(_hero_data.get("name", "HERO")).to_upper(), 24, Color("efd590")))
    summary.add_child(_label(
        "%s\n%s ALLEGIANCE\n\nEQUIPPED ITEMS\n%s / %s slots" % [
            _hero_data.get("lineage_name", "Unknown Lineage"),
            str(_hero_data.get("allegiance", "unaligned")).to_upper(),
            _equipped_count(equipment),
            PrototypeHeroProfileState.EQUIPMENT_SLOTS.size(),
        ],
        17,
        Color("b7c5d5"),
    ))
    summary.add_child(_message_label())


func _unequip_item(slot_id: String) -> void:
    var result := _profile.unequip(slot_id)
    _last_message = str(result["message"])
    _rebuild_panel()


func _build_disciplines_panel() -> void:
    var header := HBoxContainer.new()
    _window_content.add_child(header)
    var title := _section_title(
        "DISCIPLINES · LEVEL 1–99",
        "Overall Level is floor(Total Level ÷ 12). Training is Hero-specific; the catalog is universal.",
    )
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var adventure := _button("SIMULATE ADVENTURE\n+1500 XP TO ALL", Color("705d32"))
    adventure.custom_minimum_size = Vector2(220.0, 58.0)
    adventure.pressed.connect(_award_adventure)
    header.add_child(adventure)

    var grid := GridContainer.new()
    grid.columns = 4
    grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 9)
    grid.add_theme_constant_override("v_separation", 9)
    _window_content.add_child(grid)

    for discipline: Dictionary in PrototypeHeroProfileState.DISCIPLINES:
        var discipline_id := str(discipline["id"])
        var level := _profile.discipline_level(discipline_id)
        var xp := _profile.discipline_xp(discipline_id)
        var next_xp := _profile.xp_threshold(mini(PrototypeHeroProfileState.MAX_DISCIPLINE_LEVEL, level + 1))
        var card := _button(
            "%s · %s\nLEVEL %s\n%s / %s XP\nTRAIN +500" % [
                discipline["family"],
                discipline["name"],
                level,
                xp,
                next_xp,
            ],
            _family_color(str(discipline["family"])),
        )
        card.custom_minimum_size = Vector2(267.0, 85.0)
        card.tooltip_text = str(discipline["description"])
        card.pressed.connect(_train_discipline.bind(discipline_id))
        grid.add_child(card)

    _window_content.add_child(_message_label())


func _train_discipline(discipline_id: String) -> void:
    var result := _profile.award_xp(discipline_id, 500)
    _last_message = str(result["message"])
    _rebuild_panel()


func _award_adventure() -> void:
    _last_message = _profile.award_adventure_xp()
    _rebuild_panel()


func _build_talents_panel() -> void:
    _window_content.add_child(_section_title(
        "HERO-SPECIFIC TALENT TREE · %s POINTS AVAILABLE" % _profile.unspent_talent_points(),
        "Spend points on this Hero only. Overall Level and prerequisites unlock deeper tiers.",
    ))
    var branches := HBoxContainer.new()
    branches.size_flags_vertical = Control.SIZE_EXPAND_FILL
    branches.add_theme_constant_override("separation", 15)
    _window_content.add_child(branches)

    for branch_name: String in ["Blade", "Guardian", "Wayfarer"]:
        var branch := VBoxContainer.new()
        branch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        branch.add_theme_constant_override("separation", 5)
        branches.add_child(branch)
        var branch_title := _label(branch_name.to_upper(), 20, _branch_color(branch_name).lightened(0.28))
        branch_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        branch.add_child(branch_title)

        var branch_talents := _talents_for_branch(branch_name)
        for index in branch_talents.size():
            var talent := branch_talents[index]
            if index > 0:
                var arrow := _label("↓", 18, Color("71829a"))
                arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                branch.add_child(arrow)
            var owned := _profile.owns_talent(str(talent["id"]))
            var state_text := "UNLOCKED" if owned else "COST %s · LEVEL %s" % [talent["cost"], talent["level"]]
            var node := _button(
                "%s\n%s\n%s" % [talent["name"], talent["description"], state_text],
                Color("315d4b") if owned else _branch_color(branch_name),
            )
            node.custom_minimum_size = Vector2(345.0, 78.0)
            node.disabled = owned
            node.pressed.connect(_purchase_talent.bind(str(talent["id"])))
            branch.add_child(node)

    _window_content.add_child(_message_label())


func _purchase_talent(talent_id: String) -> void:
    var result := _profile.purchase_talent(talent_id)
    _last_message = str(result["message"])
    _rebuild_panel()


func _talents_for_branch(branch_name: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for talent: Dictionary in PrototypeHeroProfileState.TALENTS:
        if talent["branch"] == branch_name:
            result.append(talent)
    return result


func _section_title(title: String, subtitle: String) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_theme_constant_override("separation", 2)
    block.add_child(_label(title, 22, Color("efd590")))
    block.add_child(_label(subtitle, 14, Color("96aac0")))
    return block


func _message_label() -> Label:
    var message := _label(_last_message, 15, Color("e1bd6c"))
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message.custom_minimum_size.y = 46.0
    return message


func _equipped_count(equipment: Dictionary) -> int:
    var count := 0
    for item_id: String in equipment.values():
        if not item_id.is_empty():
            count += 1
    return count


func _family_color(family: String) -> Color:
    match family:
        "Mystic":
            return Color("4f426d")
        "World":
            return Color("365b4a")
        _:
            return Color("5c493b")


func _branch_color(branch: String) -> Color:
    match branch:
        "Guardian":
            return Color("3c5871")
        "Wayfarer":
            return Color("3c6654")
        _:
            return Color("70454a")


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
    button.add_theme_stylebox_override("normal", _style(color, color.lightened(0.18), 1))
    button.add_theme_stylebox_override("hover", _style(color.lightened(0.1), Color("d5e0eb"), 2))
    button.add_theme_stylebox_override("pressed", _style(color.darkened(0.1), Color("efd590"), 2))
    return button


func _style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(7)
    style.content_margin_left = 8.0
    style.content_margin_right = 8.0
    style.content_margin_top = 7.0
    style.content_margin_bottom = 7.0
    return style
