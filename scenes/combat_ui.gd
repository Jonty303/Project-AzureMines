extends Control
## Four-character tutorial combat UI. Pure battle mechanics live in CombatEngine.

const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatBoard = preload("res://combat/combat_board.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")

var engine: CombatEngine
var board: CombatBoard
var status_label: Label
var party_label: Label
var active_label: Label
var combat_log: RichTextLabel
var end_turn_button: Button
var ability_picker: OptionButton
var self_cast_button: Button
var second_wind_button: Button
var action_ids: Array[String] = []
var current_picker_actor := ""


func _ready() -> void:
    _build_ui()
    _restart()


func _build_ui() -> void:
    var background := ColorRect.new()
    background.color = Color("#141d29")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_bottom", 18)
    add_child(margin)

    var layout := HBoxContainer.new()
    layout.add_theme_constant_override("separation", 24)
    margin.add_child(layout)

    var left := VBoxContainer.new()
    left.add_theme_constant_override("separation", 12)
    layout.add_child(left)
    var heading := Label.new()
    heading.text = "PROJECT AZURE MINES — LEVEL 1"
    heading.add_theme_font_size_override("font_size", 26)
    left.add_child(heading)
    status_label = Label.new()
    left.add_child(status_label)
    board = CombatBoard.new()
    board.cell_clicked.connect(_on_cell_clicked)
    left.add_child(board)
    var help := Label.new()
    help.text = "Click a highlighted tile to move. Choose a spell, then click its target. End Turn advances initiative."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    left.add_child(help)

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(400, 0)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_constant_override("separation", 9)
    layout.add_child(right)
    var party_heading := Label.new()
    party_heading.text = "PARTY"
    party_heading.add_theme_font_size_override("font_size", 20)
    right.add_child(party_heading)
    party_label = Label.new()
    right.add_child(party_label)

    var turn_heading := Label.new()
    turn_heading.text = "ACTIVE TURN"
    turn_heading.add_theme_font_size_override("font_size", 20)
    right.add_child(turn_heading)
    active_label = Label.new()
    active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    right.add_child(active_label)

    var action_heading := Label.new()
    action_heading.text = "ATTACK / LEVEL-1 SPELL"
    right.add_child(action_heading)
    ability_picker = OptionButton.new()
    ability_picker.item_selected.connect(_on_action_selected)
    right.add_child(ability_picker)

    var ability_buttons := HBoxContainer.new()
    right.add_child(ability_buttons)
    self_cast_button = Button.new()
    self_cast_button.text = "Cast on Self"
    self_cast_button.pressed.connect(_on_cast_self)
    ability_buttons.add_child(self_cast_button)
    second_wind_button = Button.new()
    second_wind_button.text = "Second Wind"
    second_wind_button.pressed.connect(_on_second_wind)
    ability_buttons.add_child(second_wind_button)

    var turn_buttons := HBoxContainer.new()
    right.add_child(turn_buttons)
    end_turn_button = Button.new()
    end_turn_button.text = "End Turn"
    end_turn_button.pressed.connect(_on_end_turn)
    turn_buttons.add_child(end_turn_button)
    var restart := Button.new()
    restart.text = "Restart"
    restart.pressed.connect(_restart)
    turn_buttons.add_child(restart)

    var log_heading := Label.new()
    log_heading.text = "COMBAT LOG"
    log_heading.add_theme_font_size_override("font_size", 20)
    right.add_child(log_heading)
    combat_log = RichTextLabel.new()
    combat_log.scroll_following = true
    combat_log.custom_minimum_size = Vector2(390, 260)
    combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(combat_log)


func _restart() -> void:
    engine = CombatEngine.new()
    if not engine.start():
        status_label.text = "ERROR: cannot load the combat fixture."
        end_turn_button.disabled = true
        return
    board.engine = engine
    current_picker_actor = ""
    _run_enemy_turns()
    _refresh()


