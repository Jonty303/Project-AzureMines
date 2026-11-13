extends SceneTree
const F = preload("res://tests/web_fixture.gd")
const Builder = preload("res://combat_lab/setup_builder.gd")
const CombatEngine = preload("res://combat/combat_engine.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)
func _initialize() -> void:
    var b := F.battle()
    var id := b.create_test_web_area("elyra", Vector2i(4, 4), 5, false, 1)
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "enter")
    var save: Dictionary = F.facts(b, "rules_check")[-1]
    check(save["outcome"] == "SUCCESS" and save["dice"].size() == 1 and save["dc"] == 1, "Web success captured dice/DC")
    check(save["total"] == int(save["dice"][0]) + int(save["modifiers"]["Dexterity"]), "save modifier agreement")
    check(save["text"].contains("SUCCESS") and save["text"].contains("d20") and save["text"].contains(id), "readable Web result")
    b.effect_hook("alden", "enter")
    check(F.facts(b, "rules_check")[-1]["outcome"] == "SKIPPED", "actual duplicate boundary logged")
    b.active_effects[id]["save_dc"] = 99
    b.effect_hook("alden", "start_turn")
    check(b.has_condition("alden", "restrained") and F.facts(b, "rules_check")[-1]["outcome"] == "FAILURE", "failure consequence")
    var before := F.state(b)
    for i in range(5):
        b.preview_area_spell("web", Vector2i(5, 5))
        b.get_reachable("elyra")
        b.choose_ai_intent()
        b.action_info("dash")
    check(F.state(b) == before, "pure previews changed events/state/RNG")
    var rng_before := b.rng.state
    check(not b.move_to(Vector2i(-1, -1)), "invalid move accepted")
    check(b.rng.state == rng_before and b.events[-1]["outcome"] == "REJECTED", "explicit rejection logged without RNG")
    b.turn_index = b.turn_order.find("alden")
    b.action_used = false
    b.escape_effect(id)
    var escapes: Array = F.facts(b, "rules_check").filter(func(e: Dictionary) -> bool: return e.get("rule") == "Escape Athletics")
    check(escapes.size() == 1 and escapes[0].has("dice") and escapes[0]["dc"] == 99 and b.action_used, "Escape dice/cost")
    b = F.battle()
    b.actors["alden"]["position"] = Vector2i(2, 1)
    b.actors["alden"]["concentration"] = {"spell": "bless", "targets": []}
    b._check_concentration_after_damage("alden", 20)
    check(F.facts(b, "rules_check")[-1]["rule"] == "Concentration CON save" and F.facts(b, "rules_check")[-1].has("dice"), "concentration detail")
    b.actors["alden"]["hp"] = 0
    b.actors["alden"]["combat_state"] = "unconscious"
    b._roll_death_save("alden")
    check(F.facts(b, "rules_check")[-1]["rule"] == "Death save", "death save audit")
    check(replay() == replay(), "seed replay differs")
    b = F.battle()
    b.actors["elyra"]["dodging"] = true
    b.dexterity_save("elyra")
    check(b.last_d20["advantage"] and b.last_d20["dice"].size() == 2 and b.last_d20["reason"] == "Dodge", "Dodge DEX save advantage snapshot")
    b.actors["lab_goblin_melee_01"]["position"] = Vector2i(2, 1)
    check(b.cast_spell("fire_bolt", "lab_goblin_melee_01"), "spell attack")
    var attacks: Array = F.facts(b, "rules_check").filter(func(e: Dictionary) -> bool: return e.get("rule") == "Attack")
    check(attacks.size() == 1 and attacks[0].has("dice") and attacks[0].has("modifiers") and attacks[0].has("ac") and attacks[0].has("cover_bonus"), "attack audit missing dice/modifiers/AC/cover")
    var cast: Dictionary = F.facts(b, "cast")[0]
    check(cast["resource_cost"]["economy"] == "action" and cast["resources"]["action_used"], "cast action expenditure")
    check(b.events.all(func(e: Dictionary) -> bool: return e["kind"] == "sound" or not e["text"].is_empty()), "resolved fact has no full-log text")
    # Real giant spider fixture retains saves/Restrained; only terrain cost changes.
    b = CombatEngine.new()
    check(b.start_from_setup(Builder.build_setup(3, "thief", "spider", 1, "wide", 532), false), "spider setup")
    var spider := "lab_spider_01"
    check(b.actors[spider].get("traits", {}).get("web_walker", false), "typed fixture trait missing")
    b.walls.clear()
    b.blocked_cells.clear()
    b.difficult_terrain.clear()
    b.hazards.clear()
    id = b.create_test_web_area("elyra", Vector2i(4, 4), 5, false, 99)
    check(not id.is_empty(), "spider Web fixture")
    check(b.movement_cost(Vector2i(4, 4), spider) == 1 and b.movement_cost(Vector2i(4, 4), "alden") == 2, "Web Walker narrowly scoped terrain")
    b.difficult_terrain.append(Vector2i(4, 4))
    check(b.movement_cost(Vector2i(4, 4), spider) == 2, "trait bypassed unrelated terrain")
    b.actors[spider]["position"] = Vector2i(4, 4)
    b.effect_hook(spider, "enter")
    save = F.facts(b, "rules_check")[-1]
    check(save["modifiers"]["Dexterity"] == 3 and save["outcome"] == "FAILURE" and b.has_condition(spider, "restrained"), "fabricated spider immunity")
    check(save["text"].contains("Web Walker") and save["text"].contains("no save immunity"), "trait log explanation")
    if failures == 0: print("PASS: v0532 resolved dice/modifiers/DC/consequences, pure previews, deterministic replay and narrow Web Walker")
    quit(0 if failures == 0 else 1)
func replay() -> Array:
    var b := F.battle()
    b.cast_area_spell("web", Vector2i(5, 5))
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "start_turn")
    b.ignite_actor("alden", "test")
    b._actor_burning_start_turn("alden")
    b.cast_spell("fire_bolt", "missing")
    return b.events
