extends SceneTree
## v0.3 resolved-combat facts, VFX input contract and iPad sidebar relocation.
const CombatEngine = preload("res://combat/combat_engine.gd")
const SCENE = preload("res://scenes/combat.tscn")


func _initialize() -> void:
    call_deferred("_run")


func _has_event(events: Array[Dictionary], kind: String, source: String, target: String) -> bool:
    for event in events:
        if str(event.get("kind", "")) == kind and str(event.get("actor_id", "")) == source \
                and str(event.get("target_id", "")) == target:
            return true
    return false


func _run() -> void:
    var fight := CombatEngine.new()
    if not fight.start(1701):
        _fail("Could not initialise seeded battle")
        return
    var target: Dictionary = fight.actors["goblin_blade"]
    target["max_hp"] = 90
    target["hp"] = 90
    target["position"] = Vector2i(4, 4)
    fight.actors["goblin_blade"] = target

    var weapon: Dictionary = fight.actors["alden"]["attacks"][0]
    if not fight._resolve_hit("alden", "goblin_blade", weapon,
            {"hit": true, "critical": false, "total": 20}, false):
        _fail("Could not resolve a deterministic weapon hit")
        return
    if not _has_event(fight.events, "hit", "alden", "goblin_blade"):
        _fail("A weapon hit did not emit structured actor/target facts")
        return

    var damage_found := false
    for entry in fight.events:
        if entry.get("kind", "") == "hit" and entry.get("actor_id", "") == "alden":
            if int(entry.get("amount", 0)) > 0 and entry.get("source_kind", "") == "weapon" \
                    and entry.get("damage_type", "") == "slashing":
                damage_found = true
    if not damage_found:
        _fail("Resolved weapon damage metadata was not populated")
        return

    fight.turn_index = fight.turn_order.find("brunna")
    fight._begin_turn()
    var alden: Dictionary = fight.actors["alden"]
    alden["hp"] = 4
    fight.actors["alden"] = alden
    if not fight.cast_spell("healing_word", "alden"):
        _fail("Healing Word could not execute")
        return
    if not _has_event(fight.events, "cast", "brunna", "alden") or \
            not _has_event(fight.events, "heal", "brunna", "alden"):
        _fail("Healing Word did not emit cast and actual healing events")
        return

    fight.turn_index = fight.turn_order.find("elyra")
    fight._begin_turn()
    if not fight.cast_spell("magic_missile", "goblin_blade"):
        _fail("Magic Missile could not execute in the open test lane")
        return
    if not _has_event(fight.events, "cast", "elyra", "goblin_blade") or \
            not _has_event(fight.events, "hit", "elyra", "goblin_blade"):
        _fail("Magic Missile did not emit cast and damage facts")
        return

    var previous_id := ""
    for i in range(fight.events.size()):
        var event: Dictionary = fight.events[i]
        if int(event.get("schema_version", 0)) != 1 or not event.has("event_id") or \
                not event.has("kind") or not event.has("round"):
            _fail("An event lacks the versioned diagnostic contract")
            return
        if str(event["event_id"]) == previous_id:
            _fail("Two resolved events have the same event identifier")
            return
        previous_id = str(event["event_id"])

    var lab: Node = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    var actions: VBoxContainer = lab.get("actions_tab")
    var debug_button: Button = lab.get("debug_action_button")
    if debug_button == null or debug_button.get_parent() != actions:
        _fail("Debug I/O must live inside the Actions tab")
        return
    var heading: Control = lab.get("battle_panel").get_child(0)
    for child in heading.get_children():
        if child is Button and str(child.text) in ["Battle Log", "Debug I/O"]:
            _fail("Top bar still has a redundant Log or Debug button")
            return
    lab.call("_start_battle")
    var lab_engine = lab.get("engine")
    var board = lab.get("board")
    if lab_engine == null or board == null:
        _fail("Lab UI could not initialise combat board")
        return
    var start_effects: int = board.get("_effects").size()
    lab_engine._event("hit", "alden", "goblin_blade", {
        "amount": 7, "source_kind": "weapon", "damage_type": "slashing"
    })
    lab.call("_refresh")
    if board.get("_effects").size() != start_effects + 1:
        _fail("UI did not send the engine's resolved hit to the VFX layer")
        return
    var effect: Dictionary = board.get("_effects").back()
    if effect.get("kind", "") != "hit" or int(effect.get("amount", 0)) != 7:
        _fail("VFX layer lost the authoritative damage amount")
        return
    board.reset_presentation()
    if not board.get("_effects").is_empty():
        _fail("Retry did not reset transient visual effects")
        return

    print("PASS: versioned combat events, weapon/spell/healing facts, VFX routing, iPad Actions/Log/Debug placement")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
