extends Control
## Presentation only; CombatEngine owns all authoritative movement and damage.
## The approved mock-up drives the warm stone palette and strong target highlights.

signal cell_clicked(cell: Vector2i)
signal projectile_impact(target_id: String, final_state: String)

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
var camera_offset := Vector2.ZERO
var camera_zoom := 1.0
var camera_viewport := Vector2(816, 680)
var camera_view_active := false
const TOUCH_DRAG_THRESHOLD := 8.0
const MIN_ZOOM := 0.65
const MAX_ZOOM := 1.6
var _touch_points: Dictionary = {}
var _touch_start := Vector2.ZERO
var _touch_last := Vector2.ZERO
var _touch_dragged := false
var _pinch_used := false
var _mouse_down := false
var _mouse_start := Vector2.ZERO
var _mouse_last := Vector2.ZERO
var _mouse_dragged := false
var keyboard_cell := Vector2i(2, 5)
var _last_touch_cell := Vector2i(-1, -1)
var _last_touch_msec := -10000
var inspected_cell := Vector2i(-1, -1)
var _effects: Array[Dictionary] = []
var _projectiles: Array[Dictionary] = []
var _movement_queue: Array[Dictionary] = []
var _last_motion_end: Dictionary = {}
var _next_projectile_start_ms := 0
const EFFECT_DURATION_MS := 720
const PROJECTILE_DURATION_MS := 450
const MOVE_TILE_DURATION_MS := 115

# Creature motion and projectile flight are visual effects only.
# CombatEngine has already resolved tile paths, damage and actor states.
func _queue_movement(event: Dictionary) -> void:
    var actor_id: String = str(event.get("actor_id", ""))
    var from_data: Array = event.get("from", [])
    var to_data: Array = event.get("to", [])
    if from_data.size() != 2 or to_data.size() != 2 or actor_id.is_empty():
        return
    var from_cell := Vector2(float(from_data[0]), float(from_data[1]))
    var to_cell := Vector2(float(to_data[0]), float(to_data[1]))
    var now: int = Time.get_ticks_msec()
    var start_ms: int = maxi(now, int(_last_motion_end.get(actor_id, now)))
    _last_motion_end[actor_id] = start_ms + MOVE_TILE_DURATION_MS
    _movement_queue.append({
        "actor_id": actor_id, "from_cell": from_cell, "to_cell": to_cell,
        "start_ms": start_ms, "duration_ms": MOVE_TILE_DURATION_MS
    })
    set_process(true)
    queue_redraw()


func _render_actor_cell(actor_id: String, resolved_cell: Vector2i) -> Vector2:
    var now: int = Time.get_ticks_msec()
    for motion in _movement_queue:
        if str(motion.get("actor_id", "")) != actor_id:
            continue
        var start_ms: int = int(motion["start_ms"])
        if now < start_ms:
            return motion["from_cell"]
        var duration_ms: int = int(motion["duration_ms"])
        if now < start_ms + duration_ms:
            var fraction: float = clampf(float(now - start_ms) / float(duration_ms), 0.0, 1.0)
            var source: Vector2 = motion["from_cell"]
            var destination: Vector2 = motion["to_cell"]
            return source.lerp(destination, fraction)
    return Vector2(resolved_cell)


func _pending_fatal_projectile(actor_id: String) -> Dictionary:
    var now: int = Time.get_ticks_msec()
    for projectile in _projectiles:
        if str(projectile.get("target_id", "")) != actor_id:
            continue
        if str(projectile.get("kind", "")) != "hit":
            continue
        if int(projectile.get("hp_before", 0)) <= 0:
            continue
        if str(projectile.get("state_after", "")) not in ["dead", "unconscious", "knocked_out"]:
            continue
        if now < int(projectile["start_ms"]) + PROJECTILE_DURATION_MS:
            return projectile
    return {}


