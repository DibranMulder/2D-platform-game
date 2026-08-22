# PROTOTYPE — local-only onboarding. No credentials leave this process.
extends Control

const OnboardingStateScript := preload("res://prototypes/onboarding/onboarding_state.gd")
const LineagePreviewScript := preload("res://prototypes/onboarding/lineage_preview.gd")

var _state: PrototypeOnboardingState
var _content: VBoxContainer
var _session_label: Label
var _selected_allegiance := "light"
var _selected_lineage_id := ""
var _lineage_grid: GridContainer
var _lineage_preview: PrototypeLineagePreview
var _lineage_title: Label
var _lineage_summary: Label
var _light_button: Button
var _dark_button: Button


func _ready() -> void:
    _state = OnboardingStateScript.new() as PrototypeOnboardingState
    _build_shell()
    if OS.get_cmdline_user_args().has("--preview-create-hero"):
        _state.login("demo@realm.test", "prototype123")
        _show_create_hero()
    else:
        _show_login()
    queue_redraw()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()


func _build_shell() -> void:
    var page := MarginContainer.new()
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.add_theme_constant_override("margin_left", 38)
    page.add_theme_constant_override("margin_top", 22)
    page.add_theme_constant_override("margin_right", 38)
    page.add_theme_constant_override("margin_bottom", 20)
    add_child(page)

    var page_column := VBoxContainer.new()
    page_column.add_theme_constant_override("separation", 14)
    page.add_child(page_column)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 54.0
    page_column.add_child(header)

    var brand := _label("REALMS OF THE VEIL", 27, Color("e7c36b"))
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(brand)

    _session_label = _label("LOCAL ONBOARDING PROTOTYPE", 14, Color("97aec6"))
    _session_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(_session_label)

    var center := CenterContainer.new()
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    page_column.add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(1080.0, 575.0)
    panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.075, 0.12, 0.96), Color("40506b"), 2))
    center.add_child(panel)

    var content_margin := MarginContainer.new()
    content_margin.add_theme_constant_override("margin_left", 34)
    content_margin.add_theme_constant_override("margin_top", 28)
    content_margin.add_theme_constant_override("margin_right", 34)
    content_margin.add_theme_constant_override("margin_bottom", 28)
    panel.add_child(content_margin)

    _content = VBoxContainer.new()
    _content.add_theme_constant_override("separation", 14)
    content_margin.add_child(_content)

    var footer := _label(
        "In-memory only · no real account is created · credentials vanish when the game closes",
        13,
        Color("8092a6"),
    )
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    page_column.add_child(footer)


func _show_login() -> void:
    _clear_content()
    _session_label.text = "LOCAL ONBOARDING PROTOTYPE"

    var layout := HBoxContainer.new()
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_theme_constant_override("separation", 48)
    _content.add_child(layout)

    var story := VBoxContainer.new()
    story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    story.add_theme_constant_override("separation", 18)
    layout.add_child(story)
    story.add_child(_label("ENTER THE VEIL", 38, Color("f0dfac")))

    var intro := _label(
        "Create an Account, shape a Hero from one of eight Lineages, then enter the first combat encounter.",
        21,
        Color("c5d2e2"),
    )
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.custom_minimum_size.x = 485.0
    story.add_child(intro)

    var paths := _label(
        "LIGHT ALLEGIANCE\nTidekin · Humans · Grove Centaurs · Aeralith\n\n"
        + "DARK ALLEGIANCE\nCrag Trolls · Deep Goblins · Sunscour Legion · Rimeborn",
        17,
        Color("95b9d9"),
    )
    paths.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story.add_child(paths)

    var form := _form_column("LOG IN")
    layout.add_child(form)
    var email_edit := _line_edit("Email", false)
    email_edit.text = "demo@realm.test"
    form.add_child(email_edit)
    var password_edit := _line_edit("Password", true)
    password_edit.placeholder_text = "prototype123"
    form.add_child(password_edit)

    var error_label := _status_label()
    form.add_child(error_label)

    var login_button := _button("LOG IN", Color("456e9c"))
    login_button.pressed.connect(
        func() -> void: _submit_login(email_edit.text, password_edit.text, error_label)
    )
    form.add_child(login_button)

    var create_button := _button("CREATE A NEW ACCOUNT", Color("59647a"))
    create_button.pressed.connect(_show_create_account)
    form.add_child(create_button)

    var demo_hint := _label("Demo password: prototype123", 13, Color("8298ae"))
    demo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    form.add_child(demo_hint)


func _show_create_account() -> void:
    _clear_content()
    _content.add_child(_title_block(
        "CREATE ACCOUNT",
        "This validates the flow only. The prototype does not persist or securely hash passwords.",
    ))

    var form := _form_column("")
    form.custom_minimum_size.x = 520.0
    form.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    _content.add_child(form)

    var email_edit := _line_edit("Email", false)
    form.add_child(email_edit)
    var password_edit := _line_edit("Password · 12 characters minimum", true)
    form.add_child(password_edit)
    var confirm_edit := _line_edit("Confirm password", true)
    form.add_child(confirm_edit)
    var error_label := _status_label()
    form.add_child(error_label)

    var create_button := _button("CREATE ACCOUNT", Color("456e9c"))
    create_button.pressed.connect(
        func() -> void:
            var result := _state.create_account(email_edit.text, password_edit.text, confirm_edit.text)
            if result["ok"]:
                _show_roster()
            else:
                error_label.text = str(result["error"])
    )
    form.add_child(create_button)

    var back_button := _button("BACK TO LOGIN", Color("59647a"))
    back_button.pressed.connect(_show_login)
    form.add_child(back_button)


