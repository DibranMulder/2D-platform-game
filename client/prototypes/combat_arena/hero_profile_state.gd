class_name PrototypeHeroProfileState
extends RefCounted

const MAX_DISCIPLINE_LEVEL := 99
const POUCH_SIZE := 24

const DISCIPLINES: Array[Dictionary] = [
    {"id": "attack", "name": "Attack", "family": "Martial", "description": "Weapon control and accuracy."},
    {"id": "strength", "name": "Strength", "family": "Martial", "description": "Physical force and carrying power."},
    {"id": "defense", "name": "Defense", "family": "Martial", "description": "Armor use and damage mitigation."},
    {"id": "agility", "name": "Agility", "family": "Martial", "description": "Traversal, recovery, and evasion."},
    {"id": "stamina", "name": "Stamina", "family": "Martial", "description": "Health, endurance, and sustained Guard."},
    {"id": "focus", "name": "Focus", "family": "Mystic", "description": "Concentration and ability reliability."},
    {"id": "willpower", "name": "Willpower", "family": "Mystic", "description": "Resistance to control and corruption."},
    {"id": "arcana", "name": "Arcana", "family": "Mystic", "description": "Understanding supernatural effects."},
    {"id": "survival", "name": "Survival", "family": "World", "description": "Recovery, hazards, tracking, and food."},
    {"id": "gathering", "name": "Gathering", "family": "World", "description": "Harvesting natural and magical resources."},
    {"id": "crafting", "name": "Crafting", "family": "World", "description": "Producing, repairing, and improving items."},
    {"id": "exploration", "name": "Exploration", "family": "World", "description": "Discovering routes, secrets, and portals."},
]

const EQUIPMENT_SLOTS: Array[Dictionary] = [
    {"id": "head", "name": "Head"},
    {"id": "shoulders", "name": "Shoulders"},
    {"id": "chest", "name": "Chest"},
    {"id": "hands", "name": "Hands"},
    {"id": "main_hand", "name": "Main Hand"},
    {"id": "off_hand", "name": "Off Hand"},
    {"id": "legs", "name": "Legs"},
    {"id": "feet", "name": "Feet"},
    {"id": "neck", "name": "Neck"},
    {"id": "ring", "name": "Ring"},
    {"id": "cape", "name": "Cape"},
    {"id": "relic", "name": "Relic"},
]

const ITEMS := {
    "rusty_sword": {"name": "Rusty Sword", "slot": "main_hand", "icon": "SW", "quality": "common", "description": "+2 Attack · A dependable beginning."},
    "traveler_tunic": {"name": "Traveler Tunic", "slot": "chest", "icon": "TU", "quality": "common", "description": "+1 Defense · Weather-worn cloth armor."},
    "leather_boots": {"name": "Leather Boots", "slot": "feet", "icon": "BT", "quality": "common", "description": "+1 Agility · Soft steps on old roads."},
    "bronze_helm": {"name": "Bronze Helm", "slot": "head", "icon": "HM", "quality": "uncommon", "description": "+3 Defense · Scarred but serviceable."},
    "driftwood_buckler": {"name": "Driftwood Buckler", "slot": "off_hand", "icon": "SH", "quality": "uncommon", "description": "+4 Guard stability · Tidekin craft."},
    "wind_cape": {"name": "Wind-thread Cape", "slot": "cape", "icon": "CP", "quality": "rare", "description": "+3 Agility · Always stirs in still air."},
    "rime_ring": {"name": "Rimeglass Ring", "slot": "ring", "icon": "RG", "quality": "rare", "description": "+2 Willpower · Cold to the touch."},
    "potion": {"name": "Redleaf Potion", "slot": "", "icon": "HP", "quality": "common", "description": "Restores health when consumed."},
    "frog_pearl": {"name": "Frog Pearl", "slot": "", "icon": "FP", "quality": "uncommon", "description": "A luminous pearl from the Sea."},
    "crag_ore": {"name": "Crag Ore", "slot": "", "icon": "OR", "quality": "common", "description": "Dense ore gathered in the mountains."},
    "rations": {"name": "Dried Rations", "slot": "", "icon": "FD", "quality": "common", "description": "Simple food for long journeys."},
    "sky_feather": {"name": "Sky Feather", "slot": "", "icon": "SF", "quality": "rare", "description": "A weightless feather from the Sky Reaches."},
}

