extends Control
## Standalone Combat Lab. No narrative session, campaign registry, XP or loot writes.
const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatBoard = preload("res://combat/combat_board.gd")
const SetupBuilder = preload("res://combat_lab/setup_builder.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")
const LAST_REPORT_PATH := "user://combat_lab_last_battle.json"
const SFX := ["footstep", "melee_hit", "ranged", "magic", "heal", "miss", "damage", "death"]
const BG := Color("#0e141b")
const CREAM := Color("#e8ddc9")
const GOLD := Color("#d7aa58")

var engine: CombatEngine
var board: CombatBoard
var title_panel: VBoxContainer
var battle_panel: VBoxContainer
var title_scroll: ScrollContainer
var battle_scroll: ScrollContainer
var sidebar: VBoxContainer
var log_dialog: AcceptDialog
var log_view: TextEdit
var title_status: Label
var party_roster: RichTextLabel
var battle_status: Label
var party_status: RichTextLabel
var event_log: RichTextLabel
var formation_panel: HFlowContainer
var actions_panel: VBoxContainer
var reaction_panel: HBoxContainer
var reaction_text: Label
var reaction_accept: Button
var reaction_decline: Button
var end_turn_button: Button
var move_button: Button
var attack_button: Button
var spell_button: Button
var dash_button: Button
var dodge_button: Button
var disengage_button: Button
var wind_button: Button
var begin_button: Button
var self_button: Button
var attack_picker: OptionButton
var spell_picker: OptionButton
var level_picker: OptionButton
var fourth_picker: OptionButton
var config_dialog: ConfirmationDialog
var enemy_picker: OptionButton
var count_picker: SpinBox
var arena_picker: OptionButton
var seed_picker: SpinBox
var last_dialog: AcceptDialog
var last_view: TextEdit
var debug_dialog: AcceptDialog
var debug_view: TextEdit
var sfx_players: Dictionary = {}
var party_level := 1
var fourth_class := "thief"
var enemy_kind := "goblin_melee"
var enemy_count := 4
var arena_id := "camp"
var encounter_seed := 42024
var action_mode := ""
var deployment_actor := ""
var picker_actor := ""
var weapon_ids: Array[String] = []
var spell_ids: Array[String] = []
var last_setup: Dictionary = {}
var last_report: Dictionary = {}
var recorded := false
var heard_events := 0


func _ready() -> void:
    _build_audio()
    _load_last_report()
    _build_ui()
    _show_title()
    _apply_responsive_layout(get_viewport_rect().size)


func _make_label(content: String, parent: Node, size: int = 16) -> Label:
    var item := Label.new()
    item.text = content
    item.add_theme_font_size_override("font_size", size)
    item.add_theme_color_override("font_color", CREAM)
    parent.add_child(item)
    return item


func _make_button(content: String, parent: Node, callback: Callable, min_width: float = 120.0) -> Button:
    var item := Button.new()
    item.text = content
    item.custom_minimum_size = Vector2(min_width, 43)
    item.pressed.connect(callback)
    parent.add_child(item)
    return item


func _make_text_view(dialog: AcceptDialog) -> TextEdit:
    var item := TextEdit.new()
    item.editable = false
    item.custom_minimum_size = Vector2(300, 250)
    item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dialog.add_child(item)
    return item


func _build_audio() -> void:
    for sound_id in SFX:
        var player := AudioStreamPlayer.new()
        var path: String = "res://assets/sfx/%s.wav" % sound_id
        if ResourceLoader.exists(path):
            player.stream = load(path) as AudioStream
        player.volume_db = -12.0
        add_child(player)
        sfx_players[sound_id] = player


