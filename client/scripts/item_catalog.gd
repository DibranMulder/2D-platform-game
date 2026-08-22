class_name GameItemCatalog
extends RefCounted

const ITEM_DATA_PATH := "res://data/items.json"

var _items: Dictionary = {}
var _ordered_items: Array[Dictionary] = []


func _init() -> void:
    reload()


func reload() -> void:
    _items.clear()
    _ordered_items.clear()
    var file := FileAccess.open(ITEM_DATA_PATH, FileAccess.READ)
    if file == null:
        push_error("Unable to open item catalogue: %s" % ITEM_DATA_PATH)
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary or not parsed.has("items"):
        push_error("Invalid item catalogue JSON: %s" % ITEM_DATA_PATH)
        return
    for raw_item in parsed["items"]:
        if not raw_item is Dictionary:
            continue
        var item_definition := (raw_item as Dictionary).duplicate(true)
        var item_id := str(item_definition.get("id", ""))
        if item_id.is_empty():
            continue
        _items[item_id] = item_definition
        _ordered_items.append(item_definition)


func item(item_id: String) -> Dictionary:
    return (_items.get(item_id, {}) as Dictionary).duplicate(true)


func all_items() -> Array[Dictionary]:
    return _ordered_items.duplicate(true)


func items_for_slot(slot: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for definition: Dictionary in _ordered_items:
        if str(definition.get("slot", "")) == slot:
            result.append(definition.duplicate(true))
    return result


func can_equip_together(main_hand_id: String, off_hand_id: String) -> bool:
    if main_hand_id.is_empty() or off_hand_id.is_empty():
        return true
    var main_hand := item(main_hand_id)
    var off_hand := item(off_hand_id)
    return (
        not main_hand.is_empty()
        and not off_hand.is_empty()
        and bool(main_hand.get("offhand_compatible", false))
        and str(off_hand.get("slot", "")) == "off_hand"
    )
