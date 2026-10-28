extends SceneTree
## Contextual range previews, exhausted actions and original audio assets.
const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatScene = preload("res://scenes/combat.tscn")
const SFX := ["footstep", "melee_hit", "ranged", "magic", "heal", "miss", "damage", "death"]

func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    for sound_id in SFX:
        var path := "res://assets/sfx/%s.wav" % sound_id
        if not ResourceLoader.exists(path) or load(path) == null:
            _fail("Could not load original audio: " + path)
            return

    var battle = CombatEngine.new()
    if not battle.start(46):
        _fail("Cannot load tutorial encounter")
        return
    battle.turn_index = battle.turn_order.find("alden")
    battle._begin_turn()
    if not battle.move_to(Vector2i(3, 3)):
        _fail("Expected a legal step for Alden")
        return
    var had_step := false
    for event in battle.events:
        if event.get("sound", "") == "footstep":
            had_step = true
    if not had_step:
        _fail("Movement did not emit a footstep cue")
        return

    var scene = CombatScene.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    var board = scene.get("board")
    var game = scene.get("engine")
    if board == null or game == null:
        _fail("Scene did not instantiate combat board")
        return
    if scene.get("sfx_players").size() != 8:
        _fail("Expected eight playable sound effects")
        return
    board.action_mode = ""
    var none: Dictionary = board.get_highlights()
    if not none["move"].is_empty() or not none["attack"].is_empty() or not none["spell"].is_empty():
        _fail("Highlights visible without a selected action")
        return
    scene.call("_on_story_continue")
    scene.call("_on_begin_battle")
    if game.deployment_active:
        _fail("Begin Battle failed from action-bar scene")
        return
    game.turn_index = game.turn_order.find("alden")
    game._begin_turn()
    board.action_mode = "move"
    var moving: Dictionary = board.get_highlights()
    if moving["move"].size() < 2 or not moving["attack"].is_empty() or not moving["spell"].is_empty():
        _fail("Move preview shows incorrect selection or no movement")
        return
    board.action_mode = "attack"
    board.selected_weapon = "longsword"
    var weapon: Dictionary = board.get_highlights()
    if not weapon["move"].is_empty() or not weapon["spell"].is_empty():
        _fail("Movement visible in Attack mode")
        return

    game.action_used = true
    game.movement_used = 6
    scene.call("_refresh")
    if not scene.get("attack_button").crossed_out or not scene.get("move_button").crossed_out:
        _fail("Action and movement buttons were not crossed out on exhaustion")
        return
    if not scene.get("attack_button").disabled or not scene.get("move_button").disabled:
        _fail("Exhausted actions remained clickable")
        return
    var exhausted: Dictionary = board.get_highlights()
    if not exhausted["attack"].is_empty() or not exhausted["move"].is_empty():
        _fail("Exhausted action still has target preview")
        return

    print("PASS: original audio resources, event cues, contextual ranges and crossed-out exhausted actions")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