const TALENTS: Array[Dictionary] = [
    {"id": "keen_edge", "name": "Keen Edge", "branch": "Blade", "tier": 0, "cost": 1, "level": 1, "requires": "", "description": "+5% Sword Attack damage."},
    {"id": "decisive_blow", "name": "Decisive Blow", "branch": "Blade", "tier": 1, "cost": 2, "level": 10, "requires": "keen_edge", "description": "Power Strike staggers longer."},
    {"id": "sweeping_arc", "name": "Sweeping Arc", "branch": "Blade", "tier": 2, "cost": 3, "level": 20, "requires": "decisive_blow", "description": "Whirlwind gains reach."},
    {"id": "executioner", "name": "Executioner", "branch": "Blade", "tier": 3, "cost": 4, "level": 35, "requires": "sweeping_arc", "description": "Deal more damage to wounded enemies."},
    {"id": "firm_guard", "name": "Firm Guard", "branch": "Guardian", "tier": 0, "cost": 1, "level": 1, "requires": "", "description": "Guard consumes less Stamina."},
    {"id": "counterstance", "name": "Counterstance", "branch": "Guardian", "tier": 1, "cost": 2, "level": 10, "requires": "firm_guard", "description": "A perfect Guard empowers the next strike."},
    {"id": "iron_wall", "name": "Iron Wall", "branch": "Guardian", "tier": 2, "cost": 3, "level": 20, "requires": "counterstance", "description": "Guard also protects from behind."},
    {"id": "last_stand", "name": "Last Stand", "branch": "Guardian", "tier": 3, "cost": 4, "level": 35, "requires": "iron_wall", "description": "Survive one otherwise fatal hit."},
    {"id": "fleet_step", "name": "Fleet Step", "branch": "Wayfarer", "tier": 0, "cost": 1, "level": 1, "requires": "", "description": "+5% movement speed."},
    {"id": "aerial_control", "name": "Aerial Control", "branch": "Wayfarer", "tier": 1, "cost": 2, "level": 10, "requires": "fleet_step", "description": "Steer more quickly while airborne."},
    {"id": "relentless_lunge", "name": "Relentless Lunge", "branch": "Wayfarer", "tier": 2, "cost": 3, "level": 20, "requires": "aerial_control", "description": "Lunge resets after a defeat."},
    {"id": "renewing_wind", "name": "Renewing Wind", "branch": "Wayfarer", "tier": 3, "cost": 4, "level": 35, "requires": "relentless_lunge", "description": "Second Wind also restores Stamina."},
]

var _discipline_xp: Dictionary = {}
var _purchased_talents: Dictionary = {}
var _pouch: Array = []
var _equipment: Dictionary = {}


func _init() -> void:
    var starting_levels := {
        "attack": 10,
        "strength": 9,
        "defense": 8,
        "agility": 9,
        "stamina": 10,
        "focus": 7,
        "willpower": 7,
        "arcana": 5,
        "survival": 8,
        "gathering": 6,
        "crafting": 6,
        "exploration": 8,
    }
    for discipline: Dictionary in DISCIPLINES:
        var discipline_id := str(discipline["id"])
        _discipline_xp[discipline_id] = xp_threshold(int(starting_levels[discipline_id]))

    _pouch.resize(POUCH_SIZE)
    _pouch.fill(null)
    _set_pouch(0, "bronze_helm", 1)
    _set_pouch(1, "driftwood_buckler", 1)
    _set_pouch(2, "wind_cape", 1)
    _set_pouch(3, "rime_ring", 1)
    _set_pouch(4, "potion", 3)
    _set_pouch(5, "frog_pearl", 1)
    _set_pouch(6, "crag_ore", 8)
    _set_pouch(7, "rations", 5)
    _set_pouch(8, "sky_feather", 2)

    for slot: Dictionary in EQUIPMENT_SLOTS:
        _equipment[str(slot["id"])] = ""
    _equipment["main_hand"] = "rusty_sword"
    _equipment["chest"] = "traveler_tunic"
    _equipment["feet"] = "leather_boots"


func xp_threshold(level: int) -> int:
    var bounded_level := clampi(level, 1, MAX_DISCIPLINE_LEVEL)
    var steps := bounded_level - 1
    return 75 * steps * steps + 25 * steps


func discipline_level(discipline_id: String) -> int:
    var xp := int(_discipline_xp.get(discipline_id, 0))
    for level in range(2, MAX_DISCIPLINE_LEVEL + 1):
        if xp < xp_threshold(level):
            return level - 1
    return MAX_DISCIPLINE_LEVEL


func discipline_xp(discipline_id: String) -> int:
    return int(_discipline_xp.get(discipline_id, 0))


func total_level() -> int:
    var result := 0
    for discipline: Dictionary in DISCIPLINES:
        result += discipline_level(str(discipline["id"]))
    return result


func overall_level() -> int:
    return mini(MAX_DISCIPLINE_LEVEL, total_level() / DISCIPLINES.size())


func earned_talent_points() -> int:
    return maxi(0, overall_level() - 1)


func spent_talent_points() -> int:
    var spent := 0
    for talent: Dictionary in TALENTS:
        if _purchased_talents.has(str(talent["id"])):
            spent += int(talent["cost"])
    return spent