func _submit_login(email: String, password: String, error_label: Label) -> void:
    var result := _state.login(email, password)
    if result["ok"]:
        _show_roster()
    else:
        error_label.text = str(result["error"])


func _show_roster() -> void:
    _clear_content()
    _session_label.text = _state.active_email()

    var heading := HBoxContainer.new()
    _content.add_child(heading)
    var titles := VBoxContainer.new()
    titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_child(titles)
    titles.add_child(_label("YOUR HEROES", 32, Color("f0dfac")))
    titles.add_child(_label("Choose a Hero or create a new legacy.", 16, Color("9fb0c4")))

    var logout_button := _button("LOG OUT", Color("59647a"))
    logout_button.custom_minimum_size = Vector2(130.0, 46.0)
    logout_button.pressed.connect(
        func() -> void:
            _state.logout()
            _show_login()
    )
    heading.add_child(logout_button)

    var heroes := _state.heroes()
    if heroes.is_empty():
        var empty_panel := PanelContainer.new()
        empty_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
        empty_panel.add_theme_stylebox_override("panel", _panel_style(Color("111827"), Color("354156"), 1))
        _content.add_child(empty_panel)
        var empty := _label(
            "NO HEROES YET\n\nYour first Hero begins with a name, a Lineage, and a Homeland.",
            20,
            Color("aabbd0"),
        )
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        empty_panel.add_child(empty)
    else:
        var hero_grid := GridContainer.new()
        hero_grid.columns = 3
        hero_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
        hero_grid.add_theme_constant_override("h_separation", 14)
        hero_grid.add_theme_constant_override("v_separation", 14)
        _content.add_child(hero_grid)
        for hero: Dictionary in heroes:
            var card := _button(
                "%s\n%s · %s\n%s ALLEGIANCE\n\nENTER WORLD" % [
                    hero["name"],
                    hero["lineage_name"],
                    hero["homeland"],
                    str(hero["allegiance"]).to_upper(),
                ],
                Color("344c68") if hero["allegiance"] == "light" else Color("5b3d63"),
            )
            card.custom_minimum_size = Vector2(315.0, 170.0)
            card.pressed.connect(_enter_world.bind(hero))
            hero_grid.add_child(card)

    var create_button := _button("CREATE HERO", Color("7a5d35"))
    create_button.custom_minimum_size.y = 54.0
    create_button.pressed.connect(_show_create_hero)
    _content.add_child(create_button)