func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = BG
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 16)
    add_child(margin)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    margin.add_child(content)
    title_scroll = ScrollContainer.new()
    title_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    title_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(title_scroll)
    title_panel = VBoxContainer.new()
    title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_panel.add_theme_constant_override("separation", 14)
    title_scroll.add_child(title_panel)
    _make_label("AZURE MINES  /  COMBAT LAB", title_panel, 32)
    _make_label("Standalone tactical encounters · No narrative engine · No campaign rewards", title_panel, 16)
    var level_row := HFlowContainer.new()
    level_row.add_theme_constant_override("separation", 10)
    title_panel.add_child(level_row)
    _make_label("Test party level", level_row, 20)
    level_picker = OptionButton.new()
    level_picker.custom_minimum_size = Vector2(100, 42)
    for level in range(1, 6):
        level_picker.add_item(str(level), level)
    level_picker.select(0)
    level_row.add_child(level_picker)
    _make_button("Set Party Level", level_row, _set_party_level, 175)
    _make_label("Fourth party slot", level_row, 18)
    fourth_picker = OptionButton.new()
    fourth_picker.add_item("Pip — Thief")
    fourth_picker.add_item("Rowan — Hunter (test fixture)")
    fourth_picker.custom_minimum_size = Vector2(255, 42)
    fourth_picker.item_selected.connect(_set_fourth_class)
    level_row.add_child(fourth_picker)
    party_roster = RichTextLabel.new()
    party_roster.custom_minimum_size = Vector2(0, 210)
    party_roster.fit_content = true
    title_panel.add_child(party_roster)
    _make_label("The lab exposes every currently implemented class spell for testing. Higher-level class features and higher-level spell slots are not yet implemented.", title_panel, 14).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var menu := HFlowContainer.new()
    menu.add_theme_constant_override("separation", 12)
    title_panel.add_child(menu)
    _make_button("Configure Encounter...", menu, _show_config, 210)
    _make_button("Start Combat", menu, _start_battle, 175)
    _make_button("Last Battle Log", menu, _show_last_battle, 180)
    _make_button("Debug Input / Output", menu, _show_debug, 205)
    title_status = _make_label("", title_panel, 16)
    _make_label("Test mode only: levels 1–5 provide scaled HP and available first-level resources. Unimplemented progression features are not simulated.", title_panel, 14).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    battle_scroll = ScrollContainer.new()
    battle_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    battle_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_child(battle_scroll)
    battle_panel = VBoxContainer.new()
    battle_panel.add_theme_constant_override("separation", 8)
    battle_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    battle_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    battle_scroll.add_child(battle_panel)
    battle_panel.visible = false
    var heading := HFlowContainer.new()
    heading.add_theme_constant_override("separation", 12)
    battle_panel.add_child(heading)
    _make_label("COMBAT LAB", heading, 26)
    battle_status = _make_label("Preparing battle...", heading, 17)
    _make_button("Debug I/O", heading, _show_debug, 120)
    _make_button("Battle Log", heading, _show_live_log, 120)
    _make_button("Retry Battle", heading, _start_battle, 145)
    _make_button("Return to Title", heading, _show_title, 175)
    var main := HBoxContainer.new()
    main.add_theme_constant_override("separation", 14)
    main.size_flags_vertical = Control.SIZE_EXPAND_FILL
    battle_panel.add_child(main)
    var board_panel := PanelContainer.new()
    main.add_child(board_panel)
    board = CombatBoard.new()
    board.cell_clicked.connect(_on_cell_clicked)
    board_panel.add_child(board)
    sidebar = VBoxContainer.new()
    sidebar.custom_minimum_size = Vector2(370, 0)
    sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sidebar.add_theme_constant_override("separation", 8)
    main.add_child(sidebar)
    _make_label("PARTY / TURN", sidebar, 18)
    party_status = RichTextLabel.new()
    party_status.custom_minimum_size = Vector2(0, 180)
    sidebar.add_child(party_status)
    _make_label("COMBAT EVENT LOG", sidebar, 18)
    event_log = RichTextLabel.new()
    event_log.scroll_following = true
    event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sidebar.add_child(event_log)

    formation_panel = HFlowContainer.new()
    formation_panel.add_theme_constant_override("separation", 8)
    battle_panel.add_child(formation_panel)
    _make_label("Deployment:", formation_panel, 15)
    for formation in ["line", "square", "diamond"]:
        _make_button(formation.capitalize(), formation_panel, _set_formation.bind(formation), 100)
    begin_button = _make_button("Begin Battle", formation_panel, _begin_battle, 150)

    actions_panel = VBoxContainer.new()
    actions_panel.add_theme_constant_override("separation", 5)
    battle_panel.add_child(actions_panel)
    var command_row := HFlowContainer.new()
    command_row.add_theme_constant_override("separation", 6)
    actions_panel.add_child(command_row)
    move_button = _make_button("Move", command_row, _select_mode.bind("move"), 72)
    attack_button = _make_button("Attack", command_row, _select_mode.bind("attack"), 72)
    spell_button = _make_button("Spell", command_row, _select_mode.bind("spell"), 72)
    wind_button = _make_button("Second Wind", command_row, _use_second_wind, 122)
    dash_button = _make_button("Dash", command_row, _use_dash, 72)
    dodge_button = _make_button("Dodge", command_row, _use_dodge, 72)
    disengage_button = _make_button("Disengage", command_row, _use_disengage, 110)
    end_turn_button = _make_button("End Turn", command_row, _end_turn, 110)
    var select_row := HFlowContainer.new()
    select_row.add_theme_constant_override("separation", 12)
    actions_panel.add_child(select_row)
    _make_label("Weapon", select_row, 14)
    attack_picker = OptionButton.new()
    attack_picker.custom_minimum_size = Vector2(170, 36)
    attack_picker.item_selected.connect(_on_weapon_change)
    select_row.add_child(attack_picker)
    _make_label("Spell", select_row, 14)
    spell_picker = OptionButton.new()
    spell_picker.custom_minimum_size = Vector2(230, 36)
    spell_picker.item_selected.connect(_on_spell_change)
    select_row.add_child(spell_picker)
    self_button = _make_button("Cast on Self", select_row, _cast_self, 140)
    reaction_panel = HBoxContainer.new()
    reaction_panel.add_theme_constant_override("separation", 12)
    battle_panel.add_child(reaction_panel)
    reaction_text = _make_label("", reaction_panel, 16)
    reaction_accept = _make_button("React", reaction_panel, _resolve_reaction.bind(true), 100)
    reaction_decline = _make_button("Decline", reaction_panel, _resolve_reaction.bind(false), 100)

    _build_dialogs()
    _update_title()


