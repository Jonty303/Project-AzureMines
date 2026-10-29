extends SceneTree
## Three encounter fixtures are real tactical battles, not pre-scripted victories.
const CombatScene = preload("res://scenes/combat.tscn")
const CombatEngine = preload("res://combat/combat_engine.gd")
const OpeningSession = preload("res://adventure/opening_session.gd")
const SAVE_PATH := "user://cave_multibattle_v091_test.json"


func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _winning_combat(ui: Node, enemy_ids: Array[String], xp_total: int) -> bool:
    var engine: RefCounted = ui.get("engine")
    var adventure: RefCounted = ui.get("adventure")
    if adventure.stage != "dungeon_battle" or engine.finished:
        _fail("No ongoing dungeon tactical encounter")
        return false
    for id in enemy_ids:
        if not engine.actors.has(id) or engine.actors[id]["team"] != "enemy":
            _fail("Encounter missing expected foe " + id)
            return false
        var enemy: Dictionary = engine.actors[id]
        enemy["hp"] = 0
        enemy["combat_state"] = "dead"
        engine.actors[id] = enemy
    engine._check_victory()
    if not engine.finished or engine.victor != "party":
        _fail("Tactical fixture did not resolve through normal victory")
        return false
    ui.call("_refresh")
    if adventure.stage != "exploration":
        _fail("Battle did not return to narrative exploration")
        return false
    return true


