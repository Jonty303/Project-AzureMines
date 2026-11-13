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
    var started: bool = engine.begin_battle()
    if not started:
        push_error("Visual QA fixture failed to begin battle")
        return
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
    var cells: Array[Vector2i] = []
    for y in range(2, 6):
        for x in range(11, 15):
            var cell := Vector2i(x, y)
            if not engine._area_barrier(cell):
                cells.append(cell)
    var effect_id: String = engine.create_area_effect("elyra", {
        "schema_version": 1, "type": "web", "anchor": Vector2i(11, 2),
        "footprint": Vector2i(4, 4), "cells": cells, "duration_rounds": 20,
        "concentration": true, "save_dc": 10, "difficult_terrain": true,
        "condition": "restrained", "triggers": ["enter", "start_turn"], "flammable": true
    })
    if effect_id.is_empty():
        push_error("Visual QA fixture failed to create masked Web")
        return
    var ignited: bool = engine.ignite_web_cell(Vector2i(12, 2), "test_visual")
    if not ignited:
        push_error("Visual QA fixture failed to ignite Web")
        return
    engine.ignite_actor("pip", "test_visual")
    lab._refresh()
    board.inspected_cell = Vector2i(6, 3)
    board.camera_zoom = 0.80
    board.queue_redraw()
    lab.battle_status.text = "VISUAL QA FIXTURE — occlusion / Web / Burning / Bless"
