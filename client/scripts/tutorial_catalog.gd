class_name GameTutorialCatalog
extends RefCounted

const TUTORIAL_DATA_PATH := "res://data/tutorial.json"

var _steps: Dictionary = {}
var _ordered_steps: Array[Dictionary] = []
var _starter_kit: Array[Dictionary] = []


func _init() -> void:
    reload()


func reload() -> void:
    _steps.clear()
    _ordered_steps.clear()
    _starter_kit.clear()

    var file := FileAccess.open(TUTORIAL_DATA_PATH, FileAccess.READ)
    if file == null:
        push_error("Unable to open tutorial catalogue: %s" % TUTORIAL_DATA_PATH)
        return

    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary or not parsed.has("steps") or not parsed.has("starter_kit"):
        push_error("Invalid tutorial catalogue JSON: %s" % TUTORIAL_DATA_PATH)
        return

    for raw_step in parsed["steps"]:
        if not raw_step is Dictionary:
            continue
        var step_definition := (raw_step as Dictionary).duplicate(true)
        var step_id := str(step_definition.get("id", ""))
        if step_id.is_empty():
            continue
        _steps[step_id] = step_definition
        _ordered_steps.append(step_definition)

    for raw_entry in parsed["starter_kit"]:
        if raw_entry is Dictionary:
            _starter_kit.append((raw_entry as Dictionary).duplicate(true))


func step(step_id: String) -> Dictionary:
    return (_steps.get(step_id, {}) as Dictionary).duplicate(true)


func all_steps() -> Array[Dictionary]:
    return _ordered_steps.duplicate(true)


func starter_kit() -> Array[Dictionary]:
    return _starter_kit.duplicate(true)


func texture_for_step(step_id: String) -> Texture2D:
    var definition := step(step_id)
    var image_path := str(definition.get("image_path", ""))
    if image_path.is_empty() or not ResourceLoader.exists(image_path):
        return null
    return load(image_path) as Texture2D
