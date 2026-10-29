extends SceneTree
## Runs a complete deterministic tutorial battle without rendering or mouse input.

const CombatEngine = preload("res://combat/combat_engine.gd")


func _initialize() -> void:
    var battle = CombatEngine.new()
    if not battle.start(42024):
        _fail("Encounter fixture did not load")
        return
    var turns := 0
    while not battle.finished and turns < 100:
        if not battle.pending_reaction.is_empty():
            # Headless player resolves interactive Opportunity Attack / Shield prompts.
            battle.resolve_reaction(true)
        elif battle.current_is_party():
            _play_party_turn(battle)
        else:
            battle.take_ai_turn()
        turns += 1

    if not battle.finished:
        _fail("Battle did not finish within 100 turns (possible stalled AI/movement)")
        return
    var saw_attack := false
    var saw_move := false
    for event in battle.events:
        var line: String = event["text"]
        saw_attack = saw_attack or line.contains(" — HIT") or line.contains(" — MISS")
        saw_move = saw_move or line.contains(" moves from ")
    if not saw_attack or not saw_move:
        _fail("Expected at least one movement and one resolved attack")
        return
    if battle.victor not in ["party", "enemy"]:
        _fail("Finished battle has invalid winner")
        return
    print("PASS: deterministic playable encounter resolves in %d turns (winner: %s)" % [turns, battle.victor])
    quit(0)


func _play_party_turn(battle) -> void:
    var actor: Dictionary = battle.current_actor()
    var enemy_ids: Array[String] = []
    for id_variant in battle.actors.keys():
        var id: String = str(id_variant)
        var other: Dictionary = battle.actors[id]
        if other["team"] == "enemy" and int(other["hp"]) > 0:
            enemy_ids.append(id)
    if enemy_ids.is_empty():
        return

    var target_id := ""
    for id in enemy_ids:
        if not battle.available_attack(id).is_empty():
            target_id = id
            break

    if target_id.is_empty():
        var reachable: Dictionary = battle.get_reachable(battle.current_id())
        var best_cell: Vector2i = actor["position"]
        var best_distance := 9999
        for key in reachable.keys():
            var candidate: Vector2i = key
            var distance := 9999
            for id in enemy_ids:
                var enemy: Dictionary = battle.actors[id]
                var pos: Vector2i = enemy["position"]
                distance = mini(distance, maxi(absi(pos.x - candidate.x), absi(pos.y - candidate.y)))
            if distance < best_distance:
                best_distance = distance
                best_cell = candidate
        if best_cell != actor["position"]:
            battle.move_to(best_cell)
        for id in enemy_ids:
            if not battle.available_attack(id).is_empty():
                target_id = id
                break

    if not target_id.is_empty():
        battle.attack(target_id)
    if not battle.finished:
        battle.end_turn()


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
