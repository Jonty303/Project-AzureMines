extends RefCounted
## Shared persistent campaign state; exploration/combat/quests never own separate ledgers.
const SAVE_VERSION := 1
const DEFAULT_SAVE := "user://azure_mines_slot1.json"
const HERO_IDS := ["alden", "elyra", "brunna", "pip"]

var gold_gp := 0
var xp_by_character := {"alden": 0, "elyra": 0, "brunna": 0, "pip": 0}
var completed_encounters: Dictionary = {}
var flags: Dictionary = {}
var visited: Dictionary = {}
var known_routes: Dictionary = {}
var current_location := ""
var clues: Array = []
var events: Array = []
var quests: Dictionary = {}
var checks: Dictionary = {}
var npc_registry: Dictionary = {}
var party_snapshots: Dictionary = {}
var check_rng := RandomNumberGenerator.new()


func _init() -> void:
    check_rng.seed = 872032
    npc_registry["hesk_roadwatch"] = {
        "alive": true, "state": "unmet", "whereabouts": "wagon_clearing",
        "attitude": "wary", "trust": 0, "grievances": [], "promises": [],
        "hp": 9, "max_hp": 9, "first_aid_attempted": false
    }
    npc_registry["mara_venn"] = {
        "alive": true, "state": "active", "whereabouts": "harrowford_market",
        "attitude": "neutral", "trust": 0, "grievances": [], "promises": []
    }


func record_event(id: String, description: String) -> bool:
    if id.is_empty():
        return false
    for entry in events:
        if str(entry.get("id", "")) == id:
            return false
    events.append({"id": id, "text": description})
    return true


func discover_clue(id: String, description: String, certainty: String = "confirmed") -> bool:
    if id.is_empty() or certainty not in ["confirmed", "rumour", "suspected"]:
        return false
    for entry in clues:
        if str(entry.get("id", "")) == id:
            return false
    clues.append({"id": id, "text": description, "certainty": certainty})
    return true


func mark_visited(location_id: String) -> void:
    visited[location_id] = true
    current_location = location_id


func reveal_route(location_id: String) -> void:
    known_routes[location_id] = true


func knows_location(location_id: String) -> bool:
    return visited.has(location_id) or known_routes.has(location_id)


func set_npc(id: String, updates: Dictionary) -> bool:
    if not npc_registry.has(id):
        return false
    var state: Dictionary = npc_registry[id]
    for key in updates.keys():
        if str(key) not in ["alive", "state", "whereabouts", "attitude", "trust", "grievances", "promises", "hp", "max_hp", "first_aid_attempted"]:
            return false
    for key in updates:
        state[key] = updates[key]
    npc_registry[id] = state
    return true


func award_once(encounter_id: String, total_xp: int, coin: int) -> Dictionary:
    if encounter_id.is_empty() or completed_encounters.has(encounter_id):
        return {"already_claimed": true, "xp_total": 0, "xp_each": 0, "gold_gp": 0, "consumables": [], "named_items": []}
    if total_xp < 0 or coin < 0 or total_xp % HERO_IDS.size() != 0:
        return {"error": true, "xp_total": 0, "xp_each": 0, "gold_gp": 0, "consumables": [], "named_items": []}
    var each: int = total_xp / HERO_IDS.size()
    for id in HERO_IDS:
        xp_by_character[id] = int(xp_by_character[id]) + each
    gold_gp += coin
    completed_encounters[encounter_id] = true
    record_event("victory_" + encounter_id, "The party overcame the ambush on the Old Trade Road.")
    return {"already_claimed": false, "xp_total": total_xp, "xp_each": each,
        "gold_gp": coin, "consumables": [], "named_items": []}


func capture_party(actors: Dictionary) -> void:
    for id in HERO_IDS:
        if not actors.has(id):
            continue
        var actor: Dictionary = actors[id]
        party_snapshots[id] = {
            "hp": int(actor.get("hp", 0)), "max_hp": int(actor.get("max_hp", 0)),
            "combat_state": str(actor.get("combat_state", "active")),
            "spell_slots_remaining": int(actor.get("spell_slots_remaining", 0)),
            "death_successes": int(actor.get("death_successes", 0)),
            "death_failures": int(actor.get("death_failures", 0)),
            "second_wind_used": bool(actor.get("second_wind_used", false)),
            "hit_dice_remaining": int(actor.get("hit_dice_remaining", 0)),
            "reaction_used": bool(actor.get("reaction_used", false)),
            "class_resources": actor.get("class_resources", {}).duplicate(true),
            "conditions": actor.get("conditions", []).duplicate(true)
        }


