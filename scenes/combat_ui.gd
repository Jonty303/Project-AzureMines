extends Control
## First-pass mock-up-inspired UI: tactical map + right log + bottom action bar.
## Only clickable, implemented level-1 commands are shown.

const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatBoard = preload("res://combat/combat_board.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")
const CombatActionButton = preload("res://scenes/combat_action_button.gd")
const OpeningSession = preload("res://adventure/opening_session.gd")
const OverlandMap = preload("res://adventure/overland_map.gd")
const SOUND_NAMES := ["footstep", "melee_hit", "ranged", "magic", "heal", "miss", "damage", "death"]
const BG := Color("#0e141b")
const PANEL := Color("#121b23")
const BORDER := Color("#4a5662")
const CREAM := Color("#e8ddc9")
const GOLD := Color("#d7aa58")
const BLUE := Color("#399bd5")

var engine: CombatEngine
var adventure: OpeningSession
var board: CombatBoard
var story_image: TextureRect
var overland_map: Control
var story_choices_scroll: ScrollContainer
var story_choices_box: VBoxContainer
var story_feedback := ""
var show_map := false
var show_journal := false
var map_toggle_button: Button
var journal_button: Button
var save_game_button: Button
var load_game_button: Button
var story_panel: VBoxContainer
var story_eyebrow: Label
var story_title: Label
var story_paragraphs: RichTextLabel
var story_rewards: Label
var story_continue_button: Button
var survivor_panel: VBoxContainer
var survivor_label: Label
var survivor_first_aid_button: Button
var survivor_heal_button: Button
var log_heading: Label
var status_label: Label
var debug_skip_battle_button: Button
var party_label: Label
var active_label: Label
var combat_log: RichTextLabel
var end_turn_button: Button
var self_cast_button: Button
var second_wind_button: Button
var dash_button: Button
var dodge_button: Button
var disengage_button: Button
var reaction_row: HBoxContainer
var reaction_label: Label
var reaction_accept: Button
var reaction_decline: Button
var move_button: Button
var attack_button: Button
var spells_button: Button
var weapon_picker: OptionButton
var subdue_button: Button
var subdue_mode := false
var ability_picker: OptionButton
var action_ids: Array[String] = []
var weapon_ids: Array[String] = []
var current_picker_actor := ""
var action_mode := ""
var deployment_selected_id := ""
var setup_panel: VBoxContainer
var combat_action_row: HBoxContainer
var combat_selector_row: HBoxContainer
var begin_battle_button: Button
var deployment_instructions: Label
var formation_buttons: Dictionary = {}
var sfx_players: Dictionary = {}
var _heard_event_count := 0


func _ready() -> void:
    _build_audio()
    _build_ui()
    _restart()


func _build_audio() -> void:
    for sound_id in SOUND_NAMES:
        var player := AudioStreamPlayer.new()
        var path := "res://assets/sfx/%s.wav" % sound_id
        if ResourceLoader.exists(path):
            player.stream = load(path) as AudioStream
        player.volume_db = -12.0
        player.bus = "Master"
        add_child(player)
        sfx_players[sound_id] = player


func _play_new_events() -> void:
    if engine == null:
        return
    var played: Array[String] = []
    for i in range(_heard_event_count, engine.events.size()):
        var evt: Dictionary = engine.events[i]
        var sound_id: String = str(evt.get("sound", ""))
        if sound_id.is_empty() or played.has(sound_id) or played.size() >= 3:
            continue
        if sfx_players.has(sound_id):
            var player: AudioStreamPlayer = sfx_players[sound_id]
            if player.stream != null:
                player.play()
                played.append(sound_id)
    _heard_event_count = engine.events.size()


func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_color = BORDER
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style