func _on_cell_clicked(cell: Vector2i) -> void:
    if not engine.current_is_party():
        return
    var target_id: String = engine.actor_at(cell)
    if target_id.is_empty():
        engine.move_to(cell)
    else:
        var spell_id: String = _selected_spell()
        if spell_id.is_empty():
            if engine.actors[target_id]["team"] == "enemy":
                engine.attack(target_id)
        else:
            engine.cast_spell(spell_id, target_id)
    _refresh()


func _on_action_selected(_index: int) -> void:
    _refresh()


func _selected_spell() -> String:
    if ability_picker == null:
        return ""
    var index: int = ability_picker.get_selected_id()
    if index < 0 or index >= action_ids.size():
        return ""
    return action_ids[index]


func _on_cast_self() -> void:
    if not engine.current_is_party():
        return
    var spell_id: String = _selected_spell()
    if not spell_id.is_empty():
        engine.cast_spell(spell_id, engine.current_id())
    _refresh()


func _on_second_wind() -> void:
    if engine.current_is_party():
        engine.use_second_wind()
    _refresh()


func _on_end_turn() -> void:
    if engine.finished or not engine.current_is_party():
        return
    engine.end_turn()
    _run_enemy_turns()
    _refresh()


func _run_enemy_turns() -> void:
    var safety := 20
    while not engine.finished and not engine.current_is_party() and safety > 0:
        engine.take_ai_turn()
        safety -= 1


func _refresh_picker() -> void:
    var active_id: String = engine.current_id()
    if active_id == current_picker_actor:
        return
    current_picker_actor = active_id
    ability_picker.clear()
    action_ids.clear()
    action_ids.append("")
    ability_picker.add_item("Weapon Attack")
    for spell_id in engine.get_current_spells():
        action_ids.append(spell_id)
        var spell: Dictionary = Level1Spells.get_definition(spell_id)
        var tag := "Cantrip" if int(spell["level"]) == 0 else "Slot 1"
        ability_picker.add_item("%s (%s)" % [spell_id.replace("_", " ").capitalize(), tag])
    ability_picker.select(0)


func _refresh() -> void:
    if engine == null:
        return
    board.queue_redraw()
    _refresh_picker()
    if engine.finished:
        status_label.text = "VICTORY — goblins defeated!" if engine.victor == "party" else "DEFEAT — party down."
        active_label.text = "Battle complete."
    else:
        var actor: Dictionary = engine.current_actor()
        status_label.text = "Round %d | Active: %s" % [engine.round_number, actor["name"]]
        var remaining: int = maxi(0, int(actor.get("speed_feet", 30)) / 5 - engine.movement_used)
        var extra := ""
        if actor.get("spellcasting") != null:
            extra = "\nLevel-1 slots remaining: %d" % int(actor.get("spell_slots_remaining", 0))
        if actor.get("class_id", "") == "champion":
            extra += "\nSecond Wind uses: %d" % int(actor.get("second_wind_remaining", 0))
        active_label.text = "%s\nAction: %s | Bonus: %s | Move: %d tiles%s" % [
            actor["name"], "Used" if engine.action_used else "Ready",
            "Used" if engine.bonus_action_used else "Ready", remaining, extra
        ]

    var party_lines: PackedStringArray = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        var member: Dictionary = engine.actors[id]
        party_lines.append("%s  HP %d/%d  AC %d" % [
            member["name"], member["hp"], member["max_hp"], member["armor_class"]
        ])
    party_label.text = "\n".join(party_lines)
    end_turn_button.disabled = not engine.current_is_party()
    second_wind_button.disabled = not engine.can_use_second_wind()
    var selected: String = _selected_spell()
    var definition: Dictionary = Level1Spells.get_definition(selected)
    self_cast_button.disabled = not engine.current_is_party() or definition.get("target", "") != "self" \
        or not engine.can_cast_spell(selected, engine.current_id())

    var lines: PackedStringArray = []
    for event in engine.events:
        lines.append(str(event["text"]))
    combat_log.text = "\n".join(lines)