func _run() -> void:
    # Each enemy must use its authored attack rather than a hard-coded goblin knife.
    for config in [
        {"path": "res://adventures/test_adventure/encounters/guardroom_goblin_wolf.json", "actor": "guard_wolf", "weapon": "bite"},
        {"path": "res://adventures/test_adventure/encounters/rubbish_midden_grub.json", "actor": "midden_grub", "weapon": "mandibles"}
    ]:
        var ai = CombatEngine.new()
        if not ai.start(1200, false, str(config["path"])):
            _fail("Could not start authored enemy AI test")
            return
        if ai._ai_weapon_id(ai.actors[str(config["actor"])], 1) != str(config["weapon"]):
            _fail("Enemy AI did not select authored attack: " + str(config["weapon"]))
            return
        var creature: Dictionary = ai.actors[str(config["actor"])]
        creature["position"] = Vector2i(3, 3)
        ai.actors[str(config["actor"])] = creature
        ai.turn_index = ai.turn_order.find(str(config["actor"]))
        ai._begin_turn()
        ai.take_ai_turn()
        if not ai.events.any(func(evt: Dictionary) -> bool:
                return str(evt.get("text", "")).contains("uses " + str(config["weapon"]))):
            _fail("Enemy did not actually attack using " + str(config["weapon"]))
            return

    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    ui.call("_on_debug_skip_battle")
    ui.call("_on_story_continue")
    var session: RefCounted = ui.get("adventure")
    if session.stage != "exploration":
        _fail("Could not reach campaign exploration")
        return

    session.campaign.mark_visited("cave_approach")
    session.campaign.flags["watchpost_spotted"] = true
    session.campaign.flags["watchpost_outflanked"] = true
    session.campaign.reveal_route("watchpost_tree")
    ui.call("_refresh")
    var intro_combat: RefCounted = ui.get("engine")
    var hero: Dictionary = intro_combat.actors["alden"]
    hero["hp"] = 7
    intro_combat.actors["alden"] = hero
    var brunna: Dictionary = intro_combat.actors["brunna"]
    brunna["spell_slots_remaining"] = 1
    intro_combat.actors["brunna"] = brunna
    ui.call("_on_exploration_choice", "watchpost_attack")
    var first: RefCounted = ui.get("engine")
    if session.stage != "dungeon_battle" or first.encounter_id != "cave_watchpost":
        _fail("Watchpost narrative choice did not launch its authored tactical fight")
        return
    if first.actors.size() != 6 or first.actors["alden"]["hp"] != 7 or first.actors["brunna"]["spell_slots_remaining"] != 1:
        _fail("Entering watchpost battle reset wounded heroes or spell slots")
        return
    if first.initiative_disadvantaged_team != "enemy" or not first.events.any(func(evt: Dictionary) -> bool:
            return str(evt.get("text", "")).contains("Surprised, Disadvantage")):
        _fail("Outflanked sentries did not receive 2024 Surprise initiative Disadvantage")
        return
    if not _winning_combat(ui, ["watch_scout", "watch_signal"], 100):
        return
    if not session.campaign.flags.get("watchpost_resolved", false) or not session.campaign.flags.get("watchpost_crossed", false):
        _fail("Beaten lookouts did not mark the approach clear")
        return
    if session.campaign.flags.get("watchpost_alarm_raised", false):
        _fail("Defeating unsuspecting lookouts magically raised an alarm")
        return
    if session.campaign.xp_by_character["alden"] != 75:
        _fail("Watchpost reward should grant 25 XP per hero")
        return
    if session.campaign.party_snapshots["alden"]["hp"] != 7:
        _fail("Watchpost result did not retain existing injury")
        return
    if session.choose_exploration("watchpost_attack", ui.get("engine").actors).get("ok", true):
        _fail("Defeated watchpost can be farmed for repeated experience")
        return
    ui.call("_on_exploration_choice", "enter_cave_mouth")
    ui.call("_on_exploration_choice", "enter_first_passage")
    ui.call("_on_exploration_choice", "deeper_corridor")
    ui.call("_on_exploration_choice", "to_guardroom")
    if session.campaign.current_location != "cave_guardroom":
        _fail("Could not reach the guardroom from the main passage")
        return
    ui.call("_on_exploration_choice", "guardroom_battle")
    var second: RefCounted = ui.get("engine")
    if session.stage != "dungeon_battle" or second.encounter_id != "cave_guardroom":
        _fail("Guardroom narrative choice did not launch goblin-and-wolf encounter")
        return
    if second.actors.size() != 6 or not second.actors.has("guard_wolf"):
        _fail("Guardroom lacks wolf or goblin defender")
        return
    if second.actors["alden"]["hp"] != 7 or second.actors["brunna"]["spell_slots_remaining"] != 1:
        _fail("Party resources reset between separate battles")
        return
    if not _winning_combat(ui, ["guard_goblin", "guard_wolf"], 100):
        return
    if not session.campaign.flags.get("guardroom_resolved", false) or session.campaign.xp_by_character["pip"] != 100:
        _fail("Guardroom defeat did not persist or grant a second unique XP reward")
        return

    ui.call("_on_exploration_choice", "guardroom_leave")
    ui.call("_on_exploration_choice", "to_rubbish")
    ui.call("_on_exploration_choice", "rubbish_hole")
    if not session.campaign.flags.get("rubbish_shaft_noticed", false):
        _fail("Refuse shaft was not discovered by inspecting the rubbish")
        return
    if session.campaign.knows_location("shaft_lower_level"):
        _fail("Undefined lower shaft destination was exposed")
        return
    ui.call("_on_exploration_choice", "midden_fight")
    var third: RefCounted = ui.get("engine")
    if session.stage != "dungeon_battle" or third.encounter_id != "cave_midden_grub" or third.actors.size() != 5:
        _fail("Optional low-threat scavenger combat did not start")
        return
    if not _winning_combat(ui, ["midden_grub"], 20):
        return
    if session.campaign.xp_by_character["elyra"] != 105:
        _fail("Midden Grub should add five XP per hero, only once")
        return
    ui.call("_on_exploration_choice", "rubbish_back")
    ui.call("_on_exploration_choice", "to_common")
    if session.campaign.current_location != "cave_common":
        _fail("Common room was not reachable")
        return
    ui.call("_on_exploration_choice", "chief_open_talk")
    ui.call("_on_exploration_choice", "chief_about_bugbear")
    ui.call("_on_exploration_choice", "chief_discuss_help")
    if not session.campaign.flags.get("chief_uprising_discussed", false):
        _fail("Former chief conversation did not persist")
        return
    ui.call("_on_exploration_choice", "common_return")
    ui.call("_on_exploration_choice", "to_waterfall")
    ui.call("_on_exploration_choice", "waterfall_guards")
    if not session.campaign.flags.get("waterfall_tunnel_noted", false):
        _fail("Guarded waterfall passage not recorded as a clue")
        return
    ui.call("_on_exploration_choice", "waterfall_return")
    ui.call("_on_exploration_choice", "to_bugbear_outer")
    ui.call("_on_exploration_choice", "bugbear_observe")
    if not session.campaign.clues.any(func(clue: Dictionary) -> bool:
            return str(clue.get("id", "")) == "mage_held_by_bugbear"):
        _fail("Bugbear chamber scouting did not discover the imprisoned mage")
        return
    if session.campaign.completed_encounters.has("bugbear_lord") or session.campaign.flags.get("mage_rescued", false):
        _fail("Unimplemented boss fight or rescue was falsely marked complete")
        return
    if not session.save_game(ui.get("engine").actors, SAVE_PATH):
        _fail("Could not save after three distinct tactical encounters")
        return
    var loaded: RefCounted = OpeningSession.new()
    if not loaded.load_game(SAVE_PATH):
        _fail("Could not load multi-encounter campaign state")
        return
    if loaded.campaign.current_location != "cave_bugbear_outer" or loaded.campaign.completed_encounters.size() != 4:
        _fail("Encounter history and current dungeon room did not persist")
        return
    if loaded.campaign.party_snapshots["alden"]["hp"] != 7 or loaded.campaign.party_snapshots["brunna"]["spell_slots_remaining"] != 1:
        _fail("Party injuries or spent slots did not persist across dungeon save")
        return
    if loaded.exploration.choose("bugbear_observe", ui.get("engine").actors).get("ok", true):
        _fail("Unique boss scouting clue can be repeatedly claimed on reload")
        return
    if not loaded.exploration.choose("bugbear_back", ui.get("engine").actors).get("ok", false):
        _fail("Cannot backtrack from boss passage after reload")
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
    print("PASS: watchpost, goblin/wolf guardroom and Midden Grub tactical battles; entire cave exploration; persistence")
    quit(0)
