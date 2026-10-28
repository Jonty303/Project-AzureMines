extends SceneTree
## Four goblins, physical wagon/chests, deterministic fire hazards and cover.
const CombatEngine = preload("res://combat/combat_engine.gd")
const Scene = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var game = CombatEngine.new()
    if not game.start(360):
        _fail("Campsite encounter did not load")
        return
    var melee := 0
    var ranged := 0
    for actor in game.actors.values():
        if actor["team"] == "enemy":
            if actor["role"] == "ranged" and actor["attacks"][0]["id"] == "shortbow":
                ranged += 1
            if actor["role"] == "melee" and actor["attacks"][0]["id"] == "knife":
                melee += 1
    if melee != 2 or ranged != 2:
        _fail("Campsite must have exactly two knife goblins and two shortbow goblins")
        return
    for cell in [Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 4), Vector2i(4, 5), Vector2i(8, 6)]:
        if game._is_open("alden", cell):
            _fail("A prop permits movement through its footprint: %s" % cell)
            return
    if game._line_clear(Vector2i(4, 3), Vector2i(8, 3)):
        _fail("Shots pass through the central wagon")
        return
    if not game._line_clear(Vector2i(3, 5), Vector2i(5, 5)):
        _fail("Chest must provide half cover, not total line-of-sight blocking")
        return
    if game.cover_bonus(Vector2i(3, 5), Vector2i(5, 5)) != 2:
        _fail("Chest did not grant +2 half cover")
        return
    if game.cover_bonus(Vector2i(2, 3), Vector2i(3, 3)) != 0:
        _fail("Cover was applied without an intervening obstacle")
        return
    if not game._is_open("alden", Vector2i(7, 7)):
        _fail("Campfire must be walkable but hazardous")
        return
    if game.backdrop.get("edge", "") != "north":
        _fail("Northern forest is missing")
        return

    # Put Alden beside the fire. Entry and start of turn both hurt.
    var alden: Dictionary = game.actors["alden"]
    alden["position"] = Vector2i(6, 7)
    alden["hp"] = 12
    game.actors["alden"] = alden
    game.turn_index = game.turn_order.find("alden")
    game._begin_turn()
    var hp_before: int = int(game.actors["alden"]["hp"])
    if not game.move_to(Vector2i(7, 7)):
        _fail("Failed to move onto campfire")
        return
    var hp_after_entry: int = int(game.actors["alden"]["hp"])
    if hp_after_entry >= hp_before or hp_before - hp_after_entry > 4:
        _fail("Fire entry damage should roll 1d4")
        return
    game._begin_turn()
    var hp_after_turn: int = int(game.actors["alden"]["hp"])
    if hp_after_turn >= hp_after_entry or hp_after_entry - hp_after_turn > 4:
        _fail("Fire did not burn at turn start")
        return

    var entrance_events := 0
    var start_events := 0
    for event in game.events:
        var line: String = str(event.get("text", ""))
        if line.contains("burned") and line.contains("entry"):
            entrance_events += 1
        if line.contains("burned") and line.contains("start of turn"):
            start_events += 1
    if entrance_events != 1 or start_events != 1:
        _fail("Expected exactly one fire event per trigger")
        return

    var root_scene: Node = Scene.instantiate()
    root.add_child(root_scene)
    await process_frame
    var board = root_scene.get("board")
    for path in [
        "res://assets/environment/covered_wagon_192x128.svg",
        "res://assets/environment/supply_chest_64.svg",
        "res://assets/environment/campfire_64.svg",
        "res://assets/environment/forest_treeline_768x128.svg"
    ]:
        if not ResourceLoader.exists(path) or load(path) == null:
            _fail("Cannot load campsite artwork: " + path)
            return
    board.queue_redraw()
    await process_frame
    print("PASS: two melee/two shortbow goblins, wagon blockers, chest cover, forest, fire triggers and art imports")
    quit(0)

func _fail(msg: String) -> void:
    printerr("FAIL: " + msg)
    quit(1)
