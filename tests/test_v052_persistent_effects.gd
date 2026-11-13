extends SceneTree
## Issue #18: deterministic test-only regions, never a selectable Web spell.
const CombatEngine = preload("res://combat/combat_engine.gd")
const Dice = preload("res://core/dice_roller.gd")
var failures := 0

func _initialize() -> void:
    _creation_expiry_reset()
    _occasions_and_sources()
    _movement_and_routes()
    _escape_and_ai()
    _condition_rules()
    _concentration()
    _reaction_entry(false)
    _reaction_entry(true)
    _check(_replay() == _replay(), "fixed-seed event replay differs")
    if failures == 0:
        print("PASS: v052 lifecycle, trigger occasions, source ownership, terrain/path/AI, escape, Restrained, concentration, reactions and replay")
    quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)

func _fixture() -> CombatEngine:
    var b := CombatEngine.new()
    assert(b.start(52018))
    var selected: Dictionary = {}
    var ids: Array[String] = ["alden", "elyra", "brunna", "goblin_blade"]
    for i in ids.size():
        var id: String = ids[i]
        selected[id] = b.actors[id].duplicate(true)
        selected[id]["position"] = Vector2i(1 + i * 4, 9)
        selected[id]["hp"] = 1000
        selected[id]["max_hp"] = 1000
    b.actors = selected
    b.turn_order = ids
    b.turn_index = 0
    b.round_number = 1
    b.grid_size = Vector2i(18, 12)
    b.walls.clear()
    b.blocked_cells.clear()
    b.sight_blockers.clear()
    b.cover_cells.clear()
    b.difficult_terrain.clear()
    b.hazards.clear()
    b._begin_turn()
    b.events.clear()
    return b

func _events(b: CombatEngine, kind: String, target: String = "") -> Array:
    return b.events.filter(func(e: Dictionary) -> bool:
        return e["kind"] == kind and (target.is_empty() or e["target_id"] == target))

func _creation_expiry_reset() -> void:
    var b := _fixture()
    var before: Array = b.events.duplicate(true)
    _check(b.create_test_web_area("elyra", Vector2i(16, 10)).is_empty(), "out-of-grid fixture accepted")
    b.walls.append(Vector2i(4, 4))
    _check(b.create_test_web_area("elyra", Vector2i(4, 4)).is_empty(), "unanchored wall footprint accepted")
    b.walls.clear()
    _check(b.events == before and b.active_effects.is_empty(), "invalid creation mutated state")
    var id := b.create_test_web_area("elyra", Vector2i(4, 4), 2)
    _check(not id.is_empty(), "valid fixture rejected")
    var effect: Dictionary = b.active_effects[id]
    _check(effect["cells"].size() == 16 and effect["footprint"] == Vector2i(4, 4), "fixture not 4x4")
    _check(effect["cells"][0] == Vector2i(4, 4) and effect["cells"][15] == Vector2i(7, 7), "geometry order wrong")
    _check(effect["schema_version"] == 1 and effect["source"] == "elyra", "effect identity contract")
    _check(_events(b, "effect_started").size() == 1 and _events(b, "area_updated")[0]["cells"].size() == 16, "creation facts missing")
    _check(not b.action_used and b.spell_slots_left("elyra", 1) == 2, "test creation spent player resources")
    b.round_number = 2
    b._begin_turn()
    _check(b.active_effects.has(id), "effect expired early")
    b.round_number = 3
    b._begin_turn()
    _check(b.active_effects.is_empty() and b.actors["elyra"]["concentration"].is_empty(), "expiry did not end concentration")
    _check(_events(b, "effect_ended").size() == 1 and _events(b, "area_updated")[-1]["cells"].is_empty(), "expiry facts missing")
    _check(b.movement_cost(Vector2i(4, 4)) == 1, "baseline terrain not restored")
    b.create_test_web_area("elyra", Vector2i(4, 4))
    _check(b.start(52018), "restart failed")
    _check(b.active_effects.is_empty() and b.condition_sources.is_empty() and b.effect_sequence == 0, "reset leaked transient effects")
    # Nonzero initiative boundary: expire at original slot, not round start.
    b = _fixture()
    b.turn_index = 2
    id = b.create_test_web_area("elyra", Vector2i(4, 4), 1)
    b.round_number = 2
    b.turn_index = 1
    b._begin_turn()
    _check(b.active_effects.has(id), "nonzero initiative expiry was early")
    b.turn_index = 2
    b._begin_turn()
    _check(not b.active_effects.has(id), "nonzero initiative expiry was late")

