extends SceneTree
const CombatEngine = preload("res://combat/combat_engine.gd")
const LAB = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game := CombatEngine.new()
    if not game.start(872, true):
        _fail("Could not initialise deployment")
        return
    if game.active_formation != "square" or game.turn_order.size() != 0:
        _fail("Deployment rolled initiative prematurely")
        return
    for formation in ["line", "square", "diamond"]:
        if not game.set_formation(formation):
            _fail("Formation invalid: " + formation)
            return
    if game.place_character("alden", Vector2i(5, 3)) or game.place_character("alden", Vector2i(7, 7)):
        _fail("Invalid deployment placement accepted")
        return
    if not game.place_character("alden", Vector2i(0, 8)):
        _fail("Valid deployment placement rejected")
        return
    if not game.begin_battle() or game.turn_order.size() != 8:
        _fail("Could not begin battle after deployment")
        return
    var lab: Node = LAB.instantiate()
    root.add_child(lab)
    await process_frame
    lab.call("_start_battle")
    var instance = lab.get("engine")
    if instance == null or not instance.deployment_active or not lab.get("formation_panel").visible:
        _fail("Lab scene did not enter deployment")
        return
    if lab.get("actions_panel").visible:
        _fail("Combat commands visible during deployment")
        return
    lab.call("_set_formation", "diamond")
    var old: Vector2i = instance.actors["pip"]["position"]
    lab.call("_on_cell_clicked", old)
    if lab.get("deployment_actor") != "pip":
        _fail("Clicking a hero did not select them")
        return
    lab.call("_on_cell_clicked", Vector2i(0, 7))
    if instance.actors["pip"]["position"] != Vector2i(0, 7):
        _fail("Manual deployment was not applied")
        return
    lab.call("_begin_battle")
    if instance.deployment_active or not lab.get("actions_panel").visible:
        _fail("Action controls did not replace deployment UI")
        return
    print("PASS: deployment/formation rules and independent Combat Lab UI")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