func _build_dialogs() -> void:
    config_dialog = ConfirmationDialog.new()
    config_dialog.title = "Configure tactical encounter"
    add_child(config_dialog)
    var form := VBoxContainer.new()
    form.add_theme_constant_override("separation", 10)
    config_dialog.add_child(form)
    _make_label("Enemy archetype", form, 15)
    enemy_picker = OptionButton.new()
    for kind in ["goblin_melee", "goblin_archer", "goblin_vanguard", "wolf", "midden_grub"]:
        enemy_picker.add_item(kind.replace("_", " ").capitalize())
    form.add_child(enemy_picker)
    _make_label("Number of enemies (1–8)", form, 15)
    count_picker = SpinBox.new()
    count_picker.min_value = 1
    count_picker.max_value = 8
    count_picker.step = 1
    count_picker.value = 4
    form.add_child(count_picker)
    _make_label("Battle location", form, 15)
    arena_picker = OptionButton.new()
    for location in ["Forest camp", "Stone chamber", "Woodland watch", "Refuse room"]:
        arena_picker.add_item(location)
    form.add_child(arena_picker)
    _make_label("Deterministic seed", form, 15)
    seed_picker = SpinBox.new()
    seed_picker.min_value = 1
    seed_picker.max_value = 100000000
    seed_picker.step = 1
    seed_picker.value = encounter_seed
    form.add_child(seed_picker)
    config_dialog.confirmed.connect(_apply_config)

    last_dialog = AcceptDialog.new()
    last_dialog.title = "Last battle log"
    add_child(last_dialog)
    last_view = _make_text_view(last_dialog)
    debug_dialog = AcceptDialog.new()
    debug_dialog.title = "Combat Lab — input and result JSON"
    add_child(debug_dialog)
    debug_view = _make_text_view(debug_dialog)
    log_dialog = AcceptDialog.new()
    log_dialog.title = "Current battle events"
    add_child(log_dialog)
    log_view = _make_text_view(log_dialog)


