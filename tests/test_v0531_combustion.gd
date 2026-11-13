extends SceneTree
const F = preload("res://tests/web_fixture.gd")
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
