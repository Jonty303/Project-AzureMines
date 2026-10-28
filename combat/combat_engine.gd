extends RefCounted
## Headless, fixture-driven v0.1 combat state. Rendering and UI do not live here.
## Movement, action economy and damage are deliberately small, not a full SRD implementation.

const Dice = preload("res://core/dice_roller.gd")
const RulesMath = preload("res://combat/rules_math.gd")
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
var movement_used := 0
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
        actor["max_hp"] = int(actor.get("max_hp", 1))
        actors[id] = actor

    for template in encounter["enemies"]:
        var actor: Dictionary = template.duplicate(true)
        var id: String = str(actor["id"])
        var cell: Array = actor["position"]
        actor["position"] = Vector2i(int(cell[0]), int(cell[1]))
        actor["team"] = "enemy"
        actor["hp"] = int(actor.get("max_hp", 1))
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
    var remaining := maxi(0, int(actor.get("speed_feet", 30)) / 5 - movement_used)
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


func available_attack(target_id: String) -> Dictionary:
    if finished or action_used or not actors.has(target_id):
        return {}
    var source_id := current_id()
    if source_id.is_empty():
        return {}
    var source: Dictionary = actors[source_id]
    var target: Dictionary = actors[target_id]
    if source["team"] == target["team"] or int(target["hp"]) <= 0:
        return {}
    var distance := _distance(source["position"], target["position"])
    if not _line_clear(source["position"], target["position"]):
        return {}
    var options: Array = source.get("attacks", [])
    var ranged: Dictionary = {}
    for entry in options:
        var attack: Dictionary = entry
        if attack.get("kind", "") == "melee_weapon" and distance <= 1:
            return attack
        if attack.get("kind", "") in ["ranged_weapon", "spell_attack"]:
            if distance <= int(attack.get("long_range_feet", attack.get("normal_range_feet", 0))) / 5:
                if ranged.is_empty():
                    ranged = attack
    return ranged


func attack(target_id: String) -> bool:
    var weapon: Dictionary = available_attack(target_id)
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
    var first := Dice.roll_d20(rng)
    var natural := first
    if disadvantage:
        natural = mini(first, Dice.roll_d20(rng))
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
    var damage := RulesMath.roll_damage(str(weapon.get("damage", "1d4")), rng, bool(roll["critical"]))
    var old_hp := int(target["hp"])
    target["hp"] = maxi(0, old_hp - damage)
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
        if int(actors[turn_order[turn_index]]["hp"]) > 0:
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
    movement_used = 0
    if not current_id().is_empty():
        _record("Turn: %s." % current_actor()["name"])


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


func _record(line: String) -> void:
    events.append({"round": round_number, "text": line})


func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}
