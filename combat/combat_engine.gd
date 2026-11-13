extends RefCounted
## Headless, fixture-driven v0.1 combat state. Rendering and UI do not live here.
## Movement, action economy and damage are deliberately small, not a full SRD implementation.

const Audit = preload("res://combat/combat_audit.gd")
const Dice = preload("res://core/dice_roller.gd")
const RulesMath = preload("res://combat/rules_math.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")
const PARTY_FIXTURE := "res://combat_lab/fixtures/party/level_01_v1.json"
const ENCOUNTER_FIXTURE := "res://combat_lab/fixtures/encounters/training_battle.json"
const FORMATIONS := {
    "line": {"alden": [3, 5], "brunna": [2, 5], "pip": [1, 5], "elyra": [0, 5]},
    "square": {"alden": [3, 4], "brunna": [3, 5], "elyra": [2, 4], "pip": [2, 5]},
    "diamond": {"alden": [3, 5], "brunna": [2, 4], "elyra": [2, 6], "pip": [1, 5]}
}

var encounter_id := "training_battle"
var encounter_name := "Wagon Camp — The First Ambush"
var initiative_disadvantaged_team := ""
var actors: Dictionary = {}
var walls: Array[Vector2i] = []
var difficult_terrain: Array[Vector2i] = []
var obstacles: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var blocked_cells: Array[Vector2i] = []
var sight_blockers: Array[Vector2i] = []
var cover_cells: Array[Vector2i] = []
var backdrop: Dictionary = {}
var deployment_active := false
var deployment_zone: Array[Vector2i] = []
var active_formation := ""
var grid_size := Vector2i(12, 10)
var turn_order: Array[String] = []
var events: Array[Dictionary] = []
var round_number := 1
var turn_index := 0
var action_used := false
var bonus_action_used := false
var slotted_cast_this_turn := false
var sneak_attack_used := false
var movement_used := 0
var dash_extra_squares := 0
var pending_reaction: Dictionary = {}
var pending_move: Dictionary = {}
var reaction_checked: Array[String] = []
var finished := false
var victor := ""
var rng := RandomNumberGenerator.new()


# Transient schema v1. No fixture is installed by production setup or spell menus.
var active_effects: Dictionary = {}
var condition_sources: Dictionary = {}
var effect_sequence := 0
var turn_serial := 0
var burning_targets: Dictionary = {}
var last_d20: Dictionary = {}
var committed_actions: Array[String] = []


func area_effects_at(cell: Vector2i) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for effect in active_effects.values():
        if effect["cells"].has(cell):
            result.append(effect.duplicate(true))
    return result


func has_area_effect_at(cell: Vector2i) -> bool:
    for effect in active_effects.values():
        if effect["cells"].has(cell):
            return true
    return false


func movement_cost(cell: Vector2i, actor_id: String = "") -> int:
    if cell in difficult_terrain:
        return 2
    for effect in active_effects.values():
        if effect["cells"].has(cell) and effect.get("difficult_terrain", false):
            if actors.get(actor_id, {}).get("traits", {}).get("web_walker", false) and effect["type"] in ["web", "test_web_area"]:
                continue
            return 2
    return 1


func has_condition(actor_id: String, condition: String) -> bool:
    return not condition_sources.get(actor_id, {}).get(condition, []).is_empty()


func condition_snapshot(actor_id: String) -> Dictionary:
    return condition_sources.get(actor_id, {}).duplicate(true)


func _apply_condition(actor_id: String, condition: String, effect_id: String) -> void:
    if not condition_sources.has(actor_id):
        condition_sources[actor_id] = {}
    if not condition_sources[actor_id].has(condition):
        condition_sources[actor_id][condition] = []
    var sources: Array = condition_sources[actor_id][condition]
    if sources.has(effect_id):
        return
    sources.append(effect_id)
    active_effects[effect_id]["applications"].append({"actor_id": actor_id, "condition": condition})
    _event("condition_applied", str(active_effects[effect_id]["source"]), actor_id,
        {"effect_id": effect_id, "condition": condition})


func _remove_condition(actor_id: String, condition: String, effect_id: String) -> void:
    var sources: Array = condition_sources.get(actor_id, {}).get(condition, [])
    if not sources.has(effect_id):
        return
    sources.erase(effect_id)
    if sources.is_empty():
        condition_sources[actor_id].erase(condition)
    if condition_sources[actor_id].is_empty():
        condition_sources.erase(actor_id)
    if active_effects.has(effect_id):
        active_effects[effect_id]["applications"].erase({"actor_id": actor_id, "condition": condition})
    _event("condition_removed", "", actor_id, {"effect_id": effect_id, "condition": condition})


func create_test_web_area(source_id: String, anchor: Vector2i, duration_rounds: int = 2,
        concentrating: bool = true, save_dc: int = 13) -> String:
    # Explicit fixture adapter; no production setup or spell menu invokes it.
    return create_area_effect(source_id, {
        "schema_version": 1, "type": "test_web_area", "anchor": anchor,
        "footprint": Vector2i(4, 4), "duration_rounds": duration_rounds,
        "concentration": concentrating, "save_dc": save_dc,
        "difficult_terrain": true, "condition": "restrained",
        "triggers": ["enter", "start_turn"]
    })


func create_area_effect(source_id: String, definition: Dictionary) -> String:
    # Bounded v1 resolver: rectangular floor regions with optional Restrained.
    # Reject unsupported mechanics rather than silently implementing a spell.
    if int(definition.get("schema_version", 0)) != 1 \
            or not definition.get("anchor") is Vector2i or not definition.get("footprint") is Vector2i:
        return ""
    var anchor: Vector2i = definition["anchor"]
    var footprint: Vector2i = definition["footprint"]
    var duration_rounds: int = int(definition.get("duration_rounds", 0))
    var concentrating: bool = bool(definition.get("concentration", false))
    var save_dc: int = int(definition.get("save_dc", 0))
    var condition: String = str(definition.get("condition", ""))
    var triggers: Array = definition.get("triggers", [])
    if condition not in ["", "restrained"] or str(definition.get("type", "")).is_empty():
        return ""
    if not condition.is_empty() and save_dc < 1:
        return ""
    for trigger in triggers:
        if trigger not in ["enter", "start_turn", "end_turn"]:
            return ""
    if deployment_active or finished or not is_combat_capable(source_id) or duration_rounds < 1 \
            or footprint.x < 1 or footprint.y < 1 or footprint.x > grid_size.x or footprint.y > grid_size.y:
        return ""
    var cells: Array[Vector2i] = []
    var explicit: bool = definition.has("cells")
    if explicit and not definition["cells"] is Array:
        return ""
    for y in range(footprint.y):
        for x in range(footprint.x):
            var cell := anchor + Vector2i(x, y)
            if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
                return ""
            if explicit and not definition["cells"].has(cell):
                continue
            if cell in walls or (not explicit and cell in blocked_cells) or (explicit and _area_barrier(cell)):
                return ""
            cells.append(cell)
    if cells.is_empty():
        return ""
    if explicit:
        for cell in definition["cells"]:
            if not cell is Vector2i or not cells.has(cell):
                return ""
    if concentrating:
        _stop_concentration(source_id, "replacement")
    effect_sequence += 1
    var id := "%s:effect:%06d" % [encounter_id, effect_sequence]
    active_effects[id] = {
        "schema_version": 1, "id": id, "type": str(definition["type"]), "source": source_id,
        "anchor": anchor, "footprint": footprint, "cells": cells,
        "start_round": round_number, "start_turn": turn_index, "duration_rounds": duration_rounds,
        "expiry_round": round_number + duration_rounds, "expiry_turn": turn_index,
        "concentration_owner": source_id if concentrating else "",
        "difficult_terrain": bool(definition.get("difficult_terrain", false)),
        "condition": condition, "triggers": triggers.duplicate(),
        "save_dc": save_dc, "applications": [], "occasions": {},
        "lightly_obscured": bool(definition.get("lightly_obscured", false)),
        "flammable": bool(definition.get("flammable", false)), "burning_cells": {}
    }
    if concentrating:
        actors[source_id]["concentration"] = {"spell": str(definition["type"]), "effect_id": id}
        _event("concentration_started", source_id, "", {"effect_id": id, "spell": str(definition["type"])})
    _event("effect_started", source_id, "", _effect_payload(id))
    _event("area_updated", source_id, "", _effect_payload(id))
    if bool(definition.get("flammable", false)):
        for hazard in hazards:
            if str(hazard.get("damage_type", "")) == "fire":
                ignite_web_cell(hazard["position"], "hazard:" + str(hazard.get("kind", "fire")))
    return id


func _effect_payload(effect_id: String) -> Dictionary:
    var effect: Dictionary = active_effects[effect_id]
    var cells: Array = []
    for cell in effect["cells"]:
        cells.append([cell.x, cell.y])
    return {"effect_id": effect_id, "effect_type": effect["type"], "cells": cells}


func end_effect(effect_id: String, reason: String = "expired") -> void:
    if not active_effects.has(effect_id):
        return
    var effect: Dictionary = active_effects[effect_id]
    var payload := _effect_payload(effect_id)
    payload["reason"] = reason
    for application in effect["applications"].duplicate():
        _remove_condition(str(application["actor_id"]), str(application["condition"]), effect_id)
    for burn in effect["burning_cells"].values():
        _event("burning_ended", str(burn["source"]), "", {"target_kind": "web_cell", "target_key": burn["target_key"], "reason": reason})
    active_effects.erase(effect_id)
    var owner: String = effect["concentration_owner"]
    if not owner.is_empty() and actors[owner].get("concentration", {}).get("effect_id", "") == effect_id:
        actors[owner]["concentration"] = {}
        _event("concentration_ended", owner, "", {"effect_id": effect_id, "reason": reason})
    _event("effect_ended", str(effect["source"]), "", payload)
    _event("area_updated", str(effect["source"]), "", {"effect_id": effect_id, "cells": []})


func _expire_effects() -> void:
    for id in active_effects.keys():
        if not active_effects.has(id):
            continue
        var effect: Dictionary = active_effects[id]
        if round_number > int(effect["expiry_round"]) or (round_number == int(effect["expiry_round"]) \
                and turn_index >= int(effect["expiry_turn"])):
            end_effect(str(id))
    _expire_burning_cells()
    _expire_prop_burning()


func effect_hook(actor_id: String, trigger: String, previous: Vector2i = Vector2i(-1, -1)) -> void:
    if not actors.has(actor_id) or trigger not in ["enter", "start_turn", "end_turn"]:
        return
    var cell: Vector2i = actors[actor_id]["position"]
    if trigger == "start_turn":
        _web_fire_start_turn(actor_id, cell)
    for id in active_effects.keys():
        var effect: Dictionary = active_effects[id]
        if not effect["cells"].has(cell):
            _remove_condition(actor_id, "restrained", str(id))
            continue
        if trigger not in effect["triggers"] or effect["condition"].is_empty() or not is_combat_capable(actor_id):
            continue
        if trigger == "enter" and effect["cells"].has(previous):
            _audit("Web DEX save", actor_id, str(effect["source"]), {"effect_id": id, "trigger": trigger, "outcome": "SKIPPED", "reason": "step stays inside the same Web; no new entry", "movement_cost": movement_cost(cell, actor_id)})
            continue
        var key := "%d:%s:%s" % [turn_serial, actor_id, trigger]
        if effect["occasions"].has(key):
            _audit("Web DEX save", actor_id, str(effect["source"]), {"effect_id": id, "trigger": trigger, "outcome": "SKIPPED", "reason": "already checked this entry/start this turn"})
            continue
        effect["occasions"][key] = true
        var total := dexterity_save(actor_id)
        var check := last_d20.duplicate(true)
        check.merge({"effect_id": id, "trigger": trigger, "dc": effect["save_dc"], "outcome": "SUCCESS" if total >= int(effect["save_dc"]) else "FAILURE", "consequence": "no new Restrained" if total >= int(effect["save_dc"]) else "Restrained from " + str(id), "terrain": "Web Walker ignores Web terrain cost; no save immunity" if actors[actor_id].get("traits", {}).get("web_walker", false) else "Web difficult terrain applies"})
        _audit("Web DEX save", actor_id, str(effect["source"]), check)
        _event("effect_applied", str(effect["source"]), actor_id,
            {"effect_id": id, "trigger": trigger, "total": total, "dc": effect["save_dc"]})
        if total < int(effect["save_dc"]):
            _apply_condition(actor_id, str(effect["condition"]), str(id))


func dexterity_save(actor_id: String) -> int:
    var actor: Dictionary = actors[actor_id]
    var disadvantage := has_condition(actor_id, "restrained")
    var advantage := bool(actor.get("dodging", false)) and not disadvantage
    var first := Dice.roll_d20(rng)
    var rolls: Array = [first]
    if advantage or disadvantage:
        rolls.append(Dice.roll_d20(rng))
    var natural: int = mini(first, int(rolls[-1])) if disadvantage else maxi(first, int(rolls[-1]))
    var modifiers := {"Dexterity": Dice.ability_modifier(int(actor.get("ability_scores", {}).get("dexterity", 10))),
        "save bonus": int(actor.get("saving_throw_bonuses", {}).get("dexterity", 0)), "Bless": _bless_bonus(actor_id)}
    var total: int = natural + int(modifiers["Dexterity"]) + int(modifiers["save bonus"]) + int(modifiers["Bless"])
    last_d20 = {"dice": rolls, "die": "d20", "natural": natural, "modifiers": modifiers, "total": total,
        "advantage": advantage, "disadvantage": disadvantage, "reason": "Restrained" if disadvantage else ("Dodge" if advantage else "normal")}
    return total


