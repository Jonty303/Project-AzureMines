extends SceneTree
const SCENE = preload("res://scenes/combat.tscn")
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)

func _run() -> void:
    var lab = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab._start_battle()
    var b = lab.engine
    b.begin_battle()
    b.turn_index = b.turn_order.find("alden")
    b._begin_turn()
    b.walls.clear()
    b.blocked_cells.clear()
    b.actors["alden"]["position"] = Vector2i(5, 5)
    var id: String = b.create_test_web_area("elyra", Vector2i(4, 4), 2, true, 100)
    _check(not id.is_empty(), "presentation fixture creation failed")
    b.effect_hook("alden", "enter")
    var state: int = b.rng.state
    var facts: Array = b.events.duplicate(true)
    for zoom in [0.65, 1.0, 1.6]:
        lab.board.camera_zoom = zoom
        lab.board.camera_offset = Vector2(-50, 20)
        lab._refresh()
        await process_frame
        _check(b.area_effects_at(Vector2i(5, 5)).size() == 1, "region snapshot missing under camera changes")
    _check(b.rng.state == state and b.events == facts and not b.action_used, "presentation changed rules/occasion/resources")
    _check(lab.party_status.text.contains("Restrained") and lab.escape_button.visible and not lab.escape_button.disabled, "status/escape UI missing")
    _check(not lab.spell_ids.has("web") and not lab.spell_ids.has("test_web_area"), "fixture leaked into spell menu")
    var snapshot: Array = b.area_effects_at(Vector2i(5, 5))
    snapshot[0]["cells"].clear()
    _check(b.active_effects[id]["cells"].size() == 16, "region snapshot aliases authoritative cells")
    b.active_effects[id]["save_dc"] = 1
    lab._escape_effect()
    lab._confirm_action()
    _check(b.action_used and not b.has_condition("alden", "restrained"), "player escape adapter failed")
    b.action_used = false
    b._apply_condition("alden", "restrained", id)
    b.pending_reaction = {"kind": "opportunity", "reactor": "alden", "target": "lab_skeleton_01"}
    lab._refresh()
    _check(lab.escape_button.disabled, "escape UI bypasses pending reaction")
    b.pending_reaction.clear()
    b.actors["alden"]["hp"] = 0
    b.actors["alden"]["combat_state"] = "unconscious"
    lab._refresh()
    _check(not lab.escape_button.visible and lab.end_turn_button.disabled, "downed player action prompt regressed")
    b._stop_concentration("elyra")
    lab._refresh()
    await process_frame
    _check(b.area_effects_at(Vector2i(5, 5)).is_empty() and not lab.party_status.text.contains("Restrained"), "expired region/status persisted")
    lab.board.reset_presentation()
    lab.queue_free()
    await process_frame
    if failures == 0:
        print("PASS: v052 region/status rendering seam, camera invariance, player escape and downed controls (physical visual acceptance NOT RUN)")
    quit(0 if failures == 0 else 1)
