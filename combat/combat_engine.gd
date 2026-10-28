extends RefCounted
## Headless, fixture-driven v0.1 combat state. Rendering and UI do not live here.
## Movement, action economy and damage are deliberately small, not a full SRD implementation.

const Dice = preload("res://core/dice_roller.gd")
const RulesMath = preload("res://combat/rules_math.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")
const PARTY_FIXTURE := "res://tests/fixtures/party/level_01_v1.json"
const ENCOUNTER_FIXTURE := "res://adventures/test_adventure/encounters/training_battle.json"

var actors: Dictionary = {}
var walls: Array[Vector2i] = []
var difficult_terrain: Array[Vector2i] = []
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
var finished := false
var victor := ""
var rng := RandomNumberGenerator.new()


func start(seed: int = 42024) -> bool:
    var party: Dictionary = _read_json(PARTY_FIXTURE)
    var encounter: Dictionary = _read_json(ENCOUNTER_FIXTURE)
    if party.is_empty() or encounter.is_empty():
        return false
    if not party.has("characters") or not encounter.has("enemies"):
        return false

    actors.clear()
    walls.clear()
    difficult_terrain.clear()
    turn_order.clear()
    events.clear()
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
        actor["death_successes"] = 0
        actor["death_failures"] = 0
        actor["dodging"] = false
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
        actor["art"] = {"combat_sprite": "assets/characters/sprites/goblin_front_64.png"}
        actor["sap_pending"] = false
        actor["vex_target"] = ""
        actors[id] = actor

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
    _record("Encounter begins: four adventurers versus two goblins.")
    _begin_turn()
    return true


func current_id() -> String:
    if turn_order.is_empty() or finished:
        return ""
    return turn_order[turn_index]


func current_actor() -> Dictionary:
    var id := current_id()
    return actors.get(id, {})


func current_is_party() -> bool:
    return not finished and current_actor().get("team", "") == "party"


func actor_at(cell: Vector2i) -> String:
    for id in actors.keys():
        var actor: Dictionary = actors[id]
        if int(actor["hp"]) > 0 and actor["position"] == cell:
            return str(id)
    return ""


func get_reachable(id: String) -> Dictionary:
    var result: Dictionary = {}
    if not actors.has(id):
        return result
    var actor: Dictionary = actors[id]
    if int(actor["hp"]) <= 0:
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
    if finished or current_id().is_empty():
        return false
    var actor_id := current_id()
    var actor: Dictionary = actors[actor_id]
    if int(actor["hp"]) <= 0:
        return false
    var reachable := get_reachable(actor_id)
    if not reachable.has(destination):
        return false
    var cost: int = reachable[destination]["cost"]
    if cost <= 0:
        return false
    var old_position: Vector2i = actor["position"]
    movement_used += cost
    actor["position"] = destination
    actors[actor_id] = actor
    _record("%s moves from (%d,%d) to (%d,%d), spending %d square(s)." % [
        actor["name"], old_position.x, old_position.y, destination.x, destination.y, cost
    ])
    return true


func available_attack(target_id: String, weapon_id: String = "") -> Dictionary:
    if finished or action_used or not actors.has(target_id):
        return {}
    var source_id := current_id()
    if source_id.is_empty():
        return {}
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    if int(source["hp"]) <= 0:
        return {}
    if source["team"] == target["team"] or int(target["hp"]) <= 0:
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


func attack(target_id: String, weapon_id: String = "") -> bool:
    var weapon: Dictionary = available_attack(target_id, weapon_id)
    if weapon.is_empty():
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
        natural, int(weapon.get("to_hit", 0)), int(target.get("armor_class", 10))
    )
    var attack_name := str(weapon.get("id", "attack")).replace("_", " ")
    var disadvantage_label := " (Disadvantage)" if disadvantage else ""
    if not roll["hit"]:
        _record("%s uses %s against %s: %d vs AC %d — MISS%s." % [
            source["name"], attack_name, target["name"], roll["total"], target["armor_class"], disadvantage_label
        ])
        return true
    var damage: int = RulesMath.roll_damage(str(weapon.get("damage", "1d4")), rng, bool(roll["critical"]))
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
    target["hp"] = maxi(0, old_hp - damage)
    if int(target["hp"]) == 0:
        target["combat_state"] = "unconscious" if target["team"] == "party" else "dead"
    actors[target_id] = target
    var critical_label := " CRITICAL!" if roll["critical"] else ""
    _record("%s uses %s on %s: %d vs AC %d — HIT%s %d %s damage (%d → %d HP)%s." % [
        source["name"], attack_name, target["name"], roll["total"], target["armor_class"],
        critical_label, damage, weapon.get("damage_type", ""), old_hp, target["hp"], disadvantage_label
    ])
    if int(target["hp"]) <= 0:
        _record("%s is down." % target["name"])
    _check_victory()
    return true


func end_turn() -> void:
    if finished or current_id().is_empty():
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
    if finished or current_is_party():
        return
    var source: Dictionary = current_actor()
    var target_id := _nearest_opponent(current_id())
    if target_id.is_empty():
        _check_victory()
        return
    if available_attack(target_id).is_empty():
        var reachable: Dictionary = get_reachable(current_id())
        var best_cell: Vector2i = source["position"]
        var best_distance := 999999
        for cell_variant in reachable.keys():
            var cell: Vector2i = cell_variant
            var target: Dictionary = actors[target_id]
            var proximity := _distance(cell, target["position"])
            if proximity < best_distance and proximity > 0:
                best_distance = proximity
                best_cell = cell
        if best_cell != source["position"]:
            move_to(best_cell)
    if not finished:
        var current_target := _nearest_opponent(current_id())
        if not current_target.is_empty():
            attack(current_target)
    if not finished:
        end_turn()



