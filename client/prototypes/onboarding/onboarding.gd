# PROTOTYPE — local-only onboarding. No credentials leave this process.
extends Control

const OnboardingStateScript := preload("res://prototypes/onboarding/onboarding_state.gd")
const LineagePreviewScript := preload("res://prototypes/onboarding/lineage_preview.gd")
const ChronicleButtonScript := preload("res://scripts/chronicle_button.gd")
const BACKDROP := preload("res://assets/backgrounds/storybook-moonlit-market-v1.png")
const DISPLAY_FONT := preload("res://assets/fonts/alegreya/AlegreyaSC-Medium.ttf")
const BODY_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Regular.ttf")
const BODY_MEDIUM_FONT := preload("res://assets/fonts/alegreya/AlegreyaSans-Medium.ttf")

const INK_NAVY := Color("101b2c")
const BOOK_BLUE := Color("183454")
const PARCHMENT := Color("f3e5be")
const AGED_PAPER := Color("d6bd84")
const ANTIQUE_BRASS := Color("c79b48")
const WARM_IVORY := Color("fff5d6")
const FOREST_TEAL := Color("2d756e")
const CRYSTAL_CYAN := Color("72d6e5")
const QUEST_GOLD := Color("f2c45f")
const EMBER_RED := Color("b85645")
const MUTED_STONE := Color("78808a")

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
        _state.login("demo@realm.test", "123")
        _show_create_hero()
    else:
        _show_login()
    queue_redraw()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        queue_redraw()


func _build_shell() -> void:
    var background := TextureRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.texture = BACKDROP
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var veil := ColorRect.new()
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    veil.color = Color(0.025, 0.055, 0.10, 0.70)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(veil)

    var page := MarginContainer.new()
    page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page.add_theme_constant_override("margin_left", 28)
    page.add_theme_constant_override("margin_top", 16)
    page.add_theme_constant_override("margin_right", 28)
    page.add_theme_constant_override("margin_bottom", 14)
    add_child(page)

    var page_column := VBoxContainer.new()
    page_column.add_theme_constant_override("separation", 9)
    page.add_child(page_column)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 52.0
    header.add_theme_constant_override("separation", 14)
    page_column.add_child(header)

    var brand_panel := PanelContainer.new()
    brand_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand_panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.055, 0.12, 0.20, 0.97), ANTIQUE_BRASS, 2),
    )
    header.add_child(brand_panel)
    var brand_margin := _margin(20, 5, 20, 4)
    brand_panel.add_child(brand_margin)
    var brand_row := HBoxContainer.new()
    brand_row.add_theme_constant_override("separation", 13)
    brand_margin.add_child(brand_row)
    var crystal := _medallion("◆", 38, CRYSTAL_CYAN)
    brand_row.add_child(crystal)
    var brand := _display_label("THE VEILED REALMS", 28, WARM_IVORY)
    brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    brand_row.add_child(brand)

    var status_panel := PanelContainer.new()
    status_panel.custom_minimum_size.x = 350.0
    status_panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.04, 0.085, 0.14, 0.94), Color(0.78, 0.61, 0.28, 0.68), 1),
    )
    header.add_child(status_panel)
    var status_margin := _margin(18, 6, 18, 5)
    status_panel.add_child(status_margin)
    _session_label = _display_label("LOCAL CHRONICLE", 14, AGED_PAPER)
    _session_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _session_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_margin.add_child(_session_label)

    var center := CenterContainer.new()
    center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    page_column.add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(1120.0, 565.0)
    panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.035, 0.075, 0.125, 0.965), ANTIQUE_BRASS, 2),
    )
    center.add_child(panel)

    var inner_frame := PanelContainer.new()
    inner_frame.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.025, 0.055, 0.095, 0.72), Color(0.20, 0.38, 0.51, 0.9), 1),
    )
    panel.add_child(inner_frame)
    var content_margin := MarginContainer.new()
    content_margin.add_theme_constant_override("margin_left", 24)
    content_margin.add_theme_constant_override("margin_top", 20)
    content_margin.add_theme_constant_override("margin_right", 24)
    content_margin.add_theme_constant_override("margin_bottom", 20)
    inner_frame.add_child(content_margin)

    _content = VBoxContainer.new()
    _content.add_theme_constant_override("separation", 14)
    content_margin.add_child(_content)

    var footer := _label(
        "LOCAL PREVIEW  ·  IN-MEMORY ACCOUNT  ·  PROGRESS CLEARS WHEN THE GAME CLOSES",
        13,
        Color(0.84, 0.76, 0.56, 0.82),
    )
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    page_column.add_child(footer)


