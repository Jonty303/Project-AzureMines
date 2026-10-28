extends SceneTree
## The named goblin's survival state must affect the playable victory panel.
const CombatScene = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _run() -> void:
    var screen: Node = CombatScene.instantiate()
    root.add_child(screen)
    await process_frame
    screen.call("_on_story_continue")
    screen.call("_on_begin_battle")
    var game = screen.get("engine")
    var session = screen.get("adventure")
    if session.stage != "battle":
        _fail("Did not reach the battle scene")
        return
    for id in ["goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        var enemy: Dictionary = game.actors[id]
        enemy["hp"] = 0
        enemy["combat_state"] = "dead"
        game.actors[id] = enemy
    game._deal_damage("goblin_blade", 9)
    game._check_victory()
    screen.call("_refresh")
    if session.stage != "victory" or not screen.get("survivor_panel").visible:
        _fail("Survivor care panel did not show after the last foe fell")
        return
    var hesk: Dictionary = game.actors["goblin_blade"]
    if hesk["combat_state"] != "unconscious":
        _fail("Named raider should be dying")
        return
    if screen.get("survivor_first_aid_button").disabled or screen.get("survivor_heal_button").disabled:
        _fail("Both first aid and Cure Wounds should initially be available")
        return

    screen.call("_on_survivor_first_aid")
    if not game.actors["goblin_blade"].get("first_aid_attempted", false):
        _fail("Attempted Medicine check was not recorded")
        return
    if not screen.get("survivor_first_aid_button").disabled:
        _fail("First Aid should not grant unlimited retries")
        return
    var slots: int = int(game.actors["brunna"]["spell_slots_remaining"])
    screen.call("_on_survivor_heal")
    if game.actors["brunna"]["spell_slots_remaining"] != slots - 1:
        _fail("Cure Wounds did not consume a slot")
        return
    if game.actors["goblin_blade"]["combat_state"] != "active":
        _fail("Healing did not bring Hesk to consciousness")
        return
    if not screen.get("survivor_heal_button").disabled:
        _fail("Healing button still available after Hesk wakes")
        return
    if session.stage != "victory" or session.gold_gp != 12:
        _fail("Treating a survivor must not interrupt victory or duplicate gold")
        return

    print("PASS: named Hesk appears after combat, first aid is limited and healing costs a slot")
    quit(0)