# Non-authoritative presentation driven only by engine-resolved combat facts.
func enqueue_combat_event(event: Dictionary) -> void:
    var kind: String = str(event.get("kind", ""))
    if kind in ["area_updated", "condition_applied", "condition_removed"]:
        queue_redraw()
        return
    if kind not in ["hit", "miss", "heal", "cast", "death", "move"]:
        return
    if engine == null:
        return
    if kind == "move":
        _queue_movement(event)
        return
    var ranged: bool = kind in ["hit", "miss"] and (
        str(event.get("attack_kind", "")) == "ranged_weapon" or (
            str(event.get("source_kind", "")) == "spell" and
            str(event.get("action_id", "")) in ["fire_bolt", "ray_of_frost", "magic_missile"]))
    var from_data: Array = event.get("source_cell", [])
    var to_data: Array = event.get("target_cell", [])
    if ranged and from_data.size() == 2 and to_data.size() == 2:
        var now := Time.get_ticks_msec()
        var source_id: String = str(event.get("actor_id", ""))
        var target_id: String = str(event.get("target_id", ""))
        # If an attacker advanced into range before firing, let the movement
        # complete visually before launching the already-resolved missile.
        var start_time: int = maxi(now, _next_projectile_start_ms)
        start_time = maxi(start_time, int(_last_motion_end.get(source_id, now)))
        start_time = maxi(start_time, int(_last_motion_end.get(target_id, now)))
        _next_projectile_start_ms = start_time + PROJECTILE_DURATION_MS + 70
        _projectiles.append({
            "kind": kind, "amount": int(event.get("amount", 0)),
            "damage_type": str(event.get("damage_type", "")),
            "source_kind": str(event.get("source_kind", "")),
            "target_id": str(event.get("target_id", "")),
            "hp_before": int(event.get("hp_before", 0)),
            "state_after": str(event.get("state_after", "")),
            "from_cell": Vector2(float(from_data[0]), float(from_data[1])),
            "to_cell": Vector2(float(to_data[0]), float(to_data[1])),
            "start_ms": start_time,
            "miss": kind == "miss"
        })
        set_process(true)
        queue_redraw()
        return
    var target_id: String = str(event.get("actor_id", "")) if kind == "cast" else str(event.get("target_id", ""))
    if not engine.actors.has(target_id):
        target_id = str(event.get("actor_id", ""))
    if not engine.actors.has(target_id):
        return
    var cell: Vector2i = engine.actors[target_id]["position"]
    _effects.append({
        "kind": kind,
        "cell": cell,
        "amount": int(event.get("amount", 0)),
        "damage_type": str(event.get("damage_type", "")),
        "critical": bool(event.get("critical", false)),
        "source_kind": str(event.get("source_kind", "")),
        "start_ms": Time.get_ticks_msec()
    })
    while _effects.size() > 12:
        _effects.pop_front()
    set_process(true)
    queue_redraw()


func reset_presentation() -> void:
    _effects.clear()
    _projectiles.clear()
    _movement_queue.clear()
    _last_motion_end.clear()
    _next_projectile_start_ms = 0
    inspected_cell = Vector2i(-1, -1)
    set_process(false)
    queue_redraw()


func _process(_delta: float) -> void:
    var now := Time.get_ticks_msec()
    for i in range(_projectiles.size() - 1, -1, -1):
        var projectile: Dictionary = _projectiles[i]
        if now - int(projectile["start_ms"]) >= PROJECTILE_DURATION_MS:
            _effects.append({
                "kind": str(projectile["kind"]), "amount": int(projectile["amount"]),
                "source_kind": str(projectile["source_kind"]),
                "damage_type": str(projectile["damage_type"]),
                "cell": Vector2i(projectile["to_cell"]),
                "critical": false, "start_ms": now
            })
            if str(projectile.get("state_after", "")) == "dead":
                _effects.append({
                    "kind": "death", "amount": 0, "source_kind": "impact",
                    "damage_type": "", "cell": Vector2i(projectile["to_cell"]),
                    "critical": false, "start_ms": now
                })
                projectile_impact.emit(str(projectile.get("target_id", "")), "dead")
            _projectiles.remove_at(i)
    for i in range(_movement_queue.size() - 1, -1, -1):
        var motion: Dictionary = _movement_queue[i]
        if now >= int(motion["start_ms"]) + int(motion["duration_ms"]):
            _movement_queue.remove_at(i)
    for i in range(_effects.size() - 1, -1, -1):
        if now - int(_effects[i]["start_ms"]) >= EFFECT_DURATION_MS:
            _effects.remove_at(i)
    if _effects.is_empty() and _projectiles.is_empty() and _movement_queue.is_empty():
        set_process(false)
    queue_redraw()


func _effect_color(kind: String, damage_type: String) -> Color:
    match kind:
        "heal":
            return Color("#62e6a2")
        "miss":
            return Color("#c3d0da")
        "death":
            return Color("#9a9da8")
        "cast":
            return Color("#cba5ff")
        _:
            match damage_type:
                "fire": return Color("#ff893e")
                "cold": return Color("#75dcf5")
                "radiant": return Color("#ffea8a")
                "force": return Color("#c48aff")
                "necrotic": return Color("#9279ad")
                _: return Color("#ff7470")


