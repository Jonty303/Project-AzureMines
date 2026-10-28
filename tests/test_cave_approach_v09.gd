extends SceneTree
## First playable cave approach: watchpost perception, alarm, counter-position,
## alternate route to cave, local map and save/load.
const CombatScene = preload("res://scenes/combat.tscn")
const CombatEngine = preload("res://combat/combat_engine.gd")
const OpeningSession = preload("res://adventure/opening_session.gd")
const CampaignState = preload("res://adventure/campaign_state.gd")
const NarrativeEngine = preload("res://adventure/narrative_engine.gd")
const SAVE_PATH := "user://cave_approach_v09_test.json"


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _has_choice(explore: RefCounted, id: String) -> bool:
    for choice in explore.available_choices():
        if str(choice.get("id", "")) == id:
            return true
    return false


func _test_scout_and_outflank(actors: Dictionary) -> bool:
    var seen_success := false
    var seen_failure := false
    var found_advantage := false
    for seed in range(1, 120):
        var world = CampaignState.new()
        var explore = NarrativeEngine.new(world)
        world.mark_visited("cave_approach")
        world.check_rng.seed = seed
        if world.knows_location("watchpost_tree") or world.flags.get("watchpost_spotted", false):
            _fail("An unspotted watchpost is visible prematurely")
            return false
        var result: Dictionary = explore.choose("watchpost_scout", actors)
        if not result.get("ok", false):
            _fail("Scout check was unavailable")
            return false
        var success: bool = bool(world.checks["watchpost_scout"]["success"])
        if success:
            seen_success = true
            if not world.flags.get("watchpost_spotted", false) or not world.knows_location("watchpost_tree"):
                _fail("Successful perception failed to discover watchpost")
                return false
            if not _has_choice(explore, "watchpost_outflank"):
                _fail("Discovered sentries did not unlock the outflank choice")
                return false
            var outflank: Dictionary = explore.choose("watchpost_outflank", actors)
            if not outflank.get("ok", false):
                _fail("The party could not attempt to outflank discovered guards")
                return false
            if world.checks["watchpost_outflank"]["success"]:
                if not world.flags.get("watchpost_outflanked", false):
                    _fail("Successful outflanking did not set tactical position")
                    return false
                var sneak: Dictionary = explore.choose("watchpost_sneak", actors)
                if not sneak.get("ok", false) or not world.checks["watchpost_sneak"]["advantage"]:
                    _fail("Outflanking did not grant Advantage on the bypass Stealth check")
                    return false
                if world.checks["watchpost_sneak"]["rolls"].size() != 2:
                    _fail("Advantage dice were not stored in the campaign check record")
                    return false
                if int(world.checks["watchpost_sneak"]["die"]) != maxi(
                    int(world.checks["watchpost_sneak"]["rolls"][0]),
                    int(world.checks["watchpost_sneak"]["rolls"][1])):
                    _fail("Advantage did not take the higher die")
                    return false
                found_advantage = true
            else:
                if not world.flags.get("watchpost_alarm_raised", false):
                    _fail("Failed attempt to outflank did not raise an alarm")
                    return false
                if _has_choice(explore, "watchpost_outflank"):
                    _fail("Party can attempt a surprise outflank after the lookout alarm")
                    return false
        else:
            seen_failure = true
            if world.flags.get("watchpost_spotted", false) or world.knows_location("watchpost_tree"):
                _fail("Failed Perception revealed the secret watchpost")
                return false
            if _has_choice(explore, "watchpost_outflank"):
                _fail("Outflanking hidden guards is available without discovery")
                return false
        if seen_success and seen_failure and found_advantage:
            break
    if not seen_success or not seen_failure or not found_advantage:
        _fail("Perception success/failure and Advantage variants were not covered")
        return false
    return true


