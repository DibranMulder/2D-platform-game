class_name PrototypeHero
extends CharacterBody2D

signal combat_event(message: String)
signal defeated
signal weapon_changed(weapon_id: String)

@onready var human_sprite: AnimatedSprite2D = $HumanSprite

const MAX_HEALTH := 100
const MAX_STAMINA := 100.0
const MAX_MANA := 100.0
const GENERAL_EXP_GOAL := 1000
const MOVE_SPEED := 270.0
const GROUND_ACCELERATION := 1800.0
const AIR_ACCELERATION := 850.0
const GRAVITY := 1850.0
const JUMP_VELOCITY := -670.0
const WEAPON_ORDER: Array[String] = ["sword", "axe_shield", "bow", "staff", "wand"]
const WEAPON_NAMES := {
    "sword": "SWORD",
    "axe_shield": "AXE + SHIELD",
    "bow": "BOW",
    "staff": "STAFF",
    "wand": "WAND",
}
const LINEAGE_IDS: Array[String] = [
    "human",
    "tidekin",
    "grove_centaur",
    "aeralith",
    "crag_troll",
    "deep_goblin",
    "sunscour",
    "rimeborn",
]

var health := MAX_HEALTH
var stamina := MAX_STAMINA
var mana := MAX_MANA
var general_exp := 350
var level := 7
var current_action := "Ready"
var facing := 1
var is_blocking := false
var is_alive := true
var lineage_id := "human"
var weapon_id := "sword"
var _move_axis := 0.0
var _jump_queued := false
var _action_lock := 0.0
var _attack_flash := 0.0
var _hurt_flash := 0.0
var _is_aiming := false
var _projectiles: Array[Dictionary] = []
var _magic_flash := 0.0
var _magic_color := Color("72d8ff")
var _magic_radius := 0.0
var _target: Node2D
var _cooldowns := {
    "attack": 0.0,
    "power_strike": 0.0,
    "whirlwind": 0.0,
    "lunge": 0.0,
    "second_wind": 0.0,
    "axe_chop": 0.0,
    "sundering_cleave": 0.0,
    "shield_bash": 0.0,
    "shield_charge": 0.0,
    "quick_shot": 0.0,
    "piercing_shot": 0.0,
    "volley": 0.0,
    "backstep": 0.0,
    "arcane_bolt": 0.0,
    "fireball": 0.0,
    "frost_nova": 0.0,
    "blink": 0.0,
    "magic_missile": 0.0,
    "twin_sparks": 0.0,
    "hex_bolt": 0.0,
    "phase_step": 0.0,
    "mend": 0.0,
}


func configure_hero(hero_data: Dictionary) -> void:
    var requested_lineage := str(hero_data.get("lineage_id", "human"))
    lineage_id = requested_lineage if LINEAGE_IDS.has(requested_lineage) else "human"
    level = clampi(int(hero_data.get("level", level)), 1, 99)
    _update_human_sprite()
    queue_redraw()


func set_target(target: Node2D) -> void:
    _target = target


func set_move_axis(axis: float) -> void:
    _move_axis = clampf(axis, -1.0, 1.0)


func queue_jump() -> void:
    _jump_queued = true


func set_guard(guarding: bool) -> void:
    set_secondary(guarding)


func set_secondary(held: bool) -> void:
    if not is_alive:
        return
    _is_aiming = weapon_id == "bow" and held and stamina > 0.0
    var uses_stamina_guard := weapon_id == "sword" or weapon_id == "axe_shield"
    var uses_magic_ward := weapon_id == "staff" or weapon_id == "wand"
    is_blocking = held and (
        (uses_stamina_guard and stamina > 0.0)
        or (uses_magic_ward and mana > 0.0)
    )
    if is_blocking:
        current_action = "Arcane Ward" if uses_magic_ward else "Shield Guard" if weapon_id == "axe_shield" else "Parrying"
    elif _is_aiming:
        current_action = "Aiming"
    elif current_action in ["Guarding", "Shield Guard", "Parrying", "Arcane Ward", "Aiming"]:
        current_action = "Ready"
    queue_redraw()


func try_action(action: String) -> void:
    var legacy_slots := {
        "attack": 1,
        "power_strike": 3,
        "whirlwind": 4,
        "lunge": 5,
        "second_wind": 6,
    }
    if legacy_slots.has(action):
        try_combat_slot(int(legacy_slots[action]))


func set_weapon(next_weapon_id: String) -> void:
    if not WEAPON_ORDER.has(next_weapon_id) or weapon_id == next_weapon_id:
        return
    set_secondary(false)
    weapon_id = next_weapon_id
    current_action = "Ready"
    _update_human_sprite()
    combat_event.emit("Equipped %s." % weapon_name())
    weapon_changed.emit(weapon_id)
    queue_redraw()


func cycle_weapon(direction: int = 1) -> void:
    var index := WEAPON_ORDER.find(weapon_id)
    var next_index := posmod(index + direction, WEAPON_ORDER.size())
    set_weapon(WEAPON_ORDER[next_index])


func weapon_name() -> String:
    return str(WEAPON_NAMES.get(weapon_id, "SWORD"))