func target_at(cell: Vector2i) -> String:
    # Corpses remain rendered, but only active creatures and downed party members
    # are valid targets. Dead monsters should never intercept clicks.
    for key in actors.keys():
        var actor: Dictionary = actors[key]
        if actor["position"] != cell:
            continue
        if int(actor["hp"]) > 0 or actor.get("combat_state", "") == "unconscious":
            return str(key)
    return ""


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
        actors[current_id()] = actor
        _record("Turn: %s." % current_actor()["name"])
        if actor.get("combat_state", "") == "unconscious":
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
            _record("%s has died." % actor["name"])
        elif int(actor["death_successes"]) >= 3:
            actor["combat_state"] = "stable"
            _record("%s is stable but unconscious." % actor["name"])
    actors[actor_id] = actor


func _check_victory() -> void:
    var party_alive := false
    var enemy_alive := false
    for actor_variant in actors.values():
        var actor: Dictionary = actor_variant
        if int(actor["hp"]) <= 0:
            continue
        if actor["team"] == "party":
            party_alive = true
        else:
            enemy_alive = true
    if not enemy_alive or not party_alive:
        finished = true
        victor = "party" if party_alive else "enemy"
        _record("VICTORY!" if party_alive else "DEFEAT — the party has fallen.")


func _distance(a: Vector2i, b: Vector2i) -> int:
    return maxi(absi(a.x - b.x), absi(a.y - b.y))


func _is_open(actor_id: String, cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
        return false
    if cell in walls:
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
    # Basic tile visibility: walls block a shot. Creature cover comes later.
    var steps := _distance(from_cell, to_cell)
    if steps <= 1:
        return true
    for i in range(1, steps):
        var fraction := float(i) / float(steps)
        var cell := Vector2i(
            roundi(lerpf(float(from_cell.x), float(to_cell.x), fraction)),
            roundi(lerpf(float(from_cell.y), float(to_cell.y), fraction))
        )
        if cell in walls:
            return false
    return true



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
    if int(caster.get("hp", 0)) <= 0:
        return false
    if not Level1Spells.known_spells(caster).has(spell_id):
        return false
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    if spell.is_empty():
        return false
    if spell["time"] == "action" and action_used:
        return false
    if spell["time"] == "bonus" and bonus_action_used:
        return false
    if int(spell["level"]) > 0 and (slotted_cast_this_turn or int(caster.get("spell_slots_remaining", 0)) <= 0):
        return false
    var target: Dictionary = actors[target_id]
    if spell["target"] == "enemy" and (caster["team"] == target["team"] or int(target["hp"]) <= 0):
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
    var title: String = spell_id.replace("_", " ").capitalize()
    match effect:
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
            _record("%s casts %s on %s for %d HP (%d/%d)." % [
                caster["name"], title, target["name"], gained, target["hp"], target["max_hp"]
            ])
        "automatic_damage":
            var damage: int = RulesMath.roll_damage(str(spell["damage"]), rng)
            _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
        "dex_save_damage":
            var roll: int = Dice.roll_d20(rng) + \
                Dice.ability_modifier(int(target.get("ability_scores", {}).get("dexterity", 10)))
            var dc: int = int(caster["spellcasting"]["save_dc"])
            if roll >= dc:
                _record("%s resists %s (Dex save %d vs DC %d)." % [target["name"], title, roll, dc])
            else:
                var damage: int = RulesMath.roll_damage(str(spell["damage"]), rng)
                _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
        "attack_damage":
            var d20: int = Dice.roll_d20(rng)
            var attack_bonus: int = int(caster["spellcasting"]["spell_attack_bonus"])
            var hit: Dictionary = RulesMath.attack_hits(d20, attack_bonus, int(target["armor_class"]))
            if hit["hit"]:
                var damage: int = RulesMath.roll_damage(str(spell["damage"]), rng, bool(hit["critical"]))
                _apply_spell_damage(caster, target_id, title, damage, str(spell["damage_type"]))
            else:
                _record("%s casts %s at %s: %d vs AC %d — MISS." % [
                    caster["name"], title, target["name"], hit["total"], target["armor_class"]
                ])
    return true


func _apply_spell_damage(caster: Dictionary, target_id: String, spell_name: String, damage: int, damage_type: String) -> void:
    var target: Dictionary = actors[target_id]
    target["hp"] = maxi(0, int(target["hp"]) - damage)
    if int(target["hp"]) == 0:
        target["combat_state"] = "unconscious" if target["team"] == "party" else "dead"
    actors[target_id] = target
    _record("%s casts %s on %s: %d %s damage (%d HP left)." % [
        caster["name"], spell_name, target["name"], damage, damage_type, target["hp"]
    ])
    if int(target["hp"]) == 0:
        _record("%s is down." % target["name"])
    _check_victory()


func get_current_spells() -> Array[String]:
    if finished or current_id().is_empty():
        return []
    return Level1Spells.known_spells(current_actor())


func _record(line: String) -> void:
    events.append({"round": round_number, "text": line})


func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}