func _occasions_and_sources() -> void:
    var b := _fixture()
    var a := b.create_test_web_area("elyra", Vector2i(3, 3), 3, false, 100)
    var c := b.create_test_web_area("brunna", Vector2i(4, 3), 3, false, 100)
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "enter", Vector2i(2, 4))
    b.effect_hook("alden", "enter", Vector2i(2, 4))
    b.effect_hook("alden", "enter", Vector2i(4, 3))
    _check(_events(b, "effect_applied", "alden").size() == 2, "entry repeated per cell or reentry")
    b.effect_hook("alden", "start_turn")
    b.effect_hook("alden", "start_turn")
    b.effect_hook("alden", "end_turn")
    _check(_events(b, "effect_applied", "alden").size() == 4, "start trigger not distinct/idempotent")
    _check(b.condition_snapshot("alden")["restrained"].size() == 2, "sources overwrote each other")
    var snap := b.condition_snapshot("alden")
    snap.clear()
    _check(b.has_condition("alden", "restrained"), "condition snapshot aliases authority")
    b.end_effect(a)
    _check(b.has_condition("alden", "restrained"), "unrelated expiry removed condition")
    b.actors["alden"]["position"] = Vector2i(12, 3)
    b.effect_hook("alden", "enter", Vector2i(4, 4))
    _check(not b.has_condition("alden", "restrained") and b.active_effects[c]["applications"].is_empty(), "leaving did not remove owned condition")
    # Creation inside is not an immediate save; next actual turn resolves once.
    b.actors["alden"]["position"] = Vector2i(4, 4)
    var count := _events(b, "effect_applied", "alden").size()
    b._begin_turn()
    _check(_events(b, "effect_applied", "alden").size() == count + 1, "new turn did not reset occasion")
    _check(_events(b, "condition_applied")[0]["effect_id"] == a, "condition source event missing")

func _movement_and_routes() -> void:
    var b := _fixture()
    b.actors["alden"]["position"] = Vector2i(2, 4)
    var a := b.create_test_web_area("elyra", Vector2i(3, 3), 2, false, 1)
    var c := b.create_test_web_area("brunna", Vector2i(3, 3), 2, false, 1)
    b.difficult_terrain.append(Vector2i(3, 4))
    _check(b.movement_cost(Vector2i(3, 4)) == 2 and b.movement_cost(Vector2i(4, 4)) == 2, "overlap terrain stacked")
    _check(b.get_reachable("alden")[Vector2i(3, 4)]["cost"] == 2, "path cost ignored dynamic region")
    _check(b.move_to(Vector2i(3, 4)) and b.movement_used == 2, "movement accounting disagrees")
    _check(b.move_to(Vector2i(4, 4)) and b.movement_used == 4, "movement within region cost wrong")
    _check(_events(b, "effect_applied", "alden").size() == 2, "walk within region retriggered")
    b.end_effect(a)
    _check(b.movement_cost(Vector2i(4, 4)) == 2, "overlap removal lost terrain")
    b.end_effect(c)
    _check(b.movement_cost(Vector2i(4, 4)) == 1 and b.movement_cost(Vector2i(3, 4)) == 2, "permanent terrain restoration wrong")
    # Restrained on entry stops an already-authorized multi-step path.
    b = _fixture()
    b.actors["alden"]["position"] = Vector2i(2, 4)
    b.create_test_web_area("elyra", Vector2i(3, 3), 2, false, 100)
    _check(b.move_to(Vector2i(4, 4)), "path command failed")
    _check(b._distance(b.actors["alden"]["position"], Vector2i(2, 4)) == 1 and b.has_condition("alden", "restrained") and b.pending_move.is_empty(), "restrained mover continued path")
    _check(b.movement_remaining() == 0 and not b.move_to(Vector2i(2, 4)), "Restrained movement allowed")
    # Route choice uses shared dynamic costs and AI risk; query must be pure.
    b = _fixture()
    b.turn_index = 3
    b.actors["goblin_blade"]["position"] = Vector2i(1, 4)
    b.actors["alden"]["position"] = Vector2i(9, 4)
    b.actors["elyra"]["position"] = Vector2i(16, 9)
    b.actors["brunna"]["position"] = Vector2i(17, 9)
    b._begin_turn()
    b.create_test_web_area("elyra", Vector2i(3, 3), 2, false, 100)
    var state: int = b.rng.state
    var events := b.events.duplicate(true)
    var intent := b.choose_ai_intent()
    _check(state == b.rng.state and events == b.events, "AI/presentation query changed rules state")
    var reachable := b.get_reachable("goblin_blade")
    var cell: Vector2i = intent["cell"]
    while cell != b.actors["goblin_blade"]["position"]:
        _check(b.area_effects_at(cell).is_empty(), "AI chose avoidable region route")
        cell = reachable[cell]["previous"]
    b.walls.append(Vector2i(2, 4))
    _check(not b._can_step("goblin_blade", Vector2i(1, 4), Vector2i(2, 5)), "corner cutting regressed")