func action_id_for_slot(slot: int) -> String:
    var actions := _weapon_actions()
    if slot < 1 or slot > actions.size():
        return ""
    return str((actions[slot - 1] as Dictionary)["id"])


func action_label_for_slot(slot: int) -> String:
    var actions := _weapon_actions()
    if slot < 1 or slot > actions.size():
        return ""
    return str((actions[slot - 1] as Dictionary)["label"])


func try_combat_slot(slot: int) -> void:
    if slot == 2:
        return
    var action := action_id_for_slot(slot)
    if action.is_empty() or not is_alive or _action_lock > 0.0 or float(_cooldowns.get(action, 0.0)) > 0.0:
        return

    match action:
        "attack":
            _perform_strike("attack", "Sword Attack", 14, 86.0, 0.45, 0.18, false)
        "power_strike":
            _perform_strike("power_strike", "Power Strike", 32, 100.0, 3.0, 0.55, false)
        "whirlwind":
            _perform_strike("whirlwind", "Whirlwind", 22, 112.0, 5.0, 0.65, true)
        "lunge":
            facing = _target_direction_or_facing()
            velocity.x = float(facing) * 760.0
            _perform_strike("lunge", "Lunge", 18, 128.0, 4.0, 0.32, false)
        "axe_chop":
            _perform_strike("axe_chop", "Axe Chop", 23, 94.0, 0.72, 0.34, false)
        "sundering_cleave":
            _perform_strike("sundering_cleave", "Sundering Cleave", 40, 116.0, 4.2, 0.68, false)
        "shield_bash":
            if _perform_strike("shield_bash", "Shield Bash", 13, 82.0, 3.2, 0.28, false):
                _stagger_target(0.9)
        "shield_charge":
            facing = _target_direction_or_facing()
            velocity.x = float(facing) * 610.0
            if _perform_strike("shield_charge", "Shield Charge", 19, 132.0, 4.8, 0.38, false):
                _stagger_target(0.55)
        "quick_shot":
            _fire_projectile("quick_shot", "Quick Shot", 13 + (6 if _is_aiming else 0), 620.0, 0.48, 0.16, 0.0, Color("e6c879"), "arrow")
        "piercing_shot":
            if _spend_stamina(18.0, "Piercing Shot"):
                _fire_projectile("piercing_shot", "Piercing Shot", 31, 760.0, 3.4, 0.38, 0.0, Color("fff09a"), "arrow")
        "volley":
            if _spend_stamina(24.0, "Volley"):
                _start_action("volley", "Volley", 5.2, 0.45)
                for height_offset: float in [-15.0, 0.0, 15.0]:
                    _spawn_projectile("Volley Arrow", 10, 580.0, Color("e6c879"), "arrow", height_offset)
                combat_event.emit("Volley sends three arrows forward.")
        "backstep":
            _start_action("backstep", "Backstep", 3.0, 0.24)
            facing = _target_direction_or_facing()
            velocity.x = float(-facing) * 590.0
            combat_event.emit("Backstep creates firing distance.")
        "arcane_bolt":
            _fire_projectile("arcane_bolt", "Arcane Bolt", 17, 560.0, 0.62, 0.2, 7.0, Color("70cfff"), "orb")
        "fireball":
            _fire_projectile("fireball", "Fireball", 38, 620.0, 3.8, 0.48, 25.0, Color("ff8a45"), "fireball")
        "frost_nova":
            if _spend_mana(30.0, "Frost Nova"):
                _magic_color = Color("7ee8ff")
                _magic_radius = 155.0
                _magic_flash = 0.4
                if _perform_strike("frost_nova", "Frost Nova", 24, 155.0, 5.5, 0.5, true):
                    _stagger_target(1.2)
        "blink":
            if _spend_mana(18.0, "Blink"):
                _start_action("blink", "Blink", 3.5, 0.2)
                position.x = clampf(position.x + float(facing) * 215.0, 44.0, 1236.0)
                _magic_color = Color("8ee7ff")
                _magic_radius = 52.0
                _magic_flash = 0.3
                combat_event.emit("Blink folds the space ahead.")
        "magic_missile":
            _fire_projectile("magic_missile", "Magic Missile", 11, 500.0, 0.3, 0.1, 4.0, Color("c98cff"), "spark")
        "twin_sparks":
            if _spend_mana(14.0, "Twin Sparks"):
                _start_action("twin_sparks", "Twin Sparks", 2.6, 0.28)
                _spawn_projectile("Twin Spark", 10, 520.0, Color("e4a2ff"), "spark", -8.0)
                _spawn_projectile("Twin Spark", 10, 520.0, Color("b784ff"), "spark", 8.0)
                combat_event.emit("Twin Sparks seek the target.")
        "hex_bolt":
            _fire_projectile("hex_bolt", "Hex Bolt", 29, 590.0, 4.4, 0.34, 22.0, Color("e06cff"), "orb")
        "phase_step":
            if _spend_mana(12.0, "Phase Step"):
                _start_action("phase_step", "Phase Step", 2.8, 0.16)
                position.x = clampf(position.x + float(facing) * 145.0, 44.0, 1236.0)
                _magic_color = Color("d38bff")
                _magic_radius = 42.0
                _magic_flash = 0.25
                combat_event.emit("Phase Step slips through the veil.")
        "second_wind":
            if health >= MAX_HEALTH:
                combat_event.emit("Second Wind is ready, but health is already full.")
                return
            health = mini(MAX_HEALTH, health + 30)
            _cooldowns[action] = 12.0
            _action_lock = 0.35
            current_action = "Second Wind"
            combat_event.emit("Second Wind restores 30 health.")
            queue_redraw()
        "mend":
            if health >= MAX_HEALTH:
                combat_event.emit("Mend is ready, but health is already full.")
                return
            if _spend_mana(32.0, "Mend"):
                health = mini(MAX_HEALTH, health + 26)
                _start_action("mend", "Mend", 9.0, 0.42)
                _magic_color = Color("8dffb0")
                _magic_radius = 48.0
                _magic_flash = 0.45
                combat_event.emit("Mend restores 26 health.")
                queue_redraw()


