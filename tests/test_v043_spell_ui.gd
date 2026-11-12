extends SceneTree
const SCENE = preload("res://scenes/combat.tscn")
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + message)

func _run() -> void:
    var lab: Node = SCENE.instantiate()
    root.add_child(lab)
    await process_frame
    lab._start_battle()
    var engine = lab.engine
    engine.begin_battle()
    engine.turn_index = engine.turn_order.find("elyra")
    engine._begin_turn()
    engine.actors["elyra"]["position"] = Vector2i(3, 3)
    engine.actors["lab_skeleton_01"]["position"] = Vector2i(7, 3)
    engine.walls.clear()
    engine.sight_blockers.clear()
    lab._refresh()
    lab._select_spell_card("fire_bolt")
    _agreement(lab)
    _check(not lab.spell_cards["fire_bolt"].disabled, "Ready cantrip must be enabled")
    engine.action_used = true
    lab._refresh()
    _check(lab.spell_cards["fire_bolt"].disabled, "Spent action still advertises Fire Bolt")
    _check(not lab.spell_cards["fire_bolt"].button_pressed, "Unavailable card is highlighted as usable")
    _check(lab.action_hint.text.to_lower().contains("action"), "Unavailable spell needs action-budget hint")
    _agreement(lab)
    engine.action_used = false
    engine.actors["elyra"]["spell_slots_remaining"] = 0
    lab._refresh()
    _check(lab.spell_cards["magic_missile"].disabled, "Empty slots still advertise Magic Missile")
    _check(not lab.spell_cards["fire_bolt"].disabled, "Empty slots incorrectly disable cantrips")
    engine.actors["elyra"]["spell_slots_remaining"] = 2
    engine.slotted_cast_this_turn = true
    lab._refresh()
    _check(lab.spell_cards["magic_missile"].disabled, "Turn spell limit not reflected by card")
    engine.slotted_cast_this_turn = false
    lab._select_spell_card("mage_armor")
    _check(not lab.self_button.disabled, "Legal self spell is not usable")
    engine.actors["elyra"]["mage_armor_active"] = true
    lab._refresh()
    _check(lab.spell_cards["mage_armor"].disabled and lab.self_button.disabled, "Active Mage Armor still usable")
    lab._select_spell_card("fire_bolt")
    engine.sight_blockers.append(Vector2i(5, 3))
    lab._refresh()
    var before: Array = engine.events.duplicate(true)
    lab._on_cell_clicked(Vector2i(7, 3))
    _check(lab.action_hint.text.to_lower().contains("sight"), "Blocked target needs line-of-sight reason")
    _check(engine.events == before and not engine.action_used, "Illegal click consumed resources or events")
    _agreement(lab)
    # Change actor: bonus-action healing must stay available after an action,
    # then disappear when the bonus budget is spent.
    engine.turn_index = engine.turn_order.find("brunna")
    engine._begin_turn()
    engine.action_used = true
    lab._refresh()
    lab._select_spell_card("healing_word")
    _check(not lab.spell_cards["healing_word"].disabled, "Action spent incorrectly disables bonus heal")
    _check(lab.spell_cards["cure_wounds"].disabled, "Action heal still advertised after action spent")
    engine.bonus_action_used = true
    lab._refresh()
    _check(lab.spell_cards["healing_word"].disabled, "Bonus heal ignores bonus-action budget")
    _agreement(lab)
    if failures == 0:
        print("PASS: v043 spell cards, budgets, self cast, contextual rejection and gold targets agree")
    lab.queue_free()
    quit(0 if failures == 0 else 1)

func _agreement(lab: Node) -> void:
    var engine = lab.engine
    var targets: Dictionary = lab.board.get_highlights()["spell"]
    for id in engine.actors:
        _check(targets.has(engine.actors[id]["position"]) == engine.can_cast_spell(lab._selected_spell(), id),
            "Gold target differs from can_cast_spell for " + str(id))
    for sid in lab.spell_cards:
        var legal := false
        for id in engine.actors:
            legal = legal or engine.can_cast_spell(sid, id)
        _check(lab.spell_cards[sid].disabled == not legal, "Card differs from legal targets: " + str(sid))
