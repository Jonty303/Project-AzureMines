extends RefCounted
## Authored choice graph: no executable content or arbitrary mutations in adventure JSON.
const PATH := "res://adventures/test_adventure/exploration_v08.json"
const Dice = preload("res://core/dice_roller.gd")

var locations: Dictionary = {}
var state: RefCounted


func _init(campaign: RefCounted) -> void:
    state = campaign
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1:
        push_error("Invalid narrative adventure data")
        return
    for location_variant in parsed.get("locations", []):
        var location: Dictionary = location_variant
        locations[str(location["id"])] = location


func begin() -> bool:
    if locations.is_empty():
        return false
    state.mark_visited("wagon_clearing")
    state.reveal_route("town_road")
    state.record_event("arrived_at_wagon", "The party survived the wagon ambush on the Old Trade Road.")
    return true


func current_scene() -> Dictionary:
    var id: String = str(state.current_location)
    if not locations.has(id):
        return {}
    var scene: Dictionary = locations[id].duplicate(true)
    if state.visited.has(id) and state.flags.get("revisited_" + id, false):
        scene["description"] = scene.get("revisit_text", scene.get("description", ""))
    return scene


func available_choices() -> Array[Dictionary]:
    var scene: Dictionary = current_scene()
    var result: Array[Dictionary] = []
    for raw in scene.get("choices", []):
        var choice: Dictionary = raw
        if choice.has("requires_flag") and not bool(state.flags.get(str(choice["requires_flag"]), false)):
            continue
        if choice.has("unless_flag") and bool(state.flags.get(str(choice["unless_flag"]), false)):
            continue
        if choice.has("requires_known") and not state.knows_location(str(choice["requires_known"])):
            continue
        if choice.get("once", false) and state.flags.has("choice_" + str(choice["id"])):
            continue
        result.append(choice)
    return result


func choose(choice_id: String, party: Dictionary) -> Dictionary:
    var choice: Dictionary = {}
    for candidate in available_choices():
        if str(candidate["id"]) == choice_id:
            choice = candidate
            break
    if choice.is_empty():
        return {"ok": false, "text": "That option is not available."}
    var kind: String = str(choice.get("type", ""))
    var identifier: String = str(choice["id"])
    if kind == "travel":
        var destination: String = str(choice.get("target", ""))
        if not locations.has(destination):
            return {"ok": false, "text": "Unknown destination."}
        # A route is available only if explicitly authored as a visible choice.
        var has_visited: bool = state.visited.has(destination)
        state.mark_visited(destination)
        state.reveal_route(destination)
        if has_visited:
            state.flags["revisited_" + destination] = true
        state.record_event("visit_" + destination, "The party reached %s." % locations[destination]["title"])
        return {"ok": true, "text": "", "travel": destination}
    if kind == "effects":
        if not _validate_effects(choice.get("effects", [])):
            return {"ok": false, "text": "Adventure effect data invalid."}
        _apply_effects(choice.get("effects", []))
        if choice.get("once", false):
            state.flags["choice_" + identifier] = true
        return {"ok": true, "text": str(choice.get("result", ""))}
    if kind == "check":
        if state.checks.has(identifier):
            return {"ok": false, "text": "This check has already been attempted."}
        var ability: String = str(choice.get("ability", ""))
        var skill: String = str(choice.get("skill", ""))
        var dc: int = int(choice.get("dc", 0))
        if ability not in ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"] or dc < 1 or dc > 30:
            return {"ok": false, "text": "Adventure check data invalid."}
        if not _validate_effects(choice.get("success", {}).get("effects", [])) or not _validate_effects(choice.get("failure", {}).get("effects", [])):
            return {"ok": false, "text": "Adventure check effects invalid."}
        var best_id := ""
        var best_bonus := -999
        for id in ["alden", "elyra", "brunna", "pip"]:
            if not party.has(id) or int(party[id].get("hp", 0)) <= 0:
                continue
            var actor: Dictionary = party[id]
            var bonus: int = Dice.ability_modifier(int(actor.get("ability_scores", {}).get(ability, 10)))
            if actor.get("skill_proficiencies", []).has(skill):
                bonus += int(actor.get("proficiency_bonus", 2))
            if bonus > best_bonus:
                best_bonus = bonus
                best_id = id
        if best_id.is_empty():
            return {"ok": false, "text": "No conscious adventurer can attempt this check."}
        var die: int = Dice.roll_d20(state.check_rng)
        var total: int = die + best_bonus
        var won: bool = total >= dc
        state.checks[identifier] = {"character_id": best_id, "die": die, "bonus": best_bonus,
            "total": total, "dc": dc, "success": won}
        state.flags["choice_" + identifier] = true
        var outcome: Dictionary = choice.get("success", {}) if won else choice.get("failure", {})
        _apply_effects(outcome.get("effects", []))
        var heading: String = "%s: %s (%s) %d + %d = %d vs DC %d — %s." % [
            str(party[best_id].get("name", best_id)), ability.capitalize(),
            skill.capitalize(), die, best_bonus, total, dc, "SUCCESS" if won else "FAILURE"
        ]
        state.record_event("check_" + identifier, heading)
        return {"ok": true, "text": heading + "\n\n" + str(outcome.get("text", "")), "check": true}
    return {"ok": false, "text": "Unsupported adventure choice."}


func _validate_effects(effects: Array) -> bool:
    # Reject an entire batch before applying any action to avoid partial mutations.
    for item in effects:
        if not item is Dictionary:
            return false
        var kind: String = str(item.get("type", ""))
        if kind not in ["flag", "clue", "event", "reveal_route", "quest", "npc"]:
            return false
        if kind in ["clue", "event", "reveal_route", "quest", "npc"] and str(item.get("id", "")).is_empty():
            return false
        if kind == "flag" and str(item.get("key", "")).is_empty():
            return false
        if kind == "reveal_route" and not locations.has(str(item["id"])):
            return false
        if kind == "npc" and (not state.npc_registry.has(str(item["id"])) or not item.has("attitude")):
            return false
    return true


func _apply_effects(effects: Array) -> void:
    for item in effects:
        match str(item["type"]):
            "flag":
                state.flags[str(item["key"])] = item.get("value", true)
            "clue":
                state.discover_clue(str(item["id"]), str(item.get("text", "")), str(item.get("certainty", "confirmed")))
            "event":
                state.record_event(str(item["id"]), str(item.get("text", "")))
            "reveal_route":
                state.reveal_route(str(item["id"]))
            "quest":
                state.quests[str(item["id"])] = str(item.get("status", "offered"))
            "npc":
                var current: Dictionary = state.npc_registry[str(item["id"])]
                state.set_npc(str(item["id"]), {
                    "attitude": str(item["attitude"]),
                    "trust": int(current.get("trust", 0)) + int(item.get("trust", 0))
                })
