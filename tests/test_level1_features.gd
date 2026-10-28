extends SceneTree
## Focused tests for only level-1 features on our canonical four heroes.

const CombatEngine = preload("res://combat/combat_engine.gd")

func _initialize() -> void:
    _run()


func _turn_of(battle, id: String) -> void:
    battle.turn_index = battle.turn_order.find(id)
    battle._begin_turn()


func _run() -> void:
    var combat = CombatEngine.new()
    if not combat.start(101):
        _fail("Unable to read fixed combat fixtures")
        return

    # Second Wind: bonus action, resource use and healing cap; does not expend Action.
    _turn_of(combat, "alden")
    var alden: Dictionary = combat.actors["alden"]
    alden["hp"] = 4
    combat.actors["alden"] = alden
    if not combat.use_second_wind():
        _fail("Second Wind unavailable at level 1")
        return
    if combat.actors["alden"]["hp"] <= 4 or combat.actors["alden"]["hp"] > 12:
        _fail("Second Wind did not heal to a valid HP total")
        return
    if combat.actors["alden"]["second_wind_remaining"] != 1 or not combat.bonus_action_used or combat.action_used:
        _fail("Second Wind action/resource accounting incorrect")
        return
    if combat.use_second_wind():
        _fail("Used a second Bonus Action on the same turn")
        return

    # A level-1 Thief gains Sneak Attack only if an ally engages the target.
    _turn_of(combat, "pip")
    var shortbow: Dictionary = combat.actors["pip"]["attacks"][0]
    if combat._sneak_attack_eligible("pip", "goblin_blade", shortbow, false):
        _fail("Sneak Attack incorrectly enabled without adjacent ally")
        return
    alden = combat.actors["alden"]
    alden["position"] = combat.actors["goblin_blade"]["position"] + Vector2i(0, 1)
    combat.actors["alden"] = alden
    if not combat._sneak_attack_eligible("pip", "goblin_blade", shortbow, false):
        _fail("Sneak Attack not enabled by an adjacent ally")
        return
    if combat._sneak_attack_eligible("pip", "goblin_blade", shortbow, true):
        _fail("Sneak Attack must not apply with Disadvantage")
        return

    # Mage Armor uses one of Elyra's two level-1 slots and raises AC to 15.
    _turn_of(combat, "elyra")
    if not combat.can_cast_spell("mage_armor", "elyra"):
        _fail("Mage Armor should be legal on Elyra")
        return
    if not combat.cast_spell("mage_armor", "elyra"):
        _fail("Mage Armor cast was rejected")
        return
    if combat.actors["elyra"]["armor_class"] != 15 or combat.actors["elyra"]["spell_slots_remaining"] != 1:
        _fail("Mage Armor AC and spell slots incorrect")
        return
    if combat.cast_spell("magic_missile", "goblin_bow"):
        _fail("A second slotted spell cast in the same turn was accepted")
        return

    # Healing Word uses Bonus Action, a slot, and leaves Action available.
    _turn_of(combat, "brunna")
    if not combat.can_cast_spell("healing_word", "alden"):
        _fail("Healing Word should target a wounded ally in range")
        return
    if not combat.cast_spell("healing_word", "alden"):
        _fail("Healing Word cast was rejected")
        return
    if not combat.bonus_action_used or combat.action_used:
        _fail("Healing Word must use Bonus Action but not Action")
        return
    if int(combat.actors["brunna"]["spell_slots_remaining"]) != 1:
        _fail("Healing Word did not cost one spell slot")
        return
    if combat.can_cast_spell("guiding_bolt", "goblin_blade"):
        _fail("Unimplemented spells must not be exposed as available")
        return

    # A cantrip still works after a slotted Bonus Action spell, if Action remains.
    # This preserves modern action/slot economy without implementing reactions yet.
    var blaze: Dictionary = combat.actors["brunna"]
    if not combat.can_cast_spell("sacred_flame", "goblin_blade"):
        _fail("Sacred Flame unavailable after Healing Word")
        return
    combat.cast_spell("sacred_flame", "goblin_blade")
    if not combat.action_used:
        _fail("Sacred Flame failed to consume Action")
        return

    print("PASS: level-1 second wind, sneak attack eligibility, healing word, mage armor, cantrips and spell resources")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
