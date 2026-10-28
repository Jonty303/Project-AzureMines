extends SceneTree
## Original story -> setup -> encounter -> award -> aftermath, with no duplicate rewards.
const CombatScene = preload("res://scenes/combat.tscn")
const OpeningSession = preload("res://adventure/opening_session.gd")


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _force_victory(game) -> void:
    for id in ["goblin_blade", "goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        var actor: Dictionary = game.actors[id]
        actor["hp"] = 0
        actor["combat_state"] = "dead"
        game.actors[id] = actor
    game._check_victory()


func _run() -> void:
    var session = OpeningSession.new()
    if not session.start_journey() or session.stage != "approach":
        _fail("Opening adventure JSON failed")
        return
    if session.conclude_battle("party") or session.continue_after_victory():
        _fail("Cannot claim rewards or skip ahead before playing")
        return
    if not session.begin_deployment() or not session.begin_combat():
        _fail("Story did not advance to battle")
        return
    if not session.conclude_battle("enemy") or session.stage != "defeat":
        _fail("Defeat did not show its own outcome")
        return
    if session.gold_gp != 0 or int(session.xp_by_character["alden"]) != 0:
        _fail("Defeat incorrectly awarded XP/gold")
        return

    if not session.start_journey() or not session.begin_deployment() or not session.begin_combat():
        _fail("Cannot retry opening after defeat")
        return
    if not session.conclude_battle("party"):
        _fail("Victory could not be settled")
        return
    var reward: Dictionary = session.last_reward
    if reward.get("already_claimed", true) or int(reward["xp_total"]) != 200 or int(reward["gold_gp"]) != 12:
        _fail("Victory should grant 200 XP total and 12 gp only")
        return
    if not reward["consumables"].is_empty() or not reward["named_items"].is_empty():
        _fail("Opening goblins must not drop equipment or unimplemented inventory")
        return
    if session.gold_gp != 12 or session.completed_encounters.size() != 1:
        _fail("Party purse and encounter ledger were not credited")
        return
    for id in ["alden", "elyra", "brunna", "pip"]:
        if int(session.xp_by_character[id]) != 50:
            _fail("Each hero must receive 50 XP")
            return
    if session.conclude_battle("party") or not session.continue_after_victory():
        _fail("Victory was settled twice or aftermath was inaccessible")
        return
    if session.stage != "aftermath":
        _fail("The story did not reach the road beyond the wagon")
        return

    # Replaying in the same game session never generates duplicate loot.
    if not session.start_journey() or not session.begin_deployment() or not session.begin_combat():
        _fail("Cannot replay encounter")
        return
    if not session.conclude_battle("party") or not session.last_reward["already_claimed"]:
        _fail("Repeated victory failed to show already-claimed rewards")
        return
    if session.gold_gp != 12 or int(session.xp_by_character["pip"]) != 50:
        _fail("Repeated victory duplicated session rewards")
        return

    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    var game = ui.get("engine")
    var story = ui.get("adventure")
    if story.stage != "approach" or not ui.get("story_panel").visible:
        _fail("Opening screen must appear before combat")
        return
    if ui.get("story_title").text != "The Watchfire":
        _fail("Original campfire introduction missing")
        return
    var illustration: TextureRect = ui.get("story_image")
    if illustration == null or not illustration.visible or illustration.texture == null:
        _fail("The story must show a loaded illustration in the main battlefield pane")
        return
    if ui.get("setup_panel").visible or ui.get("combat_action_row").visible:
        _fail("Combat/setup buttons visible during narration")
        return
    ui.call("_on_begin_battle")
    if story.stage != "approach" or not game.deployment_active:
        _fail("Begin Battle bypassed the story")
        return

    ui.call("_on_story_continue")
    if story.stage != "deployment" or not ui.get("setup_panel").visible:
        _fail("Continue failed to reveal party deployment")
        return
    if illustration.visible:
        _fail("Story illustration must disappear for party deployment")
        return
    ui.call("_on_begin_battle")
    if story.stage != "battle" or game.deployment_active:
        _fail("Begin Battle did not start initiative")
        return
    _force_victory(game)
    if game.victor != "party":
        _fail("Cannot simulate legitimate victory")
        return
    ui.call("_refresh")
    if story.stage != "victory" or not ui.get("story_panel").visible:
        _fail("Victory screen did not display after final goblin fell")
        return
    if not illustration.visible:
        _fail("Story illustration should appear again during narrative aftermath")
        return
    if not ui.get("story_rewards").text.contains("200") or not ui.get("story_rewards").text.contains("12 gp"):
        _fail("Victory screen omitted XP and gold")
        return
    if ui.get("story_rewards").text.contains("leather") or ui.get("story_rewards").text.contains("sword"):
        _fail("Victory UI included unwanted equipment")
        return
    ui.call("_refresh")
    if story.gold_gp != 12 or int(story.xp_by_character["brunna"]) != 50:
        _fail("Repeated UI refresh duplicated rewards")
        return
    ui.call("_on_story_continue")
    if story.stage != "aftermath" or not ui.get("story_panel").visible:
        _fail("Continue failed to show post-ambush story")
        return

    ui.call("_on_story_continue")
    if ui.get("adventure").stage != "exploration":
        _fail("Post-ambush continue must enter narrative exploration")
        return
    if not ui.get("story_choices_scroll").visible or ui.get("adventure").campaign.current_location != "wagon_clearing":
        _fail("Narrative choices and wagon clearing did not appear")
        return
    if not ui.get("save_game_button").visible:
        _fail("Exploration must expose Save Game")
        return
    ui.call("_on_exploration_choice", "to_town_road")
    if ui.get("adventure").campaign.current_location != "town_road":
        _fail("Narrative travel to town road failed")
        return
    ui.call("_on_exploration_choice", "return_wagon")
    if ui.get("adventure").campaign.current_location != "wagon_clearing":
        _fail("The clearing must remain returnable")
        return
    if ui.get("adventure").gold_gp != 12:
        _fail("Narrative navigation duplicated or lost rewards")
        return

    print("PASS: story, deployment, victory, 50 XP each, 12 pooled gp, defeat/aftermath and one-time rewards")
    quit(0)