func _escape_and_ai() -> void:
    var b := _fixture()
    var id := b.create_test_web_area("elyra", Vector2i(3, 3), 3, false, 100)
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "enter")
    _check(b.can_escape_effect(id) and b.escape_effect(id), "legal escape rejected")
    _check(b.action_used and b.has_condition("alden", "restrained") and not b.escape_effect(id), "failed escape action economy")
    _check(not b.bonus_action_used and b.movement_used == 0, "escape spent unrelated resources")
    b._begin_turn()
    b.active_effects[id]["save_dc"] = 1
    var state: int = b.rng.state
    var probe := RandomNumberGenerator.new()
    probe.state = state
    var expected: int = Dice.roll_d20(probe) + 5 # STR +3, Athletics proficiency +2
    _check(b.escape_effect(id), "success escape rejected")
    _check(not b.has_condition("alden", "restrained") and b.movement_remaining() == 6, "successful escape did not restore movement")
    _check(_events(b, "escape_check")[-1]["total"] == expected, "Athletics proficiency omitted")
    _check(not b.available_attack("goblin_blade").size(), "escape granted an extra Action")
    b._apply_condition("alden", "restrained", id)
    b.action_used = false
    b.pending_reaction = {"kind": "opportunity"}
    _check(not b.escape_effect(id), "escape bypassed reaction prompt")
    b.pending_reaction.clear()
    b.actors["alden"]["hp"] = 0
    b.actors["alden"]["combat_state"] = "unconscious"
    _check(not b.can_escape_effect(id), "downed actor offered escape")
    b = _fixture()
    b.turn_index = 3
    b.actors["goblin_blade"]["position"] = Vector2i(4, 4)
    id = b.create_test_web_area("elyra", Vector2i(3, 3), 3, false, 100)
    b._begin_turn()
    _check(b.choose_ai_intent().get("escape_effect", "") == id, "AI failed to choose escape")
    b.take_ai_turn()
    _check(_events(b, "escape_check").size() == 1 and _events(b, "hit").is_empty(), "AI failed to use legal escape Action")

func _condition_rules() -> void:
    var b := _fixture()
    var id := b.create_test_web_area("elyra", Vector2i(3, 3), 3, false, 100)
    b._apply_condition("alden", "restrained", id)
    b.actors["alden"]["hp"] = 999
    # A condition does not prohibit Actions, bonus actions or reactions.
    _check(b.can_dodge() and b.can_disengage() and b.can_use_second_wind(), "Restrained incorrectly forbids actions")
    for variant in 3:
        var probe := RandomNumberGenerator.new()
        b.rng.seed = 52018
        probe.seed = 52018
        var first: int = Dice.roll_d20(probe)
        var second: int = Dice.roll_d20(probe)
        if variant == 0:
            _check(b._attack_d20("alden", "goblin_blade") == mini(first, second), "Restrained outgoing attack lacks disadvantage")
        elif variant == 1:
            _check(b._attack_d20("goblin_blade", "alden") == maxi(first, second), "Restrained incoming attack lacks advantage")
        else:
            _check(b._attack_d20("alden", "alden") == first, "advantage/disadvantage failed to cancel")
    b.rng.seed = 52018
    var probe := RandomNumberGenerator.new()
    probe.seed = 52018
    var expected: int = mini(Dice.roll_d20(probe), Dice.roll_d20(probe)) + 1
    _check(b.dexterity_save("alden") == expected, "Restrained Dexterity save lacks disadvantage")

