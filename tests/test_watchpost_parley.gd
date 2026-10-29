extends SceneTree
## v0.9 watchpost: legitimate guarded admission, bluff, failed parley,
## independent Hesk warning, saved dialogue and actual UI integration.
const CombatScene = preload("res://scenes/combat.tscn")
const CombatEngine = preload("res://combat/combat_engine.gd")
const CampaignState = preload("res://adventure/campaign_state.gd")
const NarrativeEngine = preload("res://adventure/narrative_engine.gd")
const SAVE_PATH := "user://watchpost_parley_test.json"


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _has_choice(runtime: RefCounted, id: String) -> bool:
    for c in runtime.available_choices():
        if str(c.get("id", "")) == id:
            return true
    return false


func _new_scene(seed: int) -> Dictionary:
    var campaign = CampaignState.new()
    campaign.mark_visited("cave_approach")
    campaign.check_rng.seed = seed
    return {"campaign": campaign, "runtime": NarrativeEngine.new(campaign)}


func _check_method(actors: Dictionary, option: String, state_name: String, must_succeed: bool = false) -> bool:
    var found_success := false
    var found_failure := false
    for seed in range(1, 170):
        var setup: Dictionary = _new_scene(seed)
        var world: RefCounted = setup["campaign"]
        var runtime: RefCounted = setup["runtime"]
        if world.knows_location("watchpost_tree") or not _has_choice(runtime, "watchpost_hail"):
            _fail("Hidden watchpost should permit a peaceful hail without revealing its position first")
            return false
        if _has_choice(runtime, option):
            _fail("Negotiation check appeared before any contact with the sentries")
            return false
        var hail: Dictionary = runtime.choose("watchpost_hail", actors)
        if not hail.get("ok", false) or not world.flags.get("watchpost_parley_open", false):
            _fail("Hailing the tree watchpost failed to open dialogue")
            return false
        if not world.flags.get("watchpost_spotted", false) or not world.knows_location("watchpost_tree"):
            _fail("The sentries did not reveal their watchpost when answering the party")
            return false
        if world.flags.get("watchpost_alarm_raised", false):
            _fail("Peaceful hail should not automatically set the battle alarm")
            return false
        if _has_choice(runtime, "watchpost_outflank") or _has_choice(runtime, "watchpost_sneak"):
            _fail("The party can surprise guards or slip past unnoticed after openly hailing them")
            return false
        if _has_choice(runtime, "watchpost_scout") or _has_choice(runtime, "watchpost_hail"):
            _fail("Scouting or hailing can repeat once the sentries are already speaking")
            return false
        if not _has_choice(runtime, "watchpost_persuade") or not _has_choice(runtime, "watchpost_bluff"):
            _fail("Dialogue did not offer both an honest appeal and a bluff")
            return false
        var answer: Dictionary = runtime.choose(option, actors)
        if not answer.get("ok", false) or not world.checks.has(option):
            _fail("Watchpost negotiation did not resolve through the actual rules")
            return false
        var passed: bool = bool(world.checks[option]["success"])
        if runtime.choose(option, actors).get("ok", true):
            _fail("Watchpost negotiation may be retried without cost")
            return false
        if passed:
            found_success = true
            if not world.flags.get("watchpost_crossed", false) or not world.flags.get("watchpost_admitted_under_guard", false):
                _fail("Sentries did not allow passage after a successful negotiation")
                return false
            if world.flags.get("watchpost_alarm_raised", false):
                _fail("Successful negotiation incorrectly sounded an alarm")
                return false
            if str(world.flags.get("watchpost_entry_method", "")) != state_name:
                _fail("Social entry method was not recorded")
                return false
            if not _has_choice(runtime, "enter_cave_mouth") or _has_choice(runtime, "watchpost_open"):
                _fail("Successful parley did not unlock the cave and close conflicting approach choices")
                return false
            if not runtime.choose("enter_cave_mouth", actors).get("ok", false) or world.current_location != "cave_entrance":
                _fail("Admitted party could not enter the cave")
                return false
            if not runtime.current_scene()["description"].contains("allowed you through"):
                _fail("Cave entrance does not acknowledge the guarded admission")
                return false
            if not world.save_to_file("exploration", SAVE_PATH):
                _fail("Failed to save successful dialogue route")
                return false
            var recovered = CampaignState.new()
            if recovered.load_from_file(SAVE_PATH) != "exploration":
                _fail("Could not reload a successful watchpost dialogue")
                return false
            if not recovered.flags.get("watchpost_admitted_under_guard", false) or recovered.flags.get("watchpost_alarm_raised", false):
                _fail("Save/load turned guarded admission into an alarm or lost it")
                return false
            if recovered.current_location != "cave_entrance" or not recovered.checks.has(option):
                _fail("Social check or cave location not preserved in the save")
                return false
            DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
        else:
            found_failure = true
            if not world.flags.get("watchpost_alarm_raised", false) or not world.flags.get("watchpost_parley_failed", false):
                _fail("Rejected negotiation did not record the goblin warning")
                return false
            if world.flags.get("watchpost_admitted_under_guard", false) or world.flags.get("watchpost_crossed", false):
                _fail("The party gained access despite being turned away")
                return false
            if _has_choice(runtime, "watchpost_persuade") or _has_choice(runtime, "watchpost_bluff"):
                _fail("Rejected guards can be rolled against repeatedly using another dialogue option")
                return false
            if not _has_choice(runtime, "watchpost_attack") or not _has_choice(runtime, "back_to_ravine"):
                _fail("Social failure did not preserve combat and retreat alternatives")
                return false
        if found_success and found_failure:
            break
    if not found_success or not found_failure:
        _fail("Both successful and rejected " + option + " outcomes must be tested")
        return false
    return true