func _show_login() -> void:
    _clear_content()
    _session_label.text = "LOCAL CHRONICLE  ·  SIGN IN"

    var layout := HBoxContainer.new()
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_theme_constant_override("separation", 24)
    _content.add_child(layout)

    var story_panel := _paper_panel()
    story_panel.custom_minimum_size.x = 585.0
    story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(story_panel)
    var story_margin := _margin(30, 24, 30, 22)
    story_panel.add_child(story_margin)
    var story := VBoxContainer.new()
    story.add_theme_constant_override("separation", 13)
    story_margin.add_child(story)
    story.add_child(_display_label("THE CHRONICLE OPENS", 35, INK_NAVY))
    story.add_child(_rule(ANTIQUE_BRASS))

    var intro := _label(
        "Shape a Hero from one of eight Lineages, choose an Allegiance, and step through the Veil into a living world.",
        20,
        Color("27384a"),
    )
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story.add_child(intro)

    story.add_child(_path_card(
        "LIGHT ALLEGIANCE",
        "Tidekin  ·  Humans  ·  Grove Centaurs  ·  Aeralith",
        FOREST_TEAL,
    ))
    story.add_child(_path_card(
        "DARK ALLEGIANCE",
        "Crag Trolls  ·  Deep Goblins  ·  Sunscour Legion  ·  Rimeborn",
        Color("554071"),
    ))
    var lore := _label(
        "Every Lineage begins with its own Homeland, history, and path into the wider world.",
        15,
        Color("53616c"),
    )
    lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story.add_child(lore)

    var form_panel := PanelContainer.new()
    form_panel.custom_minimum_size.x = 405.0
    form_panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.055, 0.12, 0.20, 0.92), Color(0.78, 0.61, 0.28, 0.72), 1),
    )
    layout.add_child(form_panel)
    var form_margin := _margin(28, 22, 28, 22)
    form_panel.add_child(form_margin)
    var form := _form_column("LOG IN")
    form_margin.add_child(form)
    form.add_child(_label("Your local chronicle awaits.", 17, Color("bfd0dc")))
    var email_edit := _line_edit("Email", false)
    email_edit.text = "demo@realm.test"
    form.add_child(email_edit)
    var password_edit := _line_edit("Password", true)
    password_edit.placeholder_text = "123"
    form.add_child(password_edit)

    var error_label := _status_label()
    form.add_child(error_label)

    password_edit.text_submitted.connect(
        func(_submitted_text: String) -> void:
            _submit_login(email_edit.text, password_edit.text, error_label)
    )

    var login_button := _button("ENTER THE VEIL", Color("9b7127"))
    login_button.pressed.connect(
        func() -> void: _submit_login(email_edit.text, password_edit.text, error_label)
    )
    form.add_child(login_button)

    var create_button := _button("CREATE A NEW ACCOUNT", BOOK_BLUE)
    create_button.pressed.connect(_show_create_account)
    form.add_child(create_button)

    var demo_hint := _label("Seeded preview  ·  demo@realm.test  ·  123", 14, Color("91a7b8"))
    demo_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    form.add_child(demo_hint)
    email_edit.call_deferred("grab_focus")