func restore_party(actors: Dictionary) -> void:
    for id in HERO_IDS:
        if not party_snapshots.has(id) or not actors.has(id):
            continue
        var actor: Dictionary = actors[id]
        var saved: Dictionary = party_snapshots[id]
        for property in ["hp", "combat_state", "spell_slots_remaining", "death_successes", "death_failures", "second_wind_used", "hit_dice_remaining", "reaction_used", "class_resources", "conditions"]:
            if saved.has(property):
                actor[property] = saved[property]
        actors[id] = actor


func capture_npc_from_combat(actors: Dictionary) -> void:
    if not actors.has("goblin_blade"):
        return
    var actor: Dictionary = actors["goblin_blade"]
    if actor.get("npc_id", "") != "hesk_roadwatch":
        return
    var state: String = str(actor.get("combat_state", "active"))
    var npc: Dictionary = npc_registry["hesk_roadwatch"]
    npc["state"] = state
    npc["alive"] = state != "dead"
    npc["whereabouts"] = "wagon_clearing"
    npc["hp"] = int(actor.get("hp", 0))
    npc["max_hp"] = int(actor.get("max_hp", 9))
    npc["first_aid_attempted"] = bool(actor.get("first_aid_attempted", false))
    npc_registry["hesk_roadwatch"] = npc
    record_event("hesk_" + state, "Hesk, the shield-bearing goblin, was last seen %s." % state)


func restore_named_npcs(actors: Dictionary) -> void:
    if not actors.has("goblin_blade") or not npc_registry.has("hesk_roadwatch"):
        return
    var npc: Dictionary = npc_registry["hesk_roadwatch"]
    if npc.get("state", "") == "unmet":
        return
    var actor: Dictionary = actors["goblin_blade"]
    actor["combat_state"] = str(npc.get("state", "active"))
    actor["hp"] = int(npc.get("hp", 0))
    actor["first_aid_attempted"] = bool(npc.get("first_aid_attempted", false))
    actors["goblin_blade"] = actor


func export_data(stage: String) -> Dictionary:
    return {
        "version": SAVE_VERSION, "stage": stage,
        "gold_gp": gold_gp, "xp_by_character": xp_by_character.duplicate(true),
        "completed_encounters": completed_encounters.duplicate(true),
        "flags": flags.duplicate(true), "visited": visited.duplicate(true),
        "known_routes": known_routes.duplicate(true), "current_location": current_location,
        "clues": clues.duplicate(true), "events": events.duplicate(true),
        "quests": quests.duplicate(true), "checks": checks.duplicate(true),
        "npc_registry": npc_registry.duplicate(true),
        "party_snapshots": party_snapshots.duplicate(true),
        "rng_state": str(check_rng.state)
    }


func import_data(data: Dictionary) -> bool:
    if int(data.get("version", -1)) != SAVE_VERSION:
        return false
    if not data.get("completed_encounters") is Dictionary or not data.get("npc_registry") is Dictionary:
        return false
    if not data.get("visited") is Dictionary or not data.get("xp_by_character") is Dictionary:
        return false
    if not data.get("clues") is Array or not data.get("events") is Array:
        return false
    for id in HERO_IDS:
        if not data["xp_by_character"].has(id):
            return false
    # Validate first, then assign; untrusted saves cannot inject arbitrary arbitrary stages.
    if str(data.get("stage", "")) not in ["victory", "aftermath", "exploration"]:
        return false
    gold_gp = maxi(0, int(data.get("gold_gp", 0)))
    xp_by_character = data["xp_by_character"].duplicate(true)
    completed_encounters = data["completed_encounters"].duplicate(true)
    flags = data.get("flags", {}).duplicate(true)
    visited = data["visited"].duplicate(true)
    known_routes = data.get("known_routes", {}).duplicate(true)
    current_location = str(data.get("current_location", ""))
    clues = data["clues"].duplicate(true)
    events = data["events"].duplicate(true)
    quests = data.get("quests", {}).duplicate(true)
    checks = data.get("checks", {}).duplicate(true)
    npc_registry = data["npc_registry"].duplicate(true)
    party_snapshots = data.get("party_snapshots", {}).duplicate(true)
    check_rng.state = int(data.get("rng_state", "872032"))
    return true


func save_to_file(stage: String, path: String = DEFAULT_SAVE) -> bool:
    if stage not in ["victory", "aftermath", "exploration"]:
        return false
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(export_data(stage), "  "))
    file.flush()
    file.close()
    return true


func load_from_file(path: String = DEFAULT_SAVE) -> String:
    if not FileAccess.file_exists(path):
        return ""
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not data is Dictionary or not import_data(data):
        return ""
    return str(data["stage"])