func receive_damage(amount: int, attacker_side: int) -> void:
    if not is_alive:
        return

    var final_damage := amount
    var frontal_attack := attacker_side == facing
    var magical_ward := weapon_id == "staff" or weapon_id == "wand"
    if is_blocking and (frontal_attack or magical_ward):
        if magical_ward and mana >= 16.0:
            mana -= 16.0
            final_damage = maxi(1, ceili(float(amount) * 0.35))
            combat_event.emit("Arcane Ward absorbs %s damage; %s gets through." % [amount - final_damage, final_damage])
        elif not magical_ward:
            var guard_cost := 11.0 if weapon_id == "axe_shield" else 20.0
            if stamina >= guard_cost:
                stamina -= guard_cost
                var damage_ratio := 0.18 if weapon_id == "axe_shield" else 0.45
                final_damage = maxi(1, ceili(float(amount) * damage_ratio))
                var guard_name := "Shield Guard" if weapon_id == "axe_shield" else "Parry"
                combat_event.emit("%s absorbs %s damage; %s gets through." % [guard_name, amount - final_damage, final_damage])
            else:
                is_blocking = false
                combat_event.emit("The guard breaks; Monster hits for %s damage." % final_damage)
        else:
            is_blocking = false
            combat_event.emit("The ward collapses; Monster hits for %s damage." % final_damage)
    else:
        combat_event.emit("Monster hits for %s damage." % final_damage)

    health = maxi(0, health - final_damage)
    _hurt_flash = 0.18
    velocity.x = float(-attacker_side) * 260.0
    if health == 0:
        is_alive = false
        is_blocking = false
        current_action = "Defeated"
        defeated.emit()
    queue_redraw()


func cooldown(action: String) -> float:
    return float(_cooldowns.get(action, 0.0))


func cooldown_for_slot(slot: int) -> float:
    return cooldown(action_id_for_slot(slot))


func _physics_process(delta: float) -> void:
    for action: String in _cooldowns:
        _cooldowns[action] = maxf(0.0, float(_cooldowns[action]) - delta)
    _action_lock = maxf(0.0, _action_lock - delta)
    _attack_flash = maxf(0.0, _attack_flash - delta)
    _hurt_flash = maxf(0.0, _hurt_flash - delta)
    _magic_flash = maxf(0.0, _magic_flash - delta)
    _update_projectiles(delta)

    if not is_on_floor():
        velocity.y += GRAVITY * delta

    if is_alive:
        if absf(_move_axis) > 0.1:
            facing = 1 if _move_axis > 0.0 else -1
        var speed_scale := 0.38 if is_blocking else 0.58 if _is_aiming else 1.0
        var desired_velocity := _move_axis * MOVE_SPEED * speed_scale
        var acceleration := GROUND_ACCELERATION if is_on_floor() else AIR_ACCELERATION
        velocity.x = move_toward(velocity.x, desired_velocity, acceleration * delta)

        if _jump_queued and is_on_floor():
            velocity.y = JUMP_VELOCITY
            current_action = "Jump"
            combat_event.emit("Hero jumps.")

        if _is_aiming:
            stamina = maxf(0.0, stamina - 8.0 * delta)
            if stamina <= 0.0:
                _is_aiming = false
        elif not is_blocking:
            stamina = minf(MAX_STAMINA, stamina + 22.0 * delta)
            if _action_lock <= 0.0 and current_action != "Jump":
                current_action = "Ready"
        if not is_blocking:
            var mana_regen := 10.0 if weapon_id == "staff" else 7.0
            mana = minf(MAX_MANA, mana + mana_regen * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, GROUND_ACCELERATION * delta)

    _jump_queued = false
    move_and_slide()
    position.x = clampf(position.x, 44.0, 1236.0)
    _update_human_sprite()
    queue_redraw()


func _uses_human_sprite() -> bool:
    return lineage_id == "human" and weapon_id == "sword" and is_instance_valid(human_sprite)


