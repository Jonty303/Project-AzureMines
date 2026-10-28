extends SceneTree
## World-state persistence, narrative checks, returning travel and the discovered map.
const CombatEngine = preload("res://combat/combat_engine.gd")
const OpeningSession = preload("res://adventure/opening_session.gd")
const CombatScene = preload("res://scenes/combat.tscn")
const SAVE_PATH := "user://v08_regression_campaign.json"


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _run() -> void:
    var game = CombatEngine.new()
    if not game.start(891, true):
        _fail("Unable to load characters")
        return
    var run = OpeningSession.new()
    if not run.start_journey() or not run.begin_deployment() or not run.begin_combat():
        _fail("Opening stages not available")
        return
    if not run.conclude_battle("party") or run.gold_gp != 12:
        _fail("Cannot award victory once")
        return
    if not run.continue_after_victory() or not run.enter_exploration():
        _fail("Cannot enter exploration after battle aftermath")
        return
    if run.campaign.current_location != "wagon_clearing":
        _fail("Exploration did not start at the wagon")
        return
    if run.campaign.knows_location("overgrown_track"):
        _fail("Hidden trail was revealed prematurely")
        return
    var available: Array[Dictionary] = run.exploration_choices()
    var names: Array[String] = []
    for choice in available:
        names.append(str(choice["id"]))
    if not names.has("follow_tracks") or names.has("follow_known_track"):
        _fail("Undiscovered ravine was not hidden from the choice list")
        return
    var result: Dictionary = run.choose_exploration("search_wagon", game.actors)
    if not result.get("ok", false) or run.campaign.checks.size() != 1:
        _fail("Data-driven Investigation check did not resolve")
        return
    var first_roll: Dictionary = run.campaign.checks["search_wagon"].duplicate(true)
    if run.choose_exploration("search_wagon", game.actors).get("ok", true):
        _fail("Once-only Investigation check can be rerolled")
        return
    if first_roll != run.campaign.checks["search_wagon"]:
        _fail("Resolved check changed")
        return
    var tracked: Dictionary = run.choose_exploration("follow_tracks", game.actors)
    if not tracked.get("ok", false):
        _fail("Survival check could not be attempted")
        return
    if run.choose_exploration("follow_tracks", game.actors).get("ok", true):
        _fail("Survival check can be rerolled")
        return
    if not run.choose_exploration("to_town_road", game.actors).get("ok", false):
        _fail("Could not leave for town")
        return
    if not run.choose_exploration("go_harrowford", game.actors).get("ok", false):
        _fail("Could not arrive at guild")
        return
    if not run.choose_exploration("report_contract", game.actors).get("ok", false):
        _fail("Could not report to adventurers guild")
        return
    if run.campaign.quests.get("marr_missing_caravans", "") != "reported":
        _fail("Merchant report did not persist as a quest status")
        return
    run.choose_exploration("go_market", game.actors)
    if not run.choose_exploration("ask_mara", game.actors).get("ok", false):
        _fail("Mara Venn did not provide the mandatory backup lead")
        return
    if not run.campaign.knows_location("overgrown_track"):
        _fail("The town witness did not reveal the ravine")
        return
    if run.campaign.npc_registry["mara_venn"]["attitude"] != "helpful":
        _fail("Mara's global character attitude did not change")
        return
    if run.choose_exploration("ask_mara", game.actors).get("ok", true):
        _fail("Town witness dialogue repeats the reward")
        return
    run.choose_exploration("accept_raider_task", game.actors)
    if run.campaign.quests.get("road_raiders", "") != "accepted":
        _fail("Raider quest was not accepted")
        return
    if run.choose_exploration("follow_known_track", game.actors).get("ok", true):
        _fail("A choice from another location was accepted")
        return
    run.choose_exploration("back_road", game.actors)
    run.choose_exploration("return_wagon", game.actors)
    if run.campaign.current_location != "wagon_clearing":
        _fail("The wagon cannot be revisited after town")
        return
    if not run.choose_exploration("follow_known_track", game.actors).get("ok", false):
        _fail("Newly discovered trail is not available on a return visit")
        return
    if run.campaign.current_location != "overgrown_track":
        _fail("Did not reach discovered ravine")
        return
    if not run.campaign.visited.has("harrowford_market") or not run.campaign.visited.has("overgrown_track"):
        _fail("Map did not record explored places")
        return
    run.campaign.set_npc("hesk_roadwatch", {"alive": true, "state": "released",
        "whereabouts": "goblin_hideout", "attitude": "receptive", "trust": 2,
        "promises": ["spare_family"]})
    run.campaign.capture_party(game.actors)
    run.campaign.record_event("hesk_released", "Hesk was released after a promise of safety.")
    var clue_count: int = run.campaign.clues.size()
    var event_count: int = run.campaign.events.size()
    if not run.save_game(game.actors, SAVE_PATH):
        _fail("Campaign cannot be saved during exploration")
        return
    var loaded = OpeningSession.new()
    if not loaded.load_game(SAVE_PATH) or loaded.stage != "exploration":
        _fail("Campaign exploration stage failed to reload")
        return
    if loaded.campaign.current_location != "overgrown_track" or loaded.gold_gp != 12:
        _fail("Save lost the current location or party purse")
        return
    if loaded.xp_by_character["alden"] != 50 or loaded.campaign.checks["search_wagon"] != first_roll:
        _fail("XP or resolved dice checks were lost")
        return
    if loaded.campaign.clues.size() != clue_count or loaded.campaign.events.size() != event_count:
        _fail("Clues and chronological events were not preserved")
        return
    if loaded.campaign.npc_registry["hesk_roadwatch"]["promises"] != ["spare_family"]:
        _fail("Hesk's fate, attitude or promises were not saved")
        return
    if loaded.campaign.quests.get("road_raiders", "") != "accepted":
        _fail("Quest state did not survive reload")
        return
    if not loaded.choose_exploration("back_wagon", game.actors).get("ok", false):
        _fail("Narrative choices stopped functioning after reload")
        return
    if loaded.choose_exploration("search_wagon", game.actors).get("ok", true):
        _fail("Save/load permitted a free extra check")
        return
    if loaded.campaign.award_once("training_battle", 200, 12).get("already_claimed", false) != true:
        _fail("Save/load permitted duplicate encounter rewards")
        return
    if loaded.gold_gp != 12:
        _fail("Gold was duplicated")
        return
    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    ui.call("_on_story_continue")
    ui.call("_on_begin_battle")
    var combat = ui.get("engine")
    for id in ["goblin_blade", "goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        var goblin: Dictionary = combat.actors[id]
        goblin["hp"] = 0
        goblin["combat_state"] = "dead"
        combat.actors[id] = goblin
    combat._check_victory()
    ui.call("_refresh")
    ui.call("_on_story_continue")
    ui.call("_on_story_continue")
    if ui.get("adventure").stage != "exploration" or not ui.get("story_choices_scroll").visible:
        _fail("Narrative choices were not rendered after victory")
        return
    ui.call("_on_map_toggle")
    if not ui.get("overland_map").visible:
        _fail("Hand-annotated discovery map did not open")
        return
    ui.call("_on_journal_toggle")
    if not ui.get("story_paragraphs").text.contains("DISCOVERED CLUES"):
        _fail("Clue and event journal did not open")
        return
    var global_path := ProjectSettings.globalize_path(SAVE_PATH)
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(global_path)
    print("PASS: authored story choices, skill checks, NPC memory, quests, map, revisit, save and reload")
    quit(0)