func _button_style(selected: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#20313e") if selected else Color("#1c2530")
    style.border_color = BLUE if selected else BORDER
    style.set_border_width_all(2)
    style.set_corner_radius_all(4)
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style


func _make_button(title: String, callback: Callable, parent: Node, minimum_width: int = 86) -> Button:
    var button := CombatActionButton.new()
    button.text = title
    button.custom_minimum_size = Vector2(minimum_width, 48)
    button.add_theme_stylebox_override("normal", _button_style())
    button.add_theme_color_override("font_color", CREAM)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button


func _make_label(title: String, parent: Node, font_size: int = 15) -> Label:
    var label := Label.new()
    label.text = title
    label.add_theme_color_override("font_color", CREAM)
    label.add_theme_font_size_override("font_size", font_size)
    parent.add_child(label)
    return label


func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = BG
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 12)
    add_child(margin)

    var screen := VBoxContainer.new()
    screen.add_theme_constant_override("separation", 8)
    margin.add_child(screen)

    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation", 18)
    screen.add_child(heading)
    _make_label("PROJECT AZURE MINES", heading, 24)
    status_label = _make_label("Loading encounter...", heading, 16)
    # Never expose encounter bypasses in release builds.
    if OS.has_feature("debug"):
        debug_skip_battle_button = _make_button(
            "DEBUG: Skip Goblins (Spare Hesk)", _on_debug_skip_battle, heading, 225
        )
        debug_skip_battle_button.tooltip_text = (
            "Test narrative exploration without combat. Hesk survives unconscious at 1 HP."
        )

    var battlefield_and_log := HBoxContainer.new()
    battlefield_and_log.add_theme_constant_override("separation", 12)
    battlefield_and_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    screen.add_child(battlefield_and_log)

    var map_frame := PanelContainer.new()
    map_frame.add_theme_stylebox_override("panel", _panel_style())
    battlefield_and_log.add_child(map_frame)
    board = CombatBoard.new()
    board.cell_clicked.connect(_on_cell_clicked)
    map_frame.add_child(board)
    story_image = TextureRect.new()
    story_image.name = "StoryIllustration"
    story_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    story_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    story_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    story_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    story_image.visible = false
    board.add_child(story_image)
    overland_map = OverlandMap.new()
    overland_map.name = "DiscoveryMap"
    overland_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overland_map.visible = false
    board.add_child(overland_map)

    var right := PanelContainer.new()
    right.custom_minimum_size = Vector2(360, 0)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_stylebox_override("panel", _panel_style())
    battlefield_and_log.add_child(right)
    var right_content := VBoxContainer.new()
    right_content.add_theme_constant_override("separation", 8)
    right.add_child(right_content)
    story_panel = VBoxContainer.new()
    story_panel.add_theme_constant_override("separation", 14)
    story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right_content.add_child(story_panel)
    story_eyebrow = _make_label("", story_panel, 13)
    story_title = _make_label("", story_panel, 22)
    story_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story_paragraphs = RichTextLabel.new()
    story_paragraphs.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story_paragraphs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story_paragraphs.add_theme_color_override("default_color", CREAM)
    story_panel.add_child(story_paragraphs)
    story_rewards = _make_label("", story_panel, 16)
    story_rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    survivor_panel = VBoxContainer.new()
    survivor_panel.add_theme_constant_override("separation", 6)
    story_panel.add_child(survivor_panel)
    survivor_label = _make_label("", survivor_panel, 13)
    survivor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var aid_row := HBoxContainer.new()
    aid_row.add_theme_constant_override("separation", 8)
    survivor_panel.add_child(aid_row)
    survivor_first_aid_button = _make_button("First Aid", _on_survivor_first_aid, aid_row, 120)
    survivor_heal_button = _make_button("Cure Wounds", _on_survivor_heal, aid_row, 130)
    story_continue_button = _make_button("Continue", _on_story_continue, story_panel, 235)
    story_continue_button.add_theme_stylebox_override("normal", _button_style(true))
    story_choices_scroll = ScrollContainer.new()
    story_choices_scroll.name = "NarrativeChoices"
    story_choices_scroll.custom_minimum_size = Vector2(0, 164)
    story_choices_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story_panel.add_child(story_choices_scroll)
    story_choices_box = VBoxContainer.new()
    story_choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    story_choices_box.add_theme_constant_override("separation", 5)
    story_choices_scroll.add_child(story_choices_box)
    var story_tools := HBoxContainer.new()
    story_tools.add_theme_constant_override("separation", 4)
    story_panel.add_child(story_tools)
    map_toggle_button = _make_button("Map", _on_map_toggle, story_tools, 66)
    journal_button = _make_button("Journal", _on_journal_toggle, story_tools, 78)
    save_game_button = _make_button("Save", _on_save_game, story_tools, 66)
    load_game_button = _make_button("Load", _on_load_game, story_tools, 66)

    log_heading = _make_label("COMBAT LOG", right_content, 19)
    combat_log = RichTextLabel.new()
    combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    combat_log.scroll_following = true
    combat_log.add_theme_color_override("default_color", CREAM)
    right_content.add_child(combat_log)

    var bottom := HBoxContainer.new()
    bottom.add_theme_constant_override("separation", 8)
    screen.add_child(bottom)

    var party_panel := PanelContainer.new()
    party_panel.custom_minimum_size = Vector2(266, 0)
    party_panel.add_theme_stylebox_override("panel", _panel_style())
    bottom.add_child(party_panel)
    var details := VBoxContainer.new()
    party_panel.add_child(details)
    _make_label("ACTIVE CHARACTER / PARTY", details, 16)
    active_label = _make_label("", details, 14)
    party_label = _make_label("", details, 13)

    var bar_panel := PanelContainer.new()
    bar_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar_panel.add_theme_stylebox_override("panel", _panel_style())
    bottom.add_child(bar_panel)
    var bar_content := VBoxContainer.new()
    bar_content.add_theme_constant_override("separation", 7)
    bar_panel.add_child(bar_content)
    _make_label("ACTIONS / PARTY DEPLOYMENT", bar_content, 16)

    setup_panel = VBoxContainer.new()
    setup_panel.add_theme_constant_override("separation", 6)
    bar_content.add_child(setup_panel)
    deployment_instructions = _make_label(
        "Formation first, then select a hero and click an available blue square.", setup_panel, 13
    )
    deployment_instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var setup_buttons := HBoxContainer.new()
    setup_buttons.add_theme_constant_override("separation", 8)
    setup_panel.add_child(setup_buttons)
    for formation_id in ["line", "square", "diamond"]:
        var button: Button = _make_button(
            formation_id.capitalize(), _on_formation.bind(formation_id), setup_buttons, 98
        )
        button.tooltip_text = "Arrange the whole party in a %s formation" % formation_id
        formation_buttons[formation_id] = button
    begin_battle_button = _make_button("Begin Battle", _on_begin_battle, setup_buttons, 145)
    begin_battle_button.add_theme_stylebox_override("normal", _button_style(true))

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 5)
    bar_content.add_child(actions)
    combat_action_row = actions
    move_button = _make_button("Move", func() -> void: _set_mode("move"), actions, 64)
    attack_button = _make_button("Attack", func() -> void: _set_mode("attack"), actions, 72)
    spells_button = _make_button("Spells", func() -> void: _set_mode("spell"), actions, 72)
    second_wind_button = _make_button("Second Wind", _on_second_wind, actions, 105)
    dash_button = _make_button("Dash", _on_dash, actions, 64)
    dodge_button = _make_button("Dodge", _on_dodge, actions, 70)
    disengage_button = _make_button("Disengage", _on_disengage, actions, 94)
    end_turn_button = _make_button("End Turn", _on_end_turn, actions, 95)
    end_turn_button.add_theme_stylebox_override("normal", _button_style(true))

    var selectors := HBoxContainer.new()
    selectors.add_theme_constant_override("separation", 8)
    bar_content.add_child(selectors)
    combat_selector_row = selectors
    _make_label("Weapon", selectors, 13)
    weapon_picker = OptionButton.new()
    weapon_picker.custom_minimum_size = Vector2(155, 35)
    weapon_picker.item_selected.connect(_on_weapon_selected)
    selectors.add_child(weapon_picker)
    subdue_button = _make_button("Subdue: Off", _on_toggle_subdue, selectors, 103)
    subdue_button.tooltip_text = "Choose a nonlethal melee strike to knock an enemy unconscious at 1 HP."
    _make_label("Spell", selectors, 13)
    ability_picker = OptionButton.new()
    ability_picker.custom_minimum_size = Vector2(190, 35)
    ability_picker.item_selected.connect(_on_spell_selected)
    selectors.add_child(ability_picker)
    self_cast_button = _make_button("Cast on Self", _on_cast_self, selectors, 98)

    reaction_row = HBoxContainer.new()
    reaction_row.add_theme_constant_override("separation", 8)
    bar_content.add_child(reaction_row)
    reaction_label = _make_label("Reaction available", reaction_row, 13)
    reaction_accept = _make_button("React", func() -> void: _on_reaction(true), reaction_row, 90)
    reaction_decline = _make_button("Decline", func() -> void: _on_reaction(false), reaction_row, 90)
    reaction_row.visible = false