func _set_party_level() -> void:
    party_level = level_picker.get_selected_id()
    _update_title()


func _set_fourth_class(index: int) -> void:
    fourth_class = "hunter" if index == 1 else "thief"
    _update_title()


func _show_config() -> void:
    config_dialog.popup_centered(_dialog_size(Vector2i(520, 490)))


func _apply_config() -> void:
    var kinds := ["goblin_melee", "goblin_archer", "goblin_vanguard", "wolf", "midden_grub"]
    var arenas := ["camp", "stone", "woodland", "refuse"]
    enemy_kind = kinds[enemy_picker.get_selected()]
    arena_id = arenas[arena_picker.get_selected()]
    enemy_count = int(count_picker.value)
    encounter_seed = int(seed_picker.value)
    _update_title()


func _current_setup() -> Dictionary:
    return SetupBuilder.build_setup(party_level, fourth_class, enemy_kind, enemy_count,
        arena_id, encounter_seed)


func _update_title() -> void:
    if title_status == null or party_roster == null:
        return
    var setup: Dictionary = _current_setup()
    if setup.is_empty():
        title_status.text = "Setup invalid; check the selected encounter."
        return
    var lines: PackedStringArray = ["PARTY — LEVEL %d" % party_level]
    for hero in setup["party"]["characters"]:
        var casting: Variant = hero.get("spellcasting")
        var spells: Array[String] = []
        if casting is Dictionary:
            for spell in casting.get("cantrips", []):
                spells.append(str(spell).replace("_", " ").capitalize())
            for spell in casting.get("prepared_spells", []):
                spells.append(str(spell).replace("_", " ").capitalize())
        var details := " | Spells: " + ", ".join(spells) if not spells.is_empty() else ""
        lines.append("• %s — %s, %d HP%s" % [
            hero["name"], str(hero["class_id"]).capitalize(), int(hero["max_hp"]), details])
    party_roster.text = "\n".join(lines)
    title_status.text = "Encounter: %d × %s  |  %s  |  Seed %d  |  Last battle: %s" % [
        enemy_count, enemy_kind.replace("_", " ").capitalize(), arena_id.capitalize(),
        encounter_seed, "recorded" if not last_report.is_empty() else "none"]


func _show_title() -> void:
    if title_panel == null:
        return
    title_panel.visible = true
    title_scroll.visible = true
    battle_panel.visible = false
    battle_scroll.visible = false
    _update_title()


func _start_battle() -> void:
    var setup: Dictionary = _current_setup()
    if setup.is_empty():
        title_status.text = "Could not construct the requested encounter."
        return
    var instance := CombatEngine.new()
    if not instance.start_from_setup(setup, true):
        title_status.text = "CombatEngine rejected the setup. Inspect Debug Input."
        return
    last_setup = setup.duplicate(true)
    engine = instance
    board.engine = engine
    recorded = false
    heard_events = 0
    picker_actor = ""
    action_mode = ""
    deployment_actor = ""
    title_panel.visible = false
    title_scroll.visible = false
    battle_panel.visible = true
    battle_scroll.visible = true
    event_log.text = ""
    _refresh()


func _set_formation(value: String) -> void:
    if engine != null and engine.deployment_active:
        engine.set_formation(value)
        deployment_actor = ""
        _refresh()


