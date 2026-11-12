extends SceneTree
const CombatEngine = preload("res://combat/combat_engine.gd")
const SCENE = preload("res://scenes/combat.tscn")
const SFX := ["footstep", "melee_hit", "ranged", "magic", "heal", "miss", "damage", "death"]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for sound in SFX:
        var path: String = "res://assets/sfx/%s.wav" % sound
        if not ResourceLoader.exists(path):
            _fail("Missing audio asset: " + path)
            return
    var lab: Node = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab.call("_start_battle")
    lab.call("_begin_battle")
    var game = lab.get("engine")
    var board = lab.get("board")
    if game == null or board == null or lab.get("sfx_players").size() != 8:
        _fail("Lab combat and audio did not initialise")
        return
    game.turn_index = game.turn_order.find("alden")
    game._begin_turn()
    board.action_mode = ""
    if not board.get_highlights()["move"].is_empty():
        _fail("No action selected yet movement was highlighted")
        return
    board.action_mode = "move"
    if board.get_highlights()["move"].size() < 2:
        _fail("Move selection has no reachable tiles")
        return
    game.action_used = true
    game.movement_used = 6
    lab.call("_refresh")
    if not lab.get("attack_button").disabled or not lab.get("move_button").disabled:
        _fail("Spent action/movement remained usable")
        return
    print("PASS: SFX assets, combat presentation, movement highlights and exhausted actions")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