func _attack_d20(source_id: String, target_id: String, advantage: bool = false,
        disadvantage: bool = false, reasons: Array = []) -> int:
    reasons = reasons.duplicate()
    if has_condition(target_id, "restrained"): reasons.append("target Restrained: advantage")
    if has_condition(source_id, "restrained"): reasons.append("attacker Restrained: disadvantage")
    advantage = advantage or has_condition(target_id, "restrained")
    disadvantage = disadvantage or has_condition(source_id, "restrained")
    var first := Dice.roll_d20(rng)
    var rolls: Array = [first]
    if advantage != disadvantage:
        rolls.append(Dice.roll_d20(rng))
    var natural: int = first if advantage == disadvantage else (maxi(first, int(rolls[-1])) if advantage else mini(first, int(rolls[-1])))
    last_d20 = {"dice": rolls, "die": "d20", "natural": natural, "advantage": advantage, "disadvantage": disadvantage,
        "reason": "; ".join(reasons) if not reasons.is_empty() else "normal", "cancelled": advantage and disadvantage}
    return natural


func _audit(rule: String, actor_id: String, target_id: String, details: Dictionary) -> void:
    var payload := details.duplicate(true)
    payload["rule"] = rule
    _event("rules_check", actor_id, target_id, payload)


func _attack_check(actor_id: String, target_id: String, natural: int, bonus: int, ac: int,
        source: String, bless: int = 0, critical_from: int = 20) -> Dictionary:
    var result := RulesMath.attack_hits(natural, bonus + bless, ac, critical_from)
    var details := last_d20.duplicate(true)
    details.merge({"source": source, "natural": natural, "base_ac": actors[target_id].get("armor_class", 10), "shield_bonus": actors[target_id].get("shield_bonus", 0), "cover_bonus": cover_bonus(actors[actor_id]["position"], actors[target_id]["position"]), "modifiers": {"attack bonus": bonus, "Bless": bless},
        "total": result["total"], "ac": ac, "outcome": "CRITICAL" if result["critical"] else ("HIT" if result["hit"] else "MISS"),
        "consequence": "hit subject to reactions" if result["hit"] else "no damage"}, true)
    _audit("Attack", actor_id, target_id, details)
    return result


func _roll_formula(formula: String, critical: bool = false, actor_id: String = "", target_id: String = "", source: String = "", trigger: String = "") -> int:
    var roll := RulesMath.damage_roll(formula, rng, critical)
    roll.merge({"source": source, "trigger": trigger})
    _audit("Damage/healing dice", actor_id, target_id, roll)
    return int(roll["total"])


func _reject(command: String, reason: String, target_id: String = "") -> bool:
    _audit(command, current_id(), target_id, {"outcome": "REJECTED", "reason": reason, "consequence": "no resources spent"})
    return false


func can_escape_effect(effect_id: String) -> bool:
    return not deployment_active and not finished and not current_id().is_empty() \
        and is_combat_capable(current_id()) and not action_used \
        and pending_reaction.is_empty() and pending_move.is_empty() \
        and condition_sources.get(current_id(), {}).get("restrained", []).has(effect_id) \
        and active_effects.has(effect_id)


func escapable_effects() -> Array[String]:
    var result: Array[String] = []
    for id in condition_sources.get(current_id(), {}).get("restrained", []):
        if can_escape_effect(str(id)):
            result.append(str(id))
    result.sort()
    return result


func escape_effect(effect_id: String) -> bool:
    if not can_escape_effect(effect_id):
        return _reject("escape_effect", "unavailable: action/resource, actor, source or pending resolution")
    action_used = true
    var actor: Dictionary = current_actor()
    var proficiency := 0
    if actor.get("skill_expertise", []).has("athletics"):
        proficiency = 2 * int(actor.get("proficiency_bonus", 0))
    elif actor.get("skill_proficiencies", []).has("athletics"):
        proficiency = int(actor.get("proficiency_bonus", 0))
    var natural := Dice.roll_d20(rng)
    var strength := Dice.ability_modifier(int(actor.get("ability_scores", {}).get("strength", 10)))
    var total: int = natural + strength + proficiency
    var dc: int = active_effects[effect_id]["save_dc"]
    _audit("Escape Athletics", current_id(), str(active_effects[effect_id]["source"]), {"effect_id": effect_id, "dice": [natural], "die": "d20", "modifiers": {"Strength": strength, "Athletics proficiency": proficiency}, "total": total, "dc": dc, "outcome": "SUCCESS" if total >= dc else "FAILURE", "consequence": "Action spent; remove this restraint source" if total >= dc else "Action spent; still Restrained"})
    _event("escape_check", current_id(), "", {"effect_id": effect_id, "total": total, "dc": dc, "success": total >= dc,
        "text": "%s attempts escape: %d vs DC %d — %s." % [actor["name"], total, dc, "success" if total >= dc else "failure"]})
    if total >= dc:
        _remove_condition(current_id(), "restrained", effect_id)
    committed_actions.append("escape")
    return true


func start(seed: int = 42024, with_deployment: bool = false, encounter_path: String = ENCOUNTER_FIXTURE) -> bool:
    if not encounter_path.begins_with("res://combat_lab/fixtures/encounters/") or not encounter_path.ends_with(".json"):
        return false
    var party: Dictionary = _read_json(PARTY_FIXTURE)
    var encounter: Dictionary = _read_json(encounter_path)
    return _start_from_data(party, encounter, seed, with_deployment)


func start_from_setup(setup: Dictionary, with_deployment: bool = true) -> bool:
    if int(setup.get("schema_version", -1)) != 1:
        return false
    var party: Variant = setup.get("party", {})
    var encounter: Variant = setup.get("encounter", {})
    if not party is Dictionary or not encounter is Dictionary:
        return false
    return _start_from_data(party.duplicate(true), encounter.duplicate(true), int(setup.get("seed", 42024)), with_deployment)


func _start_from_data(party: Dictionary, encounter: Dictionary, seed: int, with_deployment: bool) -> bool:
    if not party.has("characters") or not encounter.has("enemies"):
        return false
    if not party["characters"] is Array or not encounter["enemies"] is Array:
        return false
    if party["characters"].size() != 4 or encounter["enemies"].is_empty():
        return false

    initiative_disadvantaged_team = ""
    encounter_id = str(encounter.get("id", ""))
    encounter_name = str(encounter.get("name", encounter_id))
    if encounter_id.is_empty():
        return false
    active_effects.clear()
    burning_targets.clear()
    last_d20.clear()
    committed_actions.clear()
    condition_sources.clear()
    effect_sequence = 0
    turn_serial = 0
    actors.clear()
    walls.clear()
    difficult_terrain.clear()
    obstacles.clear()
    hazards.clear()
    blocked_cells.clear()
    sight_blockers.clear()
    cover_cells.clear()
    backdrop.clear()
    deployment_zone.clear()
    deployment_active = false
    active_formation = ""
    turn_order.clear()
    events.clear()
    pending_reaction.clear()
    pending_move.clear()
    reaction_checked.clear()
    finished = false
    victor = ""
    round_number = 1
    turn_index = 0
    rng.seed = seed
    var grid: Array = encounter.get("grid_size", [12, 10])
    grid_size = Vector2i(int(grid[0]), int(grid[1]))
    for wall in encounter.get("walls", []):
        walls.append(Vector2i(int(wall[0]), int(wall[1])))
    for rough in encounter.get("difficult_terrain", []):
        difficult_terrain.append(Vector2i(int(rough[0]), int(rough[1])))
    backdrop = encounter.get("backdrop", {}).duplicate(true)
    for template in encounter.get("obstacles", []):
        var prop: Dictionary = template.duplicate(true)
        var pos: Array = prop.get("position", [0, 0])
        var extent: Array = prop.get("size", [1, 1])
        prop["position"] = Vector2i(int(pos[0]), int(pos[1]))
        prop["size"] = Vector2i(int(extent[0]), int(extent[1]))
        obstacles.append(prop)
        for dy in range(int(extent[1])):
            for dx in range(int(extent[0])):
                var cell: Vector2i = prop["position"] + Vector2i(dx, dy)
                if bool(prop.get("blocks_movement", false)) and not blocked_cells.has(cell):
                    blocked_cells.append(cell)
                if bool(prop.get("blocks_sight", false)) and not sight_blockers.has(cell):
                    sight_blockers.append(cell)
                if prop.get("cover", "") == "half" and not cover_cells.has(cell):
                    cover_cells.append(cell)
    var zone: Dictionary = encounter.get("deployment_zone", {})
    var corner_min: Array = zone.get("min", [0, 3])
    var corner_max: Array = zone.get("max", [3, 8])
    for y in range(int(corner_min[1]), int(corner_max[1]) + 1):
        for x in range(int(corner_min[0]), int(corner_max[0]) + 1):
            deployment_zone.append(Vector2i(x, y))
    for template in encounter.get("hazards", []):
        var hazard: Dictionary = template.duplicate(true)
        var pos: Array = hazard.get("position", [0, 0])
        hazard["position"] = Vector2i(int(pos[0]), int(pos[1]))
        hazards.append(hazard)

    var party_positions: Dictionary = encounter.get("party_positions", {})
    for template in party["characters"]:
        var id: String = str(template["id"])
        var cell: Array = party_positions.get(id, [])
        if cell.size() != 2:
            return false
        var actor: Dictionary = template.duplicate(true)
        actor["team"] = "party"
        actor["position"] = Vector2i(int(cell[0]), int(cell[1]))
        actor["hp"] = int(actor.get("starting_hp", actor.get("max_hp", 1)))
        actor["combat_state"] = "active"
        actor["death_saves"] = true
        actor["death_successes"] = 0
        actor["death_failures"] = 0
        actor["dodging"] = false
        actor["reaction_used"] = false
        actor["disengaged"] = false
        actor["shield_bonus"] = 0
        actor["concentration"] = {}
        actor["blessed_by"] = ""
        actor["max_hp"] = int(actor.get("max_hp", 1))
        var casting: Variant = actor.get("spellcasting")
        var slots_by_level: Dictionary = {}
        if casting is Dictionary:
            for tier_variant in casting.get("spell_slots", {}).keys():
                var tier: String = str(tier_variant)
                slots_by_level[tier] = maxi(0, int(casting["spell_slots"][tier_variant]))
        actor["spell_slots_by_level"] = slots_by_level
        # Compatibility mirror for all existing level-one spell code and tests.
        actor["spell_slots_remaining"] = int(slots_by_level.get("1", 0))
        actor["second_wind_remaining"] = int(actor.get("resource_limits", {}).get("second_wind", 0))
        actor["mage_armor_active"] = false
        actor["vex_target"] = ""
        actor["sap_pending"] = false
        actors[id] = actor

    for template in encounter["enemies"]:
        var actor: Dictionary = template.duplicate(true)
        var id: String = str(actor["id"])
        var cell: Array = actor["position"]
        actor["position"] = Vector2i(int(cell[0]), int(cell[1]))
        actor["team"] = "enemy"
        actor["hp"] = int(actor.get("max_hp", 1))
        actor["combat_state"] = "active"
        actor["death_successes"] = 0
        actor["death_failures"] = 0
        actor["dodging"] = false
        actor["reaction_used"] = false
        actor["disengaged"] = false
        actor["shield_bonus"] = 0
        actor["concentration"] = {}
        actor["blessed_by"] = ""
        actor["art"] = actor.get("art", {"combat_sprite": "assets/characters/sprites/goblin_front_64.png"})
        actor["sap_pending"] = false
        actor["vex_target"] = ""
        actors[id] = actor

    if with_deployment:
        deployment_active = true
        if not set_formation("square"):
            return false
        _record(str(encounter.get("intro", "The party senses an ambush ahead. Arrange your formation.")))
        return true
    _roll_initiative_and_start()
    return true


func _roll_initiative_and_start() -> void:
    var rolls: Array[Dictionary] = []
    var tie_order := 0
    for id_variant in actors.keys():
        var id: String = str(id_variant)
        var actor: Dictionary = actors[id]
        var dexterity := int(actor.get("ability_scores", {}).get("dexterity", 10))
        var roll1: int = Dice.roll_d20(rng)
        var roll: int = roll1
        var disadvantage: bool = not initiative_disadvantaged_team.is_empty() and (
            str(actor.get("team", "")) == initiative_disadvantaged_team
        )
        var roll2 := 0
        if disadvantage:
            roll2 = Dice.roll_d20(rng)
            roll = mini(roll1, roll2)
        var result: int = roll + Dice.ability_modifier(dexterity)
        _audit("Initiative", id, "", {"dice": [roll1, roll2] if disadvantage else [roll1], "die": "d20", "modifiers": {"Dexterity": Dice.ability_modifier(dexterity)}, "total": result, "disadvantage": disadvantage, "reason": "Surprised" if disadvantage else "normal", "consequence": "initiative order; stable fixture tie-break"})
        rolls.append({"id": id, "initiative": result, "tie": tie_order})
        tie_order += 1
        if disadvantage:
            _record("%s initiative: %d (Surprised, Disadvantage %d/%d)" % [
                actor["name"], result, roll1, roll2
            ])
        else:
            _record("%s initiative: %d (%d on d20)" % [actor["name"], result, roll])
    rolls.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if a["initiative"] == b["initiative"]:
            return a["tie"] < b["tie"]
        return a["initiative"] > b["initiative"]
    )
    for item in rolls:
        turn_order.append(str(item["id"]))
    _record("Encounter begins: %s." % encounter_name)
    _begin_turn()


func is_deployment_cell(cell: Vector2i) -> bool:
    if not deployment_zone.has(cell):
        return false
    if cell in walls or cell in blocked_cells or cell.x < 0 or cell.y < 0:
        return false
    if cell.x >= grid_size.x or cell.y >= grid_size.y:
        return false
    for hazard in hazards:
        if hazard["position"] == cell:
            return false
    for actor in actors.values():
        if actor["team"] == "enemy" and int(actor["hp"]) > 0 and actor["position"] == cell:
            return false
    return true


func can_place_character(actor_id: String, cell: Vector2i) -> bool:
    if not deployment_active or not actors.has(actor_id) or actors[actor_id]["team"] != "party":
        return false
    if not is_deployment_cell(cell):
        return false
    for key in actors.keys():
        if str(key) != actor_id and actors[key]["position"] == cell:
            return false
    return true


