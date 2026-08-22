# PROTOTYPE — throwaway mechanics scene. Do not promote unchanged.
extends Node2D

const CharacterPanelsScript := preload("res://prototypes/combat_arena/chronicle_character_panels.gd")
const MerchantShopScript := preload("res://prototypes/combat_arena/merchant_shop.gd")
const MoonlitMarketTexture := preload("res://assets/backgrounds/storybook-moonlit-market-v1.png")
const MAP_FOREST := "sunlit_forest"
const MAP_MARKET := "moonlit_market"

@onready var hero: PrototypeHero = $Hero
@onready var monster: PrototypeMonster = $Monster
@onready var storybook_background: TextureRect = $StorybookBackground
@onready var jump_platform: StaticBody2D = $JumpPlatform
@onready var jump_platform_collision: CollisionShape2D = $JumpPlatform/CollisionShape2D
@onready var forest_ladder: Area2D = $ForestLadder
@onready var portal_area: Area2D = $PortalArea
@onready var portal_label: Label = $PortalLabel
@onready var merchant_area: Area2D = $MerchantArea
@onready var merchant_name: Label = $MerchantName
@onready var joystick: PrototypeVirtualJoystick = $HUD/VirtualJoystick
@onready var map_label: Label = $HUD/MapLabel
@onready var trade_button: Button = $HUD/TradeButton
@onready var hero_identity: Label = $HUD/HeroIdentity
@onready var hero_health: ProgressBar = $HUD/HeroHealth
@onready var hero_health_text: Label = $HUD/HeroHealth/HeroHealthText
@onready var mana_bar: ProgressBar = $HUD/Mana
@onready var mana_text: Label = $HUD/Mana/ManaText
@onready var stamina_bar: ProgressBar = $HUD/Stamina
@onready var stamina_text: Label = $HUD/Stamina/StaminaText
@onready var general_exp_bar: ProgressBar = $HUD/GeneralExp
@onready var general_exp_text: Label = $HUD/GeneralExp/GeneralExpText
@onready var state_text: Label = $HUD/StatePanel/StateText
@onready var combat_log: Label = $HUD/CombatLogPanel/CombatLog
@onready var restart_button: Button = $HUD/RestartButton
@onready var attack_button: Button = $HUD/Hotbar/Attack
@onready var guard_button: Button = $HUD/Hotbar/Guard
@onready var power_button: Button = $HUD/Hotbar/PowerStrike
@onready var whirlwind_button: Button = $HUD/Hotbar/Whirlwind
@onready var lunge_button: Button = $HUD/Hotbar/Lunge
@onready var heal_button: Button = $HUD/Hotbar/SecondWind
@onready var jump_button: Button = $HUD/Hotbar/Jump
@onready var weapon_name_label: Label = $HUD/WeaponBar/WeaponName
@onready var sword_button: Button = $HUD/WeaponBar/Sword
@onready var axe_button: Button = $HUD/WeaponBar/AxeShield
@onready var bow_button: Button = $HUD/WeaponBar/Bow
@onready var staff_button: Button = $HUD/WeaponBar/Staff
@onready var wand_button: Button = $HUD/WeaponBar/Wand
@onready var prototype_badge: Label = $HUD/PrototypeBadge
@onready var logout_button: Button = $HUD/LogoutButton

var _joystick_value := Vector2.ZERO
var _previous_joystick_y := 0.0
var _touch_guard_held := false
var _combat_messages: Array[String] = []
var _encounter_finished := false
var _character_panels: PrototypeChronicleCharacterPanels
var _shop: PrototypeMerchantShop
var _current_map := MAP_FOREST
var _near_merchant := false
var _portal_locked := false


