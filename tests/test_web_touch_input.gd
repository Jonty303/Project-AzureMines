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
    if int(board.get("display_cell_size")) >= 68 or not lab.get("sidebar").visible:
        _fail("Tablet landscape must keep the tabbed side panel visible")
        return
    if lab.get("main_grid").columns != 2 or lab.get("tabs").get_tab_count() != 4:
        _fail("Landscape must have side-by-side board and four information tabs")
        return
    lab.call("_apply_responsive_layout", Vector2(768, 1024))
    if lab.get("main_grid").columns != 1 or not lab.get("sidebar_panel").visible:
        _fail("Portrait must stack the board and tab panel")
        return
    lab.call("_apply_responsive_layout", Vector2(1550, 1000))
    if lab.get("main_grid").columns != 2 or int(board.get("display_cell_size")) != 68:
        _fail("Wide desktop viewport did not restore two-column board/sidebar")
        return
    lab.call("_start_battle")
    if lab.get("tabs").current_tab != 1:
        _fail("Party info should be the default sidebar tab for battle")
        return
    if lab.get("engine") == null:
        _fail("Combat Lab session did not load")
        return

    lab.call("_on_cell_clicked", Vector2i(9, 2))
    if not lab.get("selection_details").text.contains("CELL (9, 2)"):
        _fail("Selection Details did not update when the battlefield was tapped")
        return

    board.set_display_cell_size(48)
    var pressed: Array[Vector2i] = []
    board.cell_clicked.connect(func(cell: Vector2i) -> void: pressed.append(cell))

    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = Vector2(7 * 48 + 8, 6 * 48 + 8)
    board.call("_gui_input", touch)
    if not pressed.is_empty():
        _fail("A touch-down selected before the user could drag the battlefield")
        return
    touch.pressed = false
    board.call("_gui_input", touch)
    if pressed.size() != 1 or pressed[0] != Vector2i(7, 6):
        _fail("Touch-release did not resolve to the intended tile")
        return

    var synthetic := InputEventMouseButton.new()
    synthetic.button_index = MOUSE_BUTTON_LEFT
    synthetic.pressed = true
    synthetic.position = touch.position
    board.call("_gui_input", synthetic)
    synthetic.pressed = false
    board.call("_gui_input", synthetic)
    if pressed.size() != 1:
        _fail("Touch-generated mouse events double-activated the tile")
        return

    # Simulate elapsed suppression time before a genuine mouse interaction.
    board.set("_last_touch_msec", -10000)
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    mouse.pressed = true
    mouse.position = Vector2(8 * 48 + 8, 6 * 48 + 8)
    board.call("_gui_input", mouse)
    mouse.pressed = false
    board.call("_gui_input", mouse)
    if pressed.size() != 2 or pressed[1] != Vector2i(8, 6):
        _fail("Real mouse click on release stopped working")
        return

    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_RIGHT
    board.call("_gui_input", key)
    if board.keyboard_cell != Vector2i(9, 6):
        _fail("Keyboard navigation did not advance the tile cursor")
        return
    key = InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_ENTER
    board.call("_gui_input", key)
    if pressed.size() != 3 or pressed[2] != Vector2i(9, 6):
        _fail("Keyboard confirmation did not select highlighted tile")
        return
    # Bigger maps are viewed through the same camera transform used for clicks.
    var wide_setup = lab.call("_current_setup")
    if wide_setup["encounter"]["grid_size"][0] != 17:
        _fail("Default large arena should be 17 columns")
        return
    board.set_viewport_size(Vector2(500, 400))
    board.set_display_cell_size(48)
    board.reset_camera()
    board.pan_by(Vector2(-100, -40))
    if board.camera_offset.x >= 0.0:
        _fail("Panning did not move the expanded battlefield")
        return
    var expected_cell := Vector2i(9, 5)
    var board_space := (Vector2(expected_cell) + Vector2(0.2, 0.2)) * (
        float(board.display_cell_size) * board.camera_zoom) + board.camera_offset
    if board._cell_from_position(board_space) != expected_cell:
        _fail("Grid coordinates shifted after panning")
        return
    var previous_zoom: float = board.camera_zoom
    board.zoom_at(Vector2(220, 180), 1.3)
    if board.camera_zoom <= previous_zoom:
        _fail("Camera could not zoom on the expanded arena")
        return
    board_space = (Vector2(expected_cell) + Vector2(0.2, 0.2)) * (
        float(board.display_cell_size) * board.camera_zoom) + board.camera_offset
    if board._cell_from_position(board_space) != expected_cell:
        _fail("Grid coordinates shifted after camera zoom")
        return
    var count_before_drag: int = pressed.size()
    var drag_touch := InputEventScreenTouch.new()
    drag_touch.index = 0
    drag_touch.pressed = true
    drag_touch.position = Vector2(320, 240)
    board.call("_gui_input", drag_touch)
    var dragging := InputEventScreenDrag.new()
    dragging.index = 0
    dragging.position = Vector2(270, 240)
    board.call("_gui_input", dragging)
    drag_touch.pressed = false
    drag_touch.position = dragging.position
    board.call("_gui_input", drag_touch)
    if pressed.size() != count_before_drag:
        _fail("One-finger drag accidentally submitted a battlefield action")
        return
    var first := InputEventScreenTouch.new()
    first.index = 0
    first.pressed = true
    first.position = Vector2(200, 190)
    board.call("_gui_input", first)
    var second := InputEventScreenTouch.new()
    second.index = 1
    second.pressed = true
    second.position = Vector2(260, 190)
    board.call("_gui_input", second)
    var pinch := InputEventScreenDrag.new()
    pinch.index = 1
    pinch.position = Vector2(310, 190)
    var zoom_before_pinch: float = board.camera_zoom
    board.call("_gui_input", pinch)
    second.pressed = false
    second.position = pinch.position
    board.call("_gui_input", second)
    first.pressed = false
    board.call("_gui_input", first)
    if board.camera_zoom <= zoom_before_pinch or pressed.size() != count_before_drag:
        _fail("Pinch zoom did not change zoom or it selected a tile")
        return

    print("PASS: touch tap/drag/pinch, mouse, keyboard, coordinate mapping and responsive iPad layout")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