func _begin_battle() -> void:
    if engine == null or not engine.deployment_active:
        return
    if engine.begin_battle():
        deployment_actor = ""
        _run_ai()
    _refresh()


func _select_mode(mode: String) -> void:
    if engine == null or not engine.current_is_party() or not engine.pending_reaction.is_empty():
        return
    action_mode = mode
    _refresh()


func _on_weapon_change(_index: int) -> void:
    action_mode = "attack"
    _refresh()


func _on_spell_change(_index: int) -> void:
    action_mode = "spell"
    _refresh()


func _selected_weapon() -> String:
    var index: int = attack_picker.get_selected()
    return weapon_ids[index] if index >= 0 and index < weapon_ids.size() else ""


func _selected_spell() -> String:
    var index: int = spell_picker.get_selected()
    return spell_ids[index] if index >= 0 and index < spell_ids.size() else ""


func _on_cell_clicked(cell: Vector2i) -> void:
    if engine == null or engine.finished:
        return
    if engine.deployment_active:
        var actor_id: String = engine.actor_at(cell)
        if not actor_id.is_empty() and engine.actors[actor_id]["team"] == "party":
            deployment_actor = actor_id
        elif not deployment_actor.is_empty():
            engine.place_character(deployment_actor, cell)
        _refresh()
        return
    if not engine.current_is_party() or not engine.pending_reaction.is_empty():
        return
    var target_id: String = engine.target_at(cell)
    if action_mode == "move" and target_id.is_empty():
        engine.move_to(cell)
    elif action_mode == "attack" and not target_id.is_empty():
        engine.attack(target_id, _selected_weapon())
    elif action_mode == "spell" and not target_id.is_empty():
        engine.cast_spell(_selected_spell(), target_id)
    _run_ai()
    _refresh()


func _cast_self() -> void:
    if engine != null and engine.current_is_party():
        engine.cast_spell(_selected_spell(), engine.current_id())
        _run_ai()
    _refresh()


func _use_second_wind() -> void:
    if engine != null:
        engine.use_second_wind()
    _refresh()


func _use_dash() -> void:
    if engine != null and engine.use_dash():
        action_mode = "move"
    _refresh()


func _use_dodge() -> void:
    if engine != null:
        engine.use_dodge()
    _refresh()


func _use_disengage() -> void:
    if engine != null and engine.use_disengage():
        action_mode = "move"
    _refresh()


func _end_turn() -> void:
    if engine != null and engine.current_is_party():
        engine.end_turn()
        _run_ai()
    _refresh()


func _resolve_reaction(accept: bool) -> void:
    if engine != null:
        engine.resolve_reaction(accept)
        _run_ai()
    _refresh()


func _run_ai() -> void:
    if engine == null or engine.deployment_active:
        return
    var safety := 50
    while not engine.finished and not engine.current_is_party() and engine.pending_reaction.is_empty() and safety > 0:
        engine.take_ai_turn()
        safety -= 1


func _rebuild_pickers() -> void:
    if engine == null or engine.finished or engine.deployment_active:
        return
    var actor_id: String = engine.current_id()
    if actor_id == picker_actor:
        return
    picker_actor = actor_id
    weapon_ids.clear()
    spell_ids.clear()
    attack_picker.clear()
    spell_picker.clear()
    if not engine.current_is_party():
        return
    for attack in engine.current_actor().get("attacks", []):
        var kind: String = str(attack.get("kind", ""))
        if kind in ["melee_weapon", "ranged_weapon"]:
            weapon_ids.append(str(attack["id"]))
            attack_picker.add_item(str(attack["id"]).replace("_", " ").capitalize())
    for spell in engine.get_current_spells():
        spell_ids.append(spell)
        spell_picker.add_item(spell.replace("_", " ").capitalize())
    if not weapon_ids.is_empty():
        attack_picker.select(0)
    if not spell_ids.is_empty():
        spell_picker.select(0)