func unspent_talent_points() -> int:
    return earned_talent_points() - spent_talent_points()


func award_xp(discipline_id: String, amount: int) -> Dictionary:
    if not _discipline_xp.has(discipline_id) or amount <= 0:
        return {"ok": false, "message": "Invalid Discipline XP award."}
    var old_level := discipline_level(discipline_id)
    _discipline_xp[discipline_id] = mini(
        xp_threshold(MAX_DISCIPLINE_LEVEL),
        int(_discipline_xp[discipline_id]) + amount,
    )
    var new_level := discipline_level(discipline_id)
    return {
        "ok": true,
        "old_level": old_level,
        "new_level": new_level,
        "message": "%s gains %s XP%s" % [
            _discipline_name(discipline_id),
            amount,
            " and reaches level %s!" % new_level if new_level > old_level else ".",
        ],
    }


func award_adventure_xp(amount: int = 1500) -> String:
    var level_ups := 0
    for discipline: Dictionary in DISCIPLINES:
        var result := award_xp(str(discipline["id"]), amount)
        if int(result["new_level"]) > int(result["old_level"]):
            level_ups += 1
    return "Adventure reward: +%s XP to every Discipline · %s level-ups." % [amount, level_ups]


func purchase_talent(talent_id: String) -> Dictionary:
    var talent := talent_by_id(talent_id)
    if talent.is_empty():
        return {"ok": false, "message": "Unknown Talent."}
    if _purchased_talents.has(talent_id):
        return {"ok": false, "message": "%s is already unlocked." % talent["name"]}
    if overall_level() < int(talent["level"]):
        return {"ok": false, "message": "Requires Overall Level %s." % talent["level"]}
    var prerequisite := str(talent["requires"])
    if not prerequisite.is_empty() and not _purchased_talents.has(prerequisite):
        return {"ok": false, "message": "Requires %s first." % talent_by_id(prerequisite)["name"]}
    if unspent_talent_points() < int(talent["cost"]):
        return {"ok": false, "message": "Not enough Talent Points."}
    _purchased_talents[talent_id] = true
    return {"ok": true, "message": "Unlocked %s." % talent["name"]}


func talent_by_id(talent_id: String) -> Dictionary:
    for talent: Dictionary in TALENTS:
        if talent["id"] == talent_id:
            return talent
    return {}


func owns_talent(talent_id: String) -> bool:
    return _purchased_talents.has(talent_id)


func pouch() -> Array:
    return _pouch.duplicate(true)


func equipment() -> Dictionary:
    return _equipment.duplicate(true)


func item(item_id: String) -> Dictionary:
    return (ITEMS.get(item_id, {}) as Dictionary).duplicate(true)


func equip_from_pouch(pouch_index: int) -> Dictionary:
    if pouch_index < 0 or pouch_index >= _pouch.size() or _pouch[pouch_index] == null:
        return {"ok": false, "message": "That pouch slot is empty."}
    var entry := _pouch[pouch_index] as Dictionary
    var item_id := str(entry["item_id"])
    var item_definition := item(item_id)
    var equipment_slot := str(item_definition.get("slot", ""))
    if equipment_slot.is_empty():
        return {"ok": false, "message": "%s cannot be equipped." % item_definition["name"]}

    var previous_item_id := str(_equipment[equipment_slot])
    _equipment[equipment_slot] = item_id
    if previous_item_id.is_empty():
        _pouch[pouch_index] = null
    else:
        _pouch[pouch_index] = {"item_id": previous_item_id, "quantity": 1}
    return {"ok": true, "message": "Equipped %s." % item_definition["name"]}


func unequip(equipment_slot: String) -> Dictionary:
    if not _equipment.has(equipment_slot) or str(_equipment[equipment_slot]).is_empty():
        return {"ok": false, "message": "That Equipment Slot is empty."}
    var free_index := _first_free_pouch_index()
    if free_index == -1:
        return {"ok": false, "message": "The Item Pouch is full."}
    var item_id := str(_equipment[equipment_slot])
    _pouch[free_index] = {"item_id": item_id, "quantity": 1}
    _equipment[equipment_slot] = ""
    return {"ok": true, "message": "Moved %s to the Item Pouch." % item(item_id)["name"]}


func _set_pouch(index: int, item_id: String, quantity: int) -> void:
    _pouch[index] = {"item_id": item_id, "quantity": quantity}


func _first_free_pouch_index() -> int:
    for index in _pouch.size():
        if _pouch[index] == null:
            return index
    return -1


func _discipline_name(discipline_id: String) -> String:
    for discipline: Dictionary in DISCIPLINES:
        if discipline["id"] == discipline_id:
            return str(discipline["name"])
    return discipline_id

