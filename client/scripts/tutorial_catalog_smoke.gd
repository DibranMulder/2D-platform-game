extends SceneTree

const TutorialCatalogScript := preload("res://scripts/tutorial_catalog.gd")
const ItemCatalogScript := preload("res://scripts/item_catalog.gd")
const EXPECTED_STEP_COUNT := 10
const EXPECTED_STARTER_ITEM_COUNT := 10


func _initialize() -> void:
    var tutorial_catalog := TutorialCatalogScript.new()
    var item_catalog := ItemCatalogScript.new()
    var failures: Array[String] = []
    var steps: Array[Dictionary] = tutorial_catalog.all_steps()
    var starter_kit: Array[Dictionary] = tutorial_catalog.starter_kit()

    if steps.size() != EXPECTED_STEP_COUNT:
        failures.append("Expected %s tutorial steps, found %s." % [EXPECTED_STEP_COUNT, steps.size()])
    if starter_kit.size() != EXPECTED_STARTER_ITEM_COUNT:
        failures.append(
            "Expected %s starter items, found %s." % [EXPECTED_STARTER_ITEM_COUNT, starter_kit.size()]
        )

    var seen_step_ids: Dictionary = {}
    for step: Dictionary in steps:
        var step_id := str(step.get("id", ""))
        if step_id.is_empty() or seen_step_ids.has(step_id):
            failures.append("Tutorial step IDs must be non-empty and unique: %s." % step_id)
        seen_step_ids[step_id] = true
        var image_path := str(step.get("image_path", ""))
        if not FileAccess.file_exists(image_path):
            failures.append("Missing tutorial texture for %s: %s." % [step_id, image_path])
        elif ResourceLoader.exists(image_path) and tutorial_catalog.texture_for_step(step_id) == null:
            failures.append("Tutorial texture did not load for %s: %s." % [step_id, image_path])

    var seen_item_ids: Dictionary = {}
    for entry: Dictionary in starter_kit:
        var item_id := str(entry.get("item_id", ""))
        if item_id.is_empty() or seen_item_ids.has(item_id):
            failures.append("Starter item IDs must be non-empty and unique: %s." % item_id)
        seen_item_ids[item_id] = true
        if item_catalog.item(item_id).is_empty():
            failures.append("Starter item is absent from the item catalogue: %s." % item_id)
        if int(entry.get("quantity", 0)) < 1:
            failures.append("Starter item quantity must be positive: %s." % item_id)

    if not failures.is_empty():
        for failure: String in failures:
            push_error(failure)
        quit(1)
        return

    print("Tutorial catalogue smoke test passed: 10 steps, 10 textures, 10 starter items.")
    quit(0)