func _show_create_account() -> void:
    _clear_content()
    _session_label.text = "LOCAL CHRONICLE  ·  NEW ACCOUNT"
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

    var create_button := _button("CREATE ACCOUNT", Color("9b7127"))
    create_button.pressed.connect(
        func() -> void:
            var result := _state.create_account(email_edit.text, password_edit.text, confirm_edit.text)
            if result["ok"]:
                _show_roster()
            else:
                error_label.text = str(result["error"])
    )
    form.add_child(create_button)

    var back_button := _button("BACK TO SIGN IN", BOOK_BLUE)
    back_button.set("variant", 2)
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
    titles.add_child(_display_label("YOUR CHRONICLE", 32, WARM_IVORY))
    titles.add_child(_label("Choose a Hero or create a new legacy.", 16, Color("9fb0c4")))

    var logout_button := _button("LOG OUT", BOOK_BLUE)
    logout_button.set("variant", 3)
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
        empty_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.95, 0.88, 0.69, 0.98), Color("b8893d"), 2))
        _content.add_child(empty_panel)
        var empty := _label(
            "NO HEROES YET\n\nYour first Hero begins with a name, a Lineage, and a Homeland.",
            20,
            INK_NAVY,
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

    var create_button := _button("INSCRIBE A NEW HERO", Color("9b7127"))
    create_button.custom_minimum_size.y = 54.0
    create_button.pressed.connect(_show_create_hero)
    _content.add_child(create_button)


func _show_create_hero() -> void:
    _clear_content()
    _session_label.text = "CHRONICLE  ·  HERO CREATION"
    _selected_allegiance = "light"
    _selected_lineage_id = ""

    var heading := HBoxContainer.new()
    _content.add_child(heading)
    var back := _button("BACK TO ROSTER", BOOK_BLUE)
    back.set("variant", 2)
    back.custom_minimum_size = Vector2(130.0, 44.0)
    back.pressed.connect(_show_roster)
    heading.add_child(back)
    var title := _display_label("INSCRIBE A HERO", 31, WARM_IVORY)
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
    _light_button = _button("LIGHT", FOREST_TEAL)
    _light_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _light_button.pressed.connect(func() -> void: _select_allegiance("light"))
    allegiance_row.add_child(_light_button)
    _dark_button = _button("DARK", Color("554071"))
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
    var create := _button("CREATE HERO", Color("9b7127"))
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
    _lineage_title = _display_label("Choose a Lineage", 24, WARM_IVORY)
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
    _light_button.set("variant", 0 if allegiance == "light" else 2)
    _dark_button.set("variant", 0 if allegiance == "dark" else 2)
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
    # Hand the chosen hero and account identity to the canonical, networked
    # world scene, which joins the server with them (account_id + hero name).
    get_tree().set_meta("selected_hero", hero.duplicate(true))
    get_tree().set_meta("account_email", _state.active_email())
    get_tree().change_scene_to_file("res://scenes/world.tscn")


func _clear_content() -> void:
    for child: Node in _content.get_children():
        _content.remove_child(child)
        child.queue_free()


func _title_block(title: String, subtitle: String) -> VBoxContainer:
    var block := VBoxContainer.new()
    block.add_child(_display_label(title, 34, WARM_IVORY))
    var subtitle_label := _label(subtitle, 16, Color("9fb0c4"))
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    block.add_child(subtitle_label)
    return block


func _form_column(title: String) -> VBoxContainer:
    var form := VBoxContainer.new()
    form.custom_minimum_size.x = 410.0
    form.add_theme_constant_override("separation", 12)
    if not title.is_empty():
        form.add_child(_display_label(title, 28, WARM_IVORY))
        form.add_child(_rule(Color(0.78, 0.61, 0.28, 0.72)))
    return form


func _line_edit(placeholder: String, secret: bool) -> LineEdit:
    var edit := LineEdit.new()
    edit.custom_minimum_size.y = 48.0
    edit.placeholder_text = placeholder
    edit.secret = secret
    edit.add_theme_font_override("font", BODY_FONT)
    edit.add_theme_font_size_override("font_size", 17)
    edit.add_theme_color_override("font_color", WARM_IVORY)
    edit.add_theme_color_override("font_placeholder_color", Color(0.72, 0.77, 0.80, 0.78))
    edit.add_theme_color_override("caret_color", CRYSTAL_CYAN)
    edit.add_theme_stylebox_override(
        "normal",
        _panel_style(Color(0.025, 0.055, 0.09, 0.92), Color(0.39, 0.47, 0.52, 0.9), 1),
    )
    edit.add_theme_stylebox_override(
        "focus",
        _panel_style(Color(0.03, 0.07, 0.11, 0.98), CRYSTAL_CYAN, 2),
    )
    return edit


func _button(text: String, color: Color) -> Button:
    var button := ChronicleButtonScript.new() as Button
    button.text = text
    button.call("adopt_color_hint", color)
    return button


func _status_label() -> Label:
    var label := _label("", 14, Color("ef8d86"))
    label.custom_minimum_size.y = 24.0
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label


func _label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_override("font", BODY_FONT)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _display_label(text: String, font_size: int, color: Color) -> Label:
    var label := _label(text, font_size, color)
    label.add_theme_font_override("font", DISPLAY_FONT)
    return label


func _paper_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.95, 0.88, 0.69, 0.98), Color("b8893d"), 2),
    )
    return panel


func _path_card(title: String, copy: String, accent: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override(
        "panel",
        _panel_style(Color(0.98, 0.94, 0.82, 0.62), accent, 1),
    )
    var margin := _margin(14, 7, 14, 7)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 1)
    margin.add_child(column)
    column.add_child(_display_label(title, 16, INK_NAVY))
    var detail := _label(copy, 15, Color("455667"))
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(detail)
    return panel


func _medallion(text: String, diameter: int, accent: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(diameter, diameter)
    var style := _panel_style(Color(0.05, 0.12, 0.18, 0.98), accent, 2)
    style.set_corner_radius_all(diameter / 2)
    style.content_margin_left = 3.0
    style.content_margin_right = 3.0
    style.content_margin_top = 2.0
    style.content_margin_bottom = 2.0
    panel.add_theme_stylebox_override("panel", style)
    var label := _display_label(text, maxi(14, diameter / 2), WARM_IVORY)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    panel.add_child(label)
    return panel


func _rule(color: Color) -> HSeparator:
    var separator := HSeparator.new()
    separator.add_theme_constant_override("separation", 4)
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.content_margin_top = 1.0
    separator.add_theme_stylebox_override("separator", style)
    return separator


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", left)
    margin.add_theme_constant_override("margin_top", top)
    margin.add_theme_constant_override("margin_right", right)
    margin.add_theme_constant_override("margin_bottom", bottom)
    return margin


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
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.025, 0.05, 0.16), true)
    draw_rect(Rect2(12.0, 10.0, size.x - 24.0, size.y - 20.0), Color(0.78, 0.61, 0.28, 0.52), false, 1.0)
    draw_rect(Rect2(16.0, 14.0, size.x - 32.0, size.y - 28.0), Color(0.06, 0.16, 0.24, 0.72), false, 1.0)