func _update_human_sprite() -> void:
    if not is_instance_valid(human_sprite):
        return

    var uses_sprite := _uses_human_sprite()
    human_sprite.visible = uses_sprite
    if not uses_sprite:
        return

    human_sprite.flip_h = facing < 0

    var next_animation := &"idle"
    if not is_alive:
        next_animation = &"defeated"
    elif _hurt_flash > 0.0:
        next_animation = &"hurt"
    elif is_blocking:
        next_animation = &"block"
    elif _attack_flash > 0.0:
        next_animation = &"attack"
    elif human_sprite.animation == &"attack" and human_sprite.is_playing():
        return
    elif not is_on_floor():
        next_animation = &"jump" if velocity.y < 0.0 else &"fall"
    elif absf(velocity.x) > 20.0:
        next_animation = &"run"

    if human_sprite.animation != next_animation or not human_sprite.is_playing():
        human_sprite.play(next_animation)


func _perform_strike(
    action_key: String,
    display_name: String,
    damage: int,
    reach: float,
    cooldown_seconds: float,
    recovery_seconds: float,
    omnidirectional: bool,
) -> bool:
    is_blocking = false
    _is_aiming = false
    current_action = display_name
    _cooldowns[action_key] = cooldown_seconds
    _action_lock = recovery_seconds
    _attack_flash = recovery_seconds

    var hit := false
    if is_instance_valid(_target) and _target.has_method("receive_damage"):
        var offset := _target.global_position - global_position
        var facing_target := signf(offset.x) == float(facing)
        if absf(offset.x) <= reach and absf(offset.y) <= 90.0 and (omnidirectional or facing_target):
            _target.receive_damage(damage, global_position.x)
            hit = true

    combat_event.emit(
        "%s deals %s damage." % [display_name, damage]
        if hit
        else "%s misses." % display_name
    )
    queue_redraw()
    return hit


func _weapon_actions() -> Array[Dictionary]:
    match weapon_id:
        "axe_shield":
            return [
                {"id": "axe_chop", "label": "CHOP"},
                {"id": "shield_guard", "label": "GUARD"},
                {"id": "sundering_cleave", "label": "SUNDER"},
                {"id": "shield_bash", "label": "BASH"},
                {"id": "shield_charge", "label": "CHARGE"},
                {"id": "second_wind", "label": "HEAL"},
            ]
        "bow":
            return [
                {"id": "quick_shot", "label": "SHOT"},
                {"id": "aim", "label": "AIM"},
                {"id": "piercing_shot", "label": "PIERCE"},
                {"id": "volley", "label": "VOLLEY"},
                {"id": "backstep", "label": "BACKSTEP"},
                {"id": "second_wind", "label": "HEAL"},
            ]
        "staff":
            return [
                {"id": "arcane_bolt", "label": "BOLT"},
                {"id": "arcane_ward", "label": "WARD"},
                {"id": "fireball", "label": "FIREBALL"},
                {"id": "frost_nova", "label": "FROST"},
                {"id": "blink", "label": "BLINK"},
                {"id": "mend", "label": "MEND"},
            ]
        "wand":
            return [
                {"id": "magic_missile", "label": "MISSILE"},
                {"id": "arcane_ward", "label": "WARD"},
                {"id": "twin_sparks", "label": "TWIN"},
                {"id": "hex_bolt", "label": "HEX"},
                {"id": "phase_step", "label": "PHASE"},
                {"id": "mend", "label": "MEND"},
            ]
        _:
            return [
                {"id": "attack", "label": "ATTACK"},
                {"id": "guard", "label": "PARRY"},
                {"id": "power_strike", "label": "POWER"},
                {"id": "whirlwind", "label": "WHIRL"},
                {"id": "lunge", "label": "LUNGE"},
                {"id": "second_wind", "label": "HEAL"},
            ]


func _start_action(action_key: String, display_name: String, cooldown_seconds: float, recovery_seconds: float) -> void:
    is_blocking = false
    _is_aiming = false
    current_action = display_name
    _cooldowns[action_key] = cooldown_seconds
    _action_lock = recovery_seconds


func _spend_stamina(cost: float, display_name: String) -> bool:
    if stamina < cost:
        combat_event.emit("%s needs %s stamina." % [display_name, roundi(cost)])
        return false
    stamina -= cost
    return true


func _spend_mana(cost: float, display_name: String) -> bool:
    if mana < cost:
        combat_event.emit("%s needs %s mana." % [display_name, roundi(cost)])
        return false
    mana -= cost
    return true


func _fire_projectile(
    action_key: String,
    display_name: String,
    damage: int,
    projectile_range: float,
    cooldown_seconds: float,
    recovery_seconds: float,
    mana_cost: float,
    color: Color,
    projectile_kind: String,
) -> void:
    if mana_cost > 0.0 and not _spend_mana(mana_cost, display_name):
        return
    _start_action(action_key, display_name, cooldown_seconds, recovery_seconds)
    facing = _target_direction_or_facing()
    _spawn_projectile(display_name, damage, projectile_range, color, projectile_kind)
    combat_event.emit("%s is released." % display_name)


