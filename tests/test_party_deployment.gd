extends SceneTree
## Setup occurs before initiative; formations and manual moves are validated.
const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatScene = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _verify_layout(game) -> bool:
    var seen: Array[Vector2i] = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        var cell: Vector2i = game.actors[id]["position"]
        if seen.has(cell) or not game.is_deployment_cell(cell):
            return false
        seen.append(cell)
    return true


func _run() -> void:
    var game = CombatEngine.new()
    if not game.start(872, true):
        _fail("Could not initialise deployment")
        return
    if not game.deployment_active or game.turn_order.size() != 0:
        _fail("Initiative was rolled before party deployment")
        return
    if game.active_formation != "square" or not _verify_layout(game):
        _fail("Default Square formation is invalid")
        return
    if game.move_to(Vector2i(3, 6)):
        _fail("Combat movement was accepted during deployment")
        return

    for formation_id in ["line", "diamond", "square"]:
        if not game.set_formation(formation_id) or not _verify_layout(game):
            _fail("Formation failed or overlapped: " + formation_id)
            return
    if game.set_formation("unknown"):
        _fail("Unsupported formation accepted")
        return
    if game.place_character("alden", Vector2i(5, 3)):
        _fail("Hero placed inside wagon")
        return
    if game.place_character("alden", Vector2i(4, 5)):
        _fail("Hero placed inside a chest")
        return
    if game.place_character("alden", Vector2i(7, 7)):
        _fail("Hero placed on a burning campfire")
        return
    if game.place_character("alden", Vector2i(8, 8)):
        _fail("Hero placed beyond deployment boundary")
        return
    if game.place_character("alden", game.actors["brunna"]["position"]):
        _fail("Two heroes overlapped")
        return
    if not game.place_character("alden", Vector2i(0, 8)):
        _fail("Legal custom deployment was refused")
        return
    if game.active_formation != "custom" or not _verify_layout(game):
        _fail("Custom deployment was not recorded")
        return
    if game.turn_order.size() != 0 or not game.pending_reaction.is_empty():
        _fail("Deployment unexpectedly triggered combat")
        return
    if not game.begin_battle():
        _fail("Could not begin battle after legal deployment")
        return
    if game.deployment_active or game.turn_order.size() != 8:
        _fail("Begin Battle did not roll initiative")
        return
    if game.actors["alden"]["position"] != Vector2i(0, 8):
        _fail("Beginning combat reset the custom position")
        return
    if game.begin_battle() or game.place_character("pip", Vector2i(0, 7)):
        _fail("Deployment remained available after battle started")
        return

    var ui: Node = CombatScene.instantiate()
    root.add_child(ui)
    await process_frame
    var scene_game = ui.get("engine")
    var board = ui.get("board")
    if not scene_game.deployment_active or ui.get("adventure").stage != "approach":
        _fail("Scene did not open with story before deployment")
        return
    if not ui.get("story_panel").visible:
        _fail("Original story introduction missing")
        return
    ui.call("_on_story_continue")
    if not ui.get("setup_panel").visible:
        _fail("Continue did not reveal formation controls")
        return
    if ui.get("combat_action_row").visible:
        _fail("Combat actions must be hidden in setup")
        return
    if not board.get_highlights()["move"].is_empty():
        _fail("Movement range shown before battle")
        return

    ui.call("_on_formation", "diamond")
    if scene_game.active_formation != "diamond":
        _fail("Diamond formation button failed")
        return
    var original: Vector2i = scene_game.actors["pip"]["position"]
    ui.call("_on_cell_clicked", original)
    if ui.get("deployment_selected_id") != "pip":
        _fail("Clicking a character did not select for repositioning")
        return
    ui.call("_on_cell_clicked", Vector2i(0, 7))
    if scene_game.actors["pip"]["position"] != Vector2i(0, 7):
        _fail("Click-to-place did not move the selected hero")
        return
    if scene_game.active_formation != "custom":
        _fail("Manual placement should change formation to Custom")
        return
    ui.call("_on_begin_battle")
    if scene_game.deployment_active or ui.get("setup_panel").visible:
        _fail("Deployment UI remained visible after Begin Battle")
        return
    if not ui.get("combat_action_row").visible or scene_game.turn_order.size() != 8:
        _fail("Combat did not resume with normal action bar and initiative")
        return

    print("PASS: Square/Line/Diamond formation, manual placement, safe zones, pre-initiative setup and UI transition")
    quit(0)
