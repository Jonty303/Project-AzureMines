extends Control
## Test-only visual stress fixture. Never a production encounter or main scene.
const Scene = preload("res://scenes/combat.tscn")

func _ready() -> void:
    var lab: Node = Scene.instantiate()
    add_child(lab)
    await get_tree().process_frame
    lab._start_battle()
    var engine = lab.engine
    var board = lab.board
    engine.walls.clear()
    for x in range(17):
        engine.walls.append(Vector2i(x, 0))
    engine.walls.append(Vector2i(0, 1))
    engine.walls.append(Vector2i(0, 2))
    engine.actors["alden"]["position"] = Vector2i(6, 3)
    engine.actors["elyra"]["position"] = Vector2i(6, 5)
    engine.actors["brunna"]["position"] = Vector2i(12, 5)
    engine.actors["pip"]["position"] = Vector2i(13, 3)
    engine.actors["brunna"]["blessed_by"] = "brunna"
    engine.actors["brunna"]["concentration"] = {"spell": "bless"}
    engine.create_test_web_area("elyra", Vector2i(11, 2), 20, true, 10)
    engine.ignite_web_cell(Vector2i(12, 2), "test_visual")
    engine.ignite_actor("pip", "test_visual")
    board.inspected_cell = Vector2i(6, 3)
    board.camera_zoom = 0.80
    board.queue_redraw()
    lab.turn_label.text = "v0.5.4 VISUAL QA — test fixture / wagon occlusion / Web / Burning / Bless"