func _ready() -> void:
    var selected_hero: Dictionary = {
        "name": "Prototype Hero",
        "lineage_id": "human",
        "lineage_name": "Human",
        "allegiance": "light",
    }
    if get_tree().has_meta("selected_hero"):
        selected_hero = get_tree().get_meta("selected_hero") as Dictionary
        prototype_badge.text = "%s · %s · COMBAT PROTOTYPE" % [
            str(selected_hero.get("name", "HERO")).to_upper(),
            str(selected_hero.get("lineage_name", "Unknown Lineage")).to_upper(),
        ]

    hero.configure_hero(selected_hero)
    hero_identity.text = "%s  ·  LEVEL %s" % [
        str(selected_hero.get("name", "Prototype Hero")).to_upper(),
        hero.level,
    ]
    _character_panels = CharacterPanelsScript.new() as PrototypeChronicleCharacterPanels
    $HUD.add_child(_character_panels)
    _character_panels.configure_hero(selected_hero, hero)
    _shop = MerchantShopScript.new() as PrototypeMerchantShop
    $HUD.add_child(_shop)
    _shop.shop_closed.connect(_on_shop_closed)
    for argument: String in OS.get_cmdline_user_args():
        if argument.begins_with("--preview-panel="):
            _character_panels.call_deferred(
                "open_panel",
                argument.trim_prefix("--preview-panel="),
            )
    hero.set_target(monster)
    monster.set_target(hero)
    hero.combat_event.connect(_add_combat_message)
    monster.combat_event.connect(_add_combat_message)
    hero.defeated.connect(_on_hero_defeated)
    monster.defeated.connect(_on_monster_defeated)
    joystick.vector_changed.connect(_on_joystick_changed)

    attack_button.pressed.connect(func() -> void: hero.try_combat_slot(1))
    power_button.pressed.connect(func() -> void: hero.try_combat_slot(3))
    whirlwind_button.pressed.connect(func() -> void: hero.try_combat_slot(4))
    lunge_button.pressed.connect(func() -> void: hero.try_combat_slot(5))
    heal_button.pressed.connect(func() -> void: hero.try_combat_slot(6))
    jump_button.pressed.connect(hero.queue_jump)
    guard_button.button_down.connect(_on_guard_button_down)
    guard_button.button_up.connect(_on_guard_button_up)
    sword_button.pressed.connect(hero.set_weapon.bind("sword"))
    axe_button.pressed.connect(hero.set_weapon.bind("axe_shield"))
    bow_button.pressed.connect(hero.set_weapon.bind("bow"))
    staff_button.pressed.connect(hero.set_weapon.bind("staff"))
    wand_button.pressed.connect(hero.set_weapon.bind("wand"))
    restart_button.pressed.connect(_restart_encounter)
    logout_button.pressed.connect(_logout)
    trade_button.pressed.connect(_open_shop)
    portal_area.body_entered.connect(_on_portal_body_entered)
    merchant_area.body_entered.connect(_on_merchant_body_entered)
    merchant_area.body_exited.connect(_on_merchant_body_exited)

    _add_combat_message("A horned monster blocks the road.")
    _configure_map(MAP_FOREST)
    queue_redraw()


func _process(_delta: float) -> void:
    if _shop.visible:
        hero.set_move_axis(0.0)
        hero.set_climb_axis(0.0)
        hero.set_guard(false)
        _update_hud()
        return

    var keyboard_axis := 0.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        keyboard_axis -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        keyboard_axis += 1.0

    var movement_axis := keyboard_axis if absf(keyboard_axis) > 0.1 else _joystick_value.x
    hero.set_move_axis(movement_axis)

    var keyboard_climb_axis := 0.0
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        keyboard_climb_axis -= 1.0
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        keyboard_climb_axis += 1.0
    var climb_axis := keyboard_climb_axis if absf(keyboard_climb_axis) > 0.1 else _joystick_value.y
    hero.set_climb_axis(climb_axis)

    var keyboard_guard := Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_SHIFT)
    hero.set_guard(_touch_guard_held or keyboard_guard)
    _update_hud()


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
        joystick.visible = true


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    match key_event.keycode:
        KEY_E:
            if _shop.visible:
                _shop.close_shop()
            elif _near_merchant:
                _open_shop()
        KEY_ESCAPE:
            if _shop.visible:
                _shop.close_shop()
        KEY_SPACE:
            hero.queue_jump()
        KEY_UP:
            if not hero.can_climb():
                hero.queue_jump()
        KEY_TAB:
            hero.cycle_weapon()
        KEY_1:
            hero.try_combat_slot(1)
        KEY_3:
            hero.try_combat_slot(3)
        KEY_4:
            hero.try_combat_slot(4)
        KEY_5:
            hero.try_combat_slot(5)
        KEY_6:
            hero.try_combat_slot(6)
        KEY_R:
            if _encounter_finished:
                _restart_encounter()


func _on_joystick_changed(value: Vector2) -> void:
    _joystick_value = value
    if value.y < -0.78 and _previous_joystick_y >= -0.78 and not hero.can_climb():
        hero.queue_jump()
    _previous_joystick_y = value.y


func _on_guard_button_down() -> void:
    _touch_guard_held = true


func _on_guard_button_up() -> void:
    _touch_guard_held = false


func _on_portal_body_entered(body: Node2D) -> void:
    if body != hero or _portal_locked:
        return
    _portal_locked = true
    if _current_map == MAP_FOREST:
        _configure_map(MAP_MARKET)
        hero.position = Vector2(155.0, 549.0)
        _add_combat_message("The portal opens onto Mira's Moonlit Market.")
    else:
        _configure_map(MAP_FOREST)
        hero.position = Vector2(1110.0, 549.0)
        _add_combat_message("The portal returns you to the Sunlit Forest.")
    get_tree().create_timer(0.65).timeout.connect(func() -> void: _portal_locked = false)


