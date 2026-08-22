extends SceneTree

const StateScript := preload("res://prototypes/onboarding/onboarding_state.gd")


func _initialize() -> void:
    var state := StateScript.new() as PrototypeOnboardingState
    var failures: Array[String] = []

    _check(state.lineages_for("light").size() == 4, "expected four Light Lineages", failures)
    _check(state.lineages_for("dark").size() == 4, "expected four Dark Lineages", failures)
    _check(state.login("demo@realm.test", "prototype123")["ok"], "demo login failed", failures)
    state.logout()

    var created := state.create_account("keeper@example.test", "long-password", "long-password")
    _check(created["ok"], "account creation failed", failures)
    var hero_result := state.create_hero("Mira Vale", "tidekin")
    _check(hero_result["ok"], "Hero creation failed", failures)
    _check(state.heroes().size() == 1, "created Hero missing from roster", failures)
    _check(
        state.create_hero("mira vale", "human")["ok"] == false,
        "case-insensitive duplicate Hero name was accepted",
        failures,
    )

    if failures.is_empty():
        print("Onboarding state smoke test passed.")
        quit(0)
    else:
        for failure: String in failures:
            push_error(failure)
        quit(1)


func _check(condition: bool, failure: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(failure)

