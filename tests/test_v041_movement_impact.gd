extends SceneTree
const SCENE = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var lab: Node = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab.call("_start_battle")
    var board = lab.get("board")
    var engine = lab.get("engine")
    if board == null or engine == null:
        _fail("Missing board or engine")
        return
    board.reset_presentation()
    board.enqueue_combat_event({"kind": "move", "actor_id": "alden", "from": [2, 4], "to": [3, 4]})
    board.enqueue_combat_event({"kind": "move", "actor_id": "alden", "from": [3, 4], "to": [4, 4]})
    var motions: Array = board.get("_movement_queue")
    if motions.size() != 2:
        _fail("Each resolved tile needs a movement animation segment")
        return
    var visible_position: Vector2 = board._render_actor_cell("alden", Vector2i(4, 4))
    if visible_position.distance_to(Vector2(2, 4)) > 0.5:
        _fail("Movement teleported to final tile instead of interpolating")
        return
    if int(motions[1]["start_ms"]) < int(motions[0]["start_ms"]) + int(motions[0]["duration_ms"]):
        _fail("Movement segments did not queue sequentially")
        return
    board.reset_presentation()

    var victim := "lab_skeleton_01"
    var target: Dictionary = engine.actors[victim]
    target["hp"] = 0
    target["combat_state"] = "dead"
    engine.actors[victim] = target
    engine._event("death", victim, victim)
    engine._event("hit", "elyra", victim, {
        "action_id": "fire_bolt", "source_kind": "spell", "damage_type": "fire",
        "amount": 7, "hp_before": 7, "hp_after": 0, "state_after": "dead"
    })
    var new_events_start: int = int(lab.get("heard_events"))
    if not lab._death_waits_for_projectile(new_events_start):
        _fail("Death was not matched to the subsequent projectile")
        return
    lab.call("_refresh")
    var queue: Array = board.get("_projectiles")
    if queue.size() != 1:
        _fail("Projectile missing from visual queue")
        return
    if board._pending_fatal_projectile(victim).is_empty():
        _fail("Visual death occurred before projectile hit")
        return
    for effect in board.get("_effects"):
        if str(effect.get("kind", "")) == "death":
            _fail("Death VFX played before projectile impact")
            return
    var missile: Dictionary = queue[0]
    missile["start_ms"] = Time.get_ticks_msec() - 500
    board.call("_process", 0.5)
    if not board.get("_projectiles").is_empty() or not board._pending_fatal_projectile(victim).is_empty():
        _fail("Impact did not release the victim's visual hold")
        return
    var found_hit := false
    var found_death := false
    for effect in board.get("_effects"):
        found_hit = found_hit or str(effect.get("kind", "")) == "hit"
        found_death = found_death or str(effect.get("kind", "")) == "death"
    if not found_hit or not found_death:
        _fail("Impact and collapse were not shown together")
        return
    board.reset_presentation()
    if not board.get("_movement_queue").is_empty() or not board.get("_projectiles").is_empty():
        _fail("Retry did not clear animation queues")
        return
    print("PASS: movement interpolation, delayed projectile deaths, impact timing and reset")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