func place_character(actor_id: String, cell: Vector2i) -> bool:
    if not can_place_character(actor_id, cell):
        return false
    var actor: Dictionary = actors[actor_id]
    actor["position"] = cell
    actors[actor_id] = actor
    active_formation = "custom"
    _record("%s takes position at (%d,%d)." % [actor["name"], cell.x, cell.y])
    return true


func set_formation(formation_id: String) -> bool:
    if not deployment_active or not FORMATIONS.has(formation_id):
        return false
    var formation: Dictionary = FORMATIONS[formation_id]
    var chosen: Array[Vector2i] = []
    for actor_id_variant in formation.keys():
        var actor_id: String = str(actor_id_variant)
        var pos: Array = formation[actor_id]
        var cell := Vector2i(int(pos[0]), int(pos[1]))
        if not actors.has(actor_id) or not is_deployment_cell(cell) or chosen.has(cell):
            return false
        chosen.append(cell)
    if chosen.size() != 4:
        return false
    for actor_id_variant in formation.keys():
        var actor_id: String = str(actor_id_variant)
        var pos: Array = formation[actor_id]
        var actor: Dictionary = actors[actor_id]
        actor["position"] = Vector2i(int(pos[0]), int(pos[1]))
        actors[actor_id] = actor
    active_formation = formation_id
    _record("Formation selected: %s." % formation_id.capitalize())
    return true


func begin_battle() -> bool:
    if not deployment_active:
        return false
    var occupied: Array[Vector2i] = []
    for actor_id in ["alden", "elyra", "brunna", "pip"]:
        var pos: Vector2i = actors[actor_id]["position"]
        if not is_deployment_cell(pos) or occupied.has(pos):
            return false
        occupied.append(pos)
    deployment_active = false
    _record("Deployment complete; battle begins.")
    _roll_initiative_and_start()
    return true




func current_id() -> String:
    if turn_order.is_empty() or finished:
        return ""
    return turn_order[turn_index]


func current_actor() -> Dictionary:
    var id := current_id()
    return actors.get(id, {})


func current_is_party() -> bool:
    # Downed heroes retain their initiative slot for automatic death saves,
    # but never become a controllable character or receive action buttons.
    return not deployment_active and not finished and not current_id().is_empty()         and current_actor().get("team", "") == "party" and is_combat_capable(current_id())


func is_combat_capable(id: String) -> bool:
    if not actors.has(id):
        return false
    var actor: Dictionary = actors[id]
    return int(actor.get("hp", 0)) > 0 and actor.get("combat_state", "active") == "active"


func survivors(team: String = "enemy") -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for id_variant in actors.keys():
        var actor: Dictionary = actors[id_variant]
        if actor["team"] == team and actor.get("combat_state", "") in ["unconscious", "stable", "knocked_out"]:
            found.append({
                "actor_id": str(id_variant),
                "npc_id": str(actor.get("npc_id", "")),
                "name": str(actor["name"]), "hp": int(actor["hp"]),
                "state": str(actor["combat_state"])
            })
    return found


func actor_at(cell: Vector2i) -> String:
    for id in actors.keys():
        var actor: Dictionary = actors[id]
        if is_combat_capable(str(id)) and actor["position"] == cell:
            return str(id)
    return ""


func get_reachable(id: String) -> Dictionary:
    var result: Dictionary = {}
    if not actors.has(id):
        return result
    var actor: Dictionary = actors[id]
    if not is_combat_capable(id) or has_condition(id, "restrained"):
        return result
    var origin: Vector2i = actor["position"]
    var remaining := maxi(0, int(actor.get("speed_feet", 30)) / 5 + dash_extra_squares - movement_used)
    var pending: Array[Vector2i] = [origin]
    result[origin] = {"cost": 0, "previous": origin}

    while not pending.is_empty():
        var best := 0
        for i in range(1, pending.size()):
            if int(result[pending[i]]["cost"]) < int(result[pending[best]]["cost"]):
                best = i
        var cell: Vector2i = pending.pop_at(best)
        var spent: int = result[cell]["cost"]
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if dx == 0 and dy == 0:
                    continue
                var next := cell + Vector2i(dx, dy)
                if not _can_step(id, cell, next):
                    continue
                var cost := movement_cost(next, id)
                var next_spent := spent + cost
                if next_spent > remaining:
                    continue
                if not result.has(next) or next_spent < int(result[next]["cost"]):
                    result[next] = {"cost": next_spent, "previous": cell}
                    if not pending.has(next):
                        pending.append(next)
    return result


func move_to(destination: Vector2i) -> bool:
    if deployment_active or finished or current_id().is_empty() or not pending_reaction.is_empty() or not pending_move.is_empty():
        return _reject("Move", "actor unavailable or resolution pending")
    var actor_id: String = current_id()
    var actor: Dictionary = actors[actor_id]
    if int(actor["hp"]) <= 0:
        return false
    var reachable: Dictionary = get_reachable(actor_id)
    if not reachable.has(destination) or int(reachable[destination]["cost"]) <= 0:
        return _reject("Move", "destination blocked/unreachable, Restrained or movement exhausted")
    var path: Array[Vector2i] = []
    var current: Vector2i = destination
    var origin: Vector2i = actor["position"]
    while current != origin:
        path.push_front(current)
        current = reachable[current]["previous"]
    pending_move = {"actor": actor_id, "path": path, "index": 0}
    reaction_checked.clear()
    _advance_move()
    return true


func _advance_move() -> void:
    while not pending_move.is_empty() and pending_reaction.is_empty() and not finished:
        var mover_id: String = str(pending_move["actor"])
        if int(actors[mover_id]["hp"]) <= 0 or has_condition(mover_id, "restrained"):
            _audit("Movement stopped", mover_id, "", {"reason": "downed or Restrained", "remaining_squares": movement_remaining()})
            pending_move.clear()
            reaction_checked.clear()
            return
        var path: Array = pending_move["path"]
        var idx: int = int(pending_move["index"])
        if idx >= path.size():
            pending_move.clear()
            reaction_checked.clear()
            return
        var from_cell: Vector2i = actors[mover_id]["position"]
        var next_cell: Vector2i = path[idx]
        if not _can_step(mover_id, from_cell, next_cell):
            _audit("Movement stopped", mover_id, "", {"reason": "next step blocked", "destination": [next_cell.x, next_cell.y]})
            pending_move.clear()
            reaction_checked.clear()
            return
        var reactor_id: String = _opportunity_reactor(mover_id, from_cell, next_cell)
        if not reactor_id.is_empty():
            reaction_checked.append(reactor_id)
            if actors[reactor_id]["team"] == "party":
                pending_reaction = {"kind": "opportunity", "reactor": reactor_id, "target": mover_id}
                _record("%s may make an Opportunity Attack against %s." % [
                    actors[reactor_id]["name"], actors[mover_id]["name"]
                ])
                return
            _make_opportunity_attack(reactor_id, mover_id)
            continue
        var mover: Dictionary = actors[mover_id]
        var cost: int = movement_cost(next_cell, mover_id)
        if movement_used + cost > int(mover.get("speed_feet", 30)) / 5 + dash_extra_squares:
            _audit("Movement stopped", mover_id, "", {"reason": "movement allowance exhausted", "cost": cost})
            pending_move.clear()
            return
        mover["position"] = next_cell
        actors[mover_id] = mover
        movement_used += cost
        pending_move["index"] = idx + 1
        reaction_checked.clear()
        _record("%s moves from (%d,%d) to (%d,%d)." % [
            mover["name"], from_cell.x, from_cell.y, next_cell.x, next_cell.y
        ])
        _event("move", mover_id, "", {
            "from": [from_cell.x, from_cell.y], "to": [next_cell.x, next_cell.y], "cost_squares": cost, "remaining_squares": movement_remaining(), "disengaged": mover.get("disengaged", false)
        })
        _emit_sound("footstep")
        effect_hook(mover_id, "enter", from_cell)
        _trigger_hazards(mover_id, next_cell, "enter")
        if finished or int(actors[mover_id]["hp"]) <= 0:
            pending_move.clear()
            reaction_checked.clear()
            return


func _trigger_hazards(actor_id: String, cell: Vector2i, trigger: String) -> void:
    if not actors.has(actor_id) or int(actors[actor_id]["hp"]) <= 0:
        return
    for hazard in hazards:
        if hazard["position"] != cell or not hazard.get("trigger", []).has(trigger):
            continue
        var damage: int = _roll_formula(str(hazard.get("damage", "1d4")), false, "", actor_id, str(hazard.get("kind", "hazard")), trigger)
        _record("%s is burned by the %s for %d fire damage (%s)." % [
            actors[actor_id]["name"], str(hazard.get("kind", "hazard")), damage,
            "entry" if trigger == "enter" else "start of turn"
        ])
        _emit_sound("magic")
        _emit_sound("damage")
        _deal_damage(actor_id, damage)
        _check_victory()


func _opportunity_reactor(mover_id: String, from_cell: Vector2i, next_cell: Vector2i) -> String:
    for id_variant in actors.keys():
        var reactor_id: String = str(id_variant)
        if not reaction_checked.has(reactor_id) and _can_opportunity_attack(
                reactor_id, mover_id, from_cell, next_cell):
            return reactor_id
    return ""


func _can_opportunity_attack(reactor_id: String, mover_id: String,
        from_cell: Vector2i, next_cell: Vector2i) -> bool:
    # Shared by movement execution and tactical risk estimation; no rolls.
    var mover: Dictionary = actors[mover_id]
    var reactor: Dictionary = actors[reactor_id]
    if bool(mover.get("disengaged", false)) or reactor["team"] == mover["team"]:
        return false
    if not is_combat_capable(reactor_id) or bool(reactor.get("reaction_used", false)):
        return false
    var pos: Vector2i = reactor["position"]
    if _distance(pos, from_cell) > 1 or _distance(pos, next_cell) <= 1:
        return false
    if not _line_clear(pos, from_cell):
        return false
    for attack_data in reactor.get("attacks", []):
        if attack_data.get("kind", "") == "melee_weapon":
            return true
    return false


func _make_opportunity_attack(reactor_id: String, target_id: String) -> void:
    var reactor: Dictionary = actors[reactor_id]
    var target: Dictionary = actors[target_id]
    var weapon: Dictionary = {}
    for attack_data in reactor.get("attacks", []):
        if attack_data.get("kind", "") == "melee_weapon":
            weapon = attack_data
            break
    if weapon.is_empty() or int(target["hp"]) <= 0:
        return
    reactor["reaction_used"] = true
    actors[reactor_id] = reactor
    var natural: int = _attack_d20(reactor_id, target_id)
    var result: Dictionary = _attack_check(reactor_id, target_id, natural, int(weapon.get("to_hit", 0)),
        effective_ac(target) + cover_bonus(reactor["position"], target["position"]), "opportunity:" + str(weapon.get("id", "")), _bless_bonus(reactor_id))
    if not bool(result["hit"]):
        _emit_sound("miss")
        _record("%s Opportunity Attack against %s: %d — MISS." % [
            reactor["name"], target["name"], result["total"]
        ])
        _event("miss", reactor_id, target_id, {
            "action_id": str(weapon.get("id", "")), "source_kind": "weapon", "reaction": true,
            "attack_kind": str(weapon.get("kind", ""))
        })
        return
    var damage: int = _roll_formula(str(weapon["damage"]), bool(result["critical"]), reactor_id, target_id, str(weapon.get("id", "")), "opportunity attack")
    var before_hp: int = int(target["hp"])
    _emit_sound("melee_hit")
    _emit_sound("damage")
    _record("%s Opportunity Attack hits %s for %d damage." % [reactor["name"], target["name"], damage])
    _deal_damage(target_id, damage)
    _event("hit", reactor_id, target_id, {
        "amount": damage, "action_id": str(weapon.get("id", "")),
        "damage_type": str(weapon.get("damage_type", "physical")), "source_kind": "weapon",
        "critical": bool(result["critical"]), "reaction": true,
        "attack_kind": str(weapon.get("kind", "")), "hp_before": before_hp,
        "hp_after": int(actors[target_id]["hp"]),
        "state_after": str(actors[target_id]["combat_state"])
    })
    _check_victory()


func resolve_reaction(accept: bool) -> bool:
    if pending_reaction.is_empty():
        return false
    _event("reaction_choice", str(pending_reaction.get("reactor", "")), str(pending_reaction.get("target", "")), {"accepted": accept, "reaction": pending_reaction.get("kind", "")})
    var decision: Dictionary = pending_reaction.duplicate()
    pending_reaction.clear()
    if decision["kind"] == "opportunity":
        if accept and int(actors[decision["reactor"]]["hp"]) > 0:
            _make_opportunity_attack(str(decision["reactor"]), str(decision["target"]))
        if not finished:
            _advance_move()
    elif decision["kind"] == "shield":
        var defender_id: String = str(decision["reactor"])
        var defender: Dictionary = actors[defender_id]
        if accept and _can_shield(defender_id):
            defender["reaction_used"] = true
            defender["spell_slots_remaining"] = int(defender["spell_slots_remaining"]) - 1
            var tiered_slots: Dictionary = defender.get("spell_slots_by_level", {}).duplicate()
            tiered_slots["1"] = int(defender["spell_slots_remaining"])
            defender["spell_slots_by_level"] = tiered_slots
            defender["shield_bonus"] = 5
            actors[defender_id] = defender
            _emit_sound("magic")
            _record("%s casts Shield! AC rises to %d until the start of their next turn." % [
                defender["name"], int(defender["armor_class"]) + 5
            ])
            _event("cast", defender_id, defender_id, {"action_id": "shield", "effect": "shield"})
        var result: Dictionary = decision["roll"]
        _audit("Attack after Shield decision", str(decision["source"]), defender_id, {"total": result["total"], "ac": effective_ac(actors[defender_id]), "outcome": "MISS" if int(result["total"]) < effective_ac(actors[defender_id]) else "HIT", "reason": "same attack; no reroll"})
        if int(result["total"]) < effective_ac(actors[defender_id]):
            _emit_sound("miss")
            _record("Shield deflects the incoming attack on %s." % defender["name"])
            _event("miss", str(decision["source"]), defender_id, {
                "action_id": str(decision["weapon"].get("id", "")),
                "source_kind": "weapon", "blocked_by": "shield"
            })
        else:
            _resolve_hit(str(decision["source"]), defender_id,
                decision["weapon"], result, bool(decision["disadvantage"]), bool(decision.get("nonlethal", false)))
    return true


