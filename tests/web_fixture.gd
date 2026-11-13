extends RefCounted
const CombatEngine = preload("res://combat/combat_engine.gd")
const Builder = preload("res://combat_lab/setup_builder.gd")

static func battle(level: int = 3) -> CombatEngine:
    var b := CombatEngine.new()
    assert(b.start_from_setup(Builder.build_setup(level, "thief", "goblin_melee", 2, "wide", 53022), false))
    b.grid_size = Vector2i(30, 20)
    b.walls.clear()
    b.obstacles.clear()
    b.blocked_cells.clear()
    b.sight_blockers.clear()
    b.cover_cells.clear()
    b.difficult_terrain.clear()
    b.hazards.clear()
    var index := 0
    for id in b.actors.keys():
        b.actors[id]["position"] = Vector2i(index + 1, 15)
        b.actors[id]["hp"] = 1000
        b.actors[id]["max_hp"] = 1000
        index += 1
    b.actors["elyra"]["position"] = Vector2i(1, 1)
    b.turn_index = b.turn_order.find("elyra")
    b._begin_turn()
    b.events.clear()
    return b

static func facts(b: CombatEngine, kind: String) -> Array:
    return b.events.filter(func(e: Dictionary) -> bool: return e["kind"] == kind)

static func state(b: CombatEngine) -> Array:
    return [b.actors.duplicate(true), b.events.duplicate(true), b.active_effects.duplicate(true),
        b.condition_sources.duplicate(true), b.rng.state, b.action_used, b.slotted_cast_this_turn,
        b.effect_sequence]
