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
var main_grid: GridContainer
var sidebar_panel: PanelContainer
var bottom_action_panel: PanelContainer
var bottom_action_layout: VBoxContainer
var tabs: TabContainer
var actions_tab: VBoxContainer
var party_tab: VBoxContainer
var details_tab: VBoxContainer
var log_tab: VBoxContainer
var selection_details: RichTextLabel
var sidebar_summary: Label
var action_hint: Label
var debug_action_button: Button
var selected_cell := Vector2i(-1, -1)
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
var weapon_strip: HBoxContainer
var spell_scroll: ScrollContainer
var spell_strip: HBoxContainer
var weapon_cards: Dictionary = {}
var spell_cards: Dictionary = {}
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
var arena_id := "wide"
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
    item.custom_minimum_size = Vector2(min_width, 48)
    item.pressed.connect(callback)
    parent.add_child(item)
    _set_button_icon(item, content.to_snake_case())
    return item


func _set_button_icon(item: Button, icon_name: String) -> void:
    var resource: String = "res://assets/ui/icons/%s.svg" % icon_name
    if ResourceLoader.exists(resource):
        item.icon = load(resource) as Texture2D
        item.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


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
    level_picker.custom_minimum_size = Vector2(100, 48)
    for level in range(1, 6):
        level_picker.add_item(str(level), level)
    level_picker.select(0)
    level_row.add_child(level_picker)
    _make_button("Set Party Level", level_row, _set_party_level, 175)
    _make_label("Fourth party slot", level_row, 18)
    fourth_picker = OptionButton.new()
    fourth_picker.add_item("Pip — Thief")
    fourth_picker.add_item("Rowan — Hunter (test fixture)")
    fourth_picker.custom_minimum_size = Vector2(255, 48)
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
    _make_button("Retry Battle", heading, _start_battle, 145)
    _make_button("Return to Title", heading, _show_title, 175)
    _make_button("Zoom +", heading, _zoom_in, 90)
    _make_button("Zoom -", heading, _zoom_out, 90)
    _make_button("Reset View", heading, _reset_view, 125)
    main_grid = GridContainer.new()
    main_grid.columns = 2
    main_grid.add_theme_constant_override("h_separation", 14)
    main_grid.add_theme_constant_override("v_separation", 14)
    main_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    battle_panel.add_child(main_grid)

    var board_panel := PanelContainer.new()
    board_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    main_grid.add_child(board_panel)
    board = CombatBoard.new()
    board.cell_clicked.connect(_on_cell_clicked)
    board_panel.add_child(board)

    # Landscape: this is a permanent right-hand panel.
    # Portrait: the same tabbed panel is the second row under the map.
    sidebar_panel = PanelContainer.new()
    sidebar_panel.custom_minimum_size = Vector2(330, 0)
    sidebar_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sidebar_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var side_style := StyleBoxFlat.new()
    side_style.bg_color = Color("#141c28")
    side_style.border_color = Color("#596578")
    side_style.set_border_width_all(1)
    side_style.set_content_margin_all(10)
    sidebar_panel.add_theme_stylebox_override("panel", side_style)
    main_grid.add_child(sidebar_panel)
    sidebar = VBoxContainer.new()
    sidebar.add_theme_constant_override("separation", 8)
    sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sidebar_panel.add_child(sidebar)
    _make_label("BATTLE CONSOLE", sidebar, 18)
    sidebar_summary = _make_label("Waiting for deployment", sidebar, 14)
    sidebar_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    tabs = TabContainer.new()
    tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    tabs.custom_minimum_size = Vector2(0, 420)
    sidebar.add_child(tabs)

    actions_tab = VBoxContainer.new()
    actions_tab.name = "Debug"
    actions_tab.add_theme_constant_override("separation", 8)
    tabs.add_child(actions_tab)
    _make_label("DEVELOPER TOOLS", actions_tab, 18)
    var debug_note := _make_label("Combat inputs, results and diagnostics. Character actions are in the bottom bar.", actions_tab, 14)
    debug_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    party_tab = VBoxContainer.new()
    party_tab.name = "Party"
    party_tab.add_theme_constant_override("separation", 8)
    tabs.add_child(party_tab)
    details_tab = VBoxContainer.new()
    details_tab.name = "Details"
    details_tab.add_theme_constant_override("separation", 8)
    tabs.add_child(details_tab)
    log_tab = VBoxContainer.new()
    log_tab.name = "Log"
    log_tab.add_theme_constant_override("separation", 8)
    tabs.add_child(log_tab)

    _make_label("PARTY STATUS", party_tab, 18)
    party_status = RichTextLabel.new()
    party_status.size_flags_vertical = Control.SIZE_EXPAND_FILL
    party_status.custom_minimum_size = Vector2(0, 160)
    party_tab.add_child(party_status)

    _make_label("SELECTED TILE OR CREATURE", details_tab, 18)
    selection_details = RichTextLabel.new()
    selection_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
    selection_details.custom_minimum_size = Vector2(0, 160)
    selection_details.text = "Tap a creature or battlefield tile to inspect it."
    details_tab.add_child(selection_details)

    _make_label("COMBAT EVENTS", log_tab, 18)
    event_log = RichTextLabel.new()
    event_log.scroll_following = true
    event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    event_log.custom_minimum_size = Vector2(0, 160)
    log_tab.add_child(event_log)
    _make_button("Open Full Battle Log", log_tab, _show_live_log, 200)

    # Player commands belong below the battlefield; the right-hand tabs remain
    # informational and contain developer-only controls.
    bottom_action_panel = PanelContainer.new()
    bottom_action_panel.name = "BottomActionBar"
    bottom_action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var action_style := StyleBoxFlat.new()
    action_style.bg_color = Color("#1b2836")
    action_style.border_color = Color("#657185")
    action_style.set_border_width_all(1)
    action_style.set_content_margin_all(8)
    bottom_action_panel.add_theme_stylebox_override("panel", action_style)
    # Sibling of the scrollable battle region: commands stay docked to the viewport
    # even when a portrait player scrolls the map and information console.
    content.add_child(bottom_action_panel)
    bottom_action_layout = VBoxContainer.new()
    bottom_action_layout.add_theme_constant_override("separation", 6)
    bottom_action_panel.add_child(bottom_action_layout)

    formation_panel = HFlowContainer.new()
    formation_panel.add_theme_constant_override("separation", 8)
    bottom_action_layout.add_child(formation_panel)
    _make_label("Deployment:", formation_panel, 15)
    for formation in ["line", "square", "diamond"]:
        _make_button(formation.capitalize(), formation_panel, _set_formation.bind(formation), 100)
    begin_button = _make_button("Begin Battle", formation_panel, _begin_battle, 150)

    actions_panel = VBoxContainer.new()
    actions_panel.add_theme_constant_override("separation", 5)
    bottom_action_layout.add_child(actions_panel)
    var command_row := HBoxContainer.new()
    command_row.add_theme_constant_override("separation", 8)
    command_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions_panel.add_child(command_row)
    var player_commands := HFlowContainer.new()
    player_commands.add_theme_constant_override("h_separation", 6)
    player_commands.add_theme_constant_override("v_separation", 5)
    player_commands.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    command_row.add_child(player_commands)
    move_button = _make_button("Move", player_commands, _select_mode.bind("move"), 78)
    attack_button = _make_button("Attack", player_commands, _select_mode.bind("attack"), 90)
    spell_button = _make_button("Spell", player_commands, _select_mode.bind("spell"), 85)
    for choice in [move_button, attack_button, spell_button]:
        choice.toggle_mode = true
    wind_button = _make_button("Second Wind", player_commands, _use_second_wind, 120)
    dash_button = _make_button("Dash", player_commands, _use_dash, 76)
    dodge_button = _make_button("Dodge", player_commands, _use_dodge, 85)
    disengage_button = _make_button("Disengage", player_commands, _use_disengage, 118)
    end_turn_button = _make_button("END TURN", command_row, _end_turn, 155)
    end_turn_button.custom_minimum_size.y = 98
    _set_button_icon(end_turn_button, "end_turn")
    var end_style := StyleBoxFlat.new()
    end_style.bg_color = Color("#7b2926")
    end_style.border_color = Color("#e6b16c")
    end_style.set_border_width_all(3)
    end_style.set_corner_radius_all(8)
    end_style.set_content_margin_all(8)
    end_turn_button.add_theme_stylebox_override("normal", end_style)
    var end_hot := end_style.duplicate() as StyleBoxFlat
    end_hot.bg_color = Color("#a63b30")
    end_turn_button.add_theme_stylebox_override("hover", end_hot)
    end_turn_button.add_theme_font_size_override("font_size", 18)
    var select_row := HFlowContainer.new()
    select_row.add_theme_constant_override("h_separation", 8)
    select_row.add_theme_constant_override("v_separation", 5)
    actions_panel.add_child(select_row)
    _make_label("WEAPONS", select_row, 14)
    weapon_strip = HBoxContainer.new()
    weapon_strip.add_theme_constant_override("separation", 5)
    select_row.add_child(weapon_strip)
    attack_picker = OptionButton.new()
    attack_picker.visible = false
    select_row.add_child(attack_picker)
    _make_label("SPELLS", select_row, 14)
    _make_button("◀", select_row, _scroll_spells.bind(-1), 46)
    spell_scroll = ScrollContainer.new()
    spell_scroll.custom_minimum_size = Vector2(350, 54)
    spell_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    spell_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    spell_scroll.scroll_deadzone = 8
    select_row.add_child(spell_scroll)
    spell_strip = HBoxContainer.new()
    spell_strip.add_theme_constant_override("separation", 6)
    spell_scroll.add_child(spell_strip)
    _make_button("▶", select_row, _scroll_spells.bind(1), 46)
    spell_picker = OptionButton.new()
    spell_picker.visible = false
    select_row.add_child(spell_picker)
    self_button = _make_button("Cast on Self", select_row, _cast_self, 135)
    reaction_panel = HBoxContainer.new()
    reaction_panel.add_theme_constant_override("separation", 12)
    bottom_action_layout.add_child(reaction_panel)
    reaction_text = _make_label("", reaction_panel, 16)
    reaction_accept = _make_button("React", reaction_panel, _resolve_reaction.bind(true), 100)
    reaction_decline = _make_button("Decline", reaction_panel, _resolve_reaction.bind(false), 100)
    action_hint = _make_label("Choose a command, then tap a highlighted tile.", bottom_action_layout, 14)
    action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    debug_action_button = _make_button("Debug Input / Output", actions_tab, _show_debug, 200)
    debug_action_button.tooltip_text = "View the versioned CombatSetup and last recorded CombatResult"

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
    for kind in ["goblin_melee", "goblin_archer", "goblin_vanguard", "wolf",
            "midden_grub", "skeleton", "spider", "kobold", "bandit", "mixed"]:
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
    for location in ["Forest camp", "Stone chamber", "Woodland watch", "Refuse room", "Wide forest (17 columns)"]:
        arena_picker.add_item(location)
    arena_picker.select(4)
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
    var kinds := ["goblin_melee", "goblin_archer", "goblin_vanguard", "wolf",
        "midden_grub", "skeleton", "spider", "kobold", "bandit", "mixed"]
    var arenas := ["camp", "stone", "woodland", "refuse", "wide"]
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
    bottom_action_panel.visible = false
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
    board.reset_presentation()
    recorded = false
    heard_events = 0
    picker_actor = ""
    action_mode = ""
    deployment_actor = ""
    selected_cell = Vector2i(-1, -1)
    tabs.current_tab = 1
    title_panel.visible = false
    title_scroll.visible = false
    battle_panel.visible = true
    battle_scroll.visible = true
    bottom_action_panel.visible = true
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
    selected_cell = cell
    _update_selection_details()
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
    if action_mode.is_empty():
        tabs.current_tab = 2
        _refresh()
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
        if str(event.get("kind", "")) in ["hit", "miss", "cast", "heal", "death"]:
            board.enqueue_combat_event(event)
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
        var actor_status: String = "%s: %d/%d HP • AC %d (%s)" % [
            a["name"], a["hp"], a["max_hp"], a.get("armor_class", 10), a["combat_state"]]
        var resources: PackedStringArray = []
        if a.get("spellcasting") is Dictionary:
            resources.append("slots: %d" % int(a.get("spell_slots_remaining", 0)))
        if a.get("class_id", "") == "champion":
            resources.append("Second Wind: %d" % int(a.get("second_wind_remaining", 0)))
        if not str(a.get("blessed_by", "")).is_empty():
            resources.append("Blessed")
        if bool(a.get("mage_armor_active", false)):
            resources.append("Mage Armor")
        if bool(a.get("dodging", false)):
            resources.append("Dodging")
        if not resources.is_empty():
            actor_status += "  |  " + ", ".join(resources)
        lines.append(actor_status)
    if not engine.deployment_active and not engine.finished:
        var current: Dictionary = engine.current_actor()
        lines.append("\nActive: %s  |  Action: %s  |  Bonus: %s" % [
            current.get("name", ""), "used" if engine.action_used else "ready",
            "used" if engine.bonus_action_used else "ready"])
    party_status.text = "\n".join(lines)
    if engine.deployment_active:
        sidebar_summary.text = "Deploy your party • choose a formation"
    elif engine.finished:
        sidebar_summary.text = "Finished • " + engine.victor.capitalize()
    else:
        sidebar_summary.text = "Round %d • %s" % [engine.round_number, str(engine.current_actor().get("name", ""))]
    _update_selection_details()
    var can_act: bool = engine.current_is_party() and not pending and not engine.finished
    if engine.deployment_active:
        action_hint.text = "Select a party member, then choose a highlighted starting tile."
    elif pending:
        action_hint.text = "Resolve the reaction above before continuing."
    elif engine.finished:
        action_hint.text = "Battle ended. Review Party, Details or Log; Retry to test again."
    elif action_mode == "move":
        action_hint.text = "Blue cells are reachable. Tap a blue cell to move."
    elif action_mode == "attack":
        action_hint.text = "Red cells indicate valid weapon targets. Tap a target to attack."
    elif action_mode == "spell":
        action_hint.text = "Gold cells indicate legal spell targets. Choose a spell, then tap."
    else:
        action_hint.text = "Choose Move, Attack or Spell to highlight legal destinations and targets."
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
    for choice in [move_button, attack_button, spell_button]:
        choice.set_pressed_no_signal(not choice.disabled and action_mode == choice.text.to_lower())
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
    if board == null or sidebar_panel == null:
        return
    var landscape: bool = view_size.x >= view_size.y and view_size.x >= 900.0
    main_grid.columns = 2 if landscape else 1
    sidebar.visible = true
    sidebar_panel.visible = true
    var horizontal_margin := 68.0
    var available_width: float = view_size.x - horizontal_margin
    var sidebar_width := 0
    if landscape:
        sidebar_width = clampi(roundi(view_size.x * 0.28), 310, 380)
        available_width -= float(sidebar_width + 18)
    sidebar_panel.custom_minimum_size.x = float(sidebar_width) if landscape else 0.0
    # Reserve vertical space for the always-visible player action bar.
    var available_height: float = view_size.y - (300.0 if landscape else 250.0)
    var cell: int = floori(minf(68.0, minf(available_width / 12.0, available_height / 10.0)))
    if not landscape:
        cell = floori(minf(68.0, available_width / 12.0))
    board.set_display_cell_size(cell)