func _draw_effects() -> void:
    var now := Time.get_ticks_msec()
    for effect in _effects:
        var age: float = float(now - int(effect["start_ms"])) / float(EFFECT_DURATION_MS)
        var progress: float = clampf(age, 0.0, 1.0)
        var kind: String = str(effect["kind"])
        var cell: Vector2i = effect["cell"]
        var center := Vector2(cell * CELL_SIZE) + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
        var tint: Color = _effect_color(kind, str(effect.get("damage_type", "")))
        tint.a = 1.0 - progress
        var radius := 16.0 + progress * 22.0
        if kind in ["cast", "heal"] or (kind == "hit" and effect.get("source_kind", "") == "spell"):
            draw_arc(center, radius, 0.0, TAU, 28, tint, 4.0, true)
        elif kind == "hit":
            draw_line(center + Vector2(-19.0, 16.0), center + Vector2(19.0, -16.0),
                tint, 5.0, true)
            draw_line(center + Vector2(-17.0, -12.0), center + Vector2(15.0, 13.0),
                tint, 2.0, true)
        var caption := ""
        match kind:
            "hit":
                caption = "-%d" % int(effect["amount"])
            "heal":
                caption = "+%d" % int(effect["amount"])
            "miss":
                caption = "MISS"
            "cast":
                caption = "CAST"
            "death":
                caption = "DOWN"
        if caption.is_empty():
            continue
        var rise := 12.0 + progress * 24.0
        var label_size := 20 if kind != "cast" else 14
        draw_string(get_theme_default_font(),
            center + Vector2(-17.0, -rise), caption, HORIZONTAL_ALIGNMENT_LEFT,
            -1, label_size, tint)


func _draw_projectiles() -> void:
    var now := Time.get_ticks_msec()
    for projectile in _projectiles:
        var age_ms: int = now - int(projectile["start_ms"])
        if age_ms < 0:
            continue
        var p: float = clampf(float(age_ms) / float(PROJECTILE_DURATION_MS), 0.0, 1.0)
        var begin_cell: Vector2 = projectile["from_cell"]
        var destination: Vector2 = projectile["to_cell"]
        var start_pt := (begin_cell + Vector2(0.5, 0.5)) * CELL_SIZE
        var end_pt := (destination + Vector2(0.5, 0.5)) * CELL_SIZE
        var pos := start_pt.lerp(end_pt, p)
        var direction := (end_pt - start_pt).normalized()
        var tint := _effect_color("hit", str(projectile.get("damage_type", "")))
        if str(projectile.get("source_kind", "")) == "weapon":
            # Arrow / sling-bolt silhouette plus a modest warm trail.
            draw_line(pos - direction * 22.0, pos, Color("#efbd73", 0.85), 3.0, true)
            var side := Vector2(-direction.y, direction.x)
            draw_colored_polygon(PackedVector2Array([
                pos + direction * 11.0,
                pos - direction * 5.0 + side * 4.0,
                pos - direction * 5.0 - side * 4.0
            ]), Color("#f9e6b7"))
        else:
            draw_circle(pos - direction * 12.0, 6.0, Color(tint.r, tint.g, tint.b, 0.35))
            draw_circle(pos - direction * 6.0, 7.0, Color(tint.r, tint.g, tint.b, 0.55))
            draw_circle(pos, 9.0, tint)
            draw_circle(pos, 3.5, Color("#f4f0ff"))


func set_display_cell_size(value: int) -> void:
    display_cell_size = clampi(value, 38, CELL_SIZE)
    if camera_view_active:
        custom_minimum_size = camera_viewport
    else:
        custom_minimum_size = Vector2(12 * display_cell_size, 10 * display_cell_size)
    _clamp_camera()
    queue_redraw()


func set_viewport_size(view_size: Vector2) -> void:
    camera_view_active = true
    camera_viewport = Vector2(maxf(160.0, view_size.x), maxf(160.0, view_size.y))
    custom_minimum_size = camera_viewport
    _clamp_camera()
    queue_redraw()


func _grid_dimensions() -> Vector2i:
    return engine.grid_size if engine != null else Vector2i(12, 10)


func _clamp_camera() -> void:
    if not camera_view_active:
        camera_offset = Vector2.ZERO
        return
    var grid: Vector2i = _grid_dimensions()
    var cell_px := float(display_cell_size) * camera_zoom
    var grid_pixels := Vector2(float(grid.x) * cell_px, float(grid.y) * cell_px)
    camera_offset.x = clampf(camera_offset.x,
        minf(0.0, camera_viewport.x - grid_pixels.x), 0.0)
    camera_offset.y = clampf(camera_offset.y,
        minf(0.0, camera_viewport.y - grid_pixels.y), 0.0)