func _can_shield(actor_id: String) -> bool:
    if not actors.has(actor_id):
        return false
    var target: Dictionary = actors[actor_id]
    if target.get("team", "") != "party" or int(target["hp"]) <= 0:
        return false
    if bool(target.get("reaction_used", false)) or int(target.get("spell_slots_remaining", 0)) <= 0:
        return false
    var casting: Variant = target.get("spellcasting")
    return casting is Dictionary and casting.get("prepared_spells", []).has("shield")


func effective_ac(actor: Dictionary) -> int:
    return int(actor.get("armor_class", 10)) + int(actor.get("shield_bonus", 0))


func _deal_damage(target_id: String, damage: int, critical: bool = false) -> void:
    if damage <= 0 or not actors.has(target_id):
        return
    var target: Dictionary = actors[target_id]
    var old_hp: int = int(target["hp"])
    var previous_state: String = str(target.get("combat_state", "active"))
    if previous_state == "dead":
        return

    if old_hp <= 0:
        if damage >= int(target["max_hp"]):
            target["combat_state"] = "dead"
        else:
            if previous_state == "stable":
                target["combat_state"] = "unconscious"
                target["death_successes"] = 0
                target["death_failures"] = 0
            target["death_failures"] = int(target.get("death_failures", 0)) + (2 if critical else 1)
            if int(target["death_failures"]) >= 3:
                target["combat_state"] = "dead"
    else:
        var excess: int = damage - old_hp
        target["hp"] = maxi(0, old_hp - damage)
        if int(target["hp"]) == 0:
            if excess >= int(target["max_hp"]) or not bool(target.get("death_saves", false)):
                target["combat_state"] = "dead"
            else:
                target["combat_state"] = "unconscious"
                target["death_successes"] = 0
                target["death_failures"] = 0
    actors[target_id] = target
    _audit("Damage consequence", "", target_id, {"amount": damage, "hp_before": old_hp, "hp_after": target["hp"], "state_after": target["combat_state"], "death_failures": target.get("death_failures", 0)})
    _check_concentration_after_damage(target_id, damage)
    if target["combat_state"] == "dead" and previous_state != "dead":
        _end_burning("actor:" + target_id, "dead")
        _emit_sound("death")
        _record("%s dies." % target["name"])
        _event("death", target_id, target_id)


func can_disengage() -> bool:
    return _utility_ready() and not action_used


func use_disengage() -> bool:
    if not can_disengage():
        return _reject("use_disengage", "unavailable: action/resource, actor, source or pending resolution")
    action_used = true
    var actor: Dictionary = current_actor()
    actor["disengaged"] = true
    actors[current_id()] = actor
    _record("%s Disengages, preventing Opportunity Attacks from their movement this turn." % actor["name"])
    _event("action_committed", current_id(), "", {"action_id": "disengage", "cost": "Action", "action_used": action_used, "movement_remaining": movement_remaining()})
    committed_actions.append("disengage")
    return true


func available_attack(target_id: String, weapon_id: String = "") -> Dictionary:
    if deployment_active or finished or action_used or not actors.has(target_id):
        return {}
    return _attack_from(current_id(), target_id, current_actor().get("position", Vector2i(-1, -1)), weapon_id)


func _attack_from(source_id: String, target_id: String, from_cell: Vector2i,
        weapon_id: String = "") -> Dictionary:
    # Pure shared geometry query. Command availability/budgets stay in
    # available_attack; AI can evaluate a prospective tile without moving actors.
    if not is_combat_capable(source_id) or not is_combat_capable(target_id):
        return {}
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    if source["team"] == target["team"]:
        return {}
    var distance := _distance(from_cell, target["position"])
    if not _line_clear(from_cell, target["position"]):
        return {}
    var options: Array = source.get("attacks", [])
    var ranged: Dictionary = {}
    for entry in options:
        var attack: Dictionary = entry
        if not weapon_id.is_empty() and str(attack.get("id", "")) != weapon_id:
            continue
        if attack.get("kind", "") == "melee_weapon" and distance <= 1:
            return attack
        if attack.get("kind", "") == "ranged_weapon":
            if distance <= int(attack.get("long_range_feet", attack.get("normal_range_feet", 0))) / 5:
                if ranged.is_empty():
                    ranged = attack
    return ranged


func attack(target_id: String, weapon_id: String = "", nonlethal: bool = false) -> bool:
    if deployment_active:
        return _reject("Attack", "deployment active", target_id)
    var weapon: Dictionary = available_attack(target_id, weapon_id)
    if weapon.is_empty():
        return _reject("Attack", "no legal weapon/target, Action used or actor unavailable", target_id)
    if nonlethal and weapon.get("kind", "") != "melee_weapon":
        return _reject("Attack", "nonlethal requires melee", target_id)
    var source_id := current_id()
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    action_used = true
    var distance := _distance(source["position"], target["position"])
    var disadvantage := false
    var roll_reasons: Array = []
    if weapon.get("kind", "") == "ranged_weapon":
        disadvantage = distance > int(weapon.get("normal_range_feet", 0)) / 5
        if disadvantage: roll_reasons.append("long range: disadvantage")
        for other_id in actors.keys():
            var nearby: Dictionary = actors[other_id]
            if nearby["team"] != source["team"] and int(nearby["hp"]) > 0:
                if _distance(source["position"], nearby["position"]) <= 1:
                    disadvantage = true
                    roll_reasons.append("adjacent enemy: disadvantage")
                    break
    var advantage: bool = source.get("vex_target", "") == target_id
    if advantage: roll_reasons.append("Vex: advantage")
    if source.get("sap_pending", false): roll_reasons.append("Sap: disadvantage")
    if target.get("dodging", false) and not has_condition(target_id, "restrained"): roll_reasons.append("Dodge: disadvantage")
    if bool(source.get("sap_pending", false)) or (bool(target.get("dodging", false)) and not has_condition(target_id, "restrained")):
        disadvantage = true
    disadvantage = disadvantage or has_condition(source_id, "restrained")
    var natural: int = _attack_d20(source_id, target_id, advantage, disadvantage, roll_reasons)
    if source.get("race_id", "") == "halfling" and natural == 1:
        natural = Dice.roll_d20(rng)
        last_d20["reroll"] = natural
        _record("%s uses Halfling Luck to reroll a natural 1." % source["name"])
    source["sap_pending"] = false
    source["vex_target"] = ""
    actors[source_id] = source
    var roll: Dictionary = _attack_check(source_id, target_id, natural, int(weapon.get("to_hit", 0)),
        effective_ac(target) + cover_bonus(source["position"], target["position"]), str(weapon.get("id", "")), _bless_bonus(source_id))
    var attack_name := str(weapon.get("id", "attack")).replace("_", " ")
    var disadvantage_label := " (Disadvantage)" if disadvantage else ""
    if not roll["hit"]:
        if weapon.get("kind", "") == "ranged_weapon":
            _emit_sound("ranged")
        _emit_sound("miss")
        _record("%s uses %s against %s: %d vs AC %d — MISS%s." % [
            source["name"], attack_name, target["name"], roll["total"], target["armor_class"], disadvantage_label
        ])
        _event("miss", source_id, target_id, {
            "action_id": str(weapon.get("id", "")), "source_kind": "weapon",
            "damage_type": str(weapon.get("damage_type", "physical")),
            "attack_kind": str(weapon.get("kind", ""))
        })
        return true
    if not bool(roll["critical"]) and _can_shield(target_id):
        pending_reaction = {
            "kind": "shield", "reactor": target_id, "target": source_id,
            "source": source_id, "weapon": weapon.duplicate(true),
            "roll": roll.duplicate(true), "disadvantage": disadvantage,
            "nonlethal": nonlethal
        }
        _record("%s can cast Shield against %s's attack (%d vs AC %d)." % [
            target["name"], source["name"], roll["total"], effective_ac(target)
        ])
        return true
    return _resolve_hit(source_id, target_id, weapon, roll, disadvantage, nonlethal)


func _resolve_hit(source_id: String, target_id: String, weapon: Dictionary, roll: Dictionary, disadvantage: bool, nonlethal: bool = false) -> bool:
    if not actors.has(source_id) or not actors.has(target_id):
        return false
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    var attack_name := str(weapon.get("id", "attack")).replace("_", " ")
    var disadvantage_label := " (Disadvantage)" if disadvantage else ""
    var damage: int = _roll_formula(str(weapon.get("damage", "1d4")), bool(roll["critical"]), source_id, target_id, str(weapon.get("id", "")), "hit")
    _emit_sound("ranged" if weapon.get("kind", "") == "ranged_weapon" else "melee_hit")
    var sneak_eligible := _sneak_attack_eligible(source_id, target_id, weapon, disadvantage)
    if source.get("class_id", "") == "thief":
        _audit("Sneak Attack eligibility", source_id, target_id, {"source": weapon.get("id", ""), "outcome": "SUCCESS" if sneak_eligible else "SKIPPED", "reason": "weapon, ally adjacency, disadvantage and once-per-turn evaluated", "consequence": "extra 1d6" if sneak_eligible else "no extra damage"})
    if sneak_eligible:
        var sneak_damage: int = _roll_formula("1d6", bool(roll["critical"]), source_id, target_id, "Sneak Attack", "eligible hit")
        damage += sneak_damage
        sneak_attack_used = true
        _record("%s uses Sneak Attack for %d extra damage." % [source["name"], sneak_damage])
    if weapon.get("mastery", "") == "sap":
        target["sap_pending"] = true
        _event("mastery_applied", source_id, target_id, {"mastery": "Sap", "consequence": "next attack has disadvantage"})
    if weapon.get("mastery", "") == "vex":
        source["vex_target"] = target_id
        _event("mastery_applied", source_id, target_id, {"mastery": "Vex", "consequence": "next attack against this target has advantage"})
        actors[source_id] = source
    var old_hp := int(target["hp"])
    var knocked_out: bool = nonlethal and damage >= old_hp
    if knocked_out:
        target["hp"] = 1
        target["combat_state"] = "knocked_out"
        target["short_rest_started"] = true
        actors[target_id] = target
        _check_concentration_after_damage(target_id, damage)
    else:
        _deal_damage(target_id, damage, bool(roll["critical"]))
    target = actors[target_id]
    var critical_label := " CRITICAL!" if roll["critical"] else ""
    _record("%s uses %s on %s: %d vs AC %d — HIT%s %d %s damage (%d → %d HP)%s." % [
        source["name"], attack_name, target["name"], roll["total"], target["armor_class"],
        critical_label, damage, weapon.get("damage_type", ""), old_hp, target["hp"], disadvantage_label
    ])
    _event("hit", source_id, target_id, {
        "amount": damage, "action_id": str(weapon.get("id", "")),
        "damage_type": str(weapon.get("damage_type", "physical")),
        "source_kind": "weapon", "critical": bool(roll["critical"]), "nonlethal": knocked_out,
        "attack_kind": str(weapon.get("kind", "")), "hp_before": old_hp,
        "hp_after": int(target["hp"]), "state_after": str(target["combat_state"])
    })
    _emit_sound("damage")
    if knocked_out:
        _record("%s is knocked unconscious nonlethally (1 HP)." % target["name"])
    elif not is_combat_capable(target_id):
        _record("%s is %s." % [target["name"], target["combat_state"]])
    _check_victory()
    return true


func end_turn() -> void:
    if deployment_active or finished or current_id().is_empty() or not pending_reaction.is_empty() or not pending_move.is_empty():
        return
    if is_combat_capable(current_id()):
        _record("%s ends their turn." % current_actor()["name"])
    effect_hook(current_id(), "end_turn")
    _advance_initiative()


func _advance_initiative() -> void:
    # Process downed heroes' death saves *within* initiative, but never pause
    # for user actions or End Turn on an unconscious/stable/dead creature.
    # An unconscious hero recovering on natural 20 becomes playable immediately.
    for offset in range(1, turn_order.size() + 1):
        turn_index = (turn_index + 1) % turn_order.size()
        if turn_index == 0:
            round_number += 1
            _record("--- Round %d ---" % round_number)
        var id: String = turn_order[turn_index]
        var state: String = str(actors[id].get("combat_state", "active"))
        if state in ["unconscious", "stable"] or is_combat_capable(id):
            _begin_turn()
            if finished:
                return
            if is_combat_capable(id):
                return
            # Failed save, stabilisation, death or start-of-turn hazard:
            # continue to the next combat-capable creature automatically.
    _check_victory()


func _ai_weapon_id(actor: Dictionary, distance: int) -> String:
    var melee_id := ""
    var ranged_id := ""
    for weapon_variant in actor.get("attacks", []):
        var weapon: Dictionary = weapon_variant
        if str(weapon.get("kind", "")) == "melee_weapon" and melee_id.is_empty():
            melee_id = str(weapon.get("id", ""))
        if str(weapon.get("kind", "")) == "ranged_weapon" and ranged_id.is_empty():
            ranged_id = str(weapon.get("id", ""))
    if str(actor.get("role", "melee")) == "ranged" and distance > 1 and not ranged_id.is_empty():
        return ranged_id
    return melee_id if not melee_id.is_empty() else ranged_id


