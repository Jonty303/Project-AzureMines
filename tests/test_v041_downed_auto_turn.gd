extends SceneTree
const CombatEngine = preload("res://combat/combat_engine.gd")
const Dice = preload("res://core/dice_roller.gd")
const SCENE = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _seed_for_roll(wanted: int) -> int:
    var roller := RandomNumberGenerator.new()
    for seed_value in range(1, 10000):
        roller.seed = seed_value
        if Dice.roll_d20(roller) == wanted:
            return seed_value
    return 0

func _run() -> void:
    var fight := CombatEngine.new()
    if not fight.start(6411):
        _fail("Encounter did not start")
        return
    var low_seed := _seed_for_roll(1)
    var recovery_seed := _seed_for_roll(20)
    if low_seed == 0 or recovery_seed == 0:
        _fail("Could not find test d20 seeds")
        return
    fight.turn_order = ["brunna", "alden", "goblin_bow"]
    fight.turn_index = 0
    var hero: Dictionary = fight.actors["alden"]
    hero["hp"] = 0
    hero["combat_state"] = "unconscious"
    fight.actors["alden"] = hero
    fight.rng.seed = low_seed
    fight.end_turn()
    if fight.current_id() != "goblin_bow" or int(fight.actors["alden"]["death_failures"]) != 2:
        _fail("Failed death save must be recorded and downed turn skipped")
        return
    fight.turn_index = 1
    if fight.current_is_party() or fight.can_move_current() or fight.can_dash() or fight.can_dodge():
        _fail("Unconscious hero received player actions")
        return
    if fight.target_at(hero["position"]) != "alden" or fight._nearest_opponent("goblin_bow") == "alden":
        _fail("Downed hero must remain healable, but not an ordinary AI target")
        return
    fight.turn_index = 0
    hero = fight.actors["alden"]
    hero["combat_state"] = "stable"
    fight.actors["alden"] = hero
    fight.end_turn()
    if fight.current_id() != "goblin_bow" or fight.actors["alden"]["combat_state"] != "stable":
        _fail("Stable hero incorrectly requested a turn")
        return
    fight.turn_index = 0
    hero = fight.actors["alden"]
    hero["combat_state"] = "unconscious"
    hero["death_failures"] = 0
    hero["death_successes"] = 0
    fight.actors["alden"] = hero
    fight.rng.seed = recovery_seed
    fight.end_turn()
    if fight.current_id() != "alden" or not fight.current_is_party() or int(fight.actors["alden"]["hp"]) != 1:
        _fail("Natural 20 should revive hero and allow actions immediately")
        return

    var lab: Node = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab.call("_start_battle")
    var engine = lab.get("engine")
    hero = engine.actors["alden"]
    hero["hp"] = 0
    hero["combat_state"] = "unconscious"
    engine.actors["alden"] = hero
    engine.turn_index = engine.turn_order.find("alden")
    lab.call("_refresh")
    if not lab.get("end_turn_button").disabled or not lab.get("attack_button").disabled:
        _fail("Downed hero still has active bottom-bar commands")
        return
    print("PASS: auto death saves, skip stable/downed turns, natural-20 recovery, AI threat choice, disabled downed controls")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