func _on_merchant_body_entered(body: Node2D) -> void:
    if body != hero or _current_map != MAP_MARKET:
        return
    _near_merchant = true
    trade_button.visible = true


func _on_merchant_body_exited(body: Node2D) -> void:
    if body != hero:
        return
    _near_merchant = false
    trade_button.visible = false
    if _shop.visible:
        _shop.close_shop()


func _open_shop() -> void:
    if not _near_merchant or _current_map != MAP_MARKET:
        return
    _character_panels.close_panel()
    trade_button.visible = false
    _shop.open_shop()


func _on_shop_closed() -> void:
    trade_button.visible = _near_merchant and _current_map == MAP_MARKET


func _configure_map(map_id: String) -> void:
    _current_map = map_id
    var in_forest := map_id == MAP_FOREST
    storybook_background.texture = (
        load("res://assets/backgrounds/storybook-forest-battleground-v1.png") as Texture2D
        if in_forest
        else MoonlitMarketTexture
    )
    map_label.text = "SUNLIT FOREST" if in_forest else "MOONLIT MARKET"
    portal_area.position = Vector2(1205.0, 500.0) if in_forest else Vector2(70.0, 500.0)
    portal_label.text = "TO MOONLIT MARKET" if in_forest else "TO SUNLIT FOREST"
    portal_label.position = Vector2(
        clampf(portal_area.position.x - 85.0, 0.0, 1110.0),
        portal_area.position.y - 92.0,
    )
    merchant_name.visible = not in_forest
    merchant_area.set_deferred("monitoring", not in_forest)
    jump_platform.visible = in_forest
    jump_platform_collision.set_deferred("disabled", not in_forest)
    forest_ladder.call("set_climbing_enabled", in_forest)
    monster.visible = in_forest
    monster.process_mode = Node.PROCESS_MODE_INHERIT if in_forest else Node.PROCESS_MODE_DISABLED
    _near_merchant = false
    trade_button.visible = false
    if _shop != null and _shop.visible:
        _shop.close_shop()
    queue_redraw()


func _on_hero_defeated() -> void:
    _encounter_finished = true
    restart_button.text = "DEFEATED — TAP OR PRESS R TO RETRY"
    restart_button.visible = true
    _add_combat_message("The Hero falls.")


func _on_monster_defeated() -> void:
    _encounter_finished = true
    restart_button.text = "VICTORY — TAP OR PRESS R TO FIGHT AGAIN"
    restart_button.visible = true


func _restart_encounter() -> void:
    get_tree().reload_current_scene()


func _logout() -> void:
    if get_tree().has_meta("selected_hero"):
        get_tree().remove_meta("selected_hero")
    if get_tree().has_meta("prototype_hero_profiles"):
        get_tree().remove_meta("prototype_hero_profiles")
    get_tree().change_scene_to_file("res://prototypes/onboarding/onboarding.tscn")


func _add_combat_message(message: String) -> void:
    _combat_messages.push_front(message)
    if _combat_messages.size() > 6:
        _combat_messages.resize(6)
    combat_log.text = "\n".join(_combat_messages)


func _update_hud() -> void:
    hero_health.value = hero.health
    hero_health_text.text = "HERO  %s / %s" % [hero.health, PrototypeHero.MAX_HEALTH]
    mana_bar.value = hero.mana
    mana_text.text = "MANA  %s / %s" % [roundi(hero.mana), int(PrototypeHero.MAX_MANA)]
    stamina_bar.value = hero.stamina
    stamina_text.text = "STAMINA  %s / %s" % [roundi(hero.stamina), int(PrototypeHero.MAX_STAMINA)]
    general_exp_bar.value = hero.general_exp
    general_exp_text.text = "GENERAL EXP  %s / %s" % [
        hero.general_exp,
        PrototypeHero.GENERAL_EXP_GOAL,
    ]
    state_text.text = (
        "Hero: %s   |   Monster: %s" % [hero.current_action, monster.current_intent]
        if _current_map == MAP_FOREST
        else "MOONLIT MARKET   |   PEACEFUL TRADING OUTPOST"
    )

    _update_action_button(attack_button, 1)
    var secondary_active := hero.is_blocking or hero.current_action == "Aiming"
    guard_button.disabled = not hero.is_alive
    guard_button.text = "2\n%s\n%s" % [
        hero.action_label_for_slot(2),
        "HELD" if secondary_active else "hold",
    ]
    _update_action_button(power_button, 3)
    _update_action_button(whirlwind_button, 4)
    _update_action_button(lunge_button, 5)
    _update_action_button(heal_button, 6)
    weapon_name_label.text = "TAB · %s" % hero.weapon_name()
    _update_weapon_button(sword_button, "sword", "SWORD")
    _update_weapon_button(axe_button, "axe_shield", "AXE + SHIELD")
    _update_weapon_button(bow_button, "bow", "BOW")
    _update_weapon_button(staff_button, "staff", "STAFF")
    _update_weapon_button(wand_button, "wand", "WAND")


