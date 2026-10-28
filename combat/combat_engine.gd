extends RefCounted
## Headless, fixture-driven v0.1 combat state. Rendering and UI do not live here.
## Movement, action economy and damage are deliberately small, not a full SRD implementation.

const Dice = preload("res://core/dice_roller.gd")
const RulesMath = preload("res://combat/rules_math.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")
const PARTY_FIXTURE := "res://tests/fixtures/party/level_01_v1.json"
const ENCOUNTER_FIXTURE := "res://adventures/test_adventure/encounters/training_battle.json"
const FORMATIONS := {
    "line": {"alden": [3, 5], "brunna": [2, 5], "pip": [1, 5], "elyra": [0, 5]},
    "square": {"alden": [3, 4], "brunna": [3, 5], "elyra": [2, 4], "pip": [2, 5]},
    "diamond": {"alden": [3, 5], "brunna": [2, 4], "elyra": [2, 6], "pip": [1, 5]}
}

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


func start(seed: int = 42024, with_deployment: bool = false) -> bool:
    var party: Dictionary = _read_json(PARTY_FIXTURE)
    var encounter: Dictionary = _read_json(ENCOUNTER_FIXTURE)
    if party.is_empty() or encounter.is_empty():
        return false
    if not party.has("characters") or not encounter.has("enemies"):
        return false

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
        actor["spell_slots_remaining"] = int(casting.get("spell_slots", {}).get("1", 0)) if casting is Dictionary else 0
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
        actor["art"] = {"combat_sprite": "assets/characters/sprites/goblin_front_64.png"}
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
        var roll := Dice.roll_d20(rng)
        var result := roll + Dice.ability_modifier(dexterity)
        rolls.append({"id": id, "initiative": result, "tie": tie_order})
        tie_order += 1
        _record("%s initiative: %d (%d on d20)" % [actor["name"], result, roll])
    rolls.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        if a["initiative"] == b["initiative"]:
            return a["tie"] < b["tie"]
        return a["initiative"] > b["initiative"]
    )
    for item in rolls:
        turn_order.append(str(item["id"]))
    _record("Encounter begins: four adventurers versus four goblins at the wagon camp.")
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
    _record("The party is ready. The goblins attack!")
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
    return not deployment_active and not finished and current_actor().get("team", "") == "party"


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
    if not is_combat_capable(id):
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
                var cost := 2 if next in difficult_terrain else 1
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
        return false
    var actor_id: String = current_id()
    var actor: Dictionary = actors[actor_id]
    if int(actor["hp"]) <= 0:
        return false
    var reachable: Dictionary = get_reachable(actor_id)
    if not reachable.has(destination) or int(reachable[destination]["cost"]) <= 0:
        return false
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
        if int(actors[mover_id]["hp"]) <= 0:
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
        var cost: int = 2 if next_cell in difficult_terrain else 1
        if movement_used + cost > int(mover.get("speed_feet", 30)) / 5 + dash_extra_squares:
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
        _emit_sound("footstep")
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
        var damage: int = RulesMath.roll_damage(str(hazard.get("damage", "1d4")), rng)
        _record("%s is burned by the %s for %d fire damage (%s)." % [
            actors[actor_id]["name"], str(hazard.get("kind", "hazard")), damage,
            "entry" if trigger == "enter" else "start of turn"
        ])
        _emit_sound("magic")
        _emit_sound("damage")
        _deal_damage(actor_id, damage)
        _check_victory()


