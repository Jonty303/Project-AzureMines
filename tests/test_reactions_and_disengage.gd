extends SceneTree
## Opportunity Attack interrupt/restart and level-1 Disengage.
const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatScene = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var battle = CombatEngine.new()
    if not battle.start(156):
        _fail("Combat fixture unavailable")
        return
    var goblin: Dictionary = battle.actors["goblin_blade"]
    goblin["position"] = Vector2i(3, 3)
    battle.actors["goblin_blade"] = goblin
    battle.turn_index = battle.turn_order.find("goblin_blade")
    battle._begin_turn()

    if not battle.move_to(Vector2i(4, 3)):
        _fail("Goblin could not attempt a legal move")
        return
    if battle.pending_reaction.is_empty():
        _fail("Leaving Alden's reach did not pause for a reaction")
        return
    if battle.actors["goblin_blade"]["position"] != Vector2i(3, 3):
        _fail("Goblin moved before the Reaction was adjudicated")
        return
    if not battle.resolve_reaction(false):
        _fail("Decline reaction failed")
        return
    if not battle.pending_reaction.is_empty() or battle.actors["goblin_blade"]["position"] != Vector2i(4, 3):
        _fail("Declining Opportunity Attack did not resume movement")
        return
    if bool(battle.actors["alden"]["reaction_used"]):
        _fail("Declining a Reaction should not spend the reaction")
        return

    goblin = battle.actors["goblin_blade"]
    goblin["position"] = Vector2i(3, 3)
    battle.actors["goblin_blade"] = goblin
    battle._begin_turn()
    if not battle.move_to(Vector2i(4, 3)) or battle.pending_reaction.is_empty():
        _fail("Repeat opportunity did not prompt")
        return
    if not battle.resolve_reaction(true):
        _fail("Accepting Opportunity Attack failed")
        return
    if not bool(battle.actors["alden"]["reaction_used"]):
        _fail("Making Opportunity Attack must expend Reaction")
        return

    # Disengage prevents Opportunity Attacks while leaving enemy reach.
    goblin = battle.actors["goblin_blade"]
    goblin["position"] = Vector2i(3, 3)
    goblin["hp"] = 7
    goblin["combat_state"] = "active"
    battle.actors["goblin_blade"] = goblin
    battle.turn_index = battle.turn_order.find("alden")
    battle._begin_turn()
    if not battle.use_disengage():
        _fail("Disengage was not available")
        return
    if not battle.action_used or not bool(battle.actors["alden"]["disengaged"]):
        _fail("Disengage did not spend Action")
        return
    if not battle.move_to(Vector2i(1, 3)):
        _fail("Alden could not Disengage and move")
        return
    if not battle.pending_reaction.is_empty():
        _fail("Disengaged movement incorrectly provoked a Reaction")
        return
    if battle.actors["alden"]["position"] != Vector2i(1, 3):
        _fail("Disengaged movement did not finish")
        return

    var scene = CombatScene.instantiate()
    root.add_child(scene)
    await process_frame
    if scene.get("disengage_button") == null or scene.get("reaction_accept") == null:
        _fail("UI is missing the Disengage or reaction controls")
        return
    print("PASS: paused opportunity reactions, decline/accept, Disengage movement and UI controls")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