func _test_hesk(actors: Dictionary) -> bool:
    for released in [false, true]:
        var setup: Dictionary = _new_scene(1199)
        var world: RefCounted = setup["campaign"]
        var runtime: RefCounted = setup["runtime"]
        world.flags["hesk_promised_family"] = true
        world.flags["hesk_fate"] = "released" if released else "captive"
        if released:
            world.flags["goblin_lair_readiness"] = "alerted"
        runtime.choose("watchpost_hail", actors)
        var res: Dictionary = runtime.choose("watchpost_persuade", actors)
        if not res.get("ok", false):
            _fail("Hesk social bonus made the Persuasion check invalid")
            return false
        var check: Dictionary = world.checks["watchpost_persuade"]
        if bool(check["advantage"]) != released or check["rolls"].size() != (2 if released else 1):
            _fail("Hesk's family promise must grant advantage only if Hesk was released")
            return false
        if released and not res["text"].contains("Hesk"):
            _fail("Social check does not explain the conditional Hesk advantage")
            return false
        if released and not world.flags.get("goblin_lair_readiness", "") == "alerted":
            _fail("Peaceful contact removed Hesk's prior warning")
            return false
        if bool(check["success"]) and world.flags.get("watchpost_alarm_raised", false):
            _fail("Sentries raised a fresh alarm despite admitting the party")
            return false
    return true


func _run() -> void:
    var game = CombatEngine.new()
    if not game.start(9877, true):
        _fail("Party fixture could not load")
        return
    if not _check_method(game.actors, "watchpost_persuade", "peaceful_request"):
        return
    if not _check_method(game.actors, "watchpost_bluff", "bluff"):
        return
    if not _test_hesk(game.actors):
        return
    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    ui.call("_on_debug_skip_battle")
    ui.call("_on_story_continue")
    var adventure: RefCounted = ui.get("adventure")
    adventure.campaign.mark_visited("cave_approach")
    ui.call("_refresh")
    ui.call("_on_exploration_choice", "watchpost_hail")
    if adventure.stage != "exploration" or not adventure.campaign.flags.get("watchpost_parley_open", false):
        _fail("Live UI choice failed to start watchpost conversation")
        return
    if not ui.get("story_paragraphs").text.contains("bows"):
        _fail("Live UI did not display the goblin standoff")
        return
    if not adventure.exploration_choices().any(func(c: Dictionary) -> bool:
            return c.get("id", "") == "watchpost_persuade"):
        _fail("Live UI did not refresh with negotiation actions")
        return
    print("PASS: watchpost parley, Persuasion, Deception, Hesk advantage, alarm, map discovery and saved entry")
    quit(0)
