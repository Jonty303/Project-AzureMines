extends SceneTree
## Instantiate the real startup scene so UI script parse failures cannot hide behind
## successful headless rules tests.

const COMBAT_SCENE = preload("res://scenes/combat.tscn")
const CombatBoard = preload("res://combat/combat_board.gd")

func _initialize() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var board_script: Script = CombatBoard
    if not board_script.can_instantiate():
        _fail("CombatBoard script did not compile")
        return

    var scene_root: Node = COMBAT_SCENE.instantiate()
    if scene_root == null:
        _fail("Combat scene could not be instantiated")
        return
    root.add_child(scene_root)
    await process_frame

    var engine_instance: Variant = scene_root.get("engine")
    var board_instance: Variant = scene_root.get("board")
    if engine_instance == null:
        _fail("Combat scene did not initialise its engine")
        return
    if not (board_instance is Control):
        _fail("Combat scene did not construct its board")
        return
    if not engine_instance.current_is_party():
        _fail("AI prelude did not advance to a party turn")
        return

    var current: String = engine_instance.current_id()
    if current.is_empty():
        _fail("Combat scene has no active character")
        return
    board_instance.queue_redraw()
    await process_frame
    await process_frame

    if int(engine_instance.actors.size()) != 6:
        _fail("Expected four party members and two tutorial goblins")
        return
    var status: Variant = scene_root.get("status_label")
    if not (status is Label) or not status.text.begins_with("Round "):
        _fail("Combat UI status was not updated")
        return

    print("PASS: combat scene instantiates, board renders, active party turn and UI status present")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
