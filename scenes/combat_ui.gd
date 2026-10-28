extends Control
## The first interactive vertical slice: click empty cells to move, enemies to attack.

const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatBoard = preload("res://combat/combat_board.gd")

var engine
var board
var status_label: Label
var party_label: Label
var active_label: Label
var combat_log: RichTextLabel
var end_turn_button: Button


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
    heading.text = "PROJECT AZURE MINES"
    heading.add_theme_font_size_override("font_size", 26)
    left.add_child(heading)

    status_label = Label.new()
    left.add_child(status_label)

    board = CombatBoard.new()
    board.cell_clicked.connect(_on_cell_clicked)
    left.add_child(board)

    var instructions := Label.new()
    instructions.text = "Click a highlighted empty tile to move. Click an enemy to attack. End Turn to advance."
    instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    left.add_child(instructions)

    var right := VBoxContainer.new()
    right.custom_minimum_size = Vector2(370, 0)
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_constant_override("separation", 12)
    layout.add_child(right)

    var party_heading := Label.new()
    party_heading.text = "PARTY"
    party_heading.add_theme_font_size_override("font_size", 21)
    right.add_child(party_heading)
    party_label = Label.new()
    right.add_child(party_label)

    var turn_heading := Label.new()
    turn_heading.text = "ACTIVE TURN"
    turn_heading.add_theme_font_size_override("font_size", 21)
    right.add_child(turn_heading)
    active_label = Label.new()
    active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    right.add_child(active_label)

    var buttons := HBoxContainer.new()
    right.add_child(buttons)
    end_turn_button = Button.new()
    end_turn_button.text = "End Turn"
    end_turn_button.pressed.connect(_on_end_turn)
    buttons.add_child(end_turn_button)
    var restart_button := Button.new()
    restart_button.text = "Restart Battle"
    restart_button.pressed.connect(_restart)
    buttons.add_child(restart_button)

    var log_heading := Label.new()
    log_heading.text = "COMBAT LOG"
    log_heading.add_theme_font_size_override("font_size", 21)
    right.add_child(log_heading)
    combat_log = RichTextLabel.new()
    combat_log.scroll_following = true
    combat_log.custom_minimum_size = Vector2(350, 285)
    combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(combat_log)


func _restart() -> void:
    engine = CombatEngine.new()
    if not engine.start():
        status_label.text = "ERROR: fixture or encounter could not load."
        end_turn_button.disabled = true
        return
    board.engine = engine
    _run_enemy_turns()
    _refresh()


func _on_cell_clicked(cell: Vector2i) -> void:
    if not engine.current_is_party():
        return
    var id: String = engine.actor_at(cell)
    if not id.is_empty():
        if engine.actors[id]["team"] == "enemy":
            engine.attack(id)
    else:
        engine.move_to(cell)
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


func _refresh() -> void:
    if engine == null:
        return
    board.queue_redraw()
    if engine.finished:
        status_label.text = "VICTORY — all goblins defeated!" if engine.victor == "party" else "DEFEAT — restart to try again."
    else:
        status_label.text = "Round %d | Current: %s" % [engine.round_number, engine.current_actor()["name"]]
    var party_lines: PackedStringArray = []
    for id in ["alden", "elyra", "brunna", "pip"]:
        var actor: Dictionary = engine.actors[id]
        party_lines.append("%s (%s)   HP %d/%d  AC %d" % [
            actor["name"], str(actor["class_id"]).capitalize(), actor["hp"], actor["max_hp"], actor["armor_class"]
        ])
    party_label.text = "\n".join(party_lines)
    if engine.finished:
        active_label.text = "Battle complete."
    else:
        var active: Dictionary = engine.current_actor()
        var remaining := maxi(0, int(active.get("speed_feet", 30)) / 5 - engine.movement_used)
        active_label.text = "%s\nAction: %s | Movement: %d tiles remaining" % [
            active["name"], "Spent" if engine.action_used else "Available", remaining
        ]
    end_turn_button.disabled = engine.finished or not engine.current_is_party()
    var lines: PackedStringArray = []
    for item in engine.events:
        lines.append(str(item["text"]))
    combat_log.text = "\n".join(lines)
