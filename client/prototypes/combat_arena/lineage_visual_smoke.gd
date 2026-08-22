extends SceneTree

const ARENA := "res://prototypes/combat_arena/combat_arena.tscn"
const HERO_REGION := Rect2i(210, 430, 160, 210)
const LINEAGES: Array[Dictionary] = [
    {"id": "human", "name": "Humans", "allegiance": "light"},
    {"id": "tidekin", "name": "Tidekin", "allegiance": "light"},
    {"id": "grove_centaur", "name": "Grove Centaurs", "allegiance": "light"},
    {"id": "aeralith", "name": "Aeralith", "allegiance": "light"},
    {"id": "crag_troll", "name": "Crag Trolls", "allegiance": "dark"},
    {"id": "deep_goblin", "name": "Deep Goblins", "allegiance": "dark"},
    {"id": "sunscour", "name": "Sunscour", "allegiance": "dark"},
    {"id": "rimeborn", "name": "Rimeborn", "allegiance": "dark"},
]


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var rendered_regions: Dictionary = {}
    var failures: Array[String] = []

    for lineage: Dictionary in LINEAGES:
        var pixels := await _capture_hero(lineage)
        if pixels.is_empty():
            failures.append("%s produced no rendered pixels" % lineage["name"])
            continue
        for prior_lineage_id: String in rendered_regions:
            if rendered_regions[prior_lineage_id] == pixels:
                failures.append(
                    "%s rendered identically to %s" % [lineage["id"], prior_lineage_id]
                )
        rendered_regions[lineage["id"]] = pixels

    if not failures.is_empty():
        for failure: String in failures:
            push_error(failure)
        quit(1)
        return

    print("Lineage visual smoke test passed for all eight battle silhouettes.")
    quit(0)


func _capture_hero(lineage: Dictionary) -> PackedByteArray:
    set_meta("selected_hero", {
        "name": "%s Check" % lineage["name"],
        "lineage_id": lineage["id"],
        "lineage_name": lineage["name"],
        "allegiance": lineage["allegiance"],
    })
    change_scene_to_file(ARENA)
    await process_frame
    await process_frame
    await process_frame
    var viewport_image := root.get_viewport().get_texture().get_image()
    if viewport_image == null or viewport_image.is_empty():
        return PackedByteArray()
    return viewport_image.get_region(HERO_REGION).get_data()