func _spawn_projectile(
    display_name: String,
    damage: int,
    projectile_range: float,
    color: Color,
    projectile_kind: String,
    height_offset: float = 0.0,
) -> void:
    _projectiles.append({
        "position": global_position + Vector2(float(facing) * 42.0, -43.0 + height_offset),
        "direction": facing,
        "remaining": projectile_range,
        "damage": damage,
        "color": color,
        "kind": projectile_kind,
        "name": display_name,
    })
    queue_redraw()


func _update_projectiles(delta: float) -> void:
    var projectile_speed := 920.0
    for index in range(_projectiles.size() - 1, -1, -1):
        var projectile := _projectiles[index]
        var distance := projectile_speed * delta
        var direction := int(projectile["direction"])
        projectile["position"] = (projectile["position"] as Vector2) + Vector2(float(direction) * distance, 0.0)
        projectile["remaining"] = float(projectile["remaining"]) - distance
        var hit := false
        if is_instance_valid(_target) and _target.has_method("receive_damage"):
            var target_offset := _target.global_position - (projectile["position"] as Vector2)
            var crossed_target := absf(target_offset.x) <= 34.0 and absf(target_offset.y) <= 96.0
            if crossed_target:
                _target.receive_damage(int(projectile["damage"]), float((projectile["position"] as Vector2).x))
                combat_event.emit("%s deals %s damage." % [projectile["name"], projectile["damage"]])
                hit = true
        if hit or float(projectile["remaining"]) <= 0.0:
            if not hit:
                combat_event.emit("%s misses." % projectile["name"])
            _projectiles.remove_at(index)
        else:
            _projectiles[index] = projectile


func _stagger_target(seconds: float) -> void:
    if is_instance_valid(_target) and _target.has_method("apply_stagger"):
        _target.apply_stagger(seconds)


func _target_direction_or_facing() -> int:
    if is_instance_valid(_target):
        var direction := signi(int(_target.global_position.x - global_position.x))
        if direction != 0:
            return direction
    return facing


func _draw() -> void:
    var tint := Color("ffffff") if _hurt_flash <= 0.0 else Color("ff6b6b")
    var direction := float(facing)

    if not _uses_human_sprite():
        match lineage_id:
            "tidekin":
                _draw_tidekin(tint)
            "grove_centaur":
                _draw_grove_centaur(tint)
            "aeralith":
                _draw_aeralith(tint)
            "crag_troll":
                _draw_crag_troll(tint)
            "deep_goblin":
                _draw_deep_goblin(tint)
            "sunscour":
                _draw_sunscour(tint)
            "rimeborn":
                _draw_rimeborn(tint)
            _:
                _draw_human(tint)

        _draw_equipped_weapon(direction)
    _draw_projectiles()
    if _magic_flash > 0.0:
        var flash_ratio := _magic_flash / 0.45
        draw_arc(Vector2(0.0, -38.0), _magic_radius * (1.15 - flash_ratio * 0.15), 0.0, TAU, 40, Color(_magic_color, clampf(flash_ratio, 0.0, 1.0)), 6.0)


func _draw_human(tint: Color) -> void:
    var skin := Color("efc59b") * tint
    draw_circle(Vector2(0.0, -62.0), 15.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-19.0, -48.0),
            Vector2(19.0, -48.0),
            Vector2(15.0, -10.0),
            Vector2(-15.0, -10.0),
        ]),
        PackedColorArray([Color("3d78c5") * tint]),
    )
    draw_line(Vector2(-10.0, -10.0), Vector2(-13.0, 0.0), Color("263148"), 9.0)
    draw_line(Vector2(10.0, -10.0), Vector2(13.0, 0.0), Color("263148"), 9.0)
    draw_line(Vector2(-17.0, -42.0), Vector2(-28.0, -24.0), skin, 7.0)
    draw_line(Vector2(17.0, -42.0), Vector2(30.0, -31.0), skin, 7.0)
    draw_line(Vector2(-10.0, -71.0), Vector2(10.0, -71.0), Color("6b3f2b") * tint, 5.0)


func _draw_tidekin(tint: Color) -> void:
    var skin := Color("72b86c") * tint
    var cloth := Color("226c82") * tint
    draw_circle(Vector2(0.0, -59.0), 19.0, skin)
    draw_circle(Vector2(-10.0, -74.0), 7.0, Color("e9f2c7") * tint)
    draw_circle(Vector2(10.0, -74.0), 7.0, Color("e9f2c7") * tint)
    draw_circle(Vector2(-10.0, -74.0), 2.5, Color("18352f"))
    draw_circle(Vector2(10.0, -74.0), 2.5, Color("18352f"))
    draw_polygon(
        PackedVector2Array([
            Vector2(-21.0, -44.0),
            Vector2(21.0, -44.0),
            Vector2(16.0, -12.0),
            Vector2(-16.0, -12.0),
        ]),
        PackedColorArray([cloth]),
    )
    draw_line(Vector2(-12.0, -12.0), Vector2(-25.0, 0.0), skin, 12.0)
    draw_line(Vector2(12.0, -12.0), Vector2(25.0, 0.0), skin, 12.0)
    draw_line(Vector2(-18.0, -40.0), Vector2(-32.0, -23.0), skin, 8.0)
    draw_line(Vector2(18.0, -40.0), Vector2(31.0, -31.0), skin, 8.0)
    draw_arc(Vector2.ZERO, 30.0, 3.55, 5.15, 12, Color("65c7ba") * tint, 5.0)


