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
    check(b.cast_area_spell("web", Vector2i(4, 4)), "cast")
    var id: String = b.active_effects.keys()[0]
    check(b.active_effects[id]["save_dc"] == 100 and b.active_effects[id]["duration_rounds"] == 600, "DC/duration")
    check(F.facts(b, "effect_applied").is_empty(), "creation rolled a save")
    check(b.is_lightly_obscured(Vector2i(4, 4)) and b.sight_perception_disadvantage(Vector2i(4, 4)), "obscurement query")
    check(b._line_clear(Vector2i(1, 4), Vector2i(10, 4)), "Web falsely opaque")
    b.sight_blockers.append(Vector2i(3, 4))
    check(not b._line_clear(Vector2i(1, 4), Vector2i(10, 4)), "existing sight blocker ignored")
    for actor in ["alden", "lab_goblin_melee_01", "elyra"]:
        b.actors[actor]["position"] = Vector2i(4, 4)
        b.effect_hook(actor, "enter", Vector2i(3, 4))
        check(b.has_condition(actor, "restrained"), "ally/enemy/caster not restrained " + actor)
        var count := F.facts(b, "effect_applied").size()
        b.actors[actor]["position"] = Vector2i(5, 4)
        b.effect_hook(actor, "enter", Vector2i(4, 4))
        b.effect_hook(actor, "enter", Vector2i(3, 4))
        check(F.facts(b, "effect_applied").size() == count, "entry not deduplicated")
        b.effect_hook(actor, "start_turn")
        check(F.facts(b, "effect_applied").size() == count + 1, "independent start trigger")
        b.actors[actor]["position"] = Vector2i(3, 4)
        b.effect_hook(actor, "enter", Vector2i(5, 4))
        check(not b.has_condition(actor, "restrained"), "exit condition stale")
    b.actors["elyra"]["position"] = Vector2i(1, 1)
    var other := b.create_test_web_area("brunna", Vector2i(4, 4), 700, false, 100)
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.turn_serial += 1
    b.effect_hook("alden", "enter", Vector2i(3, 4))
    check(b.condition_snapshot("alden")["restrained"].size() == 2 and b.movement_cost(Vector2i(4, 4)) == 2, "overlap ownership/cost")
    b.round_number = 600
    b._expire_effects()
    check(b.active_effects.has(id), "600 round duration expired early")
    b.round_number = 601
    b._expire_effects()
    check(not b.active_effects.has(id) and b.active_effects.has(other) and b.has_condition("alden", "restrained"), "expiry cleared unrelated condition")
    check(not b.is_lightly_obscured(Vector2i(4, 4)), "expired obscurement")
    b = F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    b._deal_damage("elyra", 10000)
    check(b.active_effects.is_empty(), "downing leaves Web")
    b = F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    b.actors["elyra"]["ability_scores"]["constitution"] = -100
    b._deal_damage("elyra", 2)
    check(b.active_effects.is_empty(), "failed damage concentration save leaves Web")
    b = F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    id = str(b.active_effects.keys()[0])
    b.active_effects[id]["save_dc"] = 100
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.turn_index = b.turn_order.find("alden")
    b._begin_turn()
    check(b.can_escape_effect(id) and b.movement_remaining() == 0, "player escape/speed zero")
    b.active_effects[id]["save_dc"] = 1
    check(b.escape_effect(id) and b.action_used and not b.has_condition("alden", "restrained"), "player Athletics escape")
    var enemy := "lab_goblin_melee_01"
    b.actors[enemy]["position"] = Vector2i(4, 4)
    b.active_effects[id]["save_dc"] = 100
    b.turn_index = b.turn_order.find(enemy)
    b._begin_turn()
    check(b.choose_ai_intent().get("escape_effect", "") == id, "AI Web escape decision")
    b.take_ai_turn()
    check(not F.facts(b, "escape_check").is_empty(), "AI escape action not executed")
    b = F.battle()
    b.actors["elyra"]["spellcasting"]["save_dc"] = 100
    b.cast_area_spell("web", Vector2i(4, 4))
    b.actors["alden"]["position"] = Vector2i(2, 4)
    b.turn_index = b.turn_order.find("alden")
    b._begin_turn()
    check(b.get_reachable("alden")[Vector2i(4, 4)]["cost"] >= 3, "Web reachability costs")
    check(b.move_to(Vector2i(5, 5)) and b.has_area_effect_at(b.actors["alden"]["position"]) and b.has_condition("alden", "restrained") and b.pending_move.is_empty(), "Web did not stop movement path at entry")
    b = F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    b.turn_index = b.turn_order.find(enemy)
    b.actors[enemy]["position"] = Vector2i(2, 4)
    b.actors["alden"]["position"] = Vector2i(10, 4)
    for hero in ["elyra", "brunna", "pip"]:
        b.actors[hero]["position"] = Vector2i(20, 18)
    b.actors["lab_goblin_melee_02"]["position"] = Vector2i(25, 18)
    b._begin_turn()
    var reachable := b.get_reachable(enemy)
    var intent := b.choose_ai_intent()
    var cursor: Vector2i = intent["cell"]
    while cursor != b.actors[enemy]["position"]:
        check(not b.has_area_effect_at(cursor), "AI chose avoidable Web path")
        cursor = reachable[cursor]["previous"]
    check(replay() == replay(), "deterministic replay")
    if failures == 0: print("PASS: v053 caster DC, triggers/ownership, 600-round expiry, visibility, concentration and replay")
    quit(0 if failures == 0 else 1)
func replay() -> Array:
    var b := F.battle()
    b.cast_area_spell("web", Vector2i(4, 4))
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "start_turn")
    b.ignite_web_cell(Vector2i(4, 4), "elyra")
    b.effect_hook("alden", "start_turn")
    return b.events
