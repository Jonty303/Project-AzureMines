extends SceneTree
## Hesk's wound treatment and choices belong to postbattle narrative, not victory UI.
const CombatScene = preload("res://scenes/combat.tscn")
const OpeningSession = preload("res://adventure/opening_session.gd")
const SAVE_PATH := "user://hesk_narrative_regression.json"


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _choice_exists(session: RefCounted, id: String) -> bool:
    for choice in session.exploration_choices():
        if str(choice.get("id", "")) == id:
            return true
    return false


func _run() -> void:
    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    ui.call("_on_story_continue")
    ui.call("_on_begin_battle")
    var combat = ui.get("engine")
    var session = ui.get("adventure")
    for id in ["goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        var foe: Dictionary = combat.actors[id]
        foe["hp"] = 0
        foe["combat_state"] = "dead"
        combat.actors[id] = foe
    combat._deal_damage("goblin_blade", 9)
    combat._check_victory()
    ui.call("_refresh")
    if session.stage != "victory" or ui.get("story_continue_button").text != "Continue to Wagon Clearing":
        _fail("Did not reach the usual victory summary")
        return
    if ui.get("survivor_panel") != null or ui.get("survivor_first_aid_button") != null:
        _fail("Survivor actions must not appear on the postbattle summary")
        return
    if combat.actors["goblin_blade"]["combat_state"] != "unconscious":
        _fail("Hesk should be dying before narrative first aid")
        return

    ui.call("_on_story_continue")
    if session.stage != "exploration" or session.campaign.current_location != "wagon_clearing":
        _fail("Victory did not continue directly to narrative wagon clearing")
        return
    if not _choice_exists(session, "hesk_first_aid") or not _choice_exists(session, "hesk_heal") or _choice_exists(session, "hesk_talk"):
        _fail("Unconscious Hesk should have treatment choices but no conversation")
        return

    var result: Dictionary = session.choose_exploration("hesk_first_aid", combat.actors, combat)
    if not bool(result.get("ok", false)) or not combat.actors["goblin_blade"].get("first_aid_attempted", false):
        _fail("Narrative first aid did not use the real Medicine rule")
        return
    if _choice_exists(session, "hesk_first_aid") or session.choose_exploration("hesk_first_aid", combat.actors, combat).get("ok", true):
        _fail("First aid granted an unlimited free retry")
        return
    if not session.campaign.checks.has("hesk_first_aid"):
        _fail("Narrative Medicine check was not recorded in campaign history")
        return
    var spell_slots: int = int(combat.actors["brunna"]["spell_slots_remaining"])
    if not session.choose_exploration("hesk_heal", combat.actors, combat).get("ok", false):
        _fail("Cure Wounds was not usable through the narrative")
        return
    if int(combat.actors["brunna"]["spell_slots_remaining"]) != spell_slots - 1:
        _fail("Narrative Cure Wounds did not consume a slot")
        return
    if combat.actors["goblin_blade"]["combat_state"] != "active" or not _choice_exists(session, "hesk_talk"):
        _fail("Healed Hesk should be conscious and available to question")
        return
    if _choice_exists(session, "hesk_heal"):
        _fail("Cure Wounds must disappear when Hesk is conscious")
        return

    ui.call("_on_exploration_choice", "hesk_talk")
    if not _choice_exists(session, "hesk_ask_lord") or not _choice_exists(session, "hesk_promise_family"):
        _fail("Talking to Hesk should reveal dialogue branches")
        return
    ui.call("_on_exploration_choice", "hesk_ask_lord")
    if not session.campaign.clues.any(func(entry: Dictionary) -> bool:
            return entry.get("id", "") == "hesk_fearful_raiders"):
        _fail("Hesk's limited account was not recorded as a clue")
        return
    ui.call("_on_exploration_choice", "hesk_promise_family")
    if not session.campaign.knows_location("overgrown_track"):
        _fail("Family promise should give a route to the ravine")
        return
    if session.campaign.npc_registry["hesk_roadwatch"]["trust"] < 2:
        _fail("Promise did not improve Hesk's disposition")
        return
    ui.call("_on_exploration_choice", "hesk_release")
    var hesk: Dictionary = session.campaign.npc_registry["hesk_roadwatch"]
    if hesk.get("fate", "") != "released" or not hesk.get("alive", false):
        _fail("Releasing Hesk was not remembered")
        return
    if hesk.get("attitude", "") != "receptive" or session.campaign.flags.get("goblin_lair_readiness", "") != "alerted":
        _fail("Release must record both trust and the independent hideout alert")
        return
    if _choice_exists(session, "hesk_kill") or _choice_exists(session, "hesk_release"):
        _fail("Resolved Hesk fate should not offer contradictory further choices")
        return
    if not session.save_game(combat.actors, SAVE_PATH):
        _fail("Failed to save Hesk's narrative outcome")
        return
    var loaded = OpeningSession.new()
    if not loaded.load_game(SAVE_PATH):
        _fail("Failed to load Hesk's outcome")
        return
    if loaded.campaign.npc_registry["hesk_roadwatch"]["fate"] != "released":
        _fail("Released fate was not persisted")
        return
    if not loaded.campaign.flags.get("hesk_promised_family", false):
        _fail("Promises and relationships were lost on save/load")
        return
    if loaded.campaign.party_snapshots["brunna"]["spell_slots_remaining"] != spell_slots - 1:
        _fail("Healing spell cost was lost on save/load")
        return
    if loaded.exploration.available_choices().any(func(c: Dictionary) -> bool:
            return str(c.get("id", "")) == "hesk_kill"):
        _fail("Save/load reopened Hesk's resolved fate")
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    print("PASS: Hesk is handled through narrative treatment/dialogue/release with persistent state and spell cost")
    quit(0)
