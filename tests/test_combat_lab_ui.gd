extends SceneTree
const SCENE = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: Node = SCENE.instantiate()
    root.add_child(scene)
    await process_frame
    if not scene.get("title_panel").visible or scene.get("battle_panel").visible:
        _fail("Combat Lab must open on its title screen")
        return
    scene.get("level_picker").select(1)
    scene.call("_set_party_level")
    if scene.get("party_level") != 2:
        _fail("Level selection did not update party level")
        return
    scene.call("_show_config")
    if not scene.get("config_dialog").visible:
        _fail("Encounter configuration dialogue did not open")
        return
    scene.get("enemy_picker").select(3)
    scene.get("count_picker").value = 3
    scene.get("arena_picker").select(1)
    scene.get("seed_picker").value = 12345
    scene.call("_apply_config")
    if scene.get("enemy_kind") != "wolf" or scene.get("enemy_count") != 3 or scene.get("arena_id") != "stone":
        _fail("Encounter dialogue did not update the selected battle")
        return
    scene.call("_start_battle")
    var game = scene.get("engine")
    if game == null or not game.deployment_active or not scene.get("battle_panel").visible:
        _fail("Standalone combat could not start deployment")
        return
    if scene.get("title_panel").visible or game.actors["alden"]["level"] != 2 or game.actors.size() != 7:
        _fail("Title failed to transition or level did not flow into combat")
        return
    scene.call("_set_formation", "diamond")
    if game.active_formation != "diamond":
        _fail("Formation selection unavailable in the combat lab")
        return
    scene.call("_begin_battle")
    if game.deployment_active or game.turn_order.size() != 7:
        _fail("Combat Lab could not initiate the tactical battle")
        return
    for id in game.actors.keys():
        var actor: Dictionary = game.actors[id]
        if actor["team"] == "enemy":
            actor["hp"] = 0
            actor["combat_state"] = "dead"
            game.actors[id] = actor
    game._check_victory()
    scene.call("_refresh")
    var report: Dictionary = scene.get("last_report")
    if report.is_empty() or report.get("result", {}).get("outcome", "") != "party":
        _fail("Combat Lab did not capture the battle outcome")
        return
    if report["result"].get("reward_policy", "") != "sandbox_no_rewards" or report["result"]["xp"] != 0:
        _fail("Sandbox incorrectly awarded persistent rewards")
        return
    if not FileAccess.file_exists("user://combat_lab_last_battle.json"):
        _fail("Last battle report was not persisted")
        return
    scene.call("_show_title")
    if not scene.get("title_panel").visible:
        _fail("Could not return to lab title screen")
        return
    scene.call("_show_last_battle")
    if not scene.get("last_view").text.contains("Outcome: party"):
        _fail("Last Battle Log did not display persisted battle result")
        return
    var restored: Node = SCENE.instantiate()
    root.add_child(restored)
    await process_frame
    if restored.get("last_report").get("result", {}).get("outcome", "") != "party":
        _fail("Last battle did not survive a new application session")
        return
    print("PASS: title, configured arena/enemy roster, level, deployment, battle, persisted result and last-battle log")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