func _restart() -> void:
    if adventure == null:
        adventure = OpeningSession.new()
    if not adventure.start_journey():
        status_label.text = "ERROR: could not load the opening adventure."
        return
    engine = CombatEngine.new()
    if not engine.start(42024, true):
        status_label.text = "ERROR: combat fixtures could not load."
        end_turn_button.disabled = true
        return
    board.engine = engine
    current_picker_actor = ""
    action_mode = ""
    deployment_selected_id = ""
    subdue_mode = false
    story_feedback = ""
    show_map = false
    show_journal = false
    _heard_event_count = engine.events.size()
    _refresh()


func _on_survivor_first_aid() -> void:
    if adventure.stage != "victory" or not engine.actors.has("goblin_blade"):
        return
    var result: Dictionary = engine.stabilize_creature("goblin_blade", "brunna")
    if result.get("allowed", false):
        adventure.campaign.capture_npc_from_combat(engine.actors)
        var goblin: Dictionary = engine.actors["goblin_blade"]
        goblin["first_aid_attempted"] = true
        engine.actors["goblin_blade"] = goblin
    _refresh()


func _on_survivor_heal() -> void:
    if adventure.stage == "victory":
        engine.heal_survivor("brunna", "goblin_blade")
        adventure.campaign.capture_npc_from_combat(engine.actors)
        adventure.campaign.capture_party(engine.actors)
    _refresh()