func _concentration() -> void:
    var b := _fixture()
    b._start_bless("brunna", "alden")
    _check(b._bless_bonus("alden") in range(1, 5), "Bless baseline failed")
    var id := b.create_test_web_area("brunna", Vector2i(3, 3), 3, true, 100)
    _check(b.actors["alden"]["blessed_by"] == "", "region replacement left Bless")
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "enter")
    b._start_bless("brunna", "alden")
    _check(not b.active_effects.has(id) and not b.has_condition("alden", "restrained"), "Bless replacement left region/condition")
    _check(b._bless_bonus("alden") in range(1, 5), "Bless after region failed")
    b._stop_concentration("brunna")
    id = b.create_test_web_area("elyra", Vector2i(3, 3), 3, true, 100)
    b.effect_hook("alden", "start_turn")
    b.actors["elyra"]["ability_scores"]["constitution"] = 100
    b._deal_damage("elyra", 1)
    _check(b.active_effects.has(id) and _events(b, "concentration_save")[-1]["success"], "successful concentration save ended region")
    b.actors["elyra"]["ability_scores"]["constitution"] = -100
    b._deal_damage("elyra", 21)
    _check(not b.active_effects.has(id) and not b.has_condition("alden", "restrained"), "failed concentration save left owned state")
    _check(_events(b, "concentration_save")[-1]["dc"] == 10, "concentration half damage must round down")
    for state in ["unconscious", "dead", "knocked_out"]:
        b = _fixture()
        id = b.create_test_web_area("elyra", Vector2i(3, 3), 3, true, 100)
        b.actors["elyra"]["combat_state"] = state
        b._check_concentration_after_damage("elyra", 1)
        _check(not b.active_effects.has(id), "incapacitated concentration persisted: " + state)
    b = _fixture()
    b.create_test_web_area("elyra", Vector2i(3, 3), 3, true, 100)
    b._deal_damage("elyra", 1000)
    _check(b.active_effects.is_empty(), "damage downing did not clear concentration")
    b.actors["alden"]["combat_state"] = "dead"
    b.actors["alden"]["hp"] = 0
    var other := b.create_test_web_area("brunna", Vector2i(3, 3), 3, false, 100)
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "start_turn")
    _check(b.active_effects.has(other) and not b.has_condition("alden", "restrained"), "dead actor rolled a new area save")

func _reaction_entry(accept: bool) -> void:
    var b := _fixture()
    b.turn_index = 3
    b.actors["goblin_blade"]["position"] = Vector2i(2, 4)
    b.actors["alden"]["position"] = Vector2i(1, 4)
    b.actors["alden"]["attacks"][0]["to_hit"] = 100
    b._begin_turn()
    b.create_test_web_area("elyra", Vector2i(3, 3), 2, false, 100)
    _check(b.move_to(Vector2i(4, 4)), "reaction-entry path rejected")
    _check(b.pending_reaction.get("kind", "") == "opportunity" and b.actors["goblin_blade"]["position"] == Vector2i(2, 4), "entry bypassed opportunity prompt")
    _check(_events(b, "effect_applied").is_empty(), "entry save resolved before reaction")
    _check(b.resolve_reaction(accept), "opportunity resolution failed")
    _check(b._distance(b.actors["goblin_blade"]["position"], Vector2i(2, 4)) == 1 and b.has_condition("goblin_blade", "restrained") and b.pending_move.is_empty(), "resumed movement ignored Restrained")
    _check(_events(b, "effect_applied").size() == 1, "resumed entry save count wrong")
    _check(b.actors["alden"]["reaction_used"] == accept, "reaction budget changed")

func _replay() -> Array:
    var b := _fixture()
    var id := b.create_test_web_area("elyra", Vector2i(3, 3), 2, true, 100)
    b.actors["alden"]["position"] = Vector2i(4, 4)
    b.effect_hook("alden", "enter")
    b.escape_effect(id)
    b.end_turn()
    b._deal_damage("elyra", 12)
    b.round_number = 3
    b._begin_turn()
    return b.events.duplicate(true)