func take_ai_turn() -> void:
    if deployment_active or finished or current_is_party() or not pending_reaction.is_empty() or not pending_move.is_empty():
        return
    var actor_id: String = current_id()
    if actor_id.is_empty():
        return
    if not is_combat_capable(actor_id):
        # Also covers a hero becoming downed during their own turn.
        # The AI does not act on their behalf; simply move initiative forward.
        end_turn()
        return
    for effect_id in condition_sources.get(actor_id, {}).get("restrained", []).duplicate():
        if can_escape_effect(str(effect_id)):
            escape_effect(str(effect_id))
            end_turn()
            return
    var intent: Dictionary = choose_ai_intent()
    _event("ai_choice", actor_id, "", {"choice": intent.duplicate(true), "reason": "committed tactical choice; revalidate after movement"})
    if intent.is_empty():
        _check_victory()
        return
    if intent["cell"] != actors[actor_id]["position"]:
        move_to(intent["cell"])
        if not pending_reaction.is_empty() or not pending_move.is_empty() or finished:
            return
    # Revalidate after movement/hazards/reactions with the same command used by
    # player input. Resuming an interrupted AI turn recomputes intent normally.
    if is_combat_capable(actor_id):
        var shot: Dictionary = _ai_attack_choice(actor_id, actors[actor_id]["position"])
        if not shot.is_empty() and not available_attack(shot["target"], shot["weapon"]).is_empty():
            attack(shot["target"], shot["weapon"])
    if not finished and pending_reaction.is_empty() and pending_move.is_empty():
        end_turn()


func choose_ai_intent() -> Dictionary:
    # Policy only: no state writes, RNG, events or speculative actor relocation.
    # Origin wins ties, then row/column order; target ties use sorted stable IDs.
    var actor_id: String = current_id()
    if actor_id.is_empty() or not is_combat_capable(actor_id):
        return {}
    var source: Dictionary = actors[actor_id]
    var origin: Vector2i = source["position"]
    if action_used:
        return {"cell": origin}
    if has_condition(actor_id, "restrained"):
        var escapes := escapable_effects()
        return {"cell": origin, "escape_effect": escapes[0] if not escapes.is_empty() else ""}
    var goals: Dictionary = {}
    for y in grid_size.y:
        for x in grid_size.x:
            var cell := Vector2i(x, y)
            if _is_open(actor_id, cell):
                var choice: Dictionary = _ai_attack_choice(actor_id, cell)
                if not choice.is_empty():
                    goals[cell] = int(choice["score"])
    if goals.is_empty():
        return {"cell": origin}
    var approach: Dictionary = _ai_approach_costs(actor_id, goals)
    var reachable: Dictionary = get_reachable(actor_id)
    var best_cell: Vector2i = origin
    var best_score: int = _ai_position_score(actor_id, origin, reachable, approach)
    # Iterate coordinates explicitly rather than relying on Dictionary order.
    for y in grid_size.y:
        for x in grid_size.x:
            var cell := Vector2i(x, y)
            if not reachable.has(cell) or cell == origin:
                continue
            var score: int = _ai_position_score(actor_id, cell, reachable, approach)
            if score < best_score:
                best_cell = cell
                best_score = score
    return {"cell": best_cell}


func _ai_attack_choice(actor_id: String, cell: Vector2i) -> Dictionary:
    var source: Dictionary = actors[actor_id]
    var best: Dictionary = {}
    var ids: Array = actors.keys()
    ids.sort()
    for id_variant in ids:
        var target_id: String = str(id_variant)
        var target: Dictionary = actors[target_id]
        var distance: int = _distance(cell, target["position"])
        var weapon_id: String = _ai_weapon_id(source, distance)
        var weapon: Dictionary = _attack_from(actor_id, target_id, cell, weapon_id)
        if weapon.is_empty():
            continue
        var score: int = cover_bonus(cell, target["position"]) * 40
        if weapon.get("kind", "") == "ranged_weapon":
            if distance * 5 > int(weapon.get("normal_range_feet", 0)):
                score += 160
            for other_id in ids:
                if actors[other_id]["team"] != source["team"] and is_combat_capable(str(other_id)) \
                        and _distance(cell, actors[other_id]["position"]) <= 1:
                    score += 160
        if best.is_empty() or score < int(best["score"]) or (
                score == int(best["score"]) and distance < int(best["distance"])):
            best = {"target": target_id, "weapon": weapon_id, "score": score, "distance": distance}
    return best


func _ai_approach_costs(actor_id: String, goals: Dictionary) -> Dictionary:
    # Reverse Dijkstra potential to legal attack tiles, using _can_step and
    # actual terrain entry costs. Unlike straight-line distance this leads out
    # of U-shaped obstacles even when the first step goes away from the enemy.
    var costs: Dictionary = goals.duplicate()
    var pending: Array = goals.keys()
    while not pending.is_empty():
        var best := 0
        for i in range(1, pending.size()):
            if int(costs[pending[i]]) < int(costs[pending[best]]):
                best = i
        var cell: Vector2i = pending.pop_at(best)
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if dx == 0 and dy == 0:
                    continue
                var previous := cell + Vector2i(dx, dy)
                if not _is_open(actor_id, previous) or not _can_step(actor_id, previous, cell):
                    continue
                var step_cost: int = movement_cost(cell, actor_id) * 100
                step_cost += _ai_hazard_cost(cell, "enter")
                var cost: int = int(costs[cell]) + step_cost
                if not costs.has(previous) or cost < int(costs[previous]):
                    costs[previous] = cost
                    if not pending.has(previous):
                        pending.append(previous)
    return costs


func _ai_position_score(actor_id: String, cell: Vector2i, reachable: Dictionary,
        approach: Dictionary) -> int:
    var origin: Vector2i = actors[actor_id]["position"]
    var score: int = int(approach.get(cell, 1000000)) + int(reachable[cell]["cost"]) * 6
    score += _ai_hazard_cost(cell, "start_turn")
    # Evaluate the exact route move_to will reconstruct, not just its endpoint.
    var current: Vector2i = cell
    var threatened_by: Dictionary = {}
    while current != origin:
        var previous: Vector2i = reachable[current]["previous"]
        score += _ai_hazard_cost(current, "enter")
        for id_variant in actors.keys():
            var reactor_id: String = str(id_variant)
            if not threatened_by.has(reactor_id) and _can_opportunity_attack(
                    reactor_id, actor_id, previous, current):
                score += 500
                threatened_by[reactor_id] = true
        current = previous
    return score


func _ai_hazard_cost(cell: Vector2i, trigger: String) -> int:
    var cost := 0
    for effect in active_effects.values():
        if effect["cells"].has(cell) and trigger in effect["triggers"] and effect["condition"] == "restrained":
            cost += 1200
    for hazard in hazards:
        if hazard.get("position") == cell and hazard.get("trigger", []).has(trigger):
            cost += 1200
    return cost


func target_at(cell: Vector2i) -> String:
    # Corpses remain rendered, but only active creatures and downed party members
    # are valid targets. Dead monsters should never intercept clicks.
    for key in actors.keys():
        var actor: Dictionary = actors[key]
        if actor["position"] != cell:
            continue
        if int(actor["hp"]) > 0 or actor.get("combat_state", "") in ["unconscious", "stable", "knocked_out"]:
            return str(key)
    return ""


func movement_remaining() -> int:
    if finished or current_id().is_empty() or int(current_actor().get("hp", 0)) <= 0 or has_condition(current_id(), "restrained"):
        return 0
    return maxi(0, int(current_actor().get("speed_feet", 30)) / 5 + dash_extra_squares - movement_used)


func can_move_current() -> bool:
    if not current_is_party() or movement_remaining() <= 0:
        return false
    var cells: Dictionary = get_reachable(current_id())
    return cells.size() > 1


func can_cast_any_current_spell() -> bool:
    if not current_is_party() or int(current_actor().get("hp", 0)) <= 0:
        return false
    for spell_id in get_current_spells():
        if can_cast_current_spell(spell_id):
            return true
    return false


func can_dash() -> bool:
    return _utility_ready() and not action_used


func use_dash() -> bool:
    if not can_dash():
        return _reject("use_dash", "unavailable: action/resource, actor, source or pending resolution")
    action_used = true
    dash_extra_squares = int(current_actor().get("speed_feet", 30)) / 5
    _record("%s Dashes, gaining %d extra squares of movement." % [
        current_actor()["name"], dash_extra_squares
    ])
    _event("action_committed", current_id(), "", {"action_id": "dash", "cost": "Action", "action_used": action_used, "movement_remaining": movement_remaining()})
    committed_actions.append("dash")
    return true


func can_dodge() -> bool:
    return _utility_ready() and not action_used


func use_dodge() -> bool:
    if not can_dodge():
        return _reject("use_dodge", "unavailable: action/resource, actor, source or pending resolution")
    action_used = true
    var actor: Dictionary = current_actor()
    actor["dodging"] = true
    actors[current_id()] = actor
    _record("%s Dodges until their next turn." % actor["name"])
    _event("action_committed", current_id(), "", {"action_id": "dodge", "cost": "Action", "action_used": action_used, "movement_remaining": movement_remaining()})
    committed_actions.append("dodge")
    return true


func _nearest_opponent(source_id: String) -> String:
    var source: Dictionary = actors[source_id]
    var best_id := ""
    var best_distance := 999999
    for id_variant in actors.keys():
        var id: String = str(id_variant)
        var target: Dictionary = actors[id]
        if target["team"] == source["team"] or not is_combat_capable(id):
            continue
        var distance := _distance(source["position"], target["position"])
        if distance < best_distance:
            best_distance = distance
            best_id = id
    return best_id


func _begin_turn() -> void:
    turn_serial += 1
    committed_actions.clear()
    _expire_effects()
    for effect in active_effects.values():
        effect["occasions"].clear()
    action_used = false
    bonus_action_used = false
    slotted_cast_this_turn = false
    sneak_attack_used = false
    movement_used = 0
    dash_extra_squares = 0
    if not current_id().is_empty():
        var actor: Dictionary = actors[current_id()]
        actor["dodging"] = false
        actor["reaction_used"] = false
        actor["disengaged"] = false
        actor["shield_bonus"] = 0
        actors[current_id()] = actor
        _tick_concentration(current_id())
        _actor_burning_start_turn(current_id())
        var was_unconscious: bool = actor.get("combat_state", "") == "unconscious"
        if str(actor.get("combat_state", "")) in ["unconscious", "stable"]:
            _web_fire_start_turn(current_id(), actor["position"])
        if not was_unconscious and int(actor["hp"]) > 0:
            effect_hook(current_id(), "start_turn")
            _trigger_hazards(current_id(), actor["position"], "start_turn")
        _record("Turn: %s." % current_actor()["name"])
        if was_unconscious and not finished:
            _roll_death_save(current_id())
        elif actor.get("combat_state", "") == "stable":
            _audit("Death save", current_id(), "", {"outcome": "SKIPPED", "reason": "stable; no player turn"})



func _roll_death_save(actor_id: String) -> void:
    var actor: Dictionary = actors[actor_id]
    if actor.get("combat_state", "") != "unconscious":
        return
    var natural: int = Dice.roll_d20(rng)
    if natural == 20:
        actor["hp"] = 1
        actor["combat_state"] = "active"
        actor["death_successes"] = 0
        actor["death_failures"] = 0
        _record("%s rolls a natural 20 on a Death Save and regains 1 HP." % actor["name"])
    else:
        if natural == 1:
            actor["death_failures"] = int(actor["death_failures"]) + 2
        elif natural >= 10:
            actor["death_successes"] = int(actor["death_successes"]) + 1
        else:
            actor["death_failures"] = int(actor["death_failures"]) + 1
        _record("%s Death Save %d: %d success(es), %d failure(s)." % [
            actor["name"], natural, actor["death_successes"], actor["death_failures"]
        ])
        if int(actor["death_failures"]) >= 3:
            actor["combat_state"] = "dead"
            _end_burning("actor:" + actor_id, "dead")
            _emit_sound("death")
            _record("%s has died." % actor["name"])
        elif int(actor["death_successes"]) >= 3:
            actor["combat_state"] = "stable"
            actor["death_successes"] = 0
            actor["death_failures"] = 0
            _record("%s is stable but unconscious." % actor["name"])
    _audit("Death save", actor_id, actor_id, {"dice": [natural], "die": "d20", "total": natural, "dc": 10, "outcome": "SUCCESS" if natural >= 10 else "FAILURE", "consequence": {"hp": actor["hp"], "state": actor["combat_state"], "successes": actor["death_successes"], "failures": actor["death_failures"]}})
    actors[actor_id] = actor
    if actor.get("combat_state", "") == "dead":
        _event("death", actor_id, actor_id, {"source_kind": "death_save"})


func _check_victory() -> void:
    if finished or deployment_active:
        return
    var party_can_fight := false
    var enemies_can_fight := false
    for key in actors.keys():
        var id: String = str(key)
        if not is_combat_capable(id):
            continue
        if actors[id]["team"] == "party":
            party_can_fight = true
        else:
            enemies_can_fight = true
    if not enemies_can_fight or not party_can_fight:
        finished = true
        victor = "party" if party_can_fight else "enemy"
        pending_move.clear()
        pending_reaction.clear()
        for effect_id in active_effects.keys():
            end_effect(str(effect_id), "encounter_ended")
        for key in burning_targets.keys():
            _end_burning(str(key), "encounter_ended")
        _record("VICTORY — opposing side incapacitated." if party_can_fight else
            "DEFEAT — no adventurer can fight.")


