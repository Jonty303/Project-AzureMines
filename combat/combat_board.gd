extends Control
## Presentation only; CombatEngine owns all authoritative movement and damage.
## The approved mock-up drives the warm stone palette and strong target highlights.

signal cell_clicked(cell: Vector2i)

const CombatEngine = preload("res://combat/combat_engine.gd")
const CELL_SIZE := 68
const SOURCE_SIZE := 64
const PARTY_BLUE := Color("#399bd5")
const ENEMY_RED := Color("#cb4c43")
const GOLD := Color("#d7aa58")
const DOWNED_ATLAS := "assets/characters/sprites/downed_party_atlas_64.png"
const TERRAIN_ATLAS := "assets/environment/dungeon_tiles_64.svg"
const PROPS_ATLAS := "assets/environment/dungeon_props_64.png"

var engine: CombatEngine
var action_mode := ""
var selected_weapon := ""
var selected_spell := ""
var selected_deployment_actor := ""
var _sprite_cache: Dictionary = {}
var display_cell_size: int = CELL_SIZE
var keyboard_cell := Vector2i(2, 5)
var _last_touch_cell := Vector2i(-1, -1)
var _last_touch_msec := -10000


func set_display_cell_size(value: int) -> void:
    display_cell_size = clampi(value, 38, CELL_SIZE)
    custom_minimum_size = Vector2(12 * display_cell_size, 10 * display_cell_size)
    queue_redraw()


func _cell_from_position(position: Vector2) -> Vector2i:
    return Vector2i(floori(position.x / float(display_cell_size)),
        floori(position.y / float(display_cell_size)))


func _activate_cell(cell: Vector2i) -> void:
    if engine == null or cell.x < 0 or cell.y < 0:
        return
    if cell.x >= engine.grid_size.x or cell.y >= engine.grid_size.y:
        return
    keyboard_cell = cell
    cell_clicked.emit(cell)
    queue_redraw()



func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_display_cell_size(CELL_SIZE)
    focus_mode = Control.FOCUS_ALL


