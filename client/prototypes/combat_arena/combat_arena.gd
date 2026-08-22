# PROTOTYPE — throwaway mechanics scene. Do not promote unchanged.
extends Node2D

@onready var hero: PrototypeHero = $Hero
@onready var monster: PrototypeMonster = $Monster
@onready var joystick: PrototypeVirtualJoystick = $HUD/VirtualJoystick
@onready var hero_health: ProgressBar = $HUD/HeroHealth
@onready var hero_health_text: Label = $HUD/HeroHealth/HeroHealthText
@onready var stamina_bar: ProgressBar = $HUD/Stamina
@onready var stamina_text: Label = $HUD/Stamina/StaminaText
@onready var monster_health: ProgressBar = $HUD/MonsterHealth
@onready var monster_health_text: Label = $HUD/MonsterHealth/MonsterHealthText
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

var _joystick_value := Vector2.ZERO
var _previous_joystick_y := 0.0
var _touch_guard_held := false
var _combat_messages: Array[String] = []
var _encounter_finished := false


func _ready() -> void:
    hero.set_target(monster)
    monster.set_target(hero)
    hero.combat_event.connect(_add_combat_message)
    monster.combat_event.connect(_add_combat_message)
    hero.defeated.connect(_on_hero_defeated)
    monster.defeated.connect(_on_monster_defeated)
    joystick.vector_changed.connect(_on_joystick_changed)

    attack_button.pressed.connect(func() -> void: hero.try_action("attack"))
    power_button.pressed.connect(func() -> void: hero.try_action("power_strike"))
    whirlwind_button.pressed.connect(func() -> void: hero.try_action("whirlwind"))
    lunge_button.pressed.connect(func() -> void: hero.try_action("lunge"))
    heal_button.pressed.connect(func() -> void: hero.try_action("second_wind"))
    jump_button.pressed.connect(hero.queue_jump)
    guard_button.button_down.connect(_on_guard_button_down)
    guard_button.button_up.connect(_on_guard_button_up)
    restart_button.pressed.connect(_restart_encounter)

    _add_combat_message("A horned monster blocks the road.")
    _add_combat_message("Close the distance, read its wind-up, and Guard or strike.")
    queue_redraw()


func _process(_delta: float) -> void:
    var keyboard_axis := 0.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        keyboard_axis -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        keyboard_axis += 1.0

    var movement_axis := keyboard_axis if absf(keyboard_axis) > 0.1 else _joystick_value.x
    hero.set_move_axis(movement_axis)

    var keyboard_guard := Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_SHIFT)
    hero.set_guard(_touch_guard_held or keyboard_guard)
    _update_hud()


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    match key_event.keycode:
        KEY_SPACE, KEY_UP:
            hero.queue_jump()
        KEY_1:
            hero.try_action("attack")
        KEY_3:
            hero.try_action("power_strike")
        KEY_4:
            hero.try_action("whirlwind")
        KEY_5:
            hero.try_action("lunge")
        KEY_6:
            hero.try_action("second_wind")
        KEY_R:
            if _encounter_finished:
                _restart_encounter()


func _on_joystick_changed(value: Vector2) -> void:
    _joystick_value = value
    if value.y < -0.78 and _previous_joystick_y >= -0.78:
        hero.queue_jump()
    _previous_joystick_y = value.y


func _on_guard_button_down() -> void:
    _touch_guard_held = true


func _on_guard_button_up() -> void:
    _touch_guard_held = false


func _on_hero_defeated() -> void:
    _encounter_finished = true
    restart_button.text = "DEFEATED — TAP OR PRESS R TO RETRY"
    restart_button.visible = true
    _add_combat_message("The Hero falls. Try guarding during the red wind-up.")


func _on_monster_defeated() -> void:
    _encounter_finished = true
    restart_button.text = "VICTORY — TAP OR PRESS R TO FIGHT AGAIN"
    restart_button.visible = true


func _restart_encounter() -> void:
    get_tree().reload_current_scene()


func _add_combat_message(message: String) -> void:
    _combat_messages.push_front(message)
    if _combat_messages.size() > 6:
        _combat_messages.resize(6)
    combat_log.text = "\n".join(_combat_messages)


func _update_hud() -> void:
    hero_health.value = hero.health
    hero_health_text.text = "HERO  %s / %s" % [hero.health, PrototypeHero.MAX_HEALTH]
    stamina_bar.value = hero.stamina
    stamina_text.text = "STAMINA  %s / %s" % [roundi(hero.stamina), int(PrototypeHero.MAX_STAMINA)]
    monster_health.value = monster.health
    monster_health_text.text = "HORNED MARAUDER  %s / %s" % [
        monster.health,
        PrototypeMonster.MAX_HEALTH,
    ]
    state_text.text = "Hero: %s   |   Monster: %s" % [hero.current_action, monster.current_intent]

    _update_action_button(attack_button, "1", "ATTACK", "attack")
    guard_button.text = "2\nGUARD\n%s" % ("HELD" if hero.is_blocking else "hold")
    _update_action_button(power_button, "3", "POWER", "power_strike")
    _update_action_button(whirlwind_button, "4", "WHIRL", "whirlwind")
    _update_action_button(lunge_button, "5", "LUNGE", "lunge")
    _update_action_button(heal_button, "6", "HEAL", "second_wind")


func _update_action_button(button: Button, key: String, title: String, action: String) -> void:
    var remaining := hero.cooldown(action)
    button.disabled = remaining > 0.0 or not hero.is_alive
    button.text = "%s\n%s\n%s" % [
        key,
        title,
        "%.1f" % remaining if remaining > 0.0 else "READY",
    ]


func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color("111b2d"), true)
    draw_circle(Vector2(1088.0, 122.0), 75.0, Color("d9e7ff"))
    draw_circle(Vector2(1088.0, 122.0), 62.0, Color("c8d9f7"))

    draw_polygon(
        PackedVector2Array([
            Vector2(0.0, 420.0),
            Vector2(170.0, 250.0),
            Vector2(335.0, 420.0),
            Vector2(530.0, 205.0),
            Vector2(760.0, 420.0),
            Vector2(945.0, 270.0),
            Vector2(1280.0, 430.0),
        ]),
        PackedColorArray([Color("1d3043")]),
    )

    for tree_x: float in [90.0, 190.0, 750.0, 1160.0]:
        draw_rect(Rect2(tree_x - 9.0, 350.0, 18.0, 210.0), Color("27382f"), true)
        draw_circle(Vector2(tree_x, 325.0), 52.0, Color("244335"))
        draw_circle(Vector2(tree_x - 29.0, 354.0), 42.0, Color("203d31"))
        draw_circle(Vector2(tree_x + 31.0, 355.0), 45.0, Color("29493a"))

    draw_rect(Rect2(0.0, 550.0, 1280.0, 170.0), Color("253b2c"), true)
    draw_rect(Rect2(0.0, 550.0, 1280.0, 16.0), Color("789760"), true)
    for stone_x: float in [40.0, 240.0, 470.0, 680.0, 1010.0, 1210.0]:
        draw_circle(Vector2(stone_x, 572.0), 15.0, Color("526253"))

