extends SceneTree
## Headless smoke tests for deterministic level-1 combat mechanics.

const CombatEngine = preload("res://combat/combat_engine.gd")
const RulesMath = preload("res://combat/rules_math.gd")
const Dice = preload("res://core/dice_roller.gd")


func _initialize() -> void:
    var engine = CombatEngine.new()
    if not engine.start(12345):
        _fail("Combat fixture did not load")
        return
    if engine.actors.size() != 8 or engine.turn_order.size() != 8:
        _fail("Expected four heroes and four goblins")
        return
    if int(engine.actors["alden"]["armor_class"]) != 19:
        _fail("Alden's sword-and-shield AC must be 19")
        return
    if not engine.get_reachable("alden").has(Vector2i(2, 3)):
        _fail("Alden's starting square missing from movement search")
        return
    if engine.get_reachable("alden").has(Vector2i(5, 3)):
        _fail("Movement permits standing inside a wall")
        return
    if RulesMath.attack_hits(1, 99, 15)["hit"]:
        _fail("Natural 1 must always miss")
        return
    if not RulesMath.attack_hits(20, -4, 30)["critical"]:
        _fail("Natural 20 must always be critical")
        return
    if RulesMath.attack_hits(12, 2, 15)["hit"]:
        _fail("Attack calculation incorrectly hit AC 15")
        return
    if not RulesMath.attack_hits(13, 2, 15)["hit"]:
        _fail("Attack equal to AC must hit")
        return

    var rng := RandomNumberGenerator.new()
    rng.seed = 2468
    for i in range(30):
        var damage := RulesMath.roll_damage("1d8+3", rng)
        if damage < 4 or damage > 11:
            _fail("Damage formula outside 1d8+3 bounds")
            return
        var critical := RulesMath.roll_damage("1d8+3", rng, true)
        if critical < 5 or critical > 19:
            _fail("Critical dice calculation outside 2d8+3 bounds")
            return
    if Dice.ability_modifier(17) != 3:
        _fail("Ability modifier regression")
        return

    # Verify that a player turn advances without requiring the UI.
    var initial_id: String = engine.current_id()
    engine.end_turn()
    if engine.current_id() == initial_id:
        _fail("End Turn failed to advance initiative")
        return
    print("PASS: tactical fixtures, initiative, paths, attack math, damage and turn advancement")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
