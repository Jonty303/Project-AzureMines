extends SceneTree
## v0.5.1 action-aligned selector and upward-opening iPad menu contract.
const SCENE = preload("res://scenes/combat.tscn")
var failures := 0


func _initialize() -> void:
    call_deferred("_run")


func _check(ok: bool, msg: String) -> void:
    if not ok:
        failures += 1
        printerr("FAIL: " + msg)


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
    _check(lab.attack_button.get_parent() == lab.weapon_chip.get_parent(),
        "Weapon selector is not directly beneath Attack")
    _check(lab.spell_button.get_parent() == lab.spell_chip.get_parent(),
        "Spell selector is not directly beneath Spell")
    _check(lab.spell_button.text == "Spell", "Big Spell button must remain a mode control")
    _check(not lab.spell_chip.disabled, "Ready caster cannot inspect spells")
    _check(lab.slot_gems.text.contains("4/4") and lab.slot_gems.text.contains("2/2"),
        "Tiered gem resource display missing level-one/two capacities")
    _check(lab.slot_gems.text.contains("◆"), "No illuminated spell-slot gems")
    lab._toggle_spell_menu()
    _check(lab.spell_popup.visible, "Tapping spell chip did not open menu")
    _check(not lab.weapon_popup.visible, "Spell selection opened weapon menu")
    _check(lab.spell_popup.global_position.y < lab.spell_chip.global_position.y,
        "Spell menu must roll upward from selected spell chip")
    _check(lab.spell_strip.get_child_count() >= 5,
        "Spell menu did not include grouped spell entries")
    _check(lab.spell_cards.has("fire_bolt") and lab.spell_cards.has("magic_missile"),
        "Known implemented cantrip/slotted spell missing from roll-up")
    lab._select_spell_card("magic_missile")
    _check(not lab.spell_popup.visible and lab._selected_spell() == "magic_missile"
        and lab.action_mode == "spell", "Choosing spell failed to select and dismiss menu")
    lab._toggle_weapon_menu()
    _check(lab.weapon_popup.visible and not lab.spell_popup.visible,
        "Tapping weapon chip did not open an exclusive weapon menu")
    _check(lab.weapon_popup.global_position.y < lab.weapon_chip.global_position.y,
        "Weapon picker must open above weapon chip")
    lab._select_weapon_card("dagger")
    _check(not lab.weapon_popup.visible and lab._selected_weapon() == "dagger"
        and lab.action_mode == "attack", "Choosing weapon failed to select attack mode")
    lab._select_spell_card("magic_missile")
    engine.actors["elyra"]["spell_slots_remaining"] = 0
    lab._refresh()
    _check(lab.spell_cards["magic_missile"].disabled,
        "Empty first-level slots still permit Magic Missile")
    _check(not lab.spell_cards["fire_bolt"].disabled,
        "Cantrip disabled when slotted spells are exhausted")
    _check(lab.slot_gems.text.contains("0/4") and lab.slot_gems.text.contains("2/2"),
        "Expended slots not reflected independently per tier")
    lab._toggle_spell_menu()
    _check(lab.spell_popup.visible and lab.spell_cards["magic_missile"].disabled,
        "Unavailable prepared spell vanished instead of staying greyed out")
    lab._select_spell_card("fire_bolt")
    _check(lab._selected_spell() == "fire_bolt", "A legal cantrip could not be selected")
    engine.turn_index = engine.turn_order.find("alden")
    engine._begin_turn()
    lab._refresh()
    _check(not lab.slot_gems.visible, "Non-spellcaster displays empty spell resources")
    if failures == 0:
        print("PASS: v051 anchored roll-up selectors, tier markers, slot gems and disabled spells")
    lab.queue_free()
    quit(0 if failures == 0 else 1)