func _distance(a: Vector2i, b: Vector2i) -> int:
    return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _is_open(actor_id: String, cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
        return false
    if cell in walls or cell in blocked_cells:
        return false
    var occupant := actor_at(cell)
    return occupant.is_empty() or occupant == actor_id


func _can_step(actor_id: String, start_cell: Vector2i, end_cell: Vector2i) -> bool:
    if not _is_open(actor_id, end_cell):
        return false
    var diff := end_cell - start_cell
    if diff.x != 0 and diff.y != 0:
        # Neither adjacent orthogonal square may be blocked: no corner cutting.
        return _is_open(actor_id, start_cell + Vector2i(diff.x, 0)) and _is_open(actor_id, start_cell + Vector2i(0, diff.y))
    return true


func _line_clear(from_cell: Vector2i, to_cell: Vector2i) -> bool:
    # Wagon and solid walls block shots; small chests instead grant half cover.
    var steps := _distance(from_cell, to_cell)
    if steps <= 1:
        return true
    for i in range(1, steps):
        var fraction := float(i) / float(steps)
        var cell := Vector2i(
            roundi(lerpf(float(from_cell.x), float(to_cell.x), fraction)),
            roundi(lerpf(float(from_cell.y), float(to_cell.y), fraction))
        )
        if cell in walls or cell in sight_blockers:
            return false
    return true


func cover_bonus(from_cell: Vector2i, to_cell: Vector2i) -> int:
    # Half cover from a chest between attacker and target; it never blocks LOS.
    # Target standing adjacent to a chest alone is not sufficient: the chest
    # must actually intersect the tile ray between the two characters.
    var steps: int = _distance(from_cell, to_cell)
    for i in range(1, steps):
        var fraction: float = float(i) / float(steps)
        var cell := Vector2i(
            roundi(lerpf(float(from_cell.x), float(to_cell.x), fraction)),
            roundi(lerpf(float(from_cell.y), float(to_cell.y), fraction))
        )
        if cell in cover_cells:
            return 2
    return 0



# Level-1 action/bonus-action features. The immutable fixture never mutates:
# these resources live on the combatant's runtime state.
func can_use_second_wind() -> bool:
    if not _utility_ready() or bonus_action_used:
        return false
    var actor: Dictionary = current_actor()
    return actor.get("class_id", "") == "champion" \
        and int(actor.get("second_wind_remaining", 0)) > 0 \
        and int(actor["hp"]) > 0 and int(actor["hp"]) < int(actor["max_hp"])


func use_second_wind() -> bool:
    if not can_use_second_wind():
        return _reject("use_second_wind", "unavailable: action/resource, actor, source or pending resolution")
    var actor_id: String = current_id()
    var actor: Dictionary = actors[actor_id]
    var natural := Dice.roll(10, rng)
    var amount: int = natural + int(actor["level"])
    _audit("Second Wind", actor_id, actor_id, {"dice": [natural], "die": "d10", "modifiers": {"level": actor["level"]}, "total": amount, "consequence": "Bonus Action and one use spent; healing capped at missing HP"})
    var restored: int = mini(amount, int(actor["max_hp"]) - int(actor["hp"]))
    actor["hp"] = int(actor["hp"]) + restored
    actor["second_wind_remaining"] = int(actor["second_wind_remaining"]) - 1
    actors[actor_id] = actor
    bonus_action_used = true
    _emit_sound("heal")
    _record("%s uses Second Wind, healing %d HP (%d/%d); %d use(s) left." % [
        actor["name"], restored, actor["hp"], actor["max_hp"], actor["second_wind_remaining"]
    ])
    _event("heal", actor_id, actor_id, {"amount": restored, "action_id": "second_wind"})
    committed_actions.append("second_wind")
    return true


func _sneak_attack_eligible(source_id: String, target_id: String, weapon: Dictionary, disadvantage: bool) -> bool:
    if sneak_attack_used or disadvantage:
        return false
    var source: Dictionary = actors[source_id]
    if source.get("class_id", "") != "thief":
        return false
    if weapon.get("kind", "") == "ranged_weapon":
        pass
    elif not weapon.get("id", "") in ["dagger", "shortsword"]:
        return false
    var target: Dictionary = actors[target_id]
    for ally_id in actors.keys():
        var ally: Dictionary = actors[ally_id]
        if ally["team"] == source["team"] and str(ally_id) != source_id \
                and int(ally["hp"]) > 0 and _distance(ally["position"], target["position"]) <= 1:
            return true
    return false


func spell_slots_left(actor_id: String, slot_level: int) -> int:
    if not actors.has(actor_id) or slot_level <= 0:
        return 0
    var actor: Dictionary = actors[actor_id]
    if slot_level == 1:
        return maxi(0, int(actor.get("spell_slots_remaining", 0)))
    return maxi(0, int(actor.get("spell_slots_by_level", {}).get(str(slot_level), 0)))


func spell_slot_capacity(actor_id: String, slot_level: int) -> int:
    if not actors.has(actor_id) or slot_level <= 0:
        return 0
    var casting: Variant = actors[actor_id].get("spellcasting")
    if not casting is Dictionary:
        return 0
    return maxi(0, int(casting.get("spell_slots", {}).get(str(slot_level), 0)))


func can_cast_spell(spell_id: String, target_id: String) -> bool:
    return spell_unavailable_reason(spell_id, target_id).is_empty()


func can_cast_current_spell(spell_id: String) -> bool:
    if Level1Spells.get_definition(spell_id).get("target", "") == "area":
        if not spell_resource_reason(spell_id).is_empty():
            return false
        for y in range(grid_size.y):
            for x in range(grid_size.x):
                if area_spell_reason(spell_id, Vector2i(x, y)).is_empty():
                    return true
        return false
    if spell_id == "fire_bolt" and spell_resource_reason(spell_id).is_empty():
        for effect in active_effects.values():
            for cell in effect["cells"]:
                if fire_bolt_cell_reason(cell).is_empty():
                    return true
    for target_id in actors.keys():
        if can_cast_spell(spell_id, str(target_id)):
            return true
    return false


func spell_resource_reason(spell_id: String) -> String:
    # Single authority for casting, cards, target highlights and contextual hints.
    # Empty means legal. Check turn/resources before target-specific restrictions.
    if deployment_active:
        return "Begin battle before casting."
    if finished or current_id().is_empty():
        return "No active combat turn."
    if not pending_reaction.is_empty() or not pending_move.is_empty():
        return "Resolve the pending reaction or movement first."
    var caster: Dictionary = current_actor()
    if not is_combat_capable(current_id()):
        return "This creature cannot act."
    if not Level1Spells.known_spells(caster).has(spell_id):
        return "Choose a known spell."
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell.is_empty():
        return "Spell is not implemented."
    if spell["time"] == "reaction":
        return "This spell is only available as a reaction."
    if spell["time"] == "action" and action_used:
        return "Action already used this turn."
    if spell["time"] == "bonus" and bonus_action_used:
        return "Bonus action already used this turn."
    if int(spell["level"]) > 0:
        if slotted_cast_this_turn:
            return "A slotted spell was already cast this turn."
        # Spend the defined tier only; no implicit higher-slot upcasting.
        if spell_slots_left(current_id(), int(spell["level"])) <= 0:
            return "No level %d spell slots remaining." % int(spell["level"])
    if spell["effect"] == "mage_armor":
        if bool(caster.get("mage_armor_active", false)):
            return "Mage Armor is already active."
        if caster.get("armor") != null:
            return "Mage Armor requires an unarmored caster."
    return ""


func spell_unavailable_reason(spell_id: String, target_id: String) -> String:
    var reason := spell_resource_reason(spell_id)
    if not reason.is_empty():
        return reason
    var caster: Dictionary = current_actor()
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell.get("target", "") == "area":
        return "Choose a top-left floor cell, then Confirm Web."
    if not actors.has(target_id):
        return "Choose a creature on a gold target cell."
    var target: Dictionary = actors[target_id]
    if spell["target"] == "enemy" and (caster["team"] == target["team"] or not is_combat_capable(target_id)):
        return "Choose an active enemy."
    if spell["target"] == "ally" and (caster["team"] != target["team"] or target.get("combat_state", "") == "dead"):
        return "Choose a living ally (downed allies can be healed)."
    if spell["target"] == "self" and target_id != current_id():
        return "This spell targets the caster; use Cast on Self."
    if _distance(caster["position"], target["position"]) * 5 > int(spell["range_feet"]):
        return "Target is out of spell range."
    if not _line_clear(caster["position"], target["position"]):
        return "Line of sight is blocked."
    return ""


func cast_spell(spell_id: String, target_id: String) -> bool:
    if not can_cast_spell(spell_id, target_id):
        return _reject(spell_id, spell_unavailable_reason(spell_id, target_id), target_id)
    var caster_id: String = current_id()
    var caster: Dictionary = actors[caster_id]
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell["time"] == "action":
        action_used = true
    else:
        bonus_action_used = true
    if int(spell["level"]) > 0:
        var tier: String = str(int(spell["level"]))
        var slots: Dictionary = caster.get("spell_slots_by_level", {}).duplicate()
        slots[tier] = maxi(0, spell_slots_left(caster_id, int(spell["level"])) - 1)
        caster["spell_slots_by_level"] = slots
        if tier == "1":
            caster["spell_slots_remaining"] = int(slots[tier])
        slotted_cast_this_turn = true
        actors[caster_id] = caster
    var target: Dictionary = actors[target_id]
    var effect: String = str(spell["effect"])
    _event("cast", caster_id, target_id, {
        "action_id": spell_id, "effect": effect,
        "damage_type": str(spell.get("damage_type", ""))
    })
    if effect != "heal":
        _emit_sound("magic")
    var title: String = spell_id.replace("_", " ").capitalize()
    match effect:
        "bless":
            _start_bless(caster_id, target_id)
        "mage_armor":
            target["mage_armor_active"] = true
            var dexterity_mod: int = Dice.ability_modifier(int(target["ability_scores"]["dexterity"]))
            target["armor_class"] = 13 + dexterity_mod
            actors[target_id] = target
            _record("%s casts Mage Armor; AC is now %d." % [caster["name"], target["armor_class"]])
        "heal":
            var ability_bonus := Dice.ability_modifier(int(caster["ability_scores"][str(caster["spellcasting"]["ability"])]))
            var healing: int = _roll_formula(str(spell["healing"]), false, caster_id, target_id, spell_id, "healing") + ability_bonus
            _audit("Healing modifier", caster_id, target_id, {"source": spell_id, "modifiers": {"spell ability": ability_bonus}, "total": healing, "consequence": "healing capped at missing HP"})
            var gained: int = mini(maxi(0, healing), int(target["max_hp"]) - int(target["hp"]))
            target["hp"] = int(target["hp"]) + gained
            if int(target["hp"]) > 0 and target.get("combat_state", "") in ["unconscious", "stable"]:
                target["combat_state"] = "active"
                target["death_successes"] = 0
                target["death_failures"] = 0
            actors[target_id] = target
            _emit_sound("heal")
            _record("%s casts %s on %s for %d HP (%d/%d)." % [
                caster["name"], title, target["name"], gained, target["hp"], target["max_hp"]
            ])
            _event("heal", caster_id, target_id, {"amount": gained, "action_id": spell_id})
        "automatic_damage":
            var damage: int = _roll_formula(str(spell["damage"]), false, caster_id, target_id, spell_id, "spell damage")
            _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
        "dex_save_damage":
            var roll: int = dexterity_save(target_id)
            var dc: int = int(caster["spellcasting"]["save_dc"])
            var details := last_d20.duplicate(true)
            details.merge({"source": spell_id, "dc": dc, "outcome": "SUCCESS" if roll >= dc else "FAILURE", "consequence": "no damage" if roll >= dc else "roll damage"})
            _audit("DEX save", target_id, caster_id, details)
            if roll >= dc:
                _record("%s resists %s (Dex save %d vs DC %d)." % [target["name"], title, roll, dc])
                _event("miss", caster_id, target_id, {
                    "action_id": spell_id, "source_kind": "spell",
                    "damage_type": str(spell.get("damage_type", ""))
                })
            else:
                var damage: int = _roll_formula(str(spell["damage"]), false, caster_id, target_id, spell_id, "spell damage")
                _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
        "attack_damage":
            var d20: int = _attack_d20(caster_id, target_id)
            var attack_bonus: int = int(caster["spellcasting"]["spell_attack_bonus"])
            var hit: Dictionary = _attack_check(caster_id, target_id, d20, attack_bonus,
                effective_ac(target) + cover_bonus(caster["position"], target["position"]), spell_id)
            if hit["hit"]:
                var damage: int = _roll_formula(str(spell["damage"]), bool(hit["critical"]), caster_id, target_id, spell_id, "spell hit")
                _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
            else:
                _emit_sound("miss")
                _record("%s casts %s at %s: %d vs AC %d — MISS." % [
                    caster["name"], title, target["name"], hit["total"], target["armor_class"]
                ])
                _event("miss", caster_id, target_id, {
                    "action_id": spell_id, "source_kind": "spell",
                    "damage_type": str(spell.get("damage_type", ""))
                })
    return true


func _apply_spell_damage(caster: Dictionary, target_id: String, spell_name: String, damage: int, damage_type: String) -> void:
    var target: Dictionary = actors[target_id]
    var before_hp: int = int(target["hp"])
    if damage_type == "fire":
        ignite_web_cell(target["position"], str(caster.get("id", "")))
    _deal_damage(target_id, damage)
    target = actors[target_id]
    _emit_sound("damage")
    _record("%s casts %s on %s: %d %s damage (%d HP left)." % [
        caster["name"], spell_name, target["name"], damage, damage_type, target["hp"]
    ])
    _event("hit", str(caster.get("id", "")), target_id, {
        "amount": damage, "action_id": spell_name.to_snake_case(),
        "damage_type": damage_type, "source_kind": "spell",
        "hp_before": before_hp, "hp_after": int(target["hp"]),
        "state_after": str(target["combat_state"])
    })
    if not is_combat_capable(target_id):
        _record("%s is %s." % [target["name"], target["combat_state"]])
    _check_victory()


func get_current_spells() -> Array[String]:
    if finished or current_id().is_empty():
        return []
    var result: Array[String] = []
    for spell_id in Level1Spells.known_spells(current_actor()):
        if Level1Spells.get_definition(spell_id).get("time", "") != "reaction":
            result.append(spell_id)
    return result



func _bless_bonus(actor_id: String) -> int:
    if not actors.has(actor_id):
        return 0
    var blessed_by: String = str(actors[actor_id].get("blessed_by", ""))
    if blessed_by.is_empty() or not actors.has(blessed_by):
        return 0
    var caster: Dictionary = actors[blessed_by]
    var concentration: Dictionary = caster.get("concentration", {})
    if concentration.get("spell", "") != "bless":
        return 0
    var bonus: int = rng.randi_range(1, 4)
    _audit("Bless", actor_id, blessed_by, {"dice": [bonus], "die": "d4", "total": bonus, "consequence": "added to current test"})
    _record("%s gains +%d from Bless." % [actors[actor_id]["name"], bonus])
    return bonus


func _stop_concentration(caster_id: String, reason: String = "ended") -> void:
    var caster: Dictionary = actors[caster_id]
    var concentration: Dictionary = caster.get("concentration", {})
    if concentration.is_empty():
        return
    caster["concentration"] = {}
    actors[caster_id] = caster
    for effect_id in active_effects.keys():
        if active_effects[effect_id]["concentration_owner"] == caster_id:
            end_effect(str(effect_id), reason)
    for target_id_variant in concentration.get("targets", []):
        var target_id: String = str(target_id_variant)
        if actors.has(target_id):
            var target: Dictionary = actors[target_id]
            if target.get("blessed_by", "") == caster_id:
                target["blessed_by"] = ""
                actors[target_id] = target
    caster["concentration"] = {}
    actors[caster_id] = caster
    _event("concentration_ended", caster_id, "", {"spell": concentration.get("spell", ""), "effect_id": concentration.get("effect_id", ""), "reason": reason})
    _record("%s's concentration ends." % caster["name"])


func _start_bless(caster_id: String, first_target: String) -> void:
    _stop_concentration(caster_id, "replacement")
    var caster: Dictionary = actors[caster_id]
    var targets: Array[String] = [first_target]
    # The clicked target receives priority; fill the remaining spots with
    # nearby allies in deterministic order. Explicit multi-target UI comes later.
    var others: Array[Dictionary] = []
    for key in actors.keys():
        var id: String = str(key)
        var ally: Dictionary = actors[id]
        if id == first_target or ally["team"] != caster["team"] or int(ally["hp"]) <= 0:
            continue
        var squares: int = _distance(caster["position"], ally["position"])
        if squares <= 6:
            others.append({"id": id, "distance": squares})
    others.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if a["distance"] == b["distance"]:
            return a["id"] < b["id"]
        return a["distance"] < b["distance"]
    )
    for entry in others:
        if targets.size() >= 3:
            break
        targets.append(str(entry["id"]))
    for id in targets:
        var ally: Dictionary = actors[id]
        ally["blessed_by"] = caster_id
        actors[id] = ally
    caster = actors[caster_id]
    caster["concentration"] = {"spell": "bless", "targets": targets, "turns_left": 10}
    actors[caster_id] = caster
    _event("concentration_started", caster_id, "", {"spell": "bless", "targets": targets.duplicate()})
    var names: PackedStringArray = []
    for id in targets:
        names.append(str(actors[id]["name"]))
    _record("%s casts Bless on %s (+1d4 to attacks and saving throws)." % [
        caster["name"], ", ".join(names)
    ])