func pan_by(delta: Vector2) -> void:
    camera_offset += delta
    _clamp_camera()
    queue_redraw()


func zoom_at(focal_point: Vector2, magnification: float) -> void:
    if magnification <= 0.0:
        return
    var next_zoom: float = clampf(camera_zoom * magnification, MIN_ZOOM, MAX_ZOOM)
    var ratio := next_zoom / camera_zoom
    camera_offset = focal_point - (focal_point - camera_offset) * ratio
    camera_zoom = next_zoom
    _clamp_camera()
    queue_redraw()


func reset_camera() -> void:
    camera_zoom = 1.0
    camera_offset = Vector2.ZERO
    _touch_points.clear()
    _touch_dragged = false
    _pinch_used = false
    _mouse_down = false
    _clamp_camera()
    queue_redraw()


func _cell_from_position(position: Vector2) -> Vector2i:
    var pixels := (position - camera_offset) / (float(display_cell_size) * camera_zoom)
    return Vector2i(floori(pixels.x), floori(pixels.y))


func _cell_visible(cell: Vector2i) -> bool:
    var px := (Vector2(cell) + Vector2(0.5, 0.5)) * float(display_cell_size) * camera_zoom + camera_offset
    return px.x >= 0 and px.y >= 0 and px.x < camera_viewport.x and px.y < camera_viewport.y


func _reveal_keyboard_cell() -> void:
    if not camera_view_active or _cell_visible(keyboard_cell):
        return
    var px := (Vector2(keyboard_cell) + Vector2(0.5, 0.5)) * float(display_cell_size) * camera_zoom + camera_offset
    pan_by(camera_viewport * 0.5 - px)


func _activate_cell(cell: Vector2i) -> void:
    if engine == null or cell.x < 0 or cell.y < 0:
        return
    if cell.x >= engine.grid_size.x or cell.y >= engine.grid_size.y:
        return
    keyboard_cell = cell
    inspected_cell = cell
    cell_clicked.emit(cell)
    queue_redraw()



func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_display_cell_size(CELL_SIZE)
    clip_contents = true
    focus_mode = Control.FOCUS_ALL
    set_process(false)