func _opportunity_reactor(mover_id: String, from_cell: Vector2i, next_cell: Vector2i) -> String:
    if bool(actors[mover_id].get("disengaged", false)):
        return ""
    var mover: Dictionary = actors[mover_id]
    for id_variant in actors.keys():
        var reactor_id: String = str(id_variant)
        var reactor: Dictionary = actors[reactor_id]
        if reactor["team"] == mover["team"] or int(reactor["hp"]) <= 0:
            continue
        if bool(reactor.get("reaction_used", false)) or reaction_checked.has(reactor_id):
            continue
        var pos: Vector2i = reactor["position"]
        if _distance(pos, from_cell) > 1 or _distance(pos, next_cell) <= 1:
            continue
        if not _line_clear(pos, from_cell):
            continue
        for attack_data in reactor.get("attacks", []):
            if attack_data.get("kind", "") == "melee_weapon":
                return reactor_id
    return ""


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
    var natural: int = Dice.roll_d20(rng)
    var result: Dictionary = RulesMath.attack_hits(natural, int(weapon.get("to_hit", 0)) + _bless_bonus(reactor_id),
        effective_ac(target) + cover_bonus(reactor["position"], target["position"]))
    if not bool(result["hit"]):
        _emit_sound("miss")
        _record("%s Opportunity Attack against %s: %d — MISS." % [
            reactor["name"], target["name"], result["total"]
        ])
        return
    var damage: int = RulesMath.roll_damage(str(weapon["damage"]), rng, bool(result["critical"]))
    _emit_sound("melee_hit")
    _emit_sound("damage")
    _record("%s Opportunity Attack hits %s for %d damage." % [reactor["name"], target["name"], damage])
    _deal_damage(target_id, damage)
    _check_victory()


func resolve_reaction(accept: bool) -> bool:
    if pending_reaction.is_empty():
        return false
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
            defender["shield_bonus"] = 5
            actors[defender_id] = defender
            _emit_sound("magic")
            _record("%s casts Shield! AC rises to %d until the start of their next turn." % [
                defender["name"], int(defender["armor_class"]) + 5
            ])
        var result: Dictionary = decision["roll"]
        if int(result["total"]) < effective_ac(actors[defender_id]):
            _emit_sound("miss")
            _record("Shield deflects the incoming attack on %s." % defender["name"])
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
    _check_concentration_after_damage(target_id, damage)
    if target["combat_state"] == "dead" and previous_state != "dead":
        _emit_sound("death")
        _record("%s dies." % target["name"])


func stabilize_creature(actor_id: String, medic_id: String) -> Dictionary:
    # Post-battle Medicine first aid does not revive dead creatures.
    if not finished or victor != "party" or not actors.has(actor_id) or not actors.has(medic_id):
        return {"allowed": false}
    var target: Dictionary = actors[actor_id]
    var medic: Dictionary = actors[medic_id]
    if target.get("combat_state", "") not in ["unconscious", "knocked_out"] or not is_combat_capable(medic_id) or medic["team"] != "party":
        return {"allowed": false}
    var wisdom: int = Dice.ability_modifier(int(medic.get("ability_scores", {}).get("wisdom", 10)))
    var proficiency: int = int(medic.get("proficiency_bonus", 2)) if medic.get("skill_proficiencies", []).has("medicine") else 0
    var die: int = Dice.roll_d20(rng)
    var total: int = die + wisdom + proficiency
    var ok: bool = total >= 10
    if ok:
        target["combat_state"] = "active" if int(target["hp"]) > 0 else "stable"
        target["death_successes"] = 0
        target["death_failures"] = 0
        actors[actor_id] = target
    _record("%s checks %s: Medicine %d vs DC 10 — %s." % [
        medic["name"], target["name"], total, "SUCCESS" if ok else "FAILURE"
    ])
    return {"allowed": true, "roll": die, "total": total, "success": ok}


func heal_survivor(caster_id: String, target_id: String) -> bool:
    if not finished or victor != "party" or not actors.has(caster_id) or not actors.has(target_id):
        return false
    var caster: Dictionary = actors[caster_id]
    var target: Dictionary = actors[target_id]
    if caster["team"] != "party" or not is_combat_capable(caster_id):
        return false
    if target.get("combat_state", "") not in ["unconscious", "stable", "knocked_out"]:
        return false
    var spellcasting: Variant = caster.get("spellcasting")
    if not spellcasting is Dictionary or not spellcasting.get("prepared_spells", []).has("cure_wounds"):
        return false
    if int(caster.get("spell_slots_remaining", 0)) <= 0:
        return false
    var spell: Dictionary = Level1Spells.get_definition("cure_wounds")
    var healing: int = RulesMath.roll_damage(str(spell["healing"]), rng)
    healing += Dice.ability_modifier(int(caster["ability_scores"][str(spellcasting["ability"])]))
    var gained: int = mini(maxi(0, healing), int(target["max_hp"]) - int(target["hp"]))
    caster["spell_slots_remaining"] = int(caster["spell_slots_remaining"]) - 1
    target["hp"] = int(target["hp"]) + gained
    if int(target["hp"]) > 0:
        target["combat_state"] = "active"
        target["death_successes"] = 0
        target["death_failures"] = 0
    actors[caster_id] = caster
    actors[target_id] = target
    _emit_sound("heal")
    _record("%s heals %s for %d HP after battle (one spell slot spent)." % [caster["name"], target["name"], gained])
    return true