func _play_events() -> void:
    if engine == null:
        return
    var lines: PackedStringArray = []
    var sound_ids: Array[String] = []
    for i in range(heard_events, engine.events.size()):
        var event: Dictionary = engine.events[i]
        var line: String = str(event.get("text", ""))
        if not line.is_empty():
            lines.append(line)
        var sound: String = str(event.get("sound", ""))
        if not sound.is_empty() and not sound_ids.has(sound) and sound_ids.size() < 3:
            sound_ids.append(sound)
    if not lines.is_empty():
        event_log.text += ("\n" if not event_log.text.is_empty() else "") + "\n".join(lines)
    for sound in sound_ids:
        if sfx_players.has(sound):
            var player: AudioStreamPlayer = sfx_players[sound]
            if player.stream != null:
                player.play()
    heard_events = engine.events.size()


func _refresh() -> void:
    if engine == null:
        return
    board.action_mode = action_mode if not engine.deployment_active else ""
    board.selected_deployment_actor = deployment_actor
    board.selected_weapon = _selected_weapon()
    board.selected_spell = _selected_spell()
    board.queue_redraw()
    formation_panel.visible = engine.deployment_active
    actions_panel.visible = not engine.deployment_active
    var pending: bool = not engine.pending_reaction.is_empty()
    reaction_panel.visible = pending and not engine.deployment_active
    if pending:
        var reaction: Dictionary = engine.pending_reaction
        reaction_text.text = "%s: %s?" % [
            str(engine.actors[reaction["reactor"]]["name"]),
            "Cast Shield" if reaction["kind"] == "shield" else "Opportunity Attack"]
    _rebuild_pickers()
    if engine.deployment_active:
        battle_status.text = "DEPLOY PARTY — choose formation or click hero + blue tile"
    elif engine.finished:
        battle_status.text = "BATTLE COMPLETE — " + engine.victor.to_upper()
    else:
        battle_status.text = "ROUND %d — %s" % [engine.round_number, engine.current_actor().get("name", "")]
    var lines: PackedStringArray = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        var a: Dictionary = engine.actors[id]
        lines.append("%s: %d/%d HP (%s)" % [a["name"], a["hp"], a["max_hp"], a["combat_state"]])
    if not engine.deployment_active and not engine.finished:
        var current: Dictionary = engine.current_actor()
        lines.append("\nActive: %s  |  Action: %s  |  Bonus: %s" % [
            current.get("name", ""), "used" if engine.action_used else "ready",
            "used" if engine.bonus_action_used else "ready"])
    party_status.text = "\n".join(lines)
    var can_act: bool = engine.current_is_party() and not pending and not engine.finished
    move_button.disabled = not can_act or not engine.can_move_current()
    attack_button.disabled = not can_act or engine.action_used
    spell_button.disabled = not can_act or not engine.can_cast_any_current_spell()
    dash_button.disabled = not can_act or not engine.can_dash()
    dodge_button.disabled = not can_act or not engine.can_dodge()
    disengage_button.disabled = not can_act or not engine.can_disengage()
    wind_button.disabled = not can_act or not engine.can_use_second_wind()
    end_turn_button.disabled = not can_act
    attack_picker.disabled = not can_act or engine.action_used or weapon_ids.is_empty()
    spell_picker.disabled = not can_act or spell_ids.is_empty()
    var selected_spell: Dictionary = Level1Spells.get_definition(_selected_spell())
    self_button.disabled = not can_act or selected_spell.get("target", "") != "self" or (
        not engine.can_cast_spell(_selected_spell(), engine.current_id()))
    _play_events()
    if engine.finished and not recorded:
        _record_result()


