extends SceneTree
## Separate outcomes from one named goblin encounter must remain exclusive and persistent.
const CombatScene = preload("res://scenes/combat.tscn")
const OpeningSession = preload("res://adventure/opening_session.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _ids(session: RefCounted) -> Array[String]:
    var result: Array[String] = []
    for choice in session.exploration_choices():
        result.append(str(choice.get("id", "")))
    return result


func _run() -> void:
    for action in ["hesk_kill", "hesk_capture", "hesk_leave"]:
        var ui: Node = CombatScene.instantiate()
        root.add_child(ui)
        await process_frame
        ui.call("_on_debug_skip_battle")
        var adventure: RefCounted = ui.get("adventure")
        var combat: RefCounted = ui.get("engine")
        if adventure.stage != "victory":
            _fail("Debug setup did not resolve to victory")
            return
        ui.call("_on_story_continue")
        if adventure.stage != "exploration":
            _fail("Could not reach the wagon for " + action)
            return
        if not _ids(adventure).has(action):
            _fail("Missing narrative Hesk option " + action)
            return
        ui.call("_on_exploration_choice", action)
        var npc: Dictionary = adventure.campaign.npc_registry["hesk_roadwatch"]
        var fate: String = action.trim_prefix("hesk_")
        if npc.get("fate", "") != ("captive" if fate == "capture" else ("dead" if fate == "kill" else "left")):
            _fail("Incorrect saved NPC fate for " + action)
            return
        if (fate == "kill") != (not bool(npc["alive"])):
            _fail("Survival is inconsistent with " + action)
            return
        if _ids(adventure).has("hesk_talk") or _ids(adventure).has("hesk_heal") or _ids(adventure).has("hesk_kill"):
            _fail("Resolved fate still offers an incompatible action after " + action)
            return
        if adventure.choose_exploration("hesk_release", combat.actors, combat).get("ok", true):
            _fail("Hesk could be released after a different final fate")
            return
        var path := "user://hesk_" + fate + "_test.json"
        if not adventure.save_game(combat.actors, path):
            _fail("Could not save fate " + fate)
            return
        var reload = OpeningSession.new()
        if not reload.load_game(path):
            _fail("Could not reload fate " + fate)
            return
        if reload.campaign.flags.get("hesk_fate", "") != npc["fate"]:
            _fail("Global fate flag did not persist after " + action)
            return
        if reload.campaign.npc_registry["hesk_roadwatch"]["fate"] != npc["fate"]:
            _fail("NPC registry did not persist after " + action)
            return
        if reload.exploration.available_choices().any(func(c: Dictionary) -> bool:
                return str(c.get("id", "")) == "hesk_release"):
            _fail("Loaded save offers a contradictory release action")
            return
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        ui.queue_free()
        await process_frame
    print("PASS: kill/capture/leave choices mutually exclusive, stored in NPC registry, journal and saves")
    quit(0)
