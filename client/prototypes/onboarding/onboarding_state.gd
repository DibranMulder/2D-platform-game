class_name PrototypeOnboardingState
extends RefCounted

const MAX_HEROES_PER_ACCOUNT := 8

const LINEAGES: Array[Dictionary] = [
    {
        "id": "tidekin",
        "name": "Tidekin",
        "allegiance": "light",
        "homeland": "The Sea",
        "summary": "Amphibious navigators with frog-like agility and sea-born traditions.",
    },
    {
        "id": "human",
        "name": "Humans",
        "allegiance": "light",
        "homeland": "The Open Lands",
        "summary": "Adaptable builders and explorers of the broad terrestrial kingdoms.",
    },
    {
        "id": "grove_centaur",
        "name": "Grove Centaurs",
        "allegiance": "light",
        "homeland": "The Elder Forests",
        "summary": "Swift forest guardians bound to ancient groves and living paths.",
    },
    {
        "id": "aeralith",
        "name": "Aeralith",
        "allegiance": "light",
        "homeland": "The Sky Reaches",
        "summary": "Wind-shaped highlanders who travel between floating sky realms.",
    },
    {
        "id": "crag_troll",
        "name": "Crag Trolls",
        "allegiance": "dark",
        "homeland": "The Broken Mountains",
        "summary": "Massive mountain clans hardened by stone, storms, and thin air.",
    },
    {
        "id": "deep_goblin",
        "name": "Deep Goblins",
        "allegiance": "dark",
        "homeland": "The Underdeep",
        "summary": "Cunning tunnel societies who thrive among machines, fungi, and ore.",
    },
    {
        "id": "sunscour",
        "name": "Sunscour Legion",
        "allegiance": "dark",
        "homeland": "The Ember Desert",
        "summary": "Disciplined desert soldiers shaped by heat, distance, and survival.",
    },
    {
        "id": "rimeborn",
        "name": "Rimeborn",
        "allegiance": "dark",
        "homeland": "The Ice Lands",
        "summary": "Cold-adapted clans who endure the long night beyond the glaciers.",
    },
]

var _accounts: Dictionary = {}
var _active_email := ""
var _reserved_name_keys: Dictionary = {}


func _init() -> void:
    _accounts["demo@realm.test"] = {
        "email": "demo@realm.test",
        "password": "prototype123",
        "heroes": [],
    }


func create_account(email: String, password: String, confirmation: String) -> Dictionary:
    var email_key := _normalize_email(email)
    if not _valid_email(email_key):
        return _failure("Enter a valid email address.")
    if password.length() < 12:
        return _failure("Use at least 12 characters for the prototype password.")
    if password != confirmation:
        return _failure("The passwords do not match.")
    if _accounts.has(email_key):
        return _failure("An account with that email already exists.")

    _accounts[email_key] = {
        "email": email_key,
        "password": password,
        "heroes": [],
    }
    _active_email = email_key
    return {"ok": true}


func login(email: String, password: String) -> Dictionary:
    var email_key := _normalize_email(email)
    if not _accounts.has(email_key) or _accounts[email_key]["password"] != password:
        return _failure("Email or password is incorrect.")
    _active_email = email_key
    return {"ok": true}


func logout() -> void:
    _active_email = ""


func active_email() -> String:
    return _active_email


func heroes() -> Array:
    if _active_email.is_empty() or not _accounts.has(_active_email):
        return []
    return (_accounts[_active_email]["heroes"] as Array).duplicate(true)


func create_hero(hero_name: String, lineage_id: String) -> Dictionary:
    if _active_email.is_empty():
        return _failure("Log in before creating a Hero.")

    var account_heroes := _accounts[_active_email]["heroes"] as Array
    if account_heroes.size() >= MAX_HEROES_PER_ACCOUNT:
        return _failure("This Account already has eight Heroes.")

    var clean_name := " ".join(hero_name.strip_edges().split(" ", false))
    if not _valid_hero_name(clean_name):
        return _failure("Use 3–16 letters; a single space, apostrophe, or hyphen is allowed.")

    var name_key := clean_name.to_lower()
    if _reserved_name_keys.has(name_key):
        return _failure("That Hero name is already taken.")

    var lineage := lineage_by_id(lineage_id)
    if lineage.is_empty():
        return _failure("Choose a Lineage.")

    var hero := {
        "name": clean_name,
        "lineage_id": lineage["id"],
        "lineage_name": lineage["name"],
        "allegiance": lineage["allegiance"],
        "homeland": lineage["homeland"],
    }
    account_heroes.append(hero)
    _reserved_name_keys[name_key] = true
    return {"ok": true, "hero": hero.duplicate(true)}


func lineages_for(allegiance: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for lineage: Dictionary in LINEAGES:
        if lineage["allegiance"] == allegiance:
            result.append(lineage.duplicate(true))
    return result


func lineage_by_id(lineage_id: String) -> Dictionary:
    for lineage: Dictionary in LINEAGES:
        if lineage["id"] == lineage_id:
            return lineage.duplicate(true)
    return {}


func _normalize_email(email: String) -> String:
    return email.strip_edges().to_lower()


func _valid_email(email: String) -> bool:
    var at_index := email.find("@")
    return at_index > 0 and email.find(".", at_index) > at_index + 1 and not email.contains(" ")


func _valid_hero_name(hero_name: String) -> bool:
    if hero_name.length() < 3 or hero_name.length() > 16:
        return false
    var expression := RegEx.new()
    expression.compile("^[A-Za-z]+(?:[ '-][A-Za-z]+)*$")
    return expression.search(hero_name) != null


func _failure(message: String) -> Dictionary:
    return {"ok": false, "error": message}
