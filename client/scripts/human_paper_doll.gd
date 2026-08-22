class_name HumanPaperDoll
extends Node2D

## Shared animation clock and equipment state for a layered Human character.
## Each visual layer is an AnimatedSprite2D with matching animation/frame names.

const DRAW_ORDER := [
    "cape_back",
    "body",
    "legs",
    "feet",
    "chest",
    "hair",
    "head",
    "off_hand",
    "hands",
    "main_hand",
    "cape_front",
]

var _layers: Dictionary = {}
var _equipment: Dictionary = {}
var _animation := "idle"
var _catalog := GameItemCatalog.new()


func _ready() -> void:
    for layer_name: String in DRAW_ORDER:
        var layer := get_node_or_null(NodePath(layer_name)) as AnimatedSprite2D
        if layer != null:
            _layers[layer_name] = layer
    _synchronize_layers()


func set_equipment(equipment: Dictionary) -> void:
    _equipment = equipment.duplicate(true)
    if not _catalog.can_equip_together(
        str(_equipment.get("main_hand", "")),
        str(_equipment.get("off_hand", "")),
    ):
        _equipment["off_hand"] = ""
    _refresh_equipment_layers()


func play(animation_name: String) -> void:
    _animation = animation_name
    for layer in _layers.values():
        var sprite := layer as AnimatedSprite2D
        if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name):
            sprite.play(animation_name)


func set_facing_left(facing_left: bool) -> void:
    for layer in _layers.values():
        (layer as AnimatedSprite2D).flip_h = facing_left


func equipment() -> Dictionary:
    return _equipment.duplicate(true)


func _synchronize_layers() -> void:
    for index in DRAW_ORDER.size():
        if _layers.has(DRAW_ORDER[index]):
            var sprite := _layers[DRAW_ORDER[index]] as AnimatedSprite2D
            sprite.z_index = index
            sprite.frame_changed.connect(_on_reference_frame_changed.bind(sprite))
    play(_animation)


func _on_reference_frame_changed(source: AnimatedSprite2D) -> void:
    if source != _layers.get("body"):
        return
    for layer in _layers.values():
        var sprite := layer as AnimatedSprite2D
        if sprite != source and sprite.animation == source.animation:
            sprite.set_frame_and_progress(source.frame, source.frame_progress)


func _refresh_equipment_layers() -> void:
    # Layer SpriteFrames are loaded by the character scene from the item record's
    # sprite resource. Missing art deliberately hides only that equipment layer.
    for layer_name in ["head", "chest", "hands", "legs", "feet", "off_hand", "main_hand"]:
        _show_layer_when_equipped(layer_name, str(_equipment.get(layer_name, "")))
    var cape_id := str(_equipment.get("cape", ""))
    _show_layer_when_equipped("cape_back", cape_id)
    _show_layer_when_equipped("cape_front", cape_id)
    if _layers.has("hair"):
        (_layers["hair"] as AnimatedSprite2D).visible = str(_equipment.get("head", "")).is_empty()


func _show_layer_when_equipped(layer_name: String, item_id: String) -> void:
    if not _layers.has(layer_name):
        return
    (_layers[layer_name] as AnimatedSprite2D).visible = not item_id.is_empty()