func _draw_grove_centaur(tint: Color) -> void:
    var coat := Color("95643f") * tint
    var cloth := Color("4e743e") * tint
    _draw_oval(Vector2(-1.0, -21.0), Vector2(35.0, 14.0), coat)
    draw_polygon(
        PackedVector2Array([
            Vector2(-17.0, -67.0),
            Vector2(17.0, -67.0),
            Vector2(15.0, -29.0),
            Vector2(-15.0, -29.0),
        ]),
        PackedColorArray([cloth]),
    )
    draw_circle(Vector2(0.0, -79.0), 13.0, Color("d2aa7b") * tint)
    for leg_x: float in [-24.0, -8.0, 13.0, 27.0]:
        draw_line(Vector2(leg_x, -18.0), Vector2(leg_x - 2.0, 0.0), coat, 7.0)
    draw_line(Vector2(-32.0, -23.0), Vector2(-47.0, -31.0), Color("4e743e") * tint, 5.0)
    draw_line(Vector2(-14.0, -56.0), Vector2(-27.0, -39.0), Color("d2aa7b") * tint, 7.0)
    draw_line(Vector2(14.0, -56.0), Vector2(30.0, -42.0), Color("d2aa7b") * tint, 7.0)
    draw_line(Vector2(-8.0, -90.0), Vector2(-14.0, -99.0), Color("d8b463") * tint, 3.0)
    draw_line(Vector2(8.0, -90.0), Vector2(14.0, -99.0), Color("d8b463") * tint, 3.0)


func _draw_aeralith(tint: Color) -> void:
    var skin := Color("d7e8e9") * tint
    draw_polygon(
        PackedVector2Array([
            Vector2(-13.0, -52.0),
            Vector2(-47.0, -79.0),
            Vector2(-35.0, -28.0),
        ]),
        PackedColorArray([Color("ccebf4") * tint]),
    )
    draw_polygon(
        PackedVector2Array([
            Vector2(13.0, -52.0),
            Vector2(47.0, -79.0),
            Vector2(35.0, -28.0),
        ]),
        PackedColorArray([Color("ccebf4") * tint]),
    )
    draw_circle(Vector2(0.0, -67.0), 14.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-17.0, -53.0),
            Vector2(17.0, -53.0),
            Vector2(12.0, -10.0),
            Vector2(-12.0, -10.0),
        ]),
        PackedColorArray([Color("6d7fc3") * tint]),
    )
    draw_line(Vector2(-8.0, -10.0), Vector2(-12.0, 0.0), Color("39445e") * tint, 8.0)
    draw_line(Vector2(8.0, -10.0), Vector2(12.0, 0.0), Color("39445e") * tint, 8.0)
    draw_line(Vector2(-15.0, -48.0), Vector2(-28.0, -29.0), skin, 6.0)
    draw_line(Vector2(15.0, -48.0), Vector2(31.0, -35.0), skin, 6.0)
    draw_polygon(
        PackedVector2Array([Vector2(-9.0, -78.0), Vector2(0.0, -95.0), Vector2(9.0, -78.0)]),
        PackedColorArray([Color("f2c96f") * tint]),
    )


func _draw_crag_troll(tint: Color) -> void:
    var skin := Color("78896a") * tint
    draw_circle(Vector2(0.0, -63.0), 22.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-30.0, -47.0),
            Vector2(30.0, -47.0),
            Vector2(23.0, -8.0),
            Vector2(-23.0, -8.0),
        ]),
        PackedColorArray([Color("5c4036") * tint]),
    )
    draw_line(Vector2(-18.0, -8.0), Vector2(-21.0, 0.0), Color("30342f") * tint, 13.0)
    draw_line(Vector2(18.0, -8.0), Vector2(21.0, 0.0), Color("30342f") * tint, 13.0)
    draw_line(Vector2(-28.0, -40.0), Vector2(-38.0, -14.0), skin, 12.0)
    draw_line(Vector2(28.0, -40.0), Vector2(37.0, -29.0), skin, 12.0)
    draw_polygon(
        PackedVector2Array([Vector2(-21.0, -68.0), Vector2(-28.0, -79.0), Vector2(-12.0, -73.0)]),
        PackedColorArray([Color("a6b098") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(21.0, -68.0), Vector2(28.0, -79.0), Vector2(12.0, -73.0)]),
        PackedColorArray([Color("a6b098") * tint]),
    )


