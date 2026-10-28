extends SceneTree
## Level-1 Shield reaction and multi-target Bless concentration checks.

const CombatEngine = preload("res://combat/combat_engine.gd")


func _initialize() -> void:
    _run()


func _run() -> void:
    var b = CombatEngine.new()
    if not b.start(707):
        _fail("Encounter failed")
        return

    b.turn_index = b.turn_order.find("brunna")
    b._begin_turn()
    if not b.can_cast_spell("bless", "alden"):
        _fail("Bless should be a prepared level-1 spell")
        return
    if not b.cast_spell("bless", "alden"):
        _fail("Bless could not be cast")
        return
    var effect: Dictionary = b.actors["brunna"]["concentration"]
    if effect.get("spell", "") != "bless" or effect.get("targets", []).size() != 3:
        _fail("Bless must affect three nearby allies")
        return
    if b.actors["brunna"]["spell_slots_remaining"] != 1 or not b.action_used:
        _fail("Bless did not expend a spell slot and Action")
        return
    for target_id in effect["targets"]:
        if b.actors[target_id]["blessed_by"] != "brunna":
            _fail("Bless target missing a modifier")
            return
        var roll: int = b._bless_bonus(str(target_id))
        if roll < 1 or roll > 4:
            _fail("Bless bonus not in 1d4 bounds")
            return
    b._stop_concentration("brunna")
    if not b.actors["brunna"]["concentration"].is_empty():
        _fail("Concentration did not end")
        return
    for target_id in effect["targets"]:
        if b.actors[target_id]["blessed_by"] != "":
            _fail("Bless persisted after concentration ended")
            return

    var elyra: Dictionary = b.actors["elyra"]
    if b.get_current_spells().has("shield"):
        _fail("Shield should not appear in an Action spell picker")
        return
    var goblin: Dictionary = b.actors["goblin_blade"]
    goblin["position"] = Vector2i(4, 5)
    b.actors["goblin_blade"] = goblin
    b.turn_index = b.turn_order.find("goblin_blade")
    var prompted := false
    for attempt in range(12):
        b._begin_turn()
        elyra = b.actors["elyra"]
        elyra["hp"] = elyra["max_hp"]
        elyra["combat_state"] = "active"
        b.actors["elyra"] = elyra
        if not b.attack("elyra", "shortbow"):
            _fail("Goblin attack rejected")
            return
        if not b.pending_reaction.is_empty():
            prompted = true
            break
    if not prompted or b.pending_reaction.get("kind", "") != "shield":
        _fail("A successful hit did not prompt Elyra for Shield")
        return
    var before: int = int(b.actors["elyra"]["spell_slots_remaining"])
    if not b.resolve_reaction(true):
        _fail("Elyra could not cast Shield as a reaction")
        return
    if b.actors["elyra"]["reaction_used"] != true:
        _fail("Shield failed to use the Reaction")
        return
    if int(b.actors["elyra"]["spell_slots_remaining"]) != before - 1:
        _fail("Shield failed to expend one level-1 spell slot")
        return
    if int(b.actors["elyra"]["shield_bonus"]) != 5:
        _fail("Shield failed to provide +5 AC")
        return
    b.turn_index = b.turn_order.find("elyra")
    b._begin_turn()
    if b.actors["elyra"]["shield_bonus"] != 0 or b.actors["elyra"]["reaction_used"]:
        _fail("Shield/Reactions should reset at start of Elyra's turn")
        return

    print("PASS: Bless targeting/Concentration, Shield prompt, slot and Reaction timing")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
