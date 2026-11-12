extends SceneTree
## Contract tests for tablet layout, screen touch and keyboard tile selection.
const SCENE = preload("res://scenes/combat.tscn")
const CombatBoard = preload("res://combat/combat_board.gd")

func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var lab: Node = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    var board: Control = lab.get("board")
    if board == null:
        _fail("Combat board missing")
        return

    lab.call("_apply_responsive_layout", Vector2(1024, 768))
    if int(board.get("display_cell_size")) >= 68 or lab.get("sidebar").visible:
        _fail("Tablet-sized viewport did not activate compact board/layout")
        return
    lab.call("_apply_responsive_layout", Vector2(1550, 1000))
    if not lab.get("sidebar").visible or int(board.get("display_cell_size")) != 68:
        _fail("Wide desktop viewport did not restore full board/sidebar")
        return
    lab.call("_start_battle")
    if lab.get("engine") == null:
        _fail("Combat Lab session did not load")
        return

    board.set_display_cell_size(48)
    var pressed: Array[Vector2i] = []
    board.cell_clicked.connect(func(cell: Vector2i) -> void: pressed.append(cell))

    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = Vector2(7 * 48 + 8, 6 * 48 + 8)
    board.call("_gui_input", touch)
    if pressed.size() != 1 or pressed[0] != Vector2i(7, 6):
        _fail("Physical-touch event did not resolve to the correct tile")
        return

    var synthetic := InputEventMouseButton.new()
    synthetic.button_index = MOUSE_BUTTON_LEFT
    synthetic.pressed = true
    synthetic.position = touch.position
    board.call("_gui_input", synthetic)
    if pressed.size() != 1:
        _fail("Touch-generated mouse event double-activated the tile")
        return

    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    mouse.pressed = true
    mouse.position = Vector2(8 * 48 + 8, 6 * 48 + 8)
    board.call("_gui_input", mouse)
    if pressed.size() != 2 or pressed[1] != Vector2i(8, 6):
        _fail("Normal mouse clicks stopped working after touch")
        return

    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_RIGHT
    board.call("_gui_input", key)
    if board.keyboard_cell != Vector2i(8, 6):
        _fail("Keyboard navigation did not advance the tile cursor")
        return
    key = InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_ENTER
    board.call("_gui_input", key)
    if pressed.size() != 3 or pressed[2] != Vector2i(8, 6):
        _fail("Keyboard confirmation did not select highlighted tile")
        return
    print("PASS: native touch, duplicate event suppression, mouse, keyboard and responsive battle layout")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