func can_disengage() -> bool:
    return not finished and current_is_party() and not action_used and int(current_actor().get("hp", 0)) > 0


func use_disengage() -> bool:
    if not can_disengage():
        return false
    action_used = true
    var actor: Dictionary = current_actor()
    actor["disengaged"] = true
    actors[current_id()] = actor
    _record("%s Disengages, preventing Opportunity Attacks from their movement this turn." % actor["name"])
    return true


func available_attack(target_id: String, weapon_id: String = "") -> Dictionary:
    if deployment_active or finished or action_used or not actors.has(target_id):
        return {}
    var source_id := current_id()
    if source_id.is_empty():
        return {}
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    if not is_combat_capable(source_id):
        return {}
    if source["team"] == target["team"] or not is_combat_capable(target_id):
        return {}
    var distance := _distance(source["position"], target["position"])
    if not _line_clear(source["position"], target["position"]):
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
        return false
    var weapon: Dictionary = available_attack(target_id, weapon_id)
    if weapon.is_empty():
        return false
    if nonlethal and weapon.get("kind", "") != "melee_weapon":
        return false
    var source_id := current_id()
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    action_used = true
    var distance := _distance(source["position"], target["position"])
    var disadvantage := false
    if weapon.get("kind", "") == "ranged_weapon":
        disadvantage = distance > int(weapon.get("normal_range_feet", 0)) / 5
        for other_id in actors.keys():
            var nearby: Dictionary = actors[other_id]
            if nearby["team"] != source["team"] and int(nearby["hp"]) > 0:
                if _distance(source["position"], nearby["position"]) <= 1:
                    disadvantage = true
                    break
    var advantage: bool = source.get("vex_target", "") == target_id
    if bool(source.get("sap_pending", false)) or bool(target.get("dodging", false)):
        disadvantage = true
    var first: int = Dice.roll_d20(rng)
    var natural: int = first
    if advantage != disadvantage:
        var second: int = Dice.roll_d20(rng)
        natural = maxi(first, second) if advantage else mini(first, second)
    if source.get("race_id", "") == "halfling" and natural == 1:
        natural = Dice.roll_d20(rng)
        _record("%s uses Halfling Luck to reroll a natural 1." % source["name"])
    source["sap_pending"] = false
    source["vex_target"] = ""
    actors[source_id] = source
    var roll: Dictionary = RulesMath.attack_hits(
        natural, int(weapon.get("to_hit", 0)) + _bless_bonus(source_id),
        effective_ac(target) + cover_bonus(source["position"], target["position"])
    )
    var attack_name := str(weapon.get("id", "attack")).replace("_", " ")
    var disadvantage_label := " (Disadvantage)" if disadvantage else ""
    if not roll["hit"]:
        if weapon.get("kind", "") == "ranged_weapon":
            _emit_sound("ranged")
        _emit_sound("miss")
        _record("%s uses %s against %s: %d vs AC %d — MISS%s." % [
            source["name"], attack_name, target["name"], roll["total"], target["armor_class"], disadvantage_label
        ])
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
    var damage: int = RulesMath.roll_damage(str(weapon.get("damage", "1d4")), rng, bool(roll["critical"]))
    _emit_sound("ranged" if weapon.get("kind", "") == "ranged_weapon" else "melee_hit")
    if _sneak_attack_eligible(source_id, target_id, weapon, disadvantage):
        var sneak_damage: int = RulesMath.roll_damage("1d6", rng, bool(roll["critical"]))
        damage += sneak_damage
        sneak_attack_used = true
        _record("%s uses Sneak Attack for %d extra damage." % [source["name"], sneak_damage])
    if weapon.get("mastery", "") == "sap":
        target["sap_pending"] = true
    if weapon.get("mastery", "") == "vex":
        source["vex_target"] = target_id
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
    _record("%s ends their turn." % current_actor()["name"])
    for offset in range(1, turn_order.size() + 1):
        turn_index = (turn_index + 1) % turn_order.size()
        if turn_index == 0:
            round_number += 1
            _record("--- Round %d ---" % round_number)
        var next_actor: Dictionary = actors[turn_order[turn_index]]
        if int(next_actor["hp"]) > 0 or next_actor.get("combat_state", "") == "unconscious":
            _begin_turn()
            return