func _draw() -> void:
    if engine == null:
        return
    draw_set_transform(camera_offset, 0.0, Vector2.ONE * (float(display_cell_size) * camera_zoom / float(CELL_SIZE)))
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
            if not engine.area_effects_at(cell).is_empty():
                draw_rect(dest.grow(-3), Color("#c8d3f0", 0.26))
                draw_rect(dest.grow(-4), Color("#d8e7ff", 0.85), false, 2.0)
                draw_line(dest.position + Vector2(6, 6), dest.end - Vector2(6, 6), Color("#d8e7ff", 0.7), 2.0)
                draw_line(dest.position + Vector2(6, CELL_SIZE - 6), dest.position + Vector2(CELL_SIZE - 6, 6), Color("#d8e7ff", 0.7), 2.0)
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

    if inspected_cell.x >= 0 and inspected_cell.y >= 0:
        var selected := Rect2(Vector2(inspected_cell * CELL_SIZE) + Vector2(3, 3), Vector2(62, 62))
        draw_rect(selected, Color("#faf0c1"), false, 2.5)
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
        var actor_id: String = str(actor["id"])
        var draw_cell: Vector2 = _render_actor_cell(actor_id, cell)
        var cell_origin: Vector2 = draw_cell * CELL_SIZE
        var dest := Rect2(cell_origin + Vector2(2, 2), Vector2(64, 64))
        var held: Dictionary = _pending_fatal_projectile(actor_id)
        var active: bool = engine.is_combat_capable(str(id_variant)) or not held.is_empty()
        if actor_id == current or (engine.deployment_active and actor_id == selected_deployment_actor):
            draw_rect(Rect2(cell_origin + Vector2(1, 1), Vector2(66, 66)), GOLD, false, 3.0)
        elif active:
            var team_color: Color = PARTY_BLUE if actor["team"] == "party" else ENEMY_RED
            draw_rect(Rect2(cell_origin + Vector2(1, 1), Vector2(66, 66)), team_color, false, 1.3)

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

        if engine.has_condition(actor_id, "restrained"):
            draw_rect(Rect2(cell_origin + Vector2(2, 2), Vector2(64, 15)), Color("#172031", 0.9))
            draw_string(get_theme_default_font(), cell_origin + Vector2(3, 14),
                "Restrained", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e5efff"))
        if not active:
            var glyph: String = "Z" if actor.get("combat_state", "") in ["unconscious", "stable", "knocked_out"] else "X"
            var status_color: Color = PARTY_BLUE if glyph == "Z" else ENEMY_RED
            draw_string(get_theme_default_font(), dest.position + Vector2(50, 16),
                glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, status_color)
        var hp_bar := Rect2(cell_origin + Vector2(6, 62), Vector2(56, 4))
        draw_rect(hp_bar, Color("#652d32"))
        var shown_hp: int = int(held.get("hp_before", actor["hp"]))
        var fraction: float = float(shown_hp) / float(maxi(1, int(actor["max_hp"])))
        draw_rect(Rect2(hp_bar.position, Vector2(hp_bar.size.x * fraction, 4)), Color("#65bd7c"))

    _draw_effects()
    _draw_projectiles()


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
    # Screen gestures are interpreted on release. Dragging never submits a
    # combat command, and two-finger pinch never selects a tactical tile.
    if event is InputEventScreenTouch:
        _last_touch_msec = Time.get_ticks_msec()
        if event.pressed:
            _touch_points[event.index] = event.position
            if _touch_points.size() == 1:
                _touch_start = event.position
                _touch_last = event.position
                _touch_dragged = false
                _pinch_used = false
            else:
                _pinch_used = true
        else:
            var should_select: bool = _touch_points.size() == 1 and not _touch_dragged and not _pinch_used
            _touch_points.erase(event.index)
            if should_select:
                _activate_cell(_cell_from_position(event.position))
            if _touch_points.is_empty():
                _touch_dragged = false
                _pinch_used = false
        accept_event()
        return

    if event is InputEventScreenDrag:
        if not _touch_points.has(event.index):
            return
        var old_pos: Vector2 = _touch_points[event.index]
        if _touch_points.size() >= 2:
            var touch_ids: Array = _touch_points.keys()
            var other_id: int = int(touch_ids[0]) if int(touch_ids[0]) != event.index else int(touch_ids[1])
            var other_pos: Vector2 = _touch_points[other_id]
            var old_distance := maxf(1.0, old_pos.distance_to(other_pos))
            var next_distance := maxf(1.0, event.position.distance_to(other_pos))
            _touch_points[event.index] = event.position
            _pinch_used = true
            zoom_at((event.position + other_pos) * 0.5, next_distance / old_distance)
        else:
            _touch_points[event.index] = event.position
            if _touch_dragged or event.position.distance_to(_touch_start) > TOUCH_DRAG_THRESHOLD:
                _touch_dragged = true
                pan_by(event.position - _touch_last)
            _touch_last = event.position
        accept_event()
        return

    if event is InputEventMouseButton:
        # Godot may synthesise mouse events from physical touches, including
        # release, so suppress the whole pair briefly after the touch.
        if Time.get_ticks_msec() - _last_touch_msec < 480:
            accept_event()
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom_at(event.position, 1.12)
            accept_event()
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom_at(event.position, 1.0 / 1.12)
            accept_event()
            return
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _mouse_down = true
                _mouse_dragged = false
                _mouse_start = event.position
                _mouse_last = event.position
                grab_focus()
            elif _mouse_down:
                _mouse_down = false
                if not _mouse_dragged:
                    _activate_cell(_cell_from_position(event.position))
            accept_event()
            return

    if event is InputEventMouseMotion and _mouse_down:
        if _mouse_dragged or event.position.distance_to(_mouse_start) > TOUCH_DRAG_THRESHOLD:
            _mouse_dragged = true
            pan_by(event.position - _mouse_last)
        _mouse_last = event.position
        accept_event()
        return

    if event is InputEventKey and event.pressed and not event.echo:
        var offset := Vector2i.ZERO
        match event.keycode:
            KEY_LEFT: offset = Vector2i.LEFT
            KEY_RIGHT: offset = Vector2i.RIGHT
            KEY_UP: offset = Vector2i.UP
            KEY_DOWN: offset = Vector2i.DOWN
            KEY_EQUAL, KEY_PLUS:
                zoom_at(camera_viewport * 0.5, 1.12)
                accept_event()
                return
            KEY_MINUS:
                zoom_at(camera_viewport * 0.5, 1.0 / 1.12)
                accept_event()
                return
            KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
                _activate_cell(keyboard_cell)
                accept_event()
                return
            _:
                return
        if event.shift_pressed:
            pan_by(-Vector2(offset) * 60.0)
        else:
            var grid: Vector2i = _grid_dimensions()
            keyboard_cell = Vector2i(clampi(keyboard_cell.x + offset.x, 0, grid.x - 1),
                clampi(keyboard_cell.y + offset.y, 0, grid.y - 1))
            _reveal_keyboard_cell()
        queue_redraw()
        accept_event()