func _tick_concentration(caster_id: String) -> void:
    var caster: Dictionary = actors[caster_id]
    var concentration: Dictionary = caster.get("concentration", {})
    if concentration.is_empty() or concentration.has("effect_id"):
        return
    concentration["turns_left"] = int(concentration.get("turns_left", 1)) - 1
    caster["concentration"] = concentration
    actors[caster_id] = caster
    if int(concentration["turns_left"]) <= 0:
        _stop_concentration(caster_id, "expired")


func _check_concentration_after_damage(actor_id: String, damage: int) -> void:
    var actor: Dictionary = actors[actor_id]
    var concentration: Dictionary = actor.get("concentration", {})
    if concentration.is_empty() or damage <= 0:
        return
    if not is_combat_capable(actor_id):
        _audit("Concentration", actor_id, "", {"outcome": "SKIPPED", "reason": "incapacitated; concentration ends automatically"})
        _stop_concentration(actor_id, "incapacitated")
        return
    var dc: int = clampi(floori(float(damage) / 2.0), 10, 30)
    var natural: int = Dice.roll_d20(rng)
    var con_mod: int = Dice.ability_modifier(int(actor.get("ability_scores", {}).get("constitution", 10)))
    var bless := _bless_bonus(actor_id)
    var total: int = natural + con_mod + bless
    _audit("Concentration CON save", actor_id, "", {"dice": [natural], "die": "d20", "modifiers": {"Constitution": con_mod, "Bless": bless}, "total": total, "dc": dc, "outcome": "SUCCESS" if total >= dc else "FAILURE", "consequence": "concentration maintained" if total >= dc else "concentration ends"})
    _record("%s Concentration Save: %d vs DC %d." % [actor["name"], total, dc])
    _event("concentration_save", actor_id, "", {"total": total, "dc": dc, "success": total >= dc})
    if total < dc:
        _stop_concentration(actor_id, "damage")


func _event(kind: String, actor_id: String = "", target_id: String = "",
        payload: Dictionary = {}) -> void:
    # Versioned, deterministic combat facts. UI must not parse _record() prose for VFX.
    # Each resolved event gets a stable sequence ID in this encounter session.
    var entry: Dictionary = {
        "schema_version": 1, "event_id": "%s:%06d" % [encounter_id, events.size()],
        "round": round_number, "turn": turn_serial, "kind": kind, "actor_id": actor_id,
        "target_id": target_id, "text": "", "sound": ""
    }
    # Position snapshots are captured when combat resolves, before the UI
    # receives events. Presentation must not query moving actors for endpoints.
    if actors.has(actor_id):
        var source_cell: Vector2i = actors[actor_id]["position"]
        entry["source_cell"] = [source_cell.x, source_cell.y]
    if actors.has(target_id):
        var target_cell: Vector2i = actors[target_id]["position"]
        entry["target_cell"] = [target_cell.x, target_cell.y]
    entry["resources"] = {"action_used": action_used, "bonus_action_used": bonus_action_used, "movement_used": movement_used, "dash_extra_squares": dash_extra_squares}
    for key in payload.keys():
        entry[key] = payload[key]
    if str(entry["text"]).is_empty() and kind != "sound":
        entry["text"] = Audit.format_event(entry, actors)
    events.append(entry)


func _record(line: String) -> void:
    _event("log", "", "", {"text": line})


func _emit_sound(sound_id: String) -> void:
    _event("audio", "", "", {"sound": sound_id})


func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}


# Area queries never mutate resources, concentration, events or RNG.
func _area_barrier(cell: Vector2i) -> bool:
    if cell in walls:
        return true
    for prop in obstacles:
        var origin: Vector2i = prop["position"]
        var size: Vector2i = prop["size"]
        if Rect2i(origin, size).has_point(cell) and bool(prop.get("blocks_area", prop.get("blocks_sight", false))):
            return true
    return false


func preview_area_spell(spell_id: String, selected: Vector2i) -> Dictionary:
    var anchor := selected - Vector2i.ONE
    var result := {"target_point": selected, "anchor": anchor, "nominal_cells": [],
        "affected_cells": [], "blocked_cells": [], "reason": spell_resource_reason(spell_id)}
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell.get("target", "") != "area":
        result["reason"] = "This spell targets creatures."
        return result
    var footprint: Vector2i = spell["footprint"]
    var eligible: Array[Vector2i] = []
    var offboard := false
    for y in range(footprint.y):
        for x in range(footprint.x):
            var cell := anchor + Vector2i(x, y)
            result["nominal_cells"].append(cell)
            if not Rect2i(Vector2i.ZERO, grid_size).has_point(cell):
                offboard = true
            elif not _area_barrier(cell):
                eligible.append(cell)
    var reached: Array[Vector2i] = []
    if eligible.has(selected):
        reached.append(selected)
        var cursor := 0
        while cursor < reached.size():
            for offset in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
                var next: Vector2i = reached[cursor] + offset
                if eligible.has(next) and not reached.has(next):
                    reached.append(next)
            cursor += 1
    for cell in result["nominal_cells"]:
        result["affected_cells" if reached.has(cell) else "blocked_cells"].append(cell)
    if not str(result["reason"]).is_empty():
        return result
    if offboard:
        result["reason"] = "The full 4x4 footprint must be on the floor."
    elif not eligible.has(selected):
        result["reason"] = "Selected point is blocked."
    elif _distance(current_actor()["position"], selected) * 5 > int(spell["range_feet"]):
        result["reason"] = "Point is beyond 60 feet."
    elif not _line_clear(current_actor()["position"], selected):
        result["reason"] = "Line of sight to the point is blocked."
    return result


func area_spell_reason(spell_id: String, selected: Vector2i) -> String:
    return str(preview_area_spell(spell_id, selected)["reason"])


func cast_area_spell(spell_id: String, anchor: Vector2i) -> bool:
    if not area_spell_reason(spell_id, anchor).is_empty():
        return _reject(spell_id, area_spell_reason(spell_id, anchor))
    var caster_id := current_id()
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    var id := create_area_effect(caster_id, {
        "schema_version": 1, "type": spell_id, "anchor": anchor - Vector2i.ONE,
        "cells": preview_area_spell(spell_id, anchor)["affected_cells"],
        "footprint": spell["footprint"], "duration_rounds": spell["duration_rounds"],
        "concentration": true, "save_dc": int(current_actor()["spellcasting"]["save_dc"]),
        "difficult_terrain": true, "lightly_obscured": true, "flammable": true,
        "condition": "restrained", "triggers": ["enter", "start_turn"]})
    if id.is_empty():
        return false
    action_used = true
    slotted_cast_this_turn = true
    actors[caster_id]["spell_slots_by_level"]["2"] = spell_slots_left(caster_id, 2) - 1
    _event("cast", caster_id, "", {"action_id": spell_id, "effect_id": id,
        "anchor": [anchor.x, anchor.y], "slot_level": 2})
    _emit_sound("magic")
    return true


func is_lightly_obscured(cell: Vector2i) -> bool:
    for effect in area_effects_at(cell):
        if effect.get("lightly_obscured", false):
            return true
    return false


func sight_perception_disadvantage(cell: Vector2i) -> bool:
    # Lab has no Perception resolver. This typed seam does not alter LOS/attacks.
    return is_lightly_obscured(cell)


func is_web_burning(cell: Vector2i) -> bool:
    for effect in active_effects.values():
        if effect.get("burning_cells", {}).has(cell):
            return true
    return false


func fire_bolt_cell_reason(cell: Vector2i) -> String:
    var reason := spell_resource_reason("fire_bolt")
    if not reason.is_empty():
        return reason
    var eligible := false
    for effect in area_effects_at(cell):
        if effect.get("flammable", false) and not effect["burning_cells"].has(cell):
            eligible = true
    if not eligible:
        return "Choose an intact Web cell or an enemy."
    if _distance(current_actor()["position"], cell) * 5 > 120:
        return "Web cell is out of Fire Bolt range."
    if not _line_clear(current_actor()["position"], cell):
        return "Line of sight is blocked."
    return ""


func cast_fire_bolt_cell(cell: Vector2i) -> bool:
    if not fire_bolt_cell_reason(cell).is_empty():
        return false
    action_used = true
    _event("cast", current_id(), "", {"action_id": "fire_bolt", "cell": [cell.x, cell.y],
        "effect": "ignite_web", "damage_type": "fire"})
    ignite_web_cell(cell, current_id())
    _emit_sound("magic")
    return true


func ignite_web_cell(cell: Vector2i, fire_source: String) -> bool:
    var changed := false
    for id in active_effects.keys():
        var effect: Dictionary = active_effects[id]
        if not effect.get("flammable", false) or not effect["cells"].has(cell) or effect["burning_cells"].has(cell):
            continue
        var burn := _burning_state("web_cell", "%s:%d:%d" % [id, cell.x, cell.y], fire_source, "web_one_round", 1)
        # Existing overlapping fire owns its original clock and source.
        for other in active_effects.values():
            if other["burning_cells"].has(cell):
                var existing: Dictionary = other["burning_cells"][cell]
                for field in ["source", "owner", "start_round", "start_turn", "expiry_round", "expiry_turn"]:
                    burn[field] = existing[field]
                break
        effect["burning_cells"][cell] = burn
        _event("burning_started", str(burn["source"]), "", burn.duplicate(true))
        _event("web_ignited", str(burn["source"]), "", {"effect_id": id, "cell": [cell.x, cell.y]})
        _event("area_updated", str(effect["source"]), "", _effect_payload(str(id)))
        changed = true
    return changed


func _sorted_cells(cells: Array) -> Array:
    var result := cells.duplicate()
    result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
    return result