func _record_result() -> void:
    if engine == null or not engine.finished or recorded:
        return
    recorded = true
    var combatants: Array[Dictionary] = []
    for id in engine.actors.keys():
        var actor: Dictionary = engine.actors[id]
        var cell: Vector2i = actor["position"]
        combatants.append({"id": str(id), "name": str(actor.get("name", id)),
            "team": str(actor.get("team", "")), "class_id": str(actor.get("class_id", "")),
            "hp": int(actor.get("hp", 0)), "max_hp": int(actor.get("max_hp", 0)),
            "state": str(actor.get("combat_state", "unknown")), "position": [cell.x, cell.y],
            "spell_slots_remaining": int(actor.get("spell_slots_remaining", 0)),
            "second_wind_remaining": int(actor.get("second_wind_remaining", 0)),
            "equipment": actor.get("equipment", []).duplicate(true),
            "inventory": actor.get("inventory", []).duplicate(true),
            "conditions": actor.get("conditions", []).duplicate(true)})
    last_report = {
        "schema_version": 1, "setup": last_setup.duplicate(true),
        "result": {"outcome": engine.victor, "rounds": engine.round_number,
            "combatants": combatants, "events": engine.events.duplicate(true),
            "xp": 0, "gold": 0, "loot": [], "reward_policy": "sandbox_no_rewards"}
    }
    var file := FileAccess.open(LAST_REPORT_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(last_report, "  "))
        file.close()


func _load_last_report() -> void:
    if not FileAccess.file_exists(LAST_REPORT_PATH):
        return
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAST_REPORT_PATH))
    if value is Dictionary and int(value.get("schema_version", 0)) == 1:
        last_report = value


func _show_debug() -> void:
    var request: Dictionary = last_setup if not last_setup.is_empty() else _current_setup()
    debug_view.text = "COMBAT INPUT / SETUP\n" + JSON.stringify(request, "  ")
    debug_view.text += "\n\nLAST COMPLETED RESULT\n" + (
        JSON.stringify(last_report.get("result", {}), "  ") if not last_report.is_empty() else "No completed battle yet.")
    debug_dialog.popup_centered(_dialog_size(Vector2i(840, 520)))


func _show_last_battle() -> void:
    if last_report.is_empty():
        last_view.text = "No completed battle is recorded. Finish an encounter to create a result."
    else:
        var result: Dictionary = last_report.get("result", {})
        var lines: PackedStringArray = [
            "LAST COMPLETED BATTLE",
            "Outcome: %s | Rounds: %d" % [result.get("outcome", "unknown"), result.get("rounds", 0)],
            "Rewards: none (test sandbox)\n",
            "COMBATANTS"]
        for a in result.get("combatants", []):
            lines.append("%s [%s] — %d HP, %s" % [a.get("name", ""), a.get("team", ""),
                int(a.get("hp", 0)), a.get("state", "")])
        lines.append("\nEVENTS")
        for event in result.get("events", []):
            var line: String = str(event.get("text", ""))
            if not line.is_empty():
                lines.append(line)
        last_view.text = "\n".join(lines)
    last_dialog.popup_centered(_dialog_size(Vector2i(840, 520)))

# Layout-only logic; does not modify encounter state or combat actions.
func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_node_ready():
        _apply_responsive_layout(size)


func _apply_responsive_layout(view_size: Vector2) -> void:
    if board == null or sidebar == null:
        return
    var compact: bool = view_size.x < 1320
    sidebar.visible = not compact
    var sidebar_width := 400 if not compact else 0
    var width_space: float = maxf(460.0, view_size.x - float(80 + sidebar_width))
    var height_space: float = maxf(400.0, view_size.y - 280.0)
    var cell: int = floori(minf(68.0, minf(width_space / 12.0, height_space / 10.0)))
    board.set_display_cell_size(cell)


func _dialog_size(preferred: Vector2i) -> Vector2i:
    var view: Vector2 = get_viewport_rect().size
    return Vector2i(mini(preferred.x, maxi(320, int(view.x) - 32)),
        mini(preferred.y, maxi(240, int(view.y) - 32)))


func _show_live_log() -> void:
    log_view.text = event_log.text
    log_dialog.popup_centered(_dialog_size(Vector2i(840, 520)))
