extends SceneTree
const F = preload("res://tests/web_fixture.gd")
func add_web(b: F.CombatEngine, source: String, cells: Array[Vector2i]) -> String:
    return b.create_area_effect(source, {"schema_version": 1, "type": "web",
        "anchor": Vector2i(4, 4), "footprint": Vector2i(4, 4), "cells": cells,
        "duration_rounds": 600, "flammable": true, "difficult_terrain": true})

func connected_replay() -> Array:
    var b := F.battle()
    var first := add_web(b, "elyra", [Vector2i(4, 4)])
    var second := add_web(b, "brunna", [Vector2i(5, 4), Vector2i(6, 4)])
    var overlap := add_web(b, "alden", [Vector2i(5, 4)])
    var isolated := add_web(b, "pip", [Vector2i(7, 5)])
    assert(not first.is_empty() and not second.is_empty() and not overlap.is_empty() and not isolated.is_empty())
    assert(b.ignite_web_cell(Vector2i(4, 4), "torch"))
    b.round_number += 1
    b._expire_effects()
    assert(not b.active_effects.has(first))
    assert(b.is_web_burning(Vector2i(5, 4)) and not b.is_web_burning(Vector2i(6, 4)))
    var clock: Dictionary = b.active_effects[second].burning_cells[Vector2i(5, 4)].duplicate(true)
    var shared: Dictionary = b.active_effects[overlap].burning_cells[Vector2i(5, 4)]
    for field in ["source", "owner", "start_round", "start_turn", "expiry_round", "expiry_turn"]:
        assert(shared[field] == clock[field])
    assert(clock.source == "torch")
    b._expire_effects()
    assert(b.active_effects[second].burning_cells[Vector2i(5, 4)] == clock)
    b.actors.alden.position = Vector2i(5, 4)
    b.effect_hook("alden", "start_turn")
    b.effect_hook("alden", "start_turn")
    assert(F.facts(b, "hit").size() == 1)
    assert(F.facts(b, "hit")[0].amount >= 2 and F.facts(b, "hit")[0].amount <= 8)
    b.round_number += 1
    b._expire_effects()
    assert(not b.active_effects.has(overlap) and b.is_web_burning(Vector2i(6, 4)))
    assert(not b.is_web_burning(Vector2i(7, 5)))
    b.round_number += 1
    b._expire_effects()
    assert(b.active_effects.keys() == [isolated] and b.burning_snapshots().is_empty())
    return b.events

func replay() -> Array:
    var b := F.battle()
    assert(b.cast_area_spell("web", Vector2i(5, 5)))
    b.ignite_web_cell(Vector2i(4, 4), "first")
    var id: String = b.active_effects.keys()[0]
    var timer: Dictionary = b.active_effects[id].burning_cells[Vector2i(4, 4)].duplicate()
    assert(not b.ignite_web_cell(Vector2i(4, 4), "second"))
    assert(b.active_effects[id].burning_cells[Vector2i(4, 4)] == timer)
    b.round_number += 1
    b._expire_effects()
    assert(not b.has_area_effect_at(Vector2i(4, 4)))
    assert(b.is_web_burning(Vector2i(5, 4)) and b.is_web_burning(Vector2i(4, 5)))
    assert(not b.is_web_burning(Vector2i(5, 5)))
    b._expire_effects()
    assert(not b.is_web_burning(Vector2i(5, 5)))
    b.round_number += 1
    b._expire_effects()
    assert(b.is_web_burning(Vector2i(5, 5)) and not b.is_web_burning(Vector2i(6, 6)))
    b._stop_concentration("elyra", "test")
    assert(b.active_effects.is_empty())
    return b.events
func _initialize() -> void:
    assert(replay() == replay())
    assert(connected_replay() == connected_replay())
    var b := F.battle()
    for y in range(3, 7): b.walls.append(Vector2i(5, y))
    b.cast_area_spell("web", Vector2i(4, 4))
    b.ignite_web_cell(Vector2i(4, 4), "fire")
    for i in range(5):
        b.round_number += 1
        b._expire_effects()
        assert(not b.is_web_burning(Vector2i(6, 4)))
    print("PASS: v0531 snapshot waves, orthogonal spread, no recursion, wall firebreak and deterministic replay")
    quit()