func _show_create_hero() -> void:
    _clear_content()
    _selected_allegiance = "light"
    _selected_lineage_id = ""

    var heading := HBoxContainer.new()
    _content.add_child(heading)
    var back := _button("← ROSTER", Color("59647a"))
    back.custom_minimum_size = Vector2(130.0, 44.0)
    back.pressed.connect(_show_roster)
    heading.add_child(back)
    var title := _label("CREATE HERO", 31, Color("f0dfac"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_child(title)
    var balance := Control.new()
    balance.custom_minimum_size.x = 130.0
    heading.add_child(balance)

    var main := HBoxContainer.new()
    main.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_theme_constant_override("separation", 24)
    _content.add_child(main)

    var choices := VBoxContainer.new()
    choices.custom_minimum_size.x = 610.0
    choices.add_theme_constant_override("separation", 12)
    main.add_child(choices)

    choices.add_child(_label("1 · CHOOSE ALLEGIANCE", 15, Color("91a7bd")))
    var allegiance_row := HBoxContainer.new()
    allegiance_row.add_theme_constant_override("separation", 10)
    choices.add_child(allegiance_row)
    _light_button = _button("LIGHT", Color("3c6885"))
    _light_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _light_button.pressed.connect(func() -> void: _select_allegiance("light"))
    allegiance_row.add_child(_light_button)
    _dark_button = _button("DARK", Color("604162"))
    _dark_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _dark_button.pressed.connect(func() -> void: _select_allegiance("dark"))
    allegiance_row.add_child(_dark_button)

    choices.add_child(_label("2 · CHOOSE LINEAGE", 15, Color("91a7bd")))
    _lineage_grid = GridContainer.new()
    _lineage_grid.columns = 2
    _lineage_grid.add_theme_constant_override("h_separation", 10)
    _lineage_grid.add_theme_constant_override("v_separation", 10)
    choices.add_child(_lineage_grid)

    choices.add_child(_label("3 · NAME YOUR HERO", 15, Color("91a7bd")))
    var name_edit := _line_edit("3–16 letters", false)
    name_edit.max_length = 16
    choices.add_child(name_edit)
    var status := _status_label()
    choices.add_child(status)
    var create := _button("CREATE HERO", Color("7a5d35"))
    create.pressed.connect(
        func() -> void:
            var result := _state.create_hero(name_edit.text, _selected_lineage_id)
            if result["ok"]:
                _show_roster()
            else:
                status.text = str(result["error"])
    )
    choices.add_child(create)

    var preview_column := VBoxContainer.new()
    preview_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main.add_child(preview_column)
    _lineage_preview = LineagePreviewScript.new() as PrototypeLineagePreview
    _lineage_preview.custom_minimum_size = Vector2(360.0, 330.0)
    _lineage_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    preview_column.add_child(_lineage_preview)
    _lineage_title = _label("Choose a Lineage", 24, Color("f0dfac"))
    preview_column.add_child(_lineage_title)
    _lineage_summary = _label("Your Lineage determines bodily form, cultural origin, and Homeland—not Combat Class.", 15, Color("aabbd0"))
    _lineage_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    preview_column.add_child(_lineage_summary)

    _select_allegiance("light")


func _select_allegiance(allegiance: String) -> void:
    _selected_allegiance = allegiance
    _selected_lineage_id = ""
    _light_button.text = "LIGHT ✓" if allegiance == "light" else "LIGHT"
    _dark_button.text = "DARK ✓" if allegiance == "dark" else "DARK"
    _populate_lineages()


func _populate_lineages() -> void:
    for child: Node in _lineage_grid.get_children():
        _lineage_grid.remove_child(child)
        child.queue_free()

    var lineages := _state.lineages_for(_selected_allegiance)
    if _selected_lineage_id.is_empty() and not lineages.is_empty():
        _selected_lineage_id = str(lineages[0]["id"])
    for lineage: Dictionary in lineages:
        var selected: bool = str(lineage["id"]) == _selected_lineage_id
        var card := _button(
            "%s\n%s%s" % [
                lineage["name"],
                lineage["homeland"],
                "\nSELECTED" if selected else "",
            ],
            Color("3f6880") if _selected_allegiance == "light" else Color("634867"),
        )
        card.custom_minimum_size = Vector2(292.0, 78.0)
        card.disabled = selected
        card.pressed.connect(_select_lineage.bind(str(lineage["id"])))
        _lineage_grid.add_child(card)

    if not lineages.is_empty():
        _select_lineage(_selected_lineage_id, false)


func _select_lineage(lineage_id: String, rebuild: bool = true) -> void:
    _selected_lineage_id = lineage_id
    var lineage := _state.lineage_by_id(lineage_id)
    _lineage_preview.set_lineage(lineage)
    _lineage_title.text = "%s · %s" % [lineage["name"], lineage["homeland"]]
    _lineage_summary.text = str(lineage["summary"])
    if rebuild:
        _populate_lineages()


func _enter_world(hero: Dictionary) -> void:
    get_tree().set_meta("selected_hero", hero.duplicate(true))
    get_tree().change_scene_to_file("res://prototypes/combat_arena/combat_arena.tscn")


func _clear_content() -> void:
    for child: Node in _content.get_children():
        _content.remove_child(child)
        child.queue_free()


func _title_block(title: String, subtitle: String) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_child(_label(title, 34, Color("f0dfac")))
    var subtitle_label := _label(subtitle, 16, Color("9fb0c4"))
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    block.add_child(subtitle_label)
    return block


func _form_column(title: String) -> VBoxContainer:
    var form := VBoxContainer.new()
    form.custom_minimum_size.x = 410.0
    form.add_theme_constant_override("separation", 12)
    if not title.is_empty():
        form.add_child(_label(title, 28, Color("f0dfac")))
    return form


func _line_edit(placeholder: String, secret: bool) -> LineEdit:
    var edit := LineEdit.new()
    edit.custom_minimum_size.y = 48.0
    edit.placeholder_text = placeholder
    edit.secret = secret
    edit.add_theme_font_size_override("font_size", 17)
    return edit


func _button(text: String, color: Color) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 48.0
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_stylebox_override("normal", _panel_style(color, color.lightened(0.2), 1))
    button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.12), Color("d7e3ef"), 2))
    button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), Color("f0dfac"), 2))
    return button


func _status_label() -> Label:
    var label := _label("", 14, Color("ef8d86"))
    label.custom_minimum_size.y = 24.0
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label


func _label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _panel_style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(8)
    style.content_margin_left = 12.0
    style.content_margin_right = 12.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    return style


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("08101e"), true)
    draw_circle(Vector2(size.x * 0.84, size.y * 0.17), 130.0, Color(0.25, 0.35, 0.52, 0.16))
    draw_circle(Vector2(size.x * 0.12, size.y * 0.88), 220.0, Color(0.18, 0.38, 0.44, 0.12))
    for star_index in 28:
        var star_x := fmod(float(star_index * 173 + 61), maxf(1.0, size.x))
        var star_y := fmod(float(star_index * 97 + 43), maxf(1.0, size.y * 0.72))
        draw_circle(Vector2(star_x, star_y), 1.5, Color(0.75, 0.84, 0.95, 0.42))