func _draw_deep_goblin(tint: Color) -> void:
    var skin := Color("879b4c") * tint
    draw_polygon(
        PackedVector2Array([Vector2(-12.0, -52.0), Vector2(-35.0, -61.0), Vector2(-15.0, -41.0)]),
        PackedColorArray([skin]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(12.0, -52.0), Vector2(35.0, -61.0), Vector2(15.0, -41.0)]),
        PackedColorArray([skin]),
    )
    draw_circle(Vector2(0.0, -48.0), 15.0, skin)
    draw_circle(Vector2(-6.0, -51.0), 4.0, Color("c7e9d1") * tint)
    draw_circle(Vector2(6.0, -51.0), 4.0, Color("c7e9d1") * tint)
    draw_rect(Rect2(-16.0, -34.0, 32.0, 26.0), Color("684a76") * tint)
    draw_line(Vector2(-8.0, -8.0), Vector2(-12.0, 0.0), Color("292031") * tint, 8.0)
    draw_line(Vector2(8.0, -8.0), Vector2(12.0, 0.0), Color("292031") * tint, 8.0)
    draw_line(Vector2(-15.0, -29.0), Vector2(-28.0, -15.0), skin, 6.0)
    draw_line(Vector2(15.0, -29.0), Vector2(29.0, -22.0), skin, 6.0)
    draw_circle(Vector2(0.0, -30.0), 6.0, Color("d08342") * tint)


func _draw_sunscour(tint: Color) -> void:
    var skin := Color("9a6344") * tint
    draw_circle(Vector2(0.0, -64.0), 15.0, skin)
    draw_arc(Vector2(0.0, -66.0), 17.0, PI, TAU, 16, Color("b73b31") * tint, 8.0)
    draw_line(Vector2(-12.0, -62.0), Vector2(12.0, -62.0), Color("e4c18b") * tint, 6.0)
    draw_polygon(
        PackedVector2Array([
            Vector2(-19.0, -49.0),
            Vector2(19.0, -49.0),
            Vector2(16.0, -9.0),
            Vector2(-16.0, -9.0),
        ]),
        PackedColorArray([Color("84332f") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(-18.0, -45.0), Vector2(-31.0, -6.0), Vector2(-6.0, -14.0)]),
        PackedColorArray([Color("34304c") * tint]),
    )
    draw_line(Vector2(-10.0, -9.0), Vector2(-13.0, 0.0), Color("3d2926") * tint, 9.0)
    draw_line(Vector2(10.0, -9.0), Vector2(13.0, 0.0), Color("3d2926") * tint, 9.0)
    draw_line(Vector2(-17.0, -42.0), Vector2(-28.0, -24.0), skin, 7.0)
    draw_line(Vector2(17.0, -42.0), Vector2(31.0, -31.0), skin, 7.0)


func _draw_rimeborn(tint: Color) -> void:
    var skin := Color("a9cbd5") * tint
    draw_circle(Vector2(0.0, -64.0), 18.0, Color("dcebf0") * tint)
    draw_circle(Vector2(0.0, -64.0), 13.0, skin)
    draw_polygon(
        PackedVector2Array([
            Vector2(-24.0, -49.0),
            Vector2(24.0, -49.0),
            Vector2(19.0, -8.0),
            Vector2(-19.0, -8.0),
        ]),
        PackedColorArray([Color("385f85") * tint]),
    )
    draw_line(Vector2(-12.0, -8.0), Vector2(-15.0, 0.0), Color("243c55") * tint, 11.0)
    draw_line(Vector2(12.0, -8.0), Vector2(15.0, 0.0), Color("243c55") * tint, 11.0)
    draw_line(Vector2(-21.0, -42.0), Vector2(-31.0, -22.0), Color("dcebf0") * tint, 9.0)
    draw_line(Vector2(21.0, -42.0), Vector2(33.0, -31.0), Color("dcebf0") * tint, 9.0)
    draw_polygon(
        PackedVector2Array([Vector2(-17.0, -77.0), Vector2(-10.0, -91.0), Vector2(-4.0, -79.0)]),
        PackedColorArray([Color("b9efff") * tint]),
    )
    draw_polygon(
        PackedVector2Array([Vector2(17.0, -77.0), Vector2(10.0, -91.0), Vector2(4.0, -79.0)]),
        PackedColorArray([Color("b9efff") * tint]),
    )