func _on_map_toggle() -> void:
    if adventure.stage != "exploration":
        return
    show_map = not show_map
    _refresh()


func _on_journal_toggle() -> void:
    if adventure.stage != "exploration":
        return
    show_journal = not show_journal
    _refresh()


func _on_save_game() -> void:
    var ok: bool = adventure.save_game(engine.actors)
    story_feedback = "Campaign saved to slot 1." if ok else "Saving is unavailable during combat or deployment."
    _refresh()


func _on_load_game() -> void:
    if not adventure.load_game():
        story_feedback = "No valid campaign save was found in slot 1."
        _refresh()
        return
    engine = CombatEngine.new()
    engine.start(42024, true)
    engine.finished = true
    engine.victor = "party"
    engine.deployment_active = false
    adventure.campaign.restore_party(engine.actors)
    adventure.campaign.restore_named_npcs(engine.actors)
    board.engine = engine
    story_feedback = "Campaign restored from slot 1."
    show_map = false
    show_journal = false
    _refresh()


func _on_exploration_choice(choice_id: String) -> void:
    if adventure.stage != "exploration":
        return
    var result: Dictionary = adventure.choose_exploration(choice_id, engine.actors, engine)
    if bool(result.get("ok", false)) and choice_id.begins_with("hesk_"):
        adventure.campaign.capture_party(engine.actors)
    story_feedback = str(result.get("text", ""))
    overland_map.queue_redraw()
    _refresh()


func _journal_text() -> String:
    var lines: PackedStringArray = ["DISCOVERED CLUES"]
    if adventure.campaign.clues.is_empty():
        lines.append("Nothing recorded yet.")
    for clue in adventure.campaign.clues:
        lines.append("• %s (%s)" % [clue.get("text", ""), clue.get("certainty", "confirmed")])
    lines.append("\nEVENTS")
    for event in adventure.campaign.events:
        lines.append("• " + str(event.get("text", "")))
    lines.append("\nQUESTS")
    for quest_id in adventure.campaign.quests.keys():
        lines.append("• %s: %s" % [quest_id, adventure.campaign.quests[quest_id]])
    lines.append("\nPEOPLE")
    for npc_id in adventure.campaign.npc_registry.keys():
        var npc: Dictionary = adventure.campaign.npc_registry[npc_id]
        if npc_id == "hesk_roadwatch":
            lines.append("• Hesk: %s; %s; attitude %s." % [
                npc.get("state", "unknown"), npc.get("whereabouts", "unknown"),
                npc.get("attitude", "unknown")
            ])
        elif adventure.campaign.flags.get("mara_lead_given", false):
            lines.append("• Mara Venn: %s; trust %d." % [
                npc.get("attitude", "neutral"), int(npc.get("trust", 0))
            ])
    return "\n".join(lines)


func _refresh_exploration() -> void:
    var info: Dictionary = adventure.exploration_screen()
    story_panel.visible = true
    story_eyebrow.text = str(info.get("subtitle", "THE DALES"))
    story_title.text = str(info.get("title", "The Old Trade Road"))
    story_continue_button.visible = false
    story_rewards.visible = false
    survivor_panel.visible = false
    story_choices_scroll.visible = not show_journal
    map_toggle_button.visible = true
    journal_button.visible = true
    save_game_button.visible = true
    load_game_button.visible = true
    journal_button.text = "Scene" if show_journal else "Journal"
    map_toggle_button.text = "Picture" if show_map else "Map"
    var body: String = str(info.get("description", ""))
    if show_journal:
        body = _journal_text()
    elif not story_feedback.is_empty():
        body += "\n\n" + story_feedback
    story_paragraphs.text = body
    for child in story_choices_box.get_children():
        child.queue_free()
    if not show_journal:
        for choice in adventure.exploration_choices():
            var label_text: String = str(choice.get("label", "Continue"))
            var button := _make_button(label_text, _on_exploration_choice.bind(str(choice["id"])),
                story_choices_box, 0)
            button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    overland_map.campaign = adventure.campaign
    overland_map.nodes = adventure.exploration.locations
    var art_path: String = str(info.get("art", ""))
    var picture_available: bool = not art_path.is_empty() and ResourceLoader.exists(art_path)
    story_image.visible = picture_available and not show_map
    if story_image.visible:
        story_image.texture = load(art_path) as Texture2D
    overland_map.visible = show_map or not picture_available
    overland_map.queue_redraw()
    map_toggle_button.disabled = not picture_available
    setup_panel.visible = false
    combat_action_row.visible = false
    combat_selector_row.visible = false
    reaction_row.visible = false
    log_heading.visible = false
    combat_log.visible = false
    board.action_mode = ""
    board.selected_deployment_actor = ""
    board.queue_redraw()
    status_label.text = "EXPLORATION • " + str(info.get("title", "THE DALES"))
    var party_lines: PackedStringArray = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        var actor: Dictionary = engine.actors[id]
        party_lines.append("%s %d/%d HP • %d XP" % [
            actor["name"], actor["hp"], actor["max_hp"], adventure.xp_by_character[id]
        ])
    party_label.text = "\n".join(party_lines)
    active_label.text = "Pooled gold: %d gp\nLocation: %s" % [
        adventure.gold_gp, adventure.campaign.current_location
    ]