func _draw() -> void:
    if engine == null:
        return
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * (float(display_cell_size) / float(CELL_SIZE)))
    var current: String = engine.current_id()
    var highlights: Dictionary = get_highlights()
    var reachable: Dictionary = highlights["move"]
    var attack_cells: Dictionary = highlights["attack"]
    var spell_cells: Dictionary = highlights["spell"]
    var terrain: Texture2D = _texture_for(TERRAIN_ATLAS)

    for y in range(engine.grid_size.y):
        for x in range(engine.grid_size.x):
            var cell := Vector2i(x, y)
            var dest := Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
            var wall: bool = cell in engine.walls
            if terrain != null:
                var tile_idx: int = 3 if wall else (x * 13 + y * 7) % 3
                var source := Rect2(Vector2(tile_idx * SOURCE_SIZE, 0), Vector2(SOURCE_SIZE, SOURCE_SIZE))
                draw_texture_rect_region(terrain, dest, source)
            else:
                var stone: Color = Color("#25242a") if wall else Color("#51453d")
                if (x + y) % 3 == 0:
                    stone = stone.lightened(0.065)
                draw_rect(dest, stone)
            if cell in engine.difficult_terrain:
                draw_rect(dest, Color("#8c6b35", 0.32))
            if reachable.has(cell) and cell != engine.current_actor()["position"]:
                draw_rect(dest, Color("#399bd5", 0.22))
            if attack_cells.has(cell):
                draw_rect(dest, Color("#cb4c43", 0.25))
                draw_rect(dest.grow(-2), Color("#f77869"), false, 2.0)
            if spell_cells.has(cell):
                draw_rect(dest, Color("#d7aa58", 0.24))
                draw_rect(dest.grow(-2), GOLD, false, 2.0)
            if engine.deployment_active and not selected_deployment_actor.is_empty() \
                    and engine.can_place_character(selected_deployment_actor, cell):
                draw_rect(dest.grow(-3), Color("#399bd5", 0.18))
                draw_rect(dest.grow(-3), Color("#65b3df", 0.65), false, 1.5)
            draw_rect(dest, Color("#1c232b", 0.58), false, 1.0)

    if has_focus():
        var cursor := Rect2(Vector2(keyboard_cell * CELL_SIZE) + Vector2(2, 2), Vector2(64, 64))
        draw_rect(cursor, Color("#f0da86"), false, 3.0)

    # Layered scene art: forest backdrop first, then persistent physical props.
    var forest_path: String = str(engine.backdrop.get("art", "")).trim_prefix("res://")
    var forest: Texture2D = _texture_for(forest_path)
    if forest != null:
        var forest_height: int = int(engine.backdrop.get("rows", 2)) * CELL_SIZE
        # Scenery must not conceal tactical terrain or targeting information.
        draw_texture_rect(forest, Rect2(Vector2.ZERO, Vector2(engine.grid_size.x * CELL_SIZE, forest_height)), false,
            Color(1.0, 1.0, 1.0, 0.28))
        for top_y in range(mini(int(engine.backdrop.get("rows", 2)), engine.grid_size.y)):
            for top_x in range(engine.grid_size.x):
                var top_cell := Rect2(Vector2(top_x * CELL_SIZE, top_y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
                draw_rect(top_cell, Color("#d0baa0", 0.45), false, 1.5)

    for obstacle in engine.obstacles:
        var art_path: String = str(obstacle.get("art", "")).trim_prefix("res://")
        var sprite: Texture2D = _texture_for(art_path)
        var pos: Vector2i = obstacle["position"]
        var extent: Vector2i = obstacle["size"]
        var dest := Rect2(Vector2(pos * CELL_SIZE) + Vector2(2, 2),
            Vector2(extent * CELL_SIZE) - Vector2(4, 4))
        if sprite != null:
            draw_texture_rect(sprite, dest, false)
        else:
            draw_rect(dest, Color("#65503a"))
        if obstacle.get("cover", "") == "half":
            draw_rect(dest.grow(-2), Color("#bca66b", 0.5), false, 1.5)

    for hazard in engine.hazards:
        var image_path: String = str(hazard.get("art", "")).trim_prefix("res://")
        var image: Texture2D = _texture_for(image_path)
        var cell: Vector2i = hazard["position"]
        var dest := Rect2(Vector2(cell * CELL_SIZE) + Vector2(2, 2), Vector2(SOURCE_SIZE, SOURCE_SIZE))
        if image != null:
            draw_texture_rect(image, dest, false)
        else:
            draw_circle(dest.get_center(), 18.0, Color("#f49b3d"))
        draw_rect(dest.grow(-2), Color("#e97931", 0.85), false, 2.0)

    var downed: Texture2D = _texture_for(DOWNED_ATLAS)
    for id_variant in engine.actors.keys():
        var actor: Dictionary = engine.actors[id_variant]
        var cell: Vector2i = actor["position"]
        var dest := Rect2(Vector2(cell * CELL_SIZE) + Vector2(2, 2), Vector2(64, 64))
        var active: bool = engine.is_combat_capable(str(id_variant))
        var actor_id: String = str(actor["id"])
        if actor_id == current or (engine.deployment_active and actor_id == selected_deployment_actor):
            draw_rect(Rect2(Vector2(cell * CELL_SIZE) + Vector2(1, 1), Vector2(66, 66)), GOLD, false, 3.0)
        elif active:
            var team_color: Color = PARTY_BLUE if actor["team"] == "party" else ENEMY_RED
            draw_rect(Rect2(Vector2(cell * CELL_SIZE) + Vector2(1, 1), Vector2(66, 66)), team_color, false, 1.3)

        var drawn := false
        if not active and downed != null:
            var index: int = _downed_index(actor_id)
            var source := Rect2(Vector2(index * SOURCE_SIZE, 0), Vector2(SOURCE_SIZE, SOURCE_SIZE))
            draw_texture_rect_region(downed, dest, source)
            drawn = true
        if not drawn and active:
            var art: Dictionary = actor.get("art", {})
            var path: String = str(art.get("combat_sprite", ""))
            if path.ends_with("_front_32.png"):
                path = path.replace("_front_32.png", "_front_64.png")
            var sprite: Texture2D = _texture_for(path)
            if sprite != null:
                draw_texture_rect(sprite, dest, false)
                drawn = true
        if not drawn:
            draw_circle(dest.get_center(), 24.0, PARTY_BLUE if actor["team"] == "party" else ENEMY_RED)
            draw_string(get_theme_default_font(), dest.position + Vector2(23, 43),
                str(actor["name"]).substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)

        if not active:
            var glyph: String = "Z" if actor.get("combat_state", "") in ["unconscious", "stable", "knocked_out"] else "X"
            var status_color: Color = PARTY_BLUE if glyph == "Z" else ENEMY_RED
            draw_string(get_theme_default_font(), dest.position + Vector2(50, 16),
                glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, status_color)
        var hp_bar := Rect2(Vector2(cell * CELL_SIZE) + Vector2(6, 62), Vector2(56, 4))
        draw_rect(hp_bar, Color("#652d32"))
        var fraction: float = float(actor["hp"]) / float(maxi(1, int(actor["max_hp"])))
        draw_rect(Rect2(hp_bar.position, Vector2(hp_bar.size.x * fraction, 4)), Color("#65bd7c"))



func get_highlights() -> Dictionary:
    # Purely contextual. Never show a different action's targeting preview.
    var indicators := {"move": {}, "attack": {}, "spell": {}}
    if engine == null or not engine.current_is_party():
        return indicators
    if int(engine.current_actor().get("hp", 0)) <= 0:
        return indicators
    if action_mode == "move" and engine.movement_remaining() > 0:
        indicators["move"] = engine.get_reachable(engine.current_id())
    elif action_mode == "attack" and not engine.action_used:
        for id_variant in engine.actors.keys():
            var target_id: String = str(id_variant)
            if not engine.available_attack(target_id, selected_weapon).is_empty():
                indicators["attack"][engine.actors[target_id]["position"]] = true
    elif action_mode == "spell" and not selected_spell.is_empty():
        for id_variant in engine.actors.keys():
            var target_id: String = str(id_variant)
            if engine.can_cast_spell(selected_spell, target_id):
                indicators["spell"][engine.actors[target_id]["position"]] = true
    return indicators


func _downed_index(actor_id: String) -> int:
    if actor_id == "alden":
        return 0
    if actor_id == "elyra":
        return 1
    if actor_id == "brunna":
        return 2
    if actor_id == "pip":
        return 3
    return 4


func _draw_prop(atlas: Texture2D, cell: Vector2i, index: int) -> void:
    var dest := Rect2(Vector2(cell * CELL_SIZE) + Vector2(2, 2), Vector2(64, 64))
    var source := Rect2(Vector2(index * SOURCE_SIZE, 0), Vector2(SOURCE_SIZE, SOURCE_SIZE))
    draw_texture_rect_region(atlas, dest, source)


func _texture_for(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if not _sprite_cache.has(path):
        var texture: Texture2D = null
        if ResourceLoader.exists("res://" + path):
            texture = load("res://" + path) as Texture2D
        _sprite_cache[path] = texture
    return _sprite_cache[path]


func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed and event.index == 0:
        var cell: Vector2i = _cell_from_position(event.position)
        _last_touch_cell = cell
        _last_touch_msec = Time.get_ticks_msec()
        _activate_cell(cell)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var cell: Vector2i = _cell_from_position(event.position)
        # Godot may synthesise a mouse press for the same touchscreen tap.
        if cell == _last_touch_cell and Time.get_ticks_msec() - _last_touch_msec < 400:
            return
        grab_focus()
        _activate_cell(cell)
        accept_event()
    elif event is InputEventKey and event.pressed and not event.echo:
        var offset := Vector2i.ZERO
        match event.keycode:
            KEY_LEFT:
                offset = Vector2i.LEFT
            KEY_RIGHT:
                offset = Vector2i.RIGHT
            KEY_UP:
                offset = Vector2i.UP
            KEY_DOWN:
                offset = Vector2i.DOWN
            KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
                _activate_cell(keyboard_cell)
                accept_event()
                return
            _:
                return
        keyboard_cell = Vector2i(clampi(keyboard_cell.x + offset.x, 0, 11),
            clampi(keyboard_cell.y + offset.y, 0, 9))
        queue_redraw()
        accept_event()