func _update_selection_details() -> void:
    if selection_details == null or engine == null:
        return
    var tile: Vector2i = selected_cell
    if tile.x < 0 or tile.y < 0:
        if engine.deployment_active:
            selection_details.text = "Select a party member, then tap a legal starting tile."
        elif engine.finished:
            selection_details.text = "Battle complete. View the Party or Log tab for results."
        else:
            selection_details.text = "Tap a creature to inspect its statistics, or a tile to inspect terrain."
        return
    var parts: PackedStringArray = ["CELL (%d, %d)" % [tile.x, tile.y]]
    var actor_id: String = engine.actor_at(tile)
    if not actor_id.is_empty() and engine.actors.has(actor_id):
        var creature: Dictionary = engine.actors[actor_id]
        parts.append("%s • %s" % [str(creature.get("name", actor_id)), str(creature.get("team", "")).capitalize()])
        parts.append("HP %d / %d   AC %d" % [
            int(creature.get("hp", 0)), int(creature.get("max_hp", 0)), int(creature.get("armor_class", 0))])
        parts.append("Status: " + str(creature.get("combat_state", "unknown")))
        parts.append("Role: " + str(creature.get("role", creature.get("class_id", ""))))
        var attacks: Array = creature.get("attacks", [])
        if not attacks.is_empty():
            parts.append("Attacks:")
            for attack in attacks:
                parts.append("  %s • %s" % [str(attack.get("id", "unknown")).replace("_", " ").capitalize(),
                    str(attack.get("damage", ""))])
    else:
        parts.append("Empty tile")
    if tile in engine.walls:
        parts.append("Wall • impassable")
    elif tile in engine.difficult_terrain:
        parts.append("Difficult terrain")
    for obstacle in engine.obstacles:
        var corner: Vector2i = obstacle["position"]
        var extent: Vector2i = obstacle["size"]
        if tile.x >= corner.x and tile.x < corner.x + extent.x and tile.y >= corner.y and tile.y < corner.y + extent.y:
            parts.append("Obstacle: " + str(obstacle.get("kind", "")))
            parts.append("Cover: " + str(obstacle.get("cover", "none")))
            break
    for hazard in engine.hazards:
        if hazard["position"] == tile:
            parts.append("Hazard: " + str(hazard.get("kind", "")))
    selection_details.text = "\n".join(parts)


func _dialog_size(preferred: Vector2i) -> Vector2i:
    var view: Vector2 = get_viewport_rect().size
    return Vector2i(mini(preferred.x, maxi(320, int(view.x) - 32)),
        mini(preferred.y, maxi(240, int(view.y) - 32)))


func _show_live_log() -> void:
    log_view.text = event_log.text
    log_dialog.popup_centered(_dialog_size(Vector2i(840, 520)))