func _update_action_button(button: Button, slot: int) -> void:
    var remaining := hero.cooldown_for_slot(slot)
    button.disabled = remaining > 0.0 or not hero.is_alive
    button.text = "%s\n%s\n%s" % [
        slot,
        hero.action_label_for_slot(slot),
        "%.1f" % remaining if remaining > 0.0 else "READY",
    ]


func _update_weapon_button(button: Button, button_weapon_id: String, title: String) -> void:
    var selected := hero.weapon_id == button_weapon_id
    button.disabled = selected
    button.text = "%s%s" % ["> " if selected else "", title]


func _draw() -> void:
    var in_forest := _current_map == MAP_FOREST
    var ground_tint := Color(0.035, 0.11, 0.075, 0.58) if in_forest else Color(0.035, 0.05, 0.13, 0.5)
    var ground_edge := Color("a9c564") if in_forest else Color("7d85bf")
    draw_rect(Rect2(0.0, 550.0, 1280.0, 170.0), ground_tint, true)
    draw_rect(Rect2(0.0, 550.0, 1280.0, 9.0), ground_edge, true)
    draw_line(Vector2(0.0, 559.0), Vector2(1280.0, 559.0), Color("334358"), 4.0)

    if in_forest:
        draw_polygon(
            PackedVector2Array([
                Vector2(485.0, 439.0),
                Vector2(695.0, 439.0),
                Vector2(682.0, 478.0),
                Vector2(502.0, 478.0),
            ]),
            PackedColorArray([Color("344a35")]),
        )
        draw_rect(Rect2(485.0, 439.0, 210.0, 8.0), Color("a7c360"), true)
        draw_line(Vector2(500.0, 449.0), Vector2(680.0, 449.0), Color("70864d"), 3.0)
        for crack_x: float in [525.0, 576.0, 632.0, 668.0]:
            draw_line(Vector2(crack_x, 451.0), Vector2(crack_x - 5.0, 469.0), Color("1f352b"), 2.0)

    _draw_portal(portal_area.position)
    if not in_forest:
        _draw_merchant(merchant_area.position + Vector2(0.0, 49.0))


func _draw_portal(center: Vector2) -> void:
    var outer := PackedVector2Array()
    var inner := PackedVector2Array()
    for index in 33:
        var angle := TAU * float(index) / 32.0
        outer.append(center + Vector2(cos(angle) * 35.0, sin(angle) * 61.0))
        inner.append(center + Vector2(cos(angle) * 25.0, sin(angle) * 50.0))
    draw_colored_polygon(inner, Color(0.2, 0.8, 0.95, 0.22))
    draw_polyline(outer, Color("86e5ff"), 7.0, true)
    draw_polyline(inner, Color("b991ff"), 4.0, true)
    draw_circle(center, 9.0, Color(0.9, 0.96, 1.0, 0.72))


func _draw_merchant(position: Vector2) -> void:
    draw_circle(position + Vector2(0.0, -1.0), 31.0, Color(0.02, 0.04, 0.08, 0.45))
    draw_polygon(
        PackedVector2Array([
            position + Vector2(-28.0, -63.0),
            position + Vector2(28.0, -63.0),
            position + Vector2(22.0, -5.0),
            position + Vector2(-22.0, -5.0),
        ]),
        PackedColorArray([Color("5e4779")]),
    )
    draw_circle(position + Vector2(0.0, -82.0), 17.0, Color("d7ae88"))
    draw_polygon(
        PackedVector2Array([
            position + Vector2(-31.0, -91.0),
            position + Vector2(2.0, -116.0),
            position + Vector2(30.0, -90.0),
        ]),
        PackedColorArray([Color("334c70")]),
    )
    draw_line(position + Vector2(-16.0, -51.0), position + Vector2(-35.0, -28.0), Color("d7ae88"), 7.0)
    draw_line(position + Vector2(16.0, -51.0), position + Vector2(35.0, -32.0), Color("d7ae88"), 7.0)
    draw_circle(position + Vector2(6.0, -84.0), 2.5, Color("22233b"))