func take_ai_turn() -> void:
    if deployment_active or finished or current_is_party() or not pending_reaction.is_empty() or not pending_move.is_empty():
        return
    var actor_id: String = current_id()
    var source: Dictionary = current_actor()
    var role: String = str(source.get("role", "melee"))
    var enemy_ids: Array[String] = []
    for target_id_variant in actors.keys():
        var id: String = str(target_id_variant)
        var target: Dictionary = actors[id]
        if target["team"] != source["team"] and int(target["hp"]) > 0:
            enemy_ids.append(id)
    if enemy_ids.is_empty():
        _check_victory()
        return

    # Archers prefer line-of-sight shortbow shots instead of charging melee.
    # They only resort to a knife when already engaged in adjacent combat.
    var chosen_id := ""
    var chosen_weapon := ""
    var best_distance := 9999
    for id in enemy_ids:
        var distance: int = _distance(source["position"], actors[id]["position"])
        var weapon_id: String = "shortbow" if role == "ranged" and distance > 1 else "knife"
        if role == "ranged" and distance <= 1:
            weapon_id = "dagger"
        if not available_attack(id, weapon_id).is_empty() and distance < best_distance:
            best_distance = distance
            chosen_id = id
            chosen_weapon = weapon_id
    if not chosen_id.is_empty():
        attack(chosen_id, chosen_weapon)
    else:
        var reachable: Dictionary = get_reachable(actor_id)
        var best_cell: Vector2i = source["position"]
        var best_score: int = 999999
        for cell_variant in reachable.keys():
            var cell: Vector2i = cell_variant
            if cell == source["position"]:
                continue
            for id in enemy_ids:
                var target: Dictionary = actors[id]
                var distance: int = _distance(cell, target["position"])
                if distance <= 0:
                    continue
                var clear: bool = _line_clear(cell, target["position"])
                var score: int = 0
                if role == "ranged":
                    score = (0 if clear else 400) + absi(distance - 4) * 10
                else:
                    score = distance * 15 + (0 if clear else 50)
                score += int(reachable[cell]["cost"])
                if score < best_score:
                    best_score = score
                    best_cell = cell
        if best_cell != source["position"]:
            move_to(best_cell)
            if not pending_reaction.is_empty() or not pending_move.is_empty() or finished:
                return
        if not finished:
            for id in enemy_ids:
                var target: Dictionary = actors[id]
                var distance: int = _distance(actors[actor_id]["position"], target["position"])
                var weapon_id: String = "shortbow" if role == "ranged" and distance > 1 else "knife"
                if role == "ranged" and distance <= 1:
                    weapon_id = "dagger"
                if not available_attack(id, weapon_id).is_empty():
                    attack(id, weapon_id)
                    break
    if not finished and pending_reaction.is_empty() and pending_move.is_empty():
        end_turn()


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
    if finished or current_id().is_empty() or int(current_actor().get("hp", 0)) <= 0:
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
        for target_id in actors.keys():
            if can_cast_spell(spell_id, str(target_id)):
                return true
    return false


func can_dash() -> bool:
    return not finished and current_is_party() and not action_used and int(current_actor().get("hp", 0)) > 0


func use_dash() -> bool:
    if not can_dash():
        return false
    action_used = true
    dash_extra_squares = int(current_actor().get("speed_feet", 30)) / 5
    _record("%s Dashes, gaining %d extra squares of movement." % [
        current_actor()["name"], dash_extra_squares
    ])
    return true


func can_dodge() -> bool:
    return not finished and current_is_party() and not action_used and int(current_actor().get("hp", 0)) > 0


func use_dodge() -> bool:
    if not can_dodge():
        return false
    action_used = true
    var actor: Dictionary = current_actor()
    actor["dodging"] = true
    actors[current_id()] = actor
    _record("%s Dodges until their next turn." % actor["name"])
    return true


