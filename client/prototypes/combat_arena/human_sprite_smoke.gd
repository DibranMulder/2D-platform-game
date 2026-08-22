extends SceneTree

const ARENA := preload("res://prototypes/combat_arena/combat_arena.tscn")
const ONBOARDING_STATE := preload("res://prototypes/onboarding/onboarding_state.gd")
const HUMAN_FRAMES := preload(
    "res://assets/characters/human_m03/v1/human_m03_sprite_frames.tres"
)
const EXPECTED_FRAME_COUNTS := {
    &"attack": 5,
    &"block": 1,
    &"defeated": 1,
    &"fall": 1,
    &"hurt": 1,
    &"idle": 2,
    &"jump": 2,
    &"land": 1,
    &"portal": 1,
    &"ready": 1,
    &"run": 8,
}


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    for animation_name: StringName in EXPECTED_FRAME_COUNTS:
        if not HUMAN_FRAMES.has_animation(animation_name):
            push_error("Missing Human M03 animation: %s" % animation_name)
            quit(1)
            return
        var expected_count := int(EXPECTED_FRAME_COUNTS[animation_name])
        if HUMAN_FRAMES.get_frame_count(animation_name) != expected_count:
            push_error(
                "Human M03 animation %s has the wrong frame count" % animation_name
            )
            quit(1)
            return

    var onboarding := ONBOARDING_STATE.new() as PrototypeOnboardingState
    if not onboarding.login("demo@realm.test", "123")["ok"]:
        push_error("Demo login failed before the Human sprite integration test")
        quit(1)
        return
    var creation := onboarding.create_hero("Sprite Tester", "human")
    if not creation["ok"]:
        push_error("Human creation failed before the sprite integration test")
        quit(1)
        return
    set_meta("selected_hero", (creation["hero"] as Dictionary).duplicate(true))

    var arena := ARENA.instantiate()
    root.add_child(arena)
    await process_frame

    var hero := arena.get_node("Hero") as PrototypeHero
    var sprite := hero.get_node("HumanSprite") as AnimatedSprite2D
    if not sprite.visible or sprite.animation != &"idle":
        push_error("Human sword loadout did not activate the M03 idle sprite")
        quit(1)
        return

    hero.set_weapon("bow")
    await process_frame
    if sprite.visible:
        push_error("Human M03 sword sprite did not yield to another weapon loadout")
        quit(1)
        return

    print("Human M03 sprite resource and combat-arena integration passed.")
    quit(0)