func _draw_oval(center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for index in 24:
        var angle := TAU * float(index) / 24.0
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    draw_polygon(points, PackedColorArray([color]))


func _weapon_origin() -> Vector2:
    match lineage_id:
        "grove_centaur":
            return Vector2(30.0, -42.0)
        "deep_goblin":
            return Vector2(29.0, -22.0)
        "crag_troll":
            return Vector2(37.0, -29.0)
        "aeralith":
            return Vector2(31.0, -35.0)
        _:
            return Vector2(31.0, -31.0)


func _draw_equipped_weapon(direction: float) -> void:
    match weapon_id:
        "axe_shield":
            _draw_axe_and_shield(direction)
        "bow":
            _draw_bow(direction)
        "staff":
            _draw_staff(direction)
        "wand":
            _draw_wand(direction)
        _:
            _draw_sword(direction)


func _draw_sword(direction: float) -> void:
    var hand := _weapon_origin()
    hand.x *= direction

    var sword_reach := 72.0 if _attack_flash > 0.0 else 53.0
    var tip := Vector2(direction * sword_reach, hand.y - 24.0)
    draw_line(
        hand,
        tip,
        Color("dbe9ef"),
        7.0,
    )
    draw_line(
        hand + Vector2(-direction * 7.0, -6.0),
        hand + Vector2(direction * 7.0, 7.0),
        Color("d9a441"),
        5.0,
    )

    if is_blocking:
        draw_arc(hand, 31.0, -1.2, 1.2, 18, Color("80d7ff"), 7.0)


func _draw_axe_and_shield(direction: float) -> void:
    var hand := _weapon_origin()
    hand.x *= direction
    var axe_reach := 66.0 if _attack_flash > 0.0 else 49.0
    var haft_tip := Vector2(direction * axe_reach, hand.y - 21.0)
    draw_line(hand, haft_tip, Color("7a4e2f"), 7.0)
    draw_polygon(
        PackedVector2Array([
            haft_tip + Vector2(-direction * 3.0, -15.0),
            haft_tip + Vector2(direction * 19.0, -8.0),
            haft_tip + Vector2(direction * 17.0, 10.0),
            haft_tip + Vector2(-direction * 3.0, 7.0),
        ]),
        PackedColorArray([Color("c4d0d4")]),
    )
    var shield_center := Vector2(-direction * 23.0, -34.0)
    if is_blocking:
        shield_center = Vector2(direction * 32.0, -37.0)
    draw_circle(shield_center, 24.0, Color("426b75"))
    draw_arc(shield_center, 24.0, 0.0, TAU, 24, Color("e2bd62"), 5.0)
    draw_circle(shield_center, 7.0, Color("d9a441"))


func _draw_bow(direction: float) -> void:
    var hand := _weapon_origin()
    hand.x *= direction
    var bow_center := hand + Vector2(direction * 19.0, -8.0)
    var bend := 13.0 if _is_aiming else 5.0
    var top := bow_center + Vector2(direction * bend, -34.0)
    var bottom := bow_center + Vector2(direction * bend, 34.0)
    draw_arc(bow_center, 35.0, -PI * 0.5, PI * 0.5, 18, Color("bd874c"), 5.0)
    draw_line(top, bow_center + Vector2(-direction * (14.0 if _is_aiming else 0.0), 0.0), Color("eef0d5"), 2.0)
    draw_line(bottom, bow_center + Vector2(-direction * (14.0 if _is_aiming else 0.0), 0.0), Color("eef0d5"), 2.0)
    if _is_aiming:
        draw_line(bow_center + Vector2(-direction * 14.0, 0.0), bow_center + Vector2(direction * 48.0, 0.0), Color("e6c879"), 3.0)


func _draw_staff(direction: float) -> void:
    var hand := _weapon_origin()
    hand.x *= direction
    var top := Vector2(direction * 51.0, -91.0)
    var bottom := Vector2(direction * 24.0, 1.0)
    draw_line(bottom, top, Color("765035"), 7.0)
    draw_circle(top, 12.0, Color("5bbbe1"))
    draw_arc(top, 18.0, 0.0, TAU, 24, Color("b7efff"), 4.0)
    if is_blocking:
        draw_arc(Vector2(0.0, -40.0), 52.0, 0.0, TAU, 32, Color("75dfff"), 6.0)


func _draw_wand(direction: float) -> void:
    var hand := _weapon_origin()
    hand.x *= direction
    var tip := hand + Vector2(direction * 38.0, -19.0)
    draw_line(hand, tip, Color("9063aa"), 6.0)
    draw_circle(tip, 7.0, Color("dd8cff"))
    draw_line(tip + Vector2(-8.0, 0.0), tip + Vector2(8.0, 0.0), Color("f6d5ff"), 2.0)
    draw_line(tip + Vector2(0.0, -8.0), tip + Vector2(0.0, 8.0), Color("f6d5ff"), 2.0)
    if is_blocking:
        draw_arc(Vector2(0.0, -39.0), 47.0, 0.0, TAU, 32, Color("d08cff"), 5.0)


func _draw_projectiles() -> void:
    for projectile: Dictionary in _projectiles:
        var local_position := to_local(projectile["position"] as Vector2)
        var direction := float(projectile["direction"])
        var color := projectile["color"] as Color
        match str(projectile["kind"]):
            "arrow":
                draw_line(local_position - Vector2(direction * 17.0, 0.0), local_position + Vector2(direction * 17.0, 0.0), color, 3.0)
                draw_polygon(
                    PackedVector2Array([
                        local_position + Vector2(direction * 21.0, 0.0),
                        local_position + Vector2(direction * 12.0, -5.0),
                        local_position + Vector2(direction * 12.0, 5.0),
                    ]),
                    PackedColorArray([color]),
                )
            "fireball":
                draw_circle(local_position, 14.0, Color(color, 0.35))
                draw_circle(local_position, 8.0, color)
            "spark":
                draw_line(local_position - Vector2(10.0, 0.0), local_position + Vector2(10.0, 0.0), color, 5.0)
                draw_line(local_position - Vector2(0.0, 8.0), local_position + Vector2(0.0, 8.0), color.lightened(0.3), 3.0)
            _:
                draw_circle(local_position, 9.0, Color(color, 0.35))
                draw_circle(local_position, 5.0, color)
