extends SceneTree
const F = preload("res://tests/web_fixture.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)
func _initialize() -> void:
    var b := F.battle()
    b.actors["elyra"]["spellcasting"]["save_dc"] = 100
    b.cast_area_spell("web", Vector2i(4, 4))
    var id: String = b.active_effects.keys()[0]
    var before := F.state(b)
    check(not b.cast_fire_bolt_cell(Vector2i(4, 4)) and F.state(b) == before, "busy fire bolt changed state")
    b.action_used = false
    check(not b.cast_fire_bolt_cell(Vector2i(3, 4)), "nonweb ignition")
    b.sight_blockers.append(Vector2i(3, 3))
    check(not b.cast_fire_bolt_cell(Vector2i(4, 4)), "blocked ignition")
    b.sight_blockers.clear()
    check(b.cast_fire_bolt_cell(Vector2i(4, 4)) and b.action_used, "playable ignition")
    check(b.spell_slots_left("elyra", 2) == 1 and b.spell_slots_left("elyra", 1) == 4, "cantrip spent slot")
    check(b.is_web_burning(Vector2i(4, 4)) and not b.is_web_burning(Vector2i(5, 4)), "spontaneous adjacent spread")
    check(not b.ignite_web_cell(Vector2i(4, 4), "other"), "repeat ignition reset timer/source")
    var other := b.create_test_web_area("brunna", Vector2i(4, 4), 10, false, 100)
    for actor in ["alden", "lab_goblin_melee_01"]:
        b.actors[actor]["position"] = Vector2i(4, 4)
        b.effect_hook(actor, "enter", Vector2i(3, 4))
        var hp: int = b.actors[actor]["hp"]
        check(hp == 1000, "entry dealt fire damage")
        b.effect_hook(actor, "start_turn")
        var loss: int = hp - int(b.actors[actor]["hp"])
        check(loss >= 2 and loss <= 8, "start fire is not 2d4")
        b.effect_hook(actor, "start_turn")
        check(b.actors[actor]["hp"] == hp - loss, "duplicate fire on start hook")
    check(F.facts(b, "hit").size() == 2 and F.facts(b, "hit")[0]["damage_type"] == "fire" and F.facts(b, "hit")[0]["actor_id"] == "elyra", "damage facts/source")
    b.round_number = 2
    b.turn_index = int(b.active_effects[id]["start_turn"]) - 1
    b._expire_effects()
    check(b.is_web_burning(Vector2i(4, 4)), "burn removed before one-round boundary")
    b.turn_index += 1
    b._expire_effects()
    check(not b.is_web_burning(Vector2i(4, 4)) and b.active_effects[id]["cells"].size() == 15, "partial burnout")
    check(b.active_effects[id]["cells"].has(Vector2i(5, 4)), "adjacent cell lost")
    check(b.condition_snapshot("alden")["restrained"] == [other], "burn removed unrelated condition or left own")
    check(b.movement_cost(Vector2i(4, 4)) == 2, "independent terrain lost")
    b.end_effect(other)
    check(b.movement_cost(Vector2i(4, 4)) == 1 and not b.is_lightly_obscured(Vector2i(4, 4)), "stale removed cell cost/obscurement")
    check(not b.ignite_web_cell(Vector2i(4, 4), "fire"), "removed cell reignited")
    b.ignite_web_cell(Vector2i(5, 4), "fire")
    b._stop_concentration("elyra", "test")
    check(b.active_effects.is_empty() and not b.is_web_burning(Vector2i(5, 4)), "concentration leaves burning cells")
    b = F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    b.ignite_web_cell(Vector2i(4, 4), "elyra")
    for status in ["unconscious", "stable"]:
        b.actors["alden"]["position"] = Vector2i(4, 4)
        b.actors["alden"]["hp"] = 0
        b.actors["alden"]["combat_state"] = status
        b.actors["alden"]["death_failures"] = 0
        b.actors["alden"]["death_successes"] = 0
        b.turn_index = b.turn_order.find("alden")
        b._begin_turn()
        check(b.actors["alden"]["death_failures"] >= 1, "downed/stable actor ignored fire")
    b = F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    var extra := b.create_area_effect("brunna", {"schema_version": 1, "type": "web",
        "anchor": Vector2i(4, 4), "footprint": Vector2i(4, 4), "duration_rounds": 600,
        "concentration": false, "flammable": true, "lightly_obscured": true,
        "difficult_terrain": true, "condition": "restrained", "save_dc": 100,
        "triggers": ["enter", "start_turn"]})
    b.ignite_web_cell(Vector2i(4, 4), "first")
    b.ignite_web_cell(Vector2i(4, 4), "second")
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "start_turn")
    check(F.facts(b, "hit").size() == 1 and F.facts(b, "hit")[0]["actor_id"] == "first", "overlap fire double-damage/source overwrite")
    b._stop_concentration("elyra", "test")
    check(b.active_effects.has(extra) and b.is_web_burning(Vector2i(4, 4)), "unrelated fire source cleared")
    for cell in b.active_effects[extra]["cells"].duplicate():
        b.ignite_web_cell(cell, "first")
    b.round_number += 1
    b._expire_effects()
    check(b.active_effects.is_empty() and b.condition_sources.is_empty(), "last burned cell cleanup")
    b = F.battle()
    b.hazards.append({"position": Vector2i(4, 4), "kind": "campfire", "damage_type": "fire"})
    b.cast_area_spell("web", Vector2i(4, 4))
    check(b.is_web_burning(Vector2i(4, 4)), "authored fire did not ignite")
    check(b.start(53022) and b.active_effects.is_empty(), "restart left burning state")
    if failures == 0: print("PASS: v053 playable Fire Bolt ignition, single-cell 2d4 start damage/burnout, overlap and reset")
    quit(0 if failures == 0 else 1)
