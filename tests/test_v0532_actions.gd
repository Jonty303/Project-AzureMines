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
func setup(lab: Node, action: String) -> void:
    lab.engine = F.battle()
    lab.board.engine = lab.engine
    lab.picker_actor = ""
    lab.heard_events = 0
    lab._discard_action()
    var b = lab.engine
    b.turn_index = b.turn_order.find("alden")
    b._begin_turn()
    if action == "second_wind": b.actors["alden"]["hp"] -= 20
    if action == "escape":
        var effect: String = b.create_test_web_area("elyra", Vector2i(4, 4), 5, false, 99)
        b.actors["alden"]["position"] = Vector2i(4, 4)
        b._apply_condition("alden", "restrained", effect)
    if action == "extinguish": b.ignite_actor("alden", "test")
    lab._refresh()
func run() -> void:
    var lab = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab.sfx_players.clear()
    lab._start_battle()
    for action in ["dash", "disengage", "dodge", "second_wind", "escape", "extinguish"]:
        setup(lab, action)
        var b = lab.engine
        var before: Array = F.state(b)
        lab._select_action(action)
        check(lab.pending_action == action and lab.intent_controls.visible, action + " pending controls")
        for field in ["Cost:", "Effect:", "Duration:", "Consequence:"]:
            check(lab.intent_text.text.contains(field), action + " explanation " + field)
        lab._toggle_explanation_details()
        check(F.state(b) == before and not b.bonus_action_used, action + " selection/details mutated engine")
        lab._cancel_action()
        check(F.state(b) == before and lab.pending_action.is_empty(), action + " cancellation mutated state")
        lab._select_action(action)
        lab._select_action(action) # intentional second press
        var after: Array = F.state(b)
        lab._confirm_action()
        check(F.state(b) == after and lab.pending_action.is_empty(), action + " duplicate confirm")
        check(b.bonus_action_used if action == "second_wind" else b.action_used, action + " cost not spent")
        if action in ["dash", "disengage"]:
            check(lab.action_mode == "move" and not lab.move_button.disabled, action + " Move unavailable")
            check(lab.move_button.text.contains(str(b.movement_remaining() * 5)), "remaining movement")
            check(lab.utility_buttons[action].text.contains("used") or lab.utility_buttons[action].text.contains("Used"), "used/active state")
            lab._cancel_action()
            check(b.action_used, "Move cancel refunded Action")
        if action == "dodge": check(b.current_actor()["dodging"] and lab.action_mode.is_empty(), "Dodge active")
        if action == "extinguish": check(b.burning_snapshot("actor", "alden").is_empty(), "Burning remains")
    setup(lab, "escape")
    var b = lab.engine
    var second: String = b.create_test_web_area("brunna", Vector2i(4, 4), 5, false, 88)
    b._apply_condition("alden", "restrained", second)
    lab._select_action("escape")
    check(lab.pending_source.is_empty() and lab.confirm_action.disabled and lab.escape_sources.visible, "multiple sources silently chosen")
    lab._choose_escape_source(2)
    check(not lab.confirm_action.disabled and lab.intent_text.text.contains("DC 88") and lab.intent_text.text.contains(second), "selected Escape source/DC")
    lab._cancel_action()
    setup(lab, "dash")
    b = lab.engine
    lab._select_action("dash")
    b.action_used = true
    var rng_before: int = b.rng.state
    lab._confirm_action()
    check(b.dash_extra_squares == 0 and b.rng.state == rng_before and lab.confirm_action.disabled, "stale legality not revalidated")
    b.action_used = false
    lab._cancel_action()
    lab._select_action("dash")
    lab._select_mode("attack")
    check(lab.pending_action.is_empty() and not b.action_used, "other action cleanup")
    lab._select_action("dash")
    b.turn_serial += 1
    lab._refresh()
    check(lab.pending_action.is_empty(), "turn cleanup")
    lab._select_action("dash")
    b.turn_index = b.turn_order.find("brunna")
    lab._refresh()
    check(lab.pending_action.is_empty(), "actor cleanup")
    setup(lab, "dash")
    lab._select_action("dash")
    lab._start_battle()
    check(lab.pending_action.is_empty(), "retry cleanup")
    setup(lab, "dash")
    lab._select_action("dash")
    lab._show_title()
    check(lab.pending_action.is_empty(), "title cleanup")
    setup(lab, "dash")
    b = lab.engine
    b.actors["alden"]["hp"] = 0
    b.actors["alden"]["combat_state"] = "unconscious"
    lab._select_action("dash")
    check(lab.pending_action.is_empty() and not b.can_dash(), "downed actor input")
    # Full log is reconstructed from every authoritative event, not a recent slice.
    setup(lab, "dash")
    lab.engine._reject("test", "sentinel earliest")
    for i in range(200): lab.engine._record("line %d" % i)
    lab.engine._reject("test", "sentinel latest")
    lab._show_live_log()
    check(lab.log_view.text.contains("sentinel earliest") and lab.log_view.text.contains("sentinel latest"), "full log truncated")
    lab.log_dialog.hide()
    for size in [Vector2(768, 1024), Vector2(1366, 1024)]:
        lab._apply_responsive_layout(size)
        lab._select_action("dash")
        check(lab.intent_text.autowrap_mode != TextServer.AUTOWRAP_OFF and lab.confirm_action.custom_minimum_size.y >= 48, "layout/touch targets")
        lab._cancel_action()
    lab.queue_free()
    await process_frame
    if failures == 0: print("PASS: v0532 six cancellable intents, single commitment, live explanations, source selection, revalidation, states and full log (physical iPad NOT RUN)")
    quit(0 if failures == 0 else 1)
