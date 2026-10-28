extends SceneTree
## Debug fast-forward must use normal party victory, preserve Hesk and global NPC memory.
const CombatScene = preload("res://scenes/combat.tscn")
const OpeningSession = preload("res://adventure/opening_session.gd")
const TEST_SAVE := "user://debug_skip_hesk_regression.json"


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _run() -> void:
    if not OS.has_feature("debug"):
        _fail("CI must run Godot debug/editor build to verify the developer button")
        return

    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    var button: Button = ui.get("debug_skip_battle_button")
    var adventure = ui.get("adventure")
    var battle = ui.get("engine")
    if button == null or not button.visible or button.disabled:
        _fail("Developer skip button missing from the opening story")
        return

    # Actual button signal rather than calling the implementation directly.
    button.pressed.emit()
    if adventure.stage != "victory" or not battle.finished or battle.victor != "party":
        _fail("Developer button did not fast-forward to legitimate party victory")
        return
    if button.visible:
        _fail("Skip should disappear once battle is completed")
        return
    var hesk: Dictionary = battle.actors["goblin_blade"]
    if hesk.get("npc_id", "") != "hesk_roadwatch":
        _fail("The spared goblin is not the named Hesk")
        return
    if hesk.get("combat_state", "") != "knocked_out" or int(hesk["hp"]) != 1:
        _fail("Hesk must be unconscious but alive, at 1 HP")
        return
    if not battle.survivors().any(func(entry: Dictionary) -> bool:
            return entry.get("npc_id", "") == "hesk_roadwatch"):
        _fail("Hesk was not registered as a living survivor")
        return
    for id in ["goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        if battle.is_combat_capable(id):
            _fail("A regular goblin was left combat-capable: " + id)
            return
    for id in ["alden", "elyra", "brunna", "pip"]:
        if battle.actors[id]["hp"] != battle.actors[id]["max_hp"]:
            _fail("Skipping from intro damaged a hero: " + id)
            return
    if adventure.gold_gp != 12 or adventure.xp_by_character["alden"] != 50:
        _fail("Fast-forward did not process standard one-time victory rewards")
        return
    if not adventure.campaign.flags.get("debug_wagon_battle_skipped", false):
        _fail("World flags should record a developer-simulated combat result")
        return
    var npc: Dictionary = adventure.campaign.npc_registry["hesk_roadwatch"]
    if not bool(npc["alive"]) or npc["state"] != "knocked_out" or npc["hp"] != 1:
        _fail("Global NPC record forgot that Hesk survived")
        return
    if not ui.get("survivor_panel").visible or not ui.get("survivor_first_aid_button").visible:
        _fail("Victory screen must offer Hesk's normal survivor interaction")
        return

    # Calling the debug shortcut a second time must not grant extra rewards.
    ui.call("_on_debug_skip_battle")
    if adventure.gold_gp != 12 or adventure.xp_by_character["pip"] != 50:
        _fail("Repeated developer skip duplicated encounter rewards")
        return

    if not adventure.save_game(battle.actors, TEST_SAVE):
        _fail("Cannot save the fast-forwarded post-battle state")
        return
    var restored = OpeningSession.new()
    if not restored.load_game(TEST_SAVE):
        _fail("Cannot reload the developer-simulated victory")
        return
    var loaded_hesk: Dictionary = restored.campaign.npc_registry["hesk_roadwatch"]
    if not loaded_hesk["alive"] or loaded_hesk["state"] != "knocked_out" or int(loaded_hesk["hp"]) != 1:
        _fail("Save/load lost Hesk's alive and unconscious state")
        return
    if restored.gold_gp != 12 or restored.campaign.completed_encounters.size() != 1:
        _fail("Save/load lost or duplicated victory rewards")
        return

    if ui.get("story_continue_button").text != "Continue to Wagon Clearing":
        _fail("Debug victory should show the direct wagon-clearing button")
        return
    ui.call("_on_story_continue")
    if adventure.stage != "exploration" or adventure.campaign.current_location != "wagon_clearing":
        _fail("One Continue after debug skip must reach exploration with no interim replay page")
        return
    if not adventure.campaign.npc_registry["hesk_roadwatch"]["alive"]:
        _fail("Entering exploration killed the spared goblin")
        return

    # Also ensure the developer button works after normal deployment setup.
    var second: Node = CombatScene.instantiate()
    root.add_child(second)
    await process_frame
    second.call("_on_story_continue")
    if second.get("adventure").stage != "deployment" or not second.get("debug_skip_battle_button").visible:
        _fail("Developer button should be available during deployment")
        return
    second.get("debug_skip_battle_button").pressed.emit()
    if second.get("adventure").stage != "victory" or not second.get("adventure").campaign.npc_registry["hesk_roadwatch"]["alive"]:
        _fail("Deployment shortcut did not preserve Hesk")
        return

    # A test already in battle should be able to skip to its aftermath as well.
    var third: Node = CombatScene.instantiate()
    root.add_child(third)
    await process_frame
    third.call("_on_story_continue")
    third.call("_on_begin_battle")
    if third.get("adventure").stage != "battle" or not third.get("debug_skip_battle_button").visible:
        _fail("Developer button should be available during combat")
        return
    third.get("debug_skip_battle_button").pressed.emit()
    if third.get("adventure").stage != "victory" or not third.get("adventure").campaign.npc_registry["hesk_roadwatch"]["alive"]:
        _fail("In-combat shortcut did not preserve Hesk")
        return

    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
    print("PASS: debug skip from intro/setup/combat; Hesk alive, victory rewards once, save/load and exploration")
    quit(0)