func _nearest_opponent(source_id: String) -> String:
    var source: Dictionary = actors[source_id]
    var best_id := ""
    var best_distance := 999999
    for id_variant in actors.keys():
        var id: String = str(id_variant)
        var target: Dictionary = actors[id]
        if target["team"] == source["team"] or int(target["hp"]) <= 0:
            continue
        var distance := _distance(source["position"], target["position"])
        if distance < best_distance:
            best_distance = distance
            best_id = id
    return best_id


func _begin_turn() -> void:
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
        var was_unconscious: bool = actor.get("combat_state", "") == "unconscious"
        if not was_unconscious and int(actor["hp"]) > 0:
            _trigger_hazards(current_id(), actor["position"], "start_turn")
        _record("Turn: %s." % current_actor()["name"])
        if was_unconscious and not finished:
            _roll_death_save(current_id())



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
            _emit_sound("death")
            _record("%s has died." % actor["name"])
        elif int(actor["death_successes"]) >= 3:
            actor["combat_state"] = "stable"
            actor["death_successes"] = 0
            actor["death_failures"] = 0
            _record("%s is stable but unconscious." % actor["name"])
    actors[actor_id] = actor


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
    if finished or bonus_action_used or current_id().is_empty():
        return false
    var actor: Dictionary = current_actor()
    return actor.get("class_id", "") == "champion" \
        and int(actor.get("second_wind_remaining", 0)) > 0 \
        and int(actor["hp"]) > 0 and int(actor["hp"]) < int(actor["max_hp"])


func use_second_wind() -> bool:
    if not can_use_second_wind():
        return false
    var actor_id: String = current_id()
    var actor: Dictionary = actors[actor_id]
    var amount: int = Dice.roll(10, rng) + int(actor["level"])
    var restored: int = mini(amount, int(actor["max_hp"]) - int(actor["hp"]))
    actor["hp"] = int(actor["hp"]) + restored
    actor["second_wind_remaining"] = int(actor["second_wind_remaining"]) - 1
    actors[actor_id] = actor
    bonus_action_used = true
    _emit_sound("heal")
    _record("%s uses Second Wind, healing %d HP (%d/%d); %d use(s) left." % [
        actor["name"], restored, actor["hp"], actor["max_hp"], actor["second_wind_remaining"]
    ])
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


func can_cast_spell(spell_id: String, target_id: String) -> bool:
    if finished or current_id().is_empty() or not actors.has(target_id):
        return false
    var caster: Dictionary = current_actor()
    if not is_combat_capable(current_id()):
        return false
    if not Level1Spells.known_spells(caster).has(spell_id):
        return false
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell.is_empty():
        return false
    if spell["time"] == "reaction":
        return false
    if spell["time"] == "action" and action_used:
        return false
    if spell["time"] == "bonus" and bonus_action_used:
        return false
    if int(spell["level"]) > 0 and (slotted_cast_this_turn or int(caster.get("spell_slots_remaining", 0)) <= 0):
        return false
    var target: Dictionary = actors[target_id]
    if spell["target"] == "enemy" and (caster["team"] == target["team"] or not is_combat_capable(target_id)):
        return false
    if spell["target"] == "ally" and (caster["team"] != target["team"] or target.get("combat_state", "") == "dead"):
        return false
    if spell["target"] == "self" and target_id != current_id():
        return false
    if spell["effect"] == "mage_armor" and (bool(caster.get("mage_armor_active", false)) or caster.get("armor") != null):
        return false
    if _distance(caster["position"], target["position"]) * 5 > int(spell["range_feet"]):
        return false
    return _line_clear(caster["position"], target["position"])


