extends SceneTree
const F = preload("res://tests/web_fixture.gd")
const Spells = preload("res://combat/level1_spells.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)
func _initialize() -> void:
    for level in range(1, 6):
        var b := F.battle(level)
        for id in ["elyra", "alden", "pip", "brunna"]:
            check(Spells.known_spells(b.actors[id]).has("web") == (id == "elyra" and level >= 3), "loadout gating %s L%d" % [id, level])
        if level <= 2:
            check(not b.cast_area_spell("web", Vector2i(4, 4)), "low level cast")
        else:
            var before := F.state(b)
            check(b.area_spell_reason("web", Vector2i(4, 4)).is_empty(), "legal anchor rejected")
            check(F.state(b) == before, "query changed state/RNG")
            check(b.cast_area_spell("web", Vector2i(4, 4)), "valid cast rejected")
            check(b.spell_slots_left("elyra", 2) == (1 if level == 3 else 2), "wrong tier cost")
            check(b.spell_slots_left("elyra", 1) == 4 and b.action_used and b.slotted_cast_this_turn, "action or L1 mirror changed")
            check(b.active_effects.values()[0]["cells"].size() == 16 and F.facts(b, "cast").size() == 1, "geometry or cast fact")
            check(not b.cast_area_spell("web", Vector2i(4, 4)), "duplicate confirm")
            b.action_used = false
            check(not b.cast_spell("magic_missile", "lab_goblin_melee_01"), "one-slot guard")
    for variant in ["offboard", "negative", "range", "wall", "obstacle", "sight", "slot", "action", "reaction", "move", "unknown", "incapable", "deployment", "finished"]:
        var b := F.battle()
        b._start_bless("elyra", "alden")
        var anchor := Vector2i(4, 4)
        match variant:
            "offboard": anchor = Vector2i(28, 18)
            "negative": anchor = Vector2i(-1, 4)
            "range": anchor = Vector2i(14, 1)
            "wall": b.walls.append(Vector2i(7, 7))
            "obstacle": b.blocked_cells.append(Vector2i(7, 7))
            "sight": b.sight_blockers.append(Vector2i(3, 3))
            "slot": b.actors["elyra"]["spell_slots_by_level"]["2"] = 0
            "action": b.action_used = true
            "reaction": b.pending_reaction = {"test": true}
            "move": b.pending_move = {"test": true}
            "unknown": b.actors["elyra"]["spellcasting"]["prepared_spells"].erase("web")
            "incapable": b.actors["elyra"]["hp"] = 0
            "deployment": b.deployment_active = true
            "finished": b.finished = true
        var before := F.state(b)
        check(not b.area_spell_reason("web", anchor).is_empty(), "missing invalid reason " + variant)
        check(not b.cast_area_spell("web", anchor), "invalid cast " + variant)
        check(F.state(b) == before, "invalid cast mutated resources/concentration/RNG " + variant)
    var b := F.battle()
    check(b.area_spell_reason("web", Vector2i(13, 1)).is_empty(), "60ft inclusive boundary")
    b._start_bless("elyra", "alden")
    check(b.cast_area_spell("web", Vector2i(4, 4)), "Bless replacement cast")
    check(b.actors["alden"].get("bless_source", "").is_empty(), "Bless not removed")
    b._start_bless("elyra", "alden")
    check(b.active_effects.is_empty(), "Bless did not replace Web")
    if failures == 0: print("PASS: v053 level gating, atomic geometry/resources, slot guard and concentration replacement")
    quit(0 if failures == 0 else 1)
