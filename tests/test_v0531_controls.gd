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
func run() -> void:
    var lab = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    # Audio playback cleanup is covered by the existing audio suite.
    lab.sfx_players.clear()
    lab.party_level = 3
    lab._start_battle()
    lab.engine = F.battle()
    lab.board.engine = lab.engine
    lab.picker_actor = ""
    lab._refresh()
    var b = lab.engine
    check(lab.spell_ids.has("web") and not lab.spell_cards["web"].disabled, "L3 menu")
    lab._select_spell_card("web")
    check(lab.action_mode == "spell" and not lab.web_controls.visible, "selection should arm without preview")
    var before := F.state(b)
    lab._on_cell_clicked(Vector2i(4, 4))
    check(lab.web_controls.visible and not lab.confirm_web.disabled and lab.board.area_preview_valid, "legal preview")
    check(F.state(b) == before and b.active_effects.is_empty(), "tile tap cast or changed RNG")
    lab._on_cell_clicked(Vector2i(5, 4))
    check(F.state(b) == before and lab.web_anchor == Vector2i(5, 4), "different tap must retarget")
    lab._cancel_web()
    check(F.state(b) == before and not lab.web_controls.visible and lab.web_anchor.x < 0, "cancel mutated resources")
    lab._select_spell_card("web")
    lab._on_cell_clicked(Vector2i(28, 18))
    check(lab.confirm_web.disabled and not lab.board.area_preview_valid and lab.action_hint.text.contains("full 4x4"), "invalid preview/reason")
    lab._confirm_web()
    check(F.state(b) == before, "invalid confirm spent resources")
    lab._on_cell_clicked(Vector2i(4, 4))
    lab.board.pan_by(Vector2(-15, -10))
    check(lab.web_anchor.x < 0 and not lab.web_controls.visible, "pan stale anchor")
    lab._confirm_web()
    check(F.state(b) == before, "stale confirm cast")
    for zoom in [0.65, 1.0, 1.6]:
        lab.board.camera_zoom = zoom
        lab.board.camera_offset = Vector2(-10, -20)
        var point: Vector2 = (Vector2(4, 4) + Vector2(0.5, 0.5)) * float(lab.board.display_cell_size) * zoom + lab.board.camera_offset
        check(lab.board._cell_from_position(point) == Vector2i(4, 4), "camera transform")
        lab.board._activate_cell(lab.board._cell_from_position(point))
        check(lab.web_anchor == Vector2i(4, 4), "pointer preview transform")
        lab.board.zoom_at(point, 1.1)
        check(lab.web_anchor.x < 0, "zoom stale anchor")
    lab._on_cell_clicked(Vector2i(4, 4))
    lab.board.reset_camera()
    check(lab.web_anchor.x < 0, "reset view stale anchor")
    lab.board.keyboard_cell = Vector2i(4, 4)
    var key := InputEventKey.new()
    key.keycode = KEY_ENTER
    key.pressed = true
    lab.board._gui_input(key)
    check(lab.web_anchor == Vector2i(4, 4) and F.state(b) == before, "keyboard must preview, not cast")
    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.position = Vector2(120, 120)
    touch.pressed = true
    lab.board._gui_input(touch)
    var drag := InputEventScreenDrag.new()
    drag.index = 0
    drag.position = Vector2(200, 120)
    lab.board._gui_input(drag)
    touch.pressed = false
    touch.position = drag.position
    lab.board._gui_input(touch)
    check(lab.web_anchor.x < 0 and F.state(b) == before, "touch drag selected/cast")
    lab._on_cell_clicked(Vector2i(4, 4))
    touch.pressed = true
    lab.board._gui_input(touch)
    var second := InputEventScreenTouch.new()
    second.index = 1
    second.position = Vector2(250, 120)
    second.pressed = true
    lab.board._gui_input(second)
    drag.position = Vector2(180, 120)
    lab.board._gui_input(drag)
    second.pressed = false
    lab.board._gui_input(second)
    touch.pressed = false
    lab.board._gui_input(touch)
    check(lab.web_anchor.x < 0 and F.state(b) == before, "pinch selected/cast")
    lab._on_cell_clicked(Vector2i(4, 4))
    lab._select_spell_card("fire_bolt")
    check(lab.web_anchor.x < 0 and not lab.web_controls.visible, "spell change stale anchor")
    lab._select_spell_card("web")
    lab._on_cell_clicked(Vector2i(4, 4))
    lab._on_cell_clicked(Vector2i(4, 4))
    check(b.active_effects.size() == 1 and b.spell_slots_left("elyra", 2) == 1 and b.action_used, "confirmed resources")
    lab._confirm_web()
    check(b.spell_slots_left("elyra", 2) == 1 and lab.action_mode.is_empty(), "double confirmation")
    lab.selected_cell = Vector2i(4, 4)
    lab._update_selection_details()
    check(lab.selection_details.text.contains("Lightly Obscured"), "tile details")
    b.action_used = false
    lab._refresh()
    lab._select_spell_card("web")
    # Slot guard disables selection; set next-turn resources to test actor change.
    b.slotted_cast_this_turn = false
    lab._refresh()
    lab._select_spell_card("web")
    lab._on_cell_clicked(Vector2i(4, 4))
    b.turn_index = b.turn_order.find("brunna")
    b._begin_turn()
    lab._refresh()
    check(lab.web_anchor.x < 0 and not lab.spell_ids.has("web"), "actor change stale anchor")
    lab._start_battle()
    check(lab.web_anchor.x < 0 and lab.engine.active_effects.is_empty(), "retry state")
    lab._show_title()
    check(not lab.web_controls.visible, "title targeting state")
    for player in lab.sfx_players.values():
        player.stop()
    await process_frame
    lab.queue_free()
    await process_frame
    if failures == 0: print("PASS: v0531 second-tap Web menu, preview/confirm/cancel, invalid reasons, pointer/keyboard camera and stale-state reset (physical touch NOT RUN)")
    quit(0 if failures == 0 else 1)