func cast_spell(spell_id: String, target_id: String) -> bool:
    if not can_cast_spell(spell_id, target_id):
        return false
    var caster_id: String = current_id()
    var caster: Dictionary = actors[caster_id]
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell["time"] == "action":
        action_used = true
    else:
        bonus_action_used = true
    if int(spell["level"]) > 0:
        caster["spell_slots_remaining"] = int(caster["spell_slots_remaining"]) - 1
        slotted_cast_this_turn = true
        actors[caster_id] = caster
    var target: Dictionary = actors[target_id]
    var effect: String = str(spell["effect"])
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
            var healing: int = RulesMath.roll_damage(str(spell["healing"]), rng) + \
                Dice.ability_modifier(int(caster["ability_scores"][str(caster["spellcasting"]["ability"])]))
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
        "automatic_damage":
            var damage: int = RulesMath.roll_damage(str(spell["damage"]), rng)
            _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
        "dex_save_damage":
            var roll: int = Dice.roll_d20(rng) + \
                Dice.ability_modifier(int(target.get("ability_scores", {}).get("dexterity", 10))) + _bless_bonus(target_id)
            var dc: int = int(caster["spellcasting"]["save_dc"])
            if roll >= dc:
                _record("%s resists %s (Dex save %d vs DC %d)." % [target["name"], title, roll, dc])
            else:
                var damage: int = RulesMath.roll_damage(str(spell["damage"]), rng)
                _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
        "attack_damage":
            var d20: int = Dice.roll_d20(rng)
            var attack_bonus: int = int(caster["spellcasting"]["spell_attack_bonus"])
            var hit: Dictionary = RulesMath.attack_hits(d20, attack_bonus,
                effective_ac(target) + cover_bonus(caster["position"], target["position"]))
            if hit["hit"]:
                var damage: int = RulesMath.roll_damage(str(spell["damage"]), rng, bool(hit["critical"]))
                _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
            else:
                _emit_sound("miss")
                _record("%s casts %s at %s: %d vs AC %d — MISS." % [
                    caster["name"], title, target["name"], hit["total"], target["armor_class"]
                ])
    return true


func _apply_spell_damage(caster: Dictionary, target_id: String, spell_name: String, damage: int, damage_type: String) -> void:
    var target: Dictionary = actors[target_id]
    _deal_damage(target_id, damage)
    target = actors[target_id]
    _emit_sound("damage")
    _record("%s casts %s on %s: %d %s damage (%d HP left)." % [
        caster["name"], spell_name, target["name"], damage, damage_type, target["hp"]
    ])
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
    _record("%s gains +%d from Bless." % [actors[actor_id]["name"], bonus])
    return bonus


func _stop_concentration(caster_id: String) -> void:
    var caster: Dictionary = actors[caster_id]
    var concentration: Dictionary = caster.get("concentration", {})
    if concentration.is_empty():
        return
    for target_id_variant in concentration.get("targets", []):
        var target_id: String = str(target_id_variant)
        if actors.has(target_id):
            var target: Dictionary = actors[target_id]
            if target.get("blessed_by", "") == caster_id:
                target["blessed_by"] = ""
                actors[target_id] = target
    caster["concentration"] = {}
    actors[caster_id] = caster
    _record("%s's concentration ends." % caster["name"])


func _start_bless(caster_id: String, first_target: String) -> void:
    _stop_concentration(caster_id)
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
    var names: PackedStringArray = []
    for id in targets:
        names.append(str(actors[id]["name"]))
    _record("%s casts Bless on %s (+1d4 to attacks and saving throws)." % [
        caster["name"], ", ".join(names)
    ])


func _tick_concentration(caster_id: String) -> void:
    var caster: Dictionary = actors[caster_id]
    var concentration: Dictionary = caster.get("concentration", {})
    if concentration.is_empty():
        return
    concentration["turns_left"] = int(concentration.get("turns_left", 1)) - 1
    caster["concentration"] = concentration
    actors[caster_id] = caster
    if int(concentration["turns_left"]) <= 0:
        _stop_concentration(caster_id)


func _check_concentration_after_damage(actor_id: String, damage: int) -> void:
    var actor: Dictionary = actors[actor_id]
    var concentration: Dictionary = actor.get("concentration", {})
    if concentration.is_empty() or damage <= 0:
        return
    if int(actor["hp"]) <= 0:
        _stop_concentration(actor_id)
        return
    var dc: int = maxi(10, ceili(float(damage) / 2.0))
    var natural: int = Dice.roll_d20(rng)
    var con_mod: int = Dice.ability_modifier(int(actor.get("ability_scores", {}).get("constitution", 10)))
    var total: int = natural + con_mod + _bless_bonus(actor_id)
    _record("%s Concentration Save: %d vs DC %d." % [actor["name"], total, dc])
    if total < dc:
        _stop_concentration(actor_id)


func _record(line: String) -> void:
    events.append({"round": round_number, "text": line, "sound": ""})


func _emit_sound(sound_id: String) -> void:
    events.append({"round": round_number, "text": "", "sound": sound_id})


func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}
