extends SceneTree
const SCENE = preload("res://scenes/combat.tscn")
const F = preload("res://tests/web_fixture.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func touch(lab: Node, point: Vector2, pressed: bool, index: int = 0) -> void:
    var event := InputEventScreenTouch.new()
    event.position = point
    event.pressed = pressed
    event.index = index
    lab._input(event)
func run() -> void:
    var lab = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab.sfx_players.clear()
    lab._start_battle()
    lab.engine = F.battle()
    lab.board.engine = lab.engine
    lab.picker_actor = ""
    lab._refresh()
    await process_frame
    await process_frame
    var b = lab.engine
    var point: Vector2 = lab.dash_button.get_global_rect().get_center()
    var before: Array = F.state(b)
    touch(lab, point, true)
    touch(lab, point, false)
    check(lab.pending_action == "dash" and F.state(b) == before, "one physical tap committed")
    # Dispatch compatibility pair through the actual viewport input pipeline.
    var mouse := InputEventMouseButton.new()
    mouse.position = point
    mouse.device = InputEvent.DEVICE_ID_EMULATION
    mouse.button_index = MOUSE_BUTTON_LEFT
    mouse.pressed = true
    Input.parse_input_event(mouse)
    mouse = mouse.duplicate()
    mouse.pressed = false
    Input.parse_input_event(mouse)
    await process_frame
    check(lab.pending_action == "dash" and not b.action_used, "synthetic mouse double-confirmed")
    point = lab.dash_button.get_global_rect().get_center()
    touch(lab, point, true)
    touch(lab, point, false)
    check(b.action_used and b.dash_extra_squares == 6 and lab.action_mode == "move", "second distinct touch didn't commit once")
    lab._cancel_action()
    b.action_used = false
    b.dash_extra_squares = 0
    lab._refresh()
    await process_frame
    point = lab.dash_button.get_global_rect().get_center()
    touch(lab, point, true)
    var drag := InputEventScreenDrag.new()
    drag.position = point + Vector2(40, 0)
    drag.index = 0
    lab._input(drag)
    touch(lab, point, false)
    check(lab.pending_action.is_empty() and not b.action_used, "drag selected/committed")
    touch(lab, point, true)
    touch(lab, point + Vector2(30, 0), true, 1)
    touch(lab, point + Vector2(30, 0), false, 1)
    touch(lab, point, false)
    check(lab.pending_action.is_empty(), "multitouch gesture selected")
    lab._select_action("dash")
    var key := InputEventKey.new()
    key.keycode = KEY_ESCAPE
    key.pressed = true
    lab._unhandled_key_input(key)
    check(lab.pending_action.is_empty() and not b.action_used, "Escape didn't cancel")
    lab._select_action("dash")
    key.keycode = KEY_ENTER
    key.echo = true
    lab._unhandled_key_input(key)
    check(not b.action_used, "key repeat confirmed")
    key.echo = false
    lab._unhandled_key_input(key)
    check(b.action_used and lab.pending_action.is_empty(), "keyboard confirm")
    lab.queue_free()
    await process_frame
    if failures == 0: print("PASS: v0532 touch-release intent, compatibility mouse suppression, drag/pinch cancellation and keyboard parity (physical iPad NOT RUN)")
    quit(0 if failures == 0 else 1)