func _run() -> void:
    var game = CombatEngine.new()
    if not game.start(92024, true):
        _fail("Combat party could not initialise")
        return
    if not _test_scout_and_outflank(game.actors):
        return

    var screen: Node = CombatScene.instantiate()
    root.add_child(screen)
    await process_frame
    screen.call("_on_debug_skip_battle")
    screen.call("_on_story_continue")
    var session: RefCounted = screen.get("adventure")
    if session.stage != "exploration":
        _fail("Debug shortcut did not lead into exploration")
        return
    if session.campaign.knows_location("cave_approach") or session.campaign.flags.get("watchpost_spotted", false):
        _fail("Hidden cave content was spoiled before discovery")
        return
    screen.call("_on_exploration_choice", "to_town_road")
    screen.call("_on_exploration_choice", "go_market")
    screen.call("_on_exploration_choice", "ask_mara")
    screen.call("_on_exploration_choice", "back_road")
    screen.call("_on_exploration_choice", "return_wagon")
    screen.call("_on_exploration_choice", "follow_known_track")
    if session.campaign.current_location != "overgrown_track":
        _fail("Mara's backup lead did not reach the ravine")
        return
    if not session.exploration.available_choices().any(func(c: Dictionary) -> bool:
            return c.get("id", "") == "approach_goblin_cave"):
        _fail("Ravine does not lead to the exterior cave scene")
        return
    screen.call("_on_exploration_choice", "approach_goblin_cave")
    if session.campaign.current_location != "cave_approach":
        _fail("Did not enter wooded cave approach")
        return
    if not screen.get("local_cave_map").visible or screen.get("overland_map").visible:
        _fail("Local cave map was not displayed on exterior approach")
        return
    if session.campaign.flags.get("watchpost_spotted", false) or session.campaign.knows_location("watchpost_tree"):
        _fail("Approaching cave revealed hidden sentry position")
        return
    if not session.exploration.current_scene()["description"].contains("limestone"):
        _fail("Cave exterior description did not load")
        return
    if session.exploration.available_choices().any(func(c: Dictionary) -> bool:
            return c.get("id", "") == "enter_cave_mouth"):
        _fail("Party can bypass watchpost decision without crossing it")
        return
    screen.call("_on_exploration_choice", "watchpost_open")
    if not session.campaign.flags.get("watchpost_alarm_raised", false) or not session.campaign.flags.get("watchpost_crossed", false):
        _fail("Open approach did not persist the tree sentries' alarm")
        return
    if session.campaign.flags.get("watchpost_spotted", false):
        _fail("Raising alarm should not automatically mark watchpost as scouted")
        return
    if session.exploration.choose("watchpost_open", game.actors).get("ok", true):
        _fail("Open approach can trigger a second unlimited alarm outcome")
        return
    screen.call("_on_exploration_choice", "enter_cave_mouth")
    if session.campaign.current_location != "cave_entrance":
        _fail("Crossing lookouts did not reach the cave mouth")
        return
    if not session.exploration.current_scene()["description"].contains("alarm"):
        _fail("Cave narrative forgot the goblin lookout warning")
        return
    screen.call("_on_exploration_choice", "enter_first_passage")
    if session.campaign.current_location != "cave_threshold":
        _fail("First cave passage was not reachable")
        return
    if session.campaign.visited.has("cave_waterfall") or session.campaign.knows_location("cave_bugbear"):
        _fail("Unauthored deeper cave rooms were spoiled")
        return
    screen.call("_on_exploration_choice", "mark_deeper_passages")
    if not session.campaign.clues.any(func(c: Dictionary) -> bool:
            return c.get("id", "") == "unexplored_hideout"):
        _fail("Corridor exploration did not record a clue")
        return
    screen.call("_on_save_game")
    if not FileAccess.file_exists("user://azure_mines_slot1.json"):
        _fail("Player Save button did not work in the cave")
        return
    if not session.save_game(screen.get("engine").actors, SAVE_PATH):
        _fail("Could not save cave progress")
        return
    var reload = OpeningSession.new()
    if not reload.load_game(SAVE_PATH):
        _fail("Cave save could not be loaded")
        return
    if reload.campaign.current_location != "cave_threshold" or not reload.campaign.flags.get("watchpost_alarm_raised", false):
        _fail("Cave location and alarm were lost on save/load")
        return
    if reload.campaign.knows_location("watchpost_tree"):
        _fail("Unspotted watchpost appeared after reload")
        return
    if reload.exploration.choose("mark_deeper_passages", game.actors).get("ok", true):
        _fail("Save/load permitted a repeat corridor clue")
        return
    if not reload.exploration.choose("exit_to_entrance", game.actors).get("ok", false):
        _fail("Cave travel was broken after load")
        return
    if not reload.exploration.choose("return_to_trees", game.actors).get("ok", false):
        _fail("Could not exit the cave back to its approach")
        return
    if not reload.exploration.choose("back_to_ravine", game.actors).get("ok", false):
        _fail("Could not retreat from the cave to ravine")
        return

    # Existing Hesk release must persist a separate pre-warning even when
    # the watchpost itself was never detected or triggered.
    var warned = CampaignState.new()
    warned.flags["goblin_lair_readiness"] = "alerted"
    warned.mark_visited("cave_approach")
    var warned_explore = NarrativeEngine.new(warned)
    if not warned_explore.current_scene()["description"].contains("warned"):
        _fail("Hesk's warning did not influence the cave approach")
        return
    if warned.flags.get("watchpost_alarm_raised", false):
        _fail("Hesk's prior warning was conflated with the tree watchpost alarm")
        return

    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://azure_mines_slot1.json"))
    print("PASS: cave approach, watchpost discovery, alarm, Advantage, local map, persistence and retreat")
    quit(0)