func _on_story_continue() -> void:
    match adventure.stage:
        "approach":
            adventure.begin_deployment()
        "victory":
            # Preserve the underlying aftermath stage for old saves, but do not
            # display an extra story page between victory and the wagon clearing.
            if adventure.continue_after_victory():
                adventure.enter_exploration()
        "aftermath":
            # Backward compatibility for saves created at the old interim page.
            adventure.enter_exploration()
        "defeat":
            _restart()
            return
    _refresh()


func _on_formation(formation_id: String) -> void:
    if engine.deployment_active and engine.set_formation(formation_id):
        deployment_selected_id = ""
    _refresh()


func _on_debug_skip_battle() -> void:
    # Developer-only shortcut: exercise the *normal* victory and global-state flow.
    # Hesk is the named shield-bearing raider, not the unseen goblin lord.
    if not OS.has_feature("debug") or engine == null or adventure == null:
        return
    if adventure.stage not in ["approach", "deployment", "battle"] or engine.finished:
        return
    if adventure.stage == "approach" and not adventure.begin_deployment():
        return
    if adventure.stage == "deployment":
        if not engine.begin_battle() or not adventure.begin_combat():
            return
    if adventure.stage != "battle":
        return

    for id in ["goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        var raider: Dictionary = engine.actors[id]
        raider["hp"] = 0
        raider["combat_state"] = "dead"
        engine.actors[id] = raider

    var hesk: Dictionary = engine.actors["goblin_blade"]
    if hesk.get("npc_id", "") != "hesk_roadwatch":
        push_error("Debug skip requires the authored named goblin Hesk.")
        return
    hesk["hp"] = 1
    hesk["combat_state"] = "knocked_out"
    hesk["short_rest_started"] = true
    hesk["death_successes"] = 0
    hesk["death_failures"] = 0
    engine.actors["goblin_blade"] = hesk
    engine._check_victory()
    if not engine.finished or engine.victor != "party":
        push_error("Debug skip failed to complete the encounter.")
        return

    adventure.campaign.flags["debug_wagon_battle_skipped"] = true
    adventure.campaign.record_event(
        "debug_skip_wagon", "[DEBUG] Wagon ambush bypassed; Hesk spared at 1 HP."
    )
    story_feedback = "[DEBUG] Battle skipped. Hesk was subdued alive, at 1 HP."
    _refresh()


func _on_begin_battle() -> void:
    if adventure.stage != "deployment" or not engine.begin_battle():
        return
    adventure.begin_combat()
    deployment_selected_id = ""
    action_mode = ""
    current_picker_actor = ""
    _run_enemy_turns()
    _refresh()


func _set_mode(mode: String) -> void:
    if not engine.current_is_party():
        return
    if mode == "move" and not engine.can_move_current():
        return
    if mode == "attack" and engine.action_used:
        return
    if mode == "spell" and not engine.can_cast_any_current_spell():
        return
    action_mode = mode
    _refresh()


func _on_weapon_selected(_idx: int) -> void:
    subdue_mode = false
    action_mode = "attack"
    _refresh()


func _selected_weapon_is_melee() -> bool:
    if engine == null or engine.current_id().is_empty():
        return false
    var selected_id: String = _selected_weapon()
    for weapon in engine.current_actor().get("attacks", []):
        if str(weapon.get("id", "")) == selected_id:
            return weapon.get("kind", "") == "melee_weapon"
    return false


func _on_toggle_subdue() -> void:
    if engine.current_is_party() and not engine.action_used and _selected_weapon_is_melee():
        subdue_mode = not subdue_mode
        action_mode = "attack"
    _refresh()


func _on_spell_selected(_idx: int) -> void:
    action_mode = "spell"
    _refresh()


func _selected_weapon() -> String:
    var idx: int = weapon_picker.get_selected_id()
    return weapon_ids[idx] if idx >= 0 and idx < weapon_ids.size() else ""


func _selected_spell() -> String:
    var idx: int = ability_picker.get_selected_id()
    return action_ids[idx] if idx >= 0 and idx < action_ids.size() else ""


func _on_cell_clicked(cell: Vector2i) -> void:
    if adventure.stage not in ["deployment", "battle"]:
        return
    if engine.deployment_active:
        var clicked_id: String = engine.actor_at(cell)
        if not clicked_id.is_empty() and engine.actors[clicked_id]["team"] == "party":
            deployment_selected_id = clicked_id
        elif not deployment_selected_id.is_empty():
            engine.place_character(deployment_selected_id, cell)
        _refresh()
        return
    if not engine.pending_reaction.is_empty() or not engine.current_is_party():
        return
    var target_id: String = engine.target_at(cell)
    if target_id.is_empty():
        if action_mode == "move":
            engine.move_to(cell)
    elif action_mode == "spell":
        var spell_id: String = _selected_spell()
        if not spell_id.is_empty():
            engine.cast_spell(spell_id, target_id)
    elif action_mode == "attack" and engine.actors[target_id]["team"] == "enemy":
        engine.attack(target_id, _selected_weapon(), subdue_mode and _selected_weapon_is_melee())
        subdue_mode = false
    _refresh()


func _on_second_wind() -> void:
    if engine.current_is_party():
        engine.use_second_wind()
    _refresh()


func _on_dash() -> void:
    if engine.current_is_party():
        engine.use_dash()
        action_mode = "move"
    _refresh()


func _on_dodge() -> void:
    if engine.current_is_party():
        engine.use_dodge()
    _refresh()


func _on_disengage() -> void:
    if engine.current_is_party():
        engine.use_disengage()
        action_mode = "move"
    _refresh()


func _on_reaction(accept: bool) -> void:
    if engine.resolve_reaction(accept):
        _run_enemy_turns()
    _refresh()


func _on_cast_self() -> void:
    if engine.current_is_party():
        var spell_id: String = _selected_spell()
        if not spell_id.is_empty():
            engine.cast_spell(spell_id, engine.current_id())
    _refresh()


func _on_end_turn() -> void:
    if engine.current_is_party():
        subdue_mode = false
        engine.end_turn()
        _run_enemy_turns()
    _refresh()


func _run_enemy_turns() -> void:
    if engine.deployment_active:
        return
    var safety := 25
    while not engine.finished and not engine.current_is_party() and engine.pending_reaction.is_empty() and safety > 0:
        engine.take_ai_turn()
        safety -= 1


func _refresh_picker() -> void:
    var active_id: String = engine.current_id()
    if active_id == current_picker_actor:
        return
    current_picker_actor = active_id
    weapon_ids.clear()
    action_ids.clear()
    weapon_picker.clear()
    ability_picker.clear()
    if active_id.is_empty():
        return
    var active: Dictionary = engine.current_actor()
    for weapon in active.get("attacks", []):
        if weapon.get("kind", "") == "spell_attack":
            continue
        weapon_ids.append(str(weapon["id"]))
        weapon_picker.add_item(str(weapon["id"]).replace("_", " ").capitalize())
    for spell_id in engine.get_current_spells():
        action_ids.append(spell_id)
        var spell: Dictionary = Level1Spells.get_definition(spell_id)
        var cost: String = "Cantrip" if int(spell["level"]) == 0 else "Slot 1"
        ability_picker.add_item("%s [%s]" % [spell_id.replace("_", " ").capitalize(), cost])
    if not weapon_ids.is_empty():
        weapon_picker.select(0)
    if not action_ids.is_empty():
        ability_picker.select(0)


func _set_crossed(button: Button, exhausted: bool) -> void:
    if button is CombatActionButton:
        button.crossed_out = exhausted and engine.current_is_party()


func _refresh_story() -> void:
    var info: Dictionary = adventure.screen()
    story_panel.visible = true
    story_continue_button.visible = true
    story_choices_scroll.visible = false
    map_toggle_button.visible = false
    journal_button.visible = false
    save_game_button.visible = adventure.stage in ["victory", "aftermath"]
    load_game_button.visible = true
    overland_map.visible = false
    story_image.visible = true
    var image_path: String = str(info.get("art", "res://assets/story/old_timber_road_campfire.svg"))
    if ResourceLoader.exists(image_path):
        story_image.texture = load(image_path) as Texture2D
    log_heading.visible = false
    combat_log.visible = false
    setup_panel.visible = false
    combat_action_row.visible = false
    combat_selector_row.visible = false
    reaction_row.visible = false
    board.action_mode = ""
    board.selected_deployment_actor = ""
    board.queue_redraw()

    story_eyebrow.text = str(info.get("eyebrow", "THE OLD TRADE ROAD"))
    story_title.text = str(info.get("title", "The Road"))
    var passages: PackedStringArray = []
    for para in info.get("paragraphs", []):
        passages.append(str(para))
    story_paragraphs.text = "\n\n".join(passages)
    if not story_feedback.is_empty():
        story_paragraphs.text += "\n\n" + story_feedback
    story_continue_button.text = str(info.get("button", "Continue"))
    status_label.text = "THE OLD TRADE ROAD" if adventure.stage == "approach" else story_eyebrow.text

    survivor_panel.visible = adventure.stage == "victory" and engine.actors.has("goblin_blade")
    if survivor_panel.visible:
        var survivor: Dictionary = engine.actors["goblin_blade"]
        if survivor.get("npc_id", "") != "hesk_roadwatch":
            survivor_panel.visible = false
        else:
            var state: String = str(survivor.get("combat_state", "active"))
            match state:
                "unconscious":
                    survivor_label.text = "Hesk, the shield-bearing goblin, is dying. Brunna may attempt first aid or spend a spell slot."
                "stable":
                    survivor_label.text = "Hesk has been stabilised, but remains unconscious at 0 HP. Healing could wake him."
                "knocked_out":
                    survivor_label.text = "Hesk was subdued at 1 HP. He is unconscious, but not dying."
                "active":
                    survivor_label.text = "Hesk is conscious and alive. His fate and any bargain belong to the next narrative scene."
                _:
                    survivor_label.text = "Hesk died in the fighting. Ordinary first aid and healing cannot restore him."
            survivor_first_aid_button.disabled = state not in ["unconscious", "knocked_out"] or bool(survivor.get("first_aid_attempted", false))
            survivor_heal_button.disabled = state not in ["unconscious", "stable", "knocked_out"] or int(engine.actors["brunna"].get("spell_slots_remaining", 0)) <= 0 or not engine.is_combat_capable("brunna")
    story_rewards.visible = adventure.stage == "victory"
    if adventure.stage == "victory":
        var reward: Dictionary = adventure.last_reward
        if bool(reward.get("already_claimed", false)):
            story_rewards.text = "Previously recovered — no additional XP or gold awarded."
        elif bool(reward.get("error", false)):
            story_rewards.text = "Reward data error — no rewards awarded."
        else:
            story_rewards.text = "XP: %d total (%d per adventurer)\nGold recovered: %d gp" % [
                int(reward.get("xp_total", 0)), int(reward.get("xp_each", 0)),
                int(reward.get("gold_gp", 0))
            ]
    var lines: PackedStringArray = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        lines.append("%s  •  %d XP" % [engine.actors[id]["name"], int(adventure.xp_by_character[id])])
    party_label.text = "\n".join(lines)
    active_label.text = "Pooled party gold: %d gp" % adventure.gold_gp
    _heard_event_count = engine.events.size()


func _refresh() -> void:
    if engine == null:
        return
    if debug_skip_battle_button != null:
        debug_skip_battle_button.visible = OS.has_feature("debug") and (
            adventure.stage in ["approach", "deployment", "battle"] and not engine.finished
        )
    if engine.finished and adventure.stage == "battle":
        adventure.conclude_battle(engine.victor)
        if adventure.stage == "victory":
            adventure.campaign.capture_party(engine.actors)
            adventure.campaign.capture_npc_from_combat(engine.actors)
    if adventure.stage == "exploration":
        _refresh_exploration()
        return
    if adventure.stage in ["approach", "victory", "defeat", "aftermath"]:
        _refresh_story()
        return
    story_panel.visible = false
    story_image.visible = false
    log_heading.visible = true
    combat_log.visible = true
    setup_panel.visible = engine.deployment_active
    combat_action_row.visible = not engine.deployment_active
    combat_selector_row.visible = not engine.deployment_active
    if engine.deployment_active:
        reaction_row.visible = false
        board.action_mode = ""
        board.selected_deployment_actor = deployment_selected_id
        board.queue_redraw()
        status_label.text = "PREPARE FOR AMBUSH"
        if deployment_selected_id.is_empty():
            active_label.text = "Choose Line, Square or Diamond.\nClick a party member to move them."
        else:
            active_label.text = "%s selected.\nClick a free blue square to reposition." % (
                engine.actors[deployment_selected_id]["name"]
            )
        deployment_instructions.text = "Formation: %s  •  Click a hero, then a blue square." % (
            engine.active_formation.capitalize()
        )
        for formation_id in formation_buttons.keys():
            var formation_button: Button = formation_buttons[formation_id]
            formation_button.add_theme_stylebox_override(
                "normal", _button_style(engine.active_formation == formation_id)
            )
        var lines: PackedStringArray = []
        for actor_id in ["alden", "elyra", "brunna", "pip"]:
            var actor: Dictionary = engine.actors[actor_id]
            lines.append("%s  •  (%d,%d)" % [
                actor["name"], actor["position"].x, actor["position"].y
            ])
        party_label.text = "\n".join(lines)
        var log_lines: PackedStringArray = []
        for evt in engine.events:
            var line: String = str(evt.get("text", ""))
            if not line.is_empty():
                log_lines.append(line)
        combat_log.text = "\n".join(log_lines)
        _heard_event_count = engine.events.size()
        return
    board.selected_deployment_actor = ""
    _refresh_picker()
    board.action_mode = action_mode
    board.selected_weapon = _selected_weapon()
    board.selected_spell = _selected_spell()
    board.queue_redraw()
    var reaction_pending: bool = not engine.pending_reaction.is_empty()
    reaction_row.visible = reaction_pending
    if reaction_pending:
        var prompt: Dictionary = engine.pending_reaction
        if prompt.get("kind", "") == "shield":
            reaction_label.text = "%s: Shield (+5 AC, 1 spell slot)?" % engine.actors[prompt["reactor"]]["name"]
            reaction_accept.text = "Cast Shield"
        else:
            reaction_label.text = "%s: Opportunity Attack against %s?" % [
                engine.actors[prompt["reactor"]]["name"], engine.actors[prompt["target"]]["name"]
            ]
            reaction_accept.text = "Attack"
    var party_turn: bool = engine.current_is_party() and not reaction_pending
    var can_act: bool = party_turn and int(engine.current_actor().get("hp", 0)) > 0
    status_label.text = "VICTORY!" if engine.finished and engine.victor == "party" else (
        "DEFEAT!" if engine.finished else "Round %d — %s" % [
            engine.round_number, engine.current_actor()["name"]
        ]
    )
    if engine.finished:
        active_label.text = "Battle complete"
    else:
        var actor: Dictionary = engine.current_actor()
        var total_movement: int = int(actor.get("speed_feet", 30)) / 5 + engine.dash_extra_squares
        var move_left: int = maxi(0, total_movement - engine.movement_used)
        active_label.text = "%s  HP %d/%d  AC %d\nAction: %s | Bonus: %s | Move: %d" % [
            actor["name"], actor["hp"], actor["max_hp"], actor["armor_class"],
            "spent" if engine.action_used else "ready",
            "spent" if engine.bonus_action_used else "ready", move_left
        ]
    var party_lines: PackedStringArray = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        var actor: Dictionary = engine.actors[id]
        var state: String = str(actor.get("combat_state", "active"))
        var suffix: String = " — UNCONSCIOUS" if state == "unconscious" else (
            " — DEAD" if state == "dead" else ""
        )
        party_lines.append("%s  %d/%d HP%s" % [actor["name"], actor["hp"], actor["max_hp"], suffix])
    party_label.text = "\n".join(party_lines)
    second_wind_button.disabled = not engine.can_use_second_wind()
    dash_button.disabled = not engine.can_dash()
    dodge_button.disabled = not engine.can_dodge()
    disengage_button.disabled = not engine.can_disengage()
    end_turn_button.disabled = not party_turn
    move_button.disabled = not can_act or not engine.can_move_current()
    attack_button.disabled = not can_act or engine.action_used
    spells_button.disabled = not can_act or not engine.can_cast_any_current_spell()
    weapon_picker.disabled = not can_act or engine.action_used or weapon_ids.is_empty()
    subdue_button.disabled = not can_act or engine.action_used or not _selected_weapon_is_melee()
    if subdue_button.disabled:
        subdue_mode = false
    subdue_button.text = "Subdue: ON" if subdue_mode else "Subdue: Off"
    subdue_button.add_theme_stylebox_override("normal", _button_style(subdue_mode))
    ability_picker.disabled = not can_act or action_ids.is_empty()
    var spell_id: String = _selected_spell()
    var spell: Dictionary = Level1Spells.get_definition(spell_id)
    self_cast_button.disabled = not party_turn or spell.get("target", "") != "self" or (
        not engine.can_cast_spell(spell_id, engine.current_id())
    )
    _set_crossed(move_button, engine.movement_remaining() <= 0)
    _set_crossed(attack_button, engine.action_used)
    _set_crossed(spells_button, not action_ids.is_empty() and not engine.can_cast_any_current_spell())
    _set_crossed(second_wind_button, engine.bonus_action_used)
    _set_crossed(dash_button, engine.action_used)
    _set_crossed(dodge_button, engine.action_used)
    _set_crossed(disengage_button, engine.action_used)
    for entry in [[move_button, "move"], [attack_button, "attack"], [spells_button, "spell"]]:
        var button: Button = entry[0]
        button.add_theme_stylebox_override("normal", _button_style(entry[1] == action_mode))
    var log_lines: PackedStringArray = []
    for entry in engine.events:
        var line: String = str(entry.get("text", ""))
        if not line.is_empty():
            log_lines.append(line)
    combat_log.text = "\n".join(log_lines)
    _play_new_events()
