extends SceneTree
## Deterministic policy regressions; fixtures only, never canonical party edits.
const CombatEngine = preload("res://combat/combat_engine.gd")
var failures := 0

func _initialize() -> void:
    _holding_archer()
    _obstacle_approach()
    _hazard_route()
    _active_threats_and_replay()
    _ai_opportunity(false)
    _ai_opportunity(true)
    _player_disengage()
    if failures == 0:
        print("PASS: v043 holding, obstacle routes, hazards, active threats, replay, AI reactions and Disengage")
    quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)

func _fixture(id: String, origin: Vector2i, target: Vector2i) -> CombatEngine:
    var battle := CombatEngine.new()
    assert(battle.start(43014))
    var source: Dictionary = battle.actors[id].duplicate(true)
    var hero: Dictionary = battle.actors["alden"].duplicate(true)
    battle.actors = {id: source, "alden": hero}
    source["position"] = origin
    hero["position"] = target
    for actor in [source, hero]:
        actor["hp"] = 1000
        actor["max_hp"] = 1000
        actor["combat_state"] = "active"
    battle.walls.clear()
    battle.blocked_cells.clear()
    battle.sight_blockers.clear()
    battle.cover_cells.clear()
    battle.difficult_terrain.clear()
    battle.hazards.clear()
    battle.grid_size = Vector2i(10, 10)
    battle.turn_order = [id, "alden"]
    battle.turn_index = 0
    battle._begin_turn()
    battle.events.clear()
    return battle

func _next_ai(battle: CombatEngine) -> void:
    battle.turn_index = 0
    battle._begin_turn()
    battle.actors["alden"]["reaction_used"] = false

func _holding_archer() -> void:
    var battle := _fixture("goblin_bow", Vector2i(6, 3), Vector2i(1, 3))
    for turn in 3:
        _next_ai(battle)
        battle.take_ai_turn()
        _check(battle.actors["goblin_bow"]["position"] == Vector2i(6, 3), "Good firing tile must hold")
    _check(_attacks(battle).size() == 3, "Holding archer must shoot every turn")
    _check(_moves(battle).is_empty(), "Holding archer emitted pointless moves")
    _next_ai(battle)
    battle.action_used = true
    battle.take_ai_turn()
    _check(_moves(battle).is_empty(), "Spent-action archer must not wander")

func _obstacle_approach() -> void:
    var battle := _fixture("goblin_blade", Vector2i(5, 2), Vector2i(3, 2))
    battle.actors["goblin_blade"]["speed_feet"] = 10
    # Must initially move AWAY from the opponent to round this long wall.
    for y in 7:
        battle.walls.append(Vector2i(4, y))
    var endpoints: Array[Vector2i] = [Vector2i(5, 2)]
    for turn in 8:
        _next_ai(battle)
        battle.take_ai_turn()
        if not _attacks(battle).is_empty():
            break
        var cell: Vector2i = battle.actors["goblin_blade"]["position"]
        _check(not endpoints.has(cell), "Melee stalled or oscillated around obstruction")
        endpoints.append(cell)
    _check(not _attacks(battle).is_empty(), "Melee must round the wall and reach a legal attack")
    for event in _moves(battle):
        var a := Vector2i(event["from"][0], event["from"][1])
        var b := Vector2i(event["to"][0], event["to"][1])
        _check(battle._distance(a, b) == 1 and battle._can_step("goblin_blade", a, b),
            "AI move must respect walls, occupancy and blocked diagonal corners")

func _hazard_route() -> void:
    var battle := _fixture("goblin_blade", Vector2i(1, 3), Vector2i(5, 3))
    battle.actors["goblin_blade"]["speed_feet"] = 20
    for y in range(2, 5):
        battle.hazards.append({"position": Vector2i(2, y), "trigger": ["enter", "start_turn"],
            "damage": "1", "kind": "fire"})
    battle.take_ai_turn()
    _check(not _moves(battle).is_empty(), "Safe approach must make progress")
    for event in _moves(battle):
        var cell := Vector2i(event["to"][0], event["to"][1])
        _check(not (cell.x == 2 and cell.y in [2, 3, 4]), "AI crossed avoidable fire on route")

func _active_threats_and_replay() -> void:
    var first := _fixture("goblin_bow", Vector2i(6, 3), Vector2i(1, 3))
    var downed: Dictionary = first.actors["alden"].duplicate(true)
    downed["id"] = "brunna"
    downed["position"] = Vector2i(5, 3)
    downed["hp"] = 0
    downed["combat_state"] = "unconscious"
    first.actors["brunna"] = downed
    var second := _fixture("goblin_bow", Vector2i(6, 3), Vector2i(1, 3))
    second.actors["brunna"] = downed.duplicate(true)
    for turn in 3:
        _next_ai(first)
        _next_ai(second)
        first.take_ai_turn()
        second.take_ai_turn()
    _check(first.events == second.events, "Fixed seed must replay identical ordered events")
    _check(first.actors == second.actors, "Fixed seed must replay identical actions/state")
    for event in _attacks(first):
        _check(event.get("target_id") == "alden", "AI intentionally attacked a downed hero")
    _check(_attacks(first).size() == 3, "AI must continue attacking active threats")

func _ai_opportunity(accept: bool) -> void:
    var battle := _fixture("goblin_bow", Vector2i(3, 3), Vector2i(2, 3))
    # A burning cul-de-sac makes leaving reach credible. No alternative safe
    # adjacent tile exists; the AI must use move_to's ordinary interrupt.
    battle.grid_size = Vector2i(7, 7)
    for y in 7:
        for x in 7:
            if Vector2i(x, y) not in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3)]:
                battle.blocked_cells.append(Vector2i(x, y))
    battle.hazards.append({"position": Vector2i(3, 3), "trigger": ["enter", "start_turn"],
        "damage": "1", "kind": "fire"})
    battle.take_ai_turn()
    _check(not battle.pending_reaction.is_empty(), "AI leaving Brunna-style reach probe must offer AoO")
    if battle.pending_reaction.is_empty():
        return
    _check(battle.actors["goblin_bow"]["position"] == Vector2i(3, 3), "AI moved before reaction decision")
    _check(battle.resolve_reaction(accept), "AI movement reaction must resolve or decline normally")
    _check(bool(battle.actors["alden"]["reaction_used"]) == accept, "AoO reaction budget mismatch")
    _check(battle.pending_move.is_empty() and battle.pending_reaction.is_empty(), "Interrupted AI route failed to resume")
    _check(battle.actors["goblin_bow"]["position"] != Vector2i(3, 3), "AI route did not leave fire")
    battle.take_ai_turn()
    _check(_attacks(battle).size() >= 1, "AI must attack after interrupted movement resumes")

func _player_disengage() -> void:
    for disengage in [false, true]:
        var battle := _fixture("goblin_blade", Vector2i(3, 3), Vector2i(2, 3))
        battle.turn_index = 1
        battle._begin_turn()
        if disengage:
            _check(battle.use_disengage(), "Player Disengage unavailable")
        _check(battle.move_to(Vector2i(1, 3)), "Player reach probe move failed")
        _check(bool(battle.actors["goblin_blade"]["reaction_used"]) != disengage,
            "Player move/Disengage must retain shared enemy AoO rules")

func _moves(battle: CombatEngine) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for event in battle.events:
        if event.get("kind") == "move":
            result.append(event)
    return result

func _attacks(battle: CombatEngine) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for event in battle.events:
        if event.get("actor_id") == battle.turn_order[0] and event.get("kind") in ["hit", "miss"]:
            result.append(event)
    return result
