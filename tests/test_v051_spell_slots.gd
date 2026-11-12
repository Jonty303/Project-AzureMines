extends SceneTree
## v0.5.1 spell-slot tier progression and legacy first-level compatibility.
const SetupBuilder = preload("res://combat_lab/setup_builder.gd")
const CombatEngine = preload("res://combat/combat_engine.gd")
var failures := 0


func _initialize() -> void:
    _check_slot_tables()
    _check_engine_resources()
    if failures == 0:
        print("PASS: v051 tiered spell slot progression, expenditure and cantrip compatibility")
    quit(0 if failures == 0 else 1)


func _check(ok: bool, msg: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + msg)


func _check_slot_tables() -> void:
    var l1_expected := [2, 3, 4, 4, 4]
    var l2_expected := [0, 0, 2, 3, 3]
    var l3_expected := [0, 0, 0, 0, 2]
    for level in range(1, 6):
        var party: Dictionary = SetupBuilder._build_party(level, "thief")
        _check(party.get("characters", []).size() == 4, "Party not built at level " + str(level))
        for actor in party.get("characters", []):
            if actor.get("class_id") not in ["evoker", "priest"]:
                continue
            var slots: Dictionary = actor.get("spellcasting", {}).get("spell_slots", {})
            _check(int(slots.get("1", 0)) == l1_expected[level - 1],
                "First-level slot total incorrect at character level " + str(level))
            _check(int(slots.get("2", 0)) == l2_expected[level - 1],
                "Second-level slot total incorrect at character level " + str(level))
            _check(int(slots.get("3", 0)) == l3_expected[level - 1],
                "Third-level slot total incorrect at character level " + str(level))


func _check_engine_resources() -> void:
    var setup: Dictionary = SetupBuilder.build_setup(3, "thief", "mixed", 4, "wide", 50103)
    var battle := CombatEngine.new()
    _check(battle.start_from_setup(setup, false), "Level-three CombatSetup rejected")
    var caster_id := "elyra"
    _check(battle.spell_slot_capacity(caster_id, 1) == 4, "Wrong level-one capacity")
    _check(battle.spell_slot_capacity(caster_id, 2) == 2, "Wrong level-two capacity")
    _check(battle.spell_slots_left(caster_id, 1) == 4, "Wrong available level-one slots")
    _check(battle.spell_slots_left(caster_id, 2) == 2, "Wrong available level-two slots")
    _check(battle.spell_slot_capacity("alden", 1) == 0, "Noncaster given spell slots")
    var target_id := ""
    for id in battle.actors.keys():
        if battle.actors[id]["team"] == "enemy":
            target_id = str(id)
            break
    _check(not target_id.is_empty(), "No enemy to test spell resource consumption")
    if target_id.is_empty():
        return
    battle.turn_index = battle.turn_order.find(caster_id)
    battle._begin_turn()
    # The fully open direct-target test lane guarantees legal spell casting.
    battle.actors[caster_id]["position"] = Vector2i(5, 1)
    battle.actors[target_id]["position"] = Vector2i(7, 1)
    battle.sight_blockers.clear()
    battle.walls.clear()
    battle.blocked_cells.clear()
    battle.actors[target_id]["hp"] = 300
    battle.actors[target_id]["max_hp"] = 300
    _check(battle.cast_spell("magic_missile", target_id), "Level-one Magic Missile failed")
    _check(battle.spell_slots_left(caster_id, 1) == 3, "Spell did not expend level-one slot")
    _check(battle.spell_slots_left(caster_id, 2) == 2, "Spell spent level-two slot")
    _check(int(battle.actors[caster_id]["spell_slots_by_level"].get("1", -1)) == 3,
        "Compatibility first-level slot mirror not maintained")
    battle.turn_index = battle.turn_order.find(caster_id)
    battle._begin_turn()
    _check(battle.cast_spell("fire_bolt", target_id), "Cantrip failed")
    _check(battle.spell_slots_left(caster_id, 1) == 3, "Cantrip spent a spell slot")
    _check(battle.spell_slots_left(caster_id, 2) == 2, "Cantrip spent level-two slot")
