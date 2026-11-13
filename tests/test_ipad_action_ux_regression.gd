extends SceneTree
## iPad Safari visual-contract regressions: safe glyphs, touch paging and honest command state.
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
    lab.party_level = 3
    lab._start_battle()
    var engine = lab.engine
    _check(engine.begin_battle(), "Could not enter battle")
    engine.turn_index = engine.turn_order.find("elyra")
    engine._begin_turn()
    lab._refresh()
    await process_frame

    _check(lab.slot_gems.text.contains("L1: 4/4") and lab.slot_gems.text.contains("L2: 2/2"),
        "Spell resources must show legible level/count text")
    _check(not lab.slot_gems.text.contains("◆") and not lab.spell_chip.text.contains("▴"),
        "Resource or selector uses nonportable iPad Web-font symbols")
    _check(lab.spell_scroll.custom_minimum_size.y >= 260,
        "Spell list's visible touch area is too small")
    _check(lab.spell_scroll_previous.custom_minimum_size.y >= 48 and
        lab.spell_scroll_next.custom_minimum_size.y >= 48,
        "Spell paging requires finger-size buttons")

    lab._toggle_spell_menu()
    await process_frame
    await process_frame
    _check(lab.spell_popup.visible, "Spell picker failed to open")
    # Force a long enough list to exercise paging on all test viewport sizes.
    var filler := Control.new()
    filler.custom_minimum_size = Vector2(0, 400)
    lab.spell_strip.add_child(filler)
    await process_frame
    lab._update_spell_scroll_buttons()
    var scrollbar: VScrollBar = lab.spell_scroll.get_v_scroll_bar()
    _check(scrollbar.max_value - scrollbar.page > 100.0,
        "Test fixture should have scrollable content")
    _check(lab.spell_scroll_previous.disabled and not lab.spell_scroll_next.disabled,
        "Initial paging controls must start at the top")
    lab._scroll_spell_list(1)
    _check(lab.spell_scroll.scroll_vertical > 0, "More spells button did not scroll")
    _check(not lab.spell_scroll_previous.disabled,
        "Previous button did not enable after paging")
    lab._scroll_spell_list(-1)
    _check(lab.spell_scroll.scroll_vertical == 0, "Previous button did not return to top")
    filler.queue_free()
    lab._hide_selection_menus()

    # An unavailable spell may still be selected, but not visually armed.
    lab._select_spell_card("fire_bolt")
    _check(lab.action_mode == "spell", "Valid cantrip failed to arm")
    engine.action_used = true
    lab._refresh()
    _check(lab.action_mode.is_empty() and not lab.spell_button.button_pressed,
        "Spent action left spell-targeting button visibly armed")
    _check(lab.spell_button.disabled, "No-budget wizard still advertises casting")

    # Cleric retains a legal bonus spell after using the main action.
    engine.turn_index = engine.turn_order.find("brunna")
    engine._begin_turn()
    engine.action_used = true
    lab._refresh()
    _check(lab.action_mode.is_empty(), "Previous actor targeting carried into the next turn")
    _check(not lab.spell_button.disabled and lab.spell_button.text == "Bonus Spell",
        "After an action, available bonus spells must remain usable and be labelled")
    lab._select_mode("spell")
    _check(lab.action_mode == "spell" and lab._selected_spell() == "healing_word",
        "Bonus Spell must pick an available bonus-action spell")
    engine.bonus_action_used = true
    lab._refresh()
    _check(lab.spell_button.disabled and lab.action_mode.is_empty(),
        "Spent bonus action must clear spell targeting and disable casting")

    engine.turn_index = engine.turn_order.find("alden")
    engine._begin_turn()
    lab._refresh()
    _check(lab.action_mode.is_empty() and lab.spell_button.disabled,
        "Noncaster inherited prior actor's spell selection")
    if failures == 0:
        print("PASS: iPad spell paging, Web-safe labels, and action/bonus turn state")
    lab.queue_free()
    quit(0 if failures == 0 else 1)