func _expire_burning_cells() -> void:
    # Collect the complete boundary before ignition/removal. No new fire can
    # recursively propagate during this boundary, including overlapping regions.
    var expired: Array[Dictionary] = []
    var wave: Dictionary = {}
    var ids := active_effects.keys()
    ids.sort()
    var fuel_cells: Dictionary = {}
    for id in ids:
        var effect: Dictionary = active_effects[id]
        if effect.get("flammable", false):
            for cell in effect["cells"]:
                if not _area_barrier(cell):
                    fuel_cells[cell] = true
    for id in ids:
        var effect: Dictionary = active_effects[id]
        for cell in _sorted_cells(effect["burning_cells"].keys()):
            var burn: Dictionary = effect["burning_cells"][cell]
            if round_number < int(burn["expiry_round"]) or (round_number == int(burn["expiry_round"]) and turn_index < int(burn["expiry_turn"])):
                continue
            expired.append({"id": id, "cell": cell, "source": burn["source"]})
            for offset in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
                var next: Vector2i = cell + offset
                # Connected fuel may belong to another caster's Web. Region
                # ownership must not create an invisible firebreak.
                if fuel_cells.has(next) and not is_web_burning(next) and not wave.has(next):
                    wave[next] = burn["source"]
    for cell in _sorted_cells(wave.keys()):
        ignite_web_cell(cell, str(wave[cell]))
    for item in expired:
        var id: String = item["id"]
        var cell: Vector2i = item["cell"]
        var effect: Dictionary = active_effects[id]
        effect["cells"].erase(cell)
        var consumed: Dictionary = effect["burning_cells"][cell].duplicate(true)
        consumed["reason"] = "fuel_consumed"
        effect["burning_cells"].erase(cell)
        _event("burning_ended", str(item["source"]), "", consumed)
        for application in effect["applications"].duplicate():
            var actor_id: String = application["actor_id"]
            if actors[actor_id]["position"] == cell:
                _remove_condition(actor_id, str(application["condition"]), id)
        _event("web_cell_removed", str(item["source"]), "", {"effect_id": id, "cell": [cell.x, cell.y]})
        _event("area_updated", str(effect["source"]), "", _effect_payload(id))
    for id in ids:
        if active_effects.has(id) and active_effects[id]["cells"].is_empty():
            end_effect(str(id), "burned_away")


func _web_fire_start_turn(actor_id: String, cell: Vector2i) -> void:
    if actors[actor_id].get("combat_state", "") == "dead":
        return
    # Overlapping burning webs are one fire exposure per start, never per source.
    for id in active_effects.keys():
        var effect: Dictionary = active_effects[id]
        if not effect["burning_cells"].has(cell):
            continue
        var key := "%d:%s:fire" % [turn_serial, actor_id]
        if effect["occasions"].has(key):
            return
        for other in active_effects.values():
            if other["burning_cells"].has(cell):
                other["occasions"][key] = true
        var source: String = effect["burning_cells"][cell]["source"]
        var damage := _roll_formula("2d4", false, source, actor_id, str(id), "start in burning Web")
        var before: int = actors[actor_id]["hp"]
        _deal_damage(actor_id, damage)
        _event("hit", source, actor_id, {"action_id": "web_fire", "effect_id": id,
            "source_kind": "area", "damage_type": "fire", "amount": damage,
            "hp_before": before, "hp_after": actors[actor_id]["hp"],
            "state_after": actors[actor_id]["combat_state"]})
        _check_victory()
        return


# Explicit ignition commands; ordinary fire damage never invokes these adapters.
# House-rule defaults: actor 1d4 for three start turns; props consume fuel only.
func _burning_state(kind: String, key: String, source: String, fuel: String, duration: int) -> Dictionary:
    return {"schema_version": 1, "target_kind": kind, "target_key": key,
        "source": source, "owner": source, "start_round": round_number,
        "start_turn": turn_index, "expiry_round": round_number + duration,
        "expiry_turn": turn_index, "intensity": 1, "fuel_policy": fuel,
        "ticks_remaining": duration, "last_turn_serial": -1}


func burning_snapshot(kind: String, target_key: String) -> Dictionary:
    return burning_targets.get(kind + ":" + target_key, {}).duplicate(true)


func burning_snapshots() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var keys := burning_targets.keys()
    keys.sort()
    for key in keys:
        result.append(burning_targets[key].duplicate(true))
    for id in active_effects.keys():
        for cell in _sorted_cells(active_effects[id]["burning_cells"].keys()):
            result.append(active_effects[id]["burning_cells"][cell].duplicate(true))
    return result


func ignite_actor(actor_id: String, source: String) -> bool:
    var key := "actor:" + actor_id
    if deployment_active or finished or source.is_empty() or not actors.has(actor_id) \
            or str(actors[actor_id].get("combat_state", "")) in ["dead", "knocked_out"] or burning_targets.has(key):
        return false
    burning_targets[key] = _burning_state("actor", actor_id, source, "three_start_turn_ticks", 3)
    _event("burning_started", source, actor_id, burning_targets[key].duplicate(true))
    return true


func ignite_prop(prop_id: String, source: String) -> bool:
    var key := "prop:" + prop_id
    if deployment_active or finished or source.is_empty() or burning_targets.has(key):
        return false
    for prop in obstacles:
        if str(prop.get("id", "")) == prop_id and bool(prop.get("flammable", false)):
            burning_targets[key] = _burning_state("prop", prop_id, source, "authored_prop_rounds", maxi(1, int(prop.get("fuel_rounds", 3))))
            _event("burning_started", source, "", burning_targets[key].duplicate(true))
            return true
    return false


func _end_burning(key: String, reason: String) -> void:
    if not burning_targets.has(key):
        return
    var state: Dictionary = burning_targets[key].duplicate(true)
    state["reason"] = reason
    burning_targets.erase(key)
    _event("burning_ended", str(state["source"]), str(state["target_key"]) if state["target_kind"] == "actor" else "", state)


func douse_burning(kind: String, target_key: String, source: String) -> bool:
    # Typed water/future adapter. No weather system or automatic water detection.
    var key := kind + ":" + target_key
    if source.is_empty() or not burning_targets.has(key):
        return false
    _end_burning(key, "doused:" + source)
    return true


func douse_web_cell(cell: Vector2i, source: String) -> bool:
    if source.is_empty():
        return false
    var changed := false
    for id in active_effects.keys():
        if active_effects[id]["burning_cells"].has(cell):
            var burn: Dictionary = active_effects[id]["burning_cells"][cell].duplicate(true)
            active_effects[id]["burning_cells"].erase(cell)
            burn["reason"] = "doused:" + source
            _event("burning_ended", source, "", burn)
            _event("area_updated", source, "", _effect_payload(str(id)))
            changed = true
    return changed


func can_extinguish() -> bool:
    return not deployment_active and not finished and is_combat_capable(current_id()) \
        and not action_used and pending_reaction.is_empty() and pending_move.is_empty() \
        and burning_targets.has("actor:" + current_id())


func extinguish() -> bool:
    if not can_extinguish():
        return _reject("extinguish", "unavailable: action/resource, actor, source or pending resolution")
    action_used = true
    _end_burning("actor:" + current_id(), "extinguish_action")
    _event("action_committed", current_id(), "", {"action_id": "extinguish", "cost": "Action"})
    committed_actions.append("extinguish")
    return true


func _actor_burning_start_turn(actor_id: String) -> void:
    var key := "actor:" + actor_id
    if not burning_targets.has(key):
        return
    if str(actors[actor_id].get("combat_state", "")) in ["dead", "knocked_out"]:
        _end_burning(key, "incapacitated")
        return
    var burn: Dictionary = burning_targets[key]
    if int(burn["last_turn_serial"]) == turn_serial:
        return
    burn["last_turn_serial"] = turn_serial
    burn["ticks_remaining"] -= 1
    var damage := _roll_formula("1d4", false, str(burn["source"]), actor_id, "Burning", "start_turn")
    var before: int = actors[actor_id]["hp"]
    _deal_damage(actor_id, damage)
    _event("hit", str(burn["source"]), actor_id, {"action_id": "burning", "source_kind": "burning",
        "damage_type": "fire", "amount": damage, "hp_before": before,
        "hp_after": actors[actor_id]["hp"], "state_after": actors[actor_id]["combat_state"]})
    _event("burning_updated", str(burn["source"]), actor_id, burn.duplicate(true))
    if int(burn["ticks_remaining"]) <= 0 or str(actors[actor_id]["combat_state"]) == "dead":
        _end_burning(key, "fuel_consumed")
    _check_victory()


func _expire_prop_burning() -> void:
    for key in burning_targets.keys():
        var burn: Dictionary = burning_targets[key]
        if burn["target_kind"] == "prop" and (round_number > int(burn["expiry_round"]) or \
                (round_number == int(burn["expiry_round"]) and turn_index >= int(burn["expiry_turn"]))):
            _end_burning(str(key), "fuel_consumed")


func _utility_ready() -> bool:
    return not deployment_active and not finished and current_is_party() and is_combat_capable(current_id()) and pending_reaction.is_empty() and pending_move.is_empty()


func action_info(action_id: String, source_id: String = "", target_id: String = "") -> Dictionary:
    # Schema 1 is the sole UI explanation/legality seam; queries are side-effect free.
    var info := {"schema_version": 1, "id": action_id, "name": action_id.replace("_", " ").capitalize(),
        "cost": "1 Action", "effect": "", "duration": "instant", "consequence": "Action is spent on commitment",
        "details": "Select to inspect; Confirm or a second distinct press commits. Cancel spends nothing.", "legal": false, "reason": ""}
    var actor := current_actor()
    match action_id:
        "dash":
            info["legal"] = can_dash()
            info["effect"] = "gain %d ft of movement" % int(actor.get("speed_feet", 30))
            info["duration"] = "rest of this turn"
            info["consequence"] = "movement can still provoke opportunity attacks; cancelling Move does not refund the Action"
        "disengage":
            info["legal"] = can_disengage()
            info["effect"] = "your movement does not provoke opportunity attacks"
            info["duration"] = "rest of this turn"
            info["consequence"] = "does not grant movement; cancelling Move does not refund the Action"
        "dodge":
            info["legal"] = can_dodge()
            info["effect"] = "incoming attacks have disadvantage; Dexterity saves have advantage"
            info["duration"] = "until your next turn"
            info["consequence"] = "defence is lost while Restrained (speed zero) or incapacitated"
        "second_wind":
            info["legal"] = can_use_second_wind()
            info["cost"] = "1 Bonus Action + 1 use (%d left)" % int(actor.get("second_wind_remaining", 0))
            info["effect"] = "heal 1d10 + %d HP" % int(actor.get("level", 1))
            info["consequence"] = "healing capped at missing HP; Action remains independent"
        "escape":
            info["legal"] = can_escape_effect(source_id)
            var source: Dictionary = active_effects.get(source_id, {})
            info["effect"] = "Strength (Athletics) vs DC %d; remove Restrained from %s (%s, caster %s) on success" % [int(source.get("save_dc", 0)), source.get("type", "choose source"), source_id, source.get("source", "unknown")]
            info["consequence"] = "failure still spends Action; other restraint sources remain"
            info["details"] = "Choose a specific restraint source. Leaving or ending that source also removes its condition. " + str(info["details"])
        "extinguish":
            info["legal"] = can_extinguish()
            info["effect"] = "end your Burning (%d ticks left)" % int(burning_snapshot("actor", current_id()).get("ticks_remaining", 0))
            info["consequence"] = "does not extinguish surrounding Web or props; later ignition remains possible"
        "move":
            info["legal"] = can_move_current() and pending_reaction.is_empty() and pending_move.is_empty()
            info["cost"] = "movement only (%d ft left)" % (movement_remaining() * 5)
            info["effect"] = "tap a reachable destination"
            info["duration"] = "this turn's movement allowance"
            info["consequence"] = "terrain costs extra; movement may provoke unless Disengaged"
            info["details"] = "Move is not another Action. Cancel only clears targeting. Restrained prevents movement."
        "attack":
            info["legal"] = _utility_ready() and not action_used
            info["effect"] = "attack a legal target with " + source_id.replace("_", " ")
            info["consequence"] = "target tap commits; hit and damage are rolled"
            info["details"] = "Red targets are legal. Range, cover, defence and conditions affect the roll."
            if not target_id.is_empty() and available_attack(target_id, source_id).is_empty():
                info["legal"] = false
                info["reason"] = "selected target is not legal for this weapon"
        "spell":
            var spell := Level1Spells.get_definition(source_id)
            info["name"] = source_id.replace("_", " ").capitalize()
            info["legal"] = can_cast_current_spell(source_id)
            info["reason"] = spell_resource_reason(source_id)
            info["cost"] = ("1 Bonus Action" if spell.get("time", "") == "bonus" else "1 Action")
            var level := int(spell.get("level", 0))
            if level > 0:
                info["cost"] += " + L%d slot (%d left)" % [level, spell_slots_left(current_id(), level)]
            info["effect"] = {"attack_damage": "roll a spell attack; on hit deal", "dex_save_damage": "target makes a Dexterity save; on failure deal", "automatic_damage": "automatically deal", "heal": "restore HP:", "mage_armor": "set AC to 13 + Dexterity", "bless": "up to three allies add 1d4 to attacks and saves", "web": "create Web"}.get(str(spell.get("effect", "")), "unimplemented")
            if spell.has("damage"):
                info["effect"] += " " + str(spell["damage"]) + " " + str(spell.get("damage_type", ""))
            if spell.has("healing"):
                info["effect"] += " " + str(spell["healing"]) + " + spell ability modifier"
            info["duration"] = "%d rounds%s" % [int(spell["duration_rounds"]), " (concentration)" if spell.get("concentration", false) else ""] if spell.has("duration_rounds") else ("8 hours" if source_id == "mage_armor" else "instant")
            info["consequence"] = "target tap commits; one spell-slot expenditure per turn"
            info["details"] = "Range: %d ft. Resource and target legality are revalidated when casting." % int(spell.get("range_feet", 0))
            if source_id == "web":
                info["effect"] = "4x4 Web; difficult terrain, lightly obscured; DEX vs DC %d or Restrained" % int(actor.get("spellcasting", {}).get("save_dc", 0))
                info["consequence"] = "same-square second tap or Confirm Web casts; replaces concentration; flammable"
            elif not target_id.is_empty():
                info["reason"] = spell_unavailable_reason(source_id, target_id)
                info["legal"] = info["reason"].is_empty()
        _:
            info["reason"] = "unknown action"
    if not info["legal"] and str(info["reason"]).is_empty():
        if not _utility_ready():
            info["reason"] = "actor unavailable, deployment, battle ended or resolution pending"
        elif action_id == "move":
            info["reason"] = "Restrained, no reachable destinations or movement exhausted"
        elif action_id == "second_wind":
            info["reason"] = "Bonus Action used, no uses, full HP or class unavailable"
        else:
            info["reason"] = "Action used or required condition/source unavailable"
    return info
