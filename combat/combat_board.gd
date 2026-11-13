extends Control
## Presentation only; CombatEngine owns all authoritative movement and damage.
## The approved mock-up drives the warm stone palette and strong target highlights.

signal cell_clicked(cell: Vector2i)
signal camera_gesture()
signal cancel_targeting()
signal projectile_impact(target_id: String, final_state: String)

const CombatEngine = preload("res://combat/combat_engine.gd")
const CELL_SIZE := 68
const SOURCE_SIZE := 64
const PARTY_BLUE := Color("#399bd5")
const ENEMY_RED := Color("#cb4c43")
const GOLD := Color("#d7aa58")
const DOWNED_ATLAS := "assets/characters/sprites/downed_party_atlas_64.png"
const Art = preload("res://combat/combat_art.gd")
const TERRAIN_ATLAS := "assets/combat_v054/terrain.png"
const PROPS_ATLAS := "assets/environment/dungeon_props_64.png"

var engine: CombatEngine
var action_mode := ""
var selected_weapon := ""
var selected_spell := ""
var area_preview := Vector2i(-1, -1)
var area_preview_valid := false
var area_shape: Dictionary = {}
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
var _actor_actions: Dictionary = {}
var _actor_facing: Dictionary = {}
var _last_cosmetic_frame := -1
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
    _actor_facing[actor_id] = 1 if int(to_data[0]) >= int(from_data[0]) else -1
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
    var source_actor: String = str(event.get("actor_id", ""))
    var target_actor: String = str(event.get("target_id", ""))
    if kind in ["hit", "miss"] and engine.actors.has(source_actor):
        if engine.actors.has(target_actor):
            _actor_facing[source_actor] = 1 if engine.actors[target_actor]["position"].x >= engine.actors[source_actor]["position"].x else -1
        _actor_actions[source_actor] = {"state": "melee", "start_ms": maxi(Time.get_ticks_msec(), int(_last_motion_end.get(source_actor, 0)))}
        if kind == "hit":
            _actor_actions[target_actor] = {"state": "hit", "start_ms": Time.get_ticks_msec()}
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
        _actor_actions[source_id] = {"state": "ranged", "start_ms": start_time}
        _actor_actions.erase(target_id)
        _projectiles.append({
            "action_id": str(event.get("action_id", "")),
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
        "action_id": str(event.get("action_id", "")),
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
    _actor_actions.clear()
    _actor_facing.clear()
    inspected_cell = Vector2i(-1, -1)
    set_process(false)
    queue_redraw()


func _process(_delta: float) -> void:
    var now := Time.get_ticks_msec()
    for i in range(_projectiles.size() - 1, -1, -1):
        var projectile: Dictionary = _projectiles[i]
        if now - int(projectile["start_ms"]) >= PROJECTILE_DURATION_MS:
            _effects.append({
                "action_id": str(projectile.get("action_id", "")),
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
            _actor_actions[str(projectile.get("target_id", ""))] = {"state": "hit", "start_ms": now}
            _projectiles.remove_at(i)
    for i in range(_movement_queue.size() - 1, -1, -1):
        var motion: Dictionary = _movement_queue[i]
        if now >= int(motion["start_ms"]) + int(motion["duration_ms"]):
            _movement_queue.remove_at(i)
    for i in range(_effects.size() - 1, -1, -1):
        if now - int(_effects[i]["start_ms"]) >= EFFECT_DURATION_MS:
            _effects.remove_at(i)
    # Bounded cosmetic loops; no particle nodes, random rolls or simulation writes.
    var frame: int = now / 83
    if frame != _last_cosmetic_frame or not _movement_queue.is_empty() or not _projectiles.is_empty() or not _effects.is_empty():
        _last_cosmetic_frame = frame
        queue_redraw()
    if engine == null:
        set_process(false)


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


func _draw_effects(labels_only: bool = false) -> void:
    var now := Time.get_ticks_msec()
    for effect in _effects:
        var age: float = float(now - int(effect["start_ms"])) / float(EFFECT_DURATION_MS)
        var progress: float = clampf(age, 0.0, 1.0)
        var kind: String = str(effect["kind"])
        var cell: Vector2i = effect["cell"]
        var center := Vector2(cell * CELL_SIZE) + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
        var tint: Color = _effect_color(kind, str(effect.get("damage_type", "")))
        tint.a = 1.0 - progress
        if not labels_only:
            var effect_name: String = _effect_art(effect)
            _draw_vfx(effect_name, Rect2(center - Vector2(32, 32), Vector2(64, 64)), mini(3, int(progress * 4.0)), Color(1, 1, 1, 1.0 - progress * 0.65))
            continue
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
        var action: String = str(projectile.get("action_id", ""))
        var effect_name := "arrow"
        if str(projectile.get("source_kind", "")) == "spell":
            effect_name = {"fire_bolt": "fire_bolt", "ray_of_frost": "frost", "magic_missile": "magic_missile"}.get(action, "magic_missile")
        elif action == "sling":
            effect_name = "sling"
        var scale_factor := float(display_cell_size) * camera_zoom / float(CELL_SIZE)
        draw_set_transform(camera_offset + pos * scale_factor, direction.angle(), Vector2.ONE * scale_factor)
        _draw_vfx(effect_name, Rect2(-32, -32, 64, 64), (age_ms / 90) % 4)
        _board_transform()


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
    camera_gesture.emit()
    camera_offset += delta
    _clamp_camera()
    queue_redraw()


func zoom_at(focal_point: Vector2, magnification: float) -> void:
    camera_gesture.emit()
    if magnification <= 0.0:
        return
    var next_zoom: float = clampf(camera_zoom * magnification, MIN_ZOOM, MAX_ZOOM)
    var ratio := next_zoom / camera_zoom
    camera_offset = focal_point - (focal_point - camera_offset) * ratio
    camera_zoom = next_zoom
    _clamp_camera()
    queue_redraw()


func reset_camera() -> void:
    camera_gesture.emit()
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


func _board_transform() -> void:
    draw_set_transform(camera_offset, 0.0, Vector2.ONE * (float(display_cell_size) * camera_zoom / float(CELL_SIZE)))


func _draw() -> void:
    if engine == null:
        return
    set_process(true)
    _board_transform()
    _draw_terrain()
    _draw_ground()
    _draw_contact_shadows()
    for entry in render_entries():
        if entry["kind"] == "actor":
            _draw_actor(str(entry["id"]))
        else:
            _draw_obstacle(entry["prop"])
    _draw_wall_foreground()
    _draw_environment()
    _draw_projectiles()
    _draw_effects()
    _draw_tactical()
    for actor_id in engine.actors:
        _draw_actor(str(actor_id), true)
    _draw_effects(true)


func render_entries() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    if engine == null:
        return entries
    for prop in engine.obstacles:
        entries.append({"kind": "prop", "id": str(prop.get("id", "")), "anchor": Art.prop_anchor(prop), "prop": prop})
    for actor_id in engine.actors:
        var cell: Vector2 = _render_actor_cell(str(actor_id), engine.actors[actor_id]["position"])
        entries.append({"kind": "actor", "id": str(actor_id), "anchor": cell + Vector2(0.5, 0.90)})
    entries.sort_custom(Art.depth_before)
    return entries


func _draw_terrain() -> void:
    var terrain: Texture2D = _texture_for(TERRAIN_ATLAS)
    for y in range(engine.grid_size.y):
        for x in range(engine.grid_size.x):
            var cell := Vector2i(x, y)
            var dest := Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
            var hash_value: int = posmod(x * 7919 + y * 104729 + x * y * 31, 101)
            var tile: int = hash_value % 3
            if hash_value > 88:
                tile = 3 + hash_value % 5
            draw_texture_rect_region(terrain, dest, Rect2(tile * 32, 0, 32, 32))
            draw_rect(dest, Color("#141b23", 0.40), false, 1.0)


func _draw_ground() -> void:
    var decals: Texture2D = _texture_for(Art.ROOT + "decals.png")
    for y in range(engine.grid_size.y):
        for x in range(engine.grid_size.x):
            var cell := Vector2i(x, y)
            var dest := Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
            if cell in engine.difficult_terrain:
                draw_texture_rect_region(decals, dest, Rect2(128, 0, 32, 32))
            for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
                if cell not in engine.walls and cell + direction in engine.walls:
                    var index: int = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT].find(direction)
                    draw_texture_rect_region(decals, dest, Rect2(index * 32, 0, 32, 32))
            if engine.has_area_effect_at(cell):
                _draw_vfx("burning_web" if engine.is_web_burning(cell) else "web", dest, _loop_frame(cell))


func draw_ellipse_shadow(dest: Rect2) -> void:
    draw_style_box(_shadow_style(), Rect2(dest.position + Vector2(dest.size.x * 0.14, dest.size.y * 0.83), Vector2(dest.size.x * 0.72, dest.size.y * 0.12)))


func _shadow_style() -> StyleBoxFlat:
    # Cached once; rounded contact shadow remains below the actual artwork.
    if not has_meta("contact_shadow"):
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.025, 0.035, 0.05, 0.48)
        style.set_corner_radius_all(12)
        set_meta("contact_shadow", style)
    return get_meta("contact_shadow")


func _draw_contact_shadows() -> void:
    for prop in engine.obstacles:
        draw_ellipse_shadow(Art.prop_rect(prop, CELL_SIZE))
    for actor in engine.actors.values():
        var cell: Vector2 = _render_actor_cell(str(actor["id"]), actor["position"])
        draw_ellipse_shadow(Rect2(cell * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE)))
    for hazard in engine.hazards:
        var dest := Rect2(Vector2(hazard["position"] * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
        var image: Texture2D = _texture_for(Art.ROOT + "campfire.png")
        draw_texture_rect(image, Rect2(dest.position - Vector2(0, CELL_SIZE * 0.25), Vector2(CELL_SIZE, CELL_SIZE * 1.25)), false)


func _occludes_actor(rect: Rect2, ground_y: float) -> bool:
    for actor in engine.actors.values():
        var cell: Vector2 = _render_actor_cell(str(actor["id"]), actor["position"])
        if cell.y + 0.90 < ground_y and rect.intersects(Rect2(cell * CELL_SIZE + Vector2(10, 4), Vector2(48, 60))):
            return true
    return false


func _draw_obstacle(prop: Dictionary) -> void:
    var kind: String = Art.prop_kind(prop)
    var path: String = Art.ROOT + kind + ".png" if not kind.is_empty() else str(prop.get("art", "")).trim_prefix("res://")
    var sprite: Texture2D = _texture_for(path)
    var dest: Rect2 = Art.prop_rect(prop, CELL_SIZE)
    var alpha := 0.42 if _occludes_actor(dest, Art.prop_anchor(prop).y) else 1.0
    if sprite != null:
        draw_texture_rect(sprite, dest, false, Color(1, 1, 1, alpha))
    else:
        draw_rect(dest, Color("#65503a", alpha))


func _draw_wall_foreground() -> void:
    var walls: Texture2D = _texture_for(Art.ROOT + "walls.png")
    for cell in engine.walls:
        var dest := Rect2(Vector2(cell * CELL_SIZE) - Vector2(0, CELL_SIZE * 0.5), Vector2(CELL_SIZE, CELL_SIZE * 1.5))
        var mask: int = Art.wall_mask(cell, engine.walls)
        var alpha := 0.38 if _occludes_actor(dest, float(cell.y) + 1.0) else 1.0
        draw_texture_rect_region(walls, dest, Rect2(mask * 32, 0, 32, 48), Color(1, 1, 1, alpha))


func _loop_frame(cell: Vector2i) -> int:
    return (Time.get_ticks_msec() / 140 + cell.x * 3 + cell.y * 7) % 4


func _draw_vfx(effect_name: String, dest: Rect2, frame: int, tint: Color = Color.WHITE) -> void:
    var row: int = Art.VFX_ROWS.find(effect_name)
    if row < 0:
        return
    draw_texture_rect_region(_texture_for(Art.ROOT + "vfx.png"), dest, Rect2(posmod(frame, 4) * 32, row * 32, 32, 32), tint)


func _draw_fire(cell: Vector2i) -> void:
    var frame: int = _loop_frame(cell)
    var base := Vector2(cell * CELL_SIZE)
    var pulse: float = 0.045 + float(frame % 2) * 0.015
    draw_circle(base + Vector2(34, 43), 30, Color(0.95, 0.52, 0.18, pulse))
    _draw_vfx("flame", Rect2(base - Vector2(0, 12), Vector2(68, 68)), frame)
    _draw_vfx("ember", Rect2(base - Vector2(0, 36), Vector2(68, 68)), frame)
    _draw_vfx("smoke", Rect2(base - Vector2(0, 68), Vector2(68, 68)), frame)


func _draw_environment() -> void:
    for hazard in engine.hazards:
        _draw_fire(hazard["position"])
    for prop in engine.obstacles:
        if not engine.burning_snapshot("prop", str(prop.get("id", ""))).is_empty():
            _draw_fire(prop["position"])
    for y in range(engine.grid_size.y):
        for x in range(engine.grid_size.x):
            var cell := Vector2i(x, y)
            if engine.is_web_burning(cell):
                _draw_fire(cell)
    for actor_id in engine.actors:
        var actor: Dictionary = engine.actors[actor_id]
        var draw_cell: Vector2 = _render_actor_cell(str(actor_id), actor["position"])
        var dest := Rect2(draw_cell * CELL_SIZE, Vector2(68, 68))
        if not engine.burning_snapshot("actor", str(actor_id)).is_empty():
            _draw_vfx("flame", dest, _loop_frame(actor["position"]))
        if not str(actor.get("blessed_by", "")).is_empty():
            _draw_vfx("bless", dest, _loop_frame(actor["position"]))
        if not actor.get("concentration", {}).is_empty():
            _draw_vfx("arcane", dest, _loop_frame(actor["position"]), Color(1, 1, 1, 0.65))
        if bool(actor.get("mage_armor_active", false)) or int(actor.get("shield_bonus", 0)) > 0:
            _draw_vfx("shield", dest, _loop_frame(actor["position"]), Color(1, 1, 1, 0.65))


func _effect_art(effect: Dictionary) -> String:
    var action: String = str(effect.get("action_id", ""))
    if str(effect.get("kind", "")) == "heal":
        return "healing"
    if action == "bless":
        return "bless"
    if action in ["mage_armor", "shield"]:
        return "shield"
    match str(effect.get("damage_type", "")):
        "fire": return "flame"
        "cold": return "frost"
        "force": return "magic_missile"
        "radiant": return "radiant"
    if str(effect.get("damage_type", "")) == "slashing" and str(effect.get("kind", "")) == "hit":
        return "slash"
    return "arcane" if str(effect.get("kind", "")) == "cast" else "impact"


func _draw_monster(actor: Dictionary, dest: Rect2, active: bool) -> bool:
    var species: String = Art.monster(actor)
    if species.is_empty():
        return false
    var actor_id: String = str(actor["id"])
    var state := "idle" if active else "defeated"
    var elapsed: int = Time.get_ticks_msec()
    var ranged := false
    for attack in actor.get("attacks", []):
        ranged = ranged or str(attack.get("kind", "")) == "ranged_weapon"
    ranged = ranged and species in ["goblin", "kobold"]
    if active:
        var action: Dictionary = _actor_actions.get(actor_id, {})
        var age: int = elapsed - int(action.get("start_ms", 0))
        if not action.is_empty() and age >= 0 and age < 340:
            state = str(action["state"])
            if state == "ranged" and not ranged:
                state = "melee"
            elapsed = age
        for motion in _movement_queue:
            if str(motion["actor_id"]) == actor_id and Time.get_ticks_msec() >= int(motion["start_ms"]):
                state = "walk"
                elapsed = Time.get_ticks_msec()
                break
    if state == "melee":
        ranged = false
    var source: Rect2 = Art.monster_region(state, elapsed, int(_actor_facing.get(actor_id, -1)), ranged)
    var art_scale := 1.75
    var ground_contact := dest.position - Vector2(2, 2) + Vector2(34, CELL_SIZE * 0.90)
    var sprite_rect := Rect2(ground_contact - Vector2(24, 41) * art_scale, Vector2(48, 48) * art_scale)
    draw_texture_rect_region(_texture_for(Art.ROOT + species + ".png"), sprite_rect, source)
    return true


func _draw_actor(actor_id_value: String, labels_only: bool = false) -> void:
    var actor: Dictionary = engine.actors[actor_id_value]
    var cell: Vector2i = actor["position"]
    var actor_id: String = str(actor["id"])
    var draw_cell: Vector2 = _render_actor_cell(actor_id, cell)
    var cell_origin: Vector2 = draw_cell * CELL_SIZE
    var dest := Rect2(cell_origin + Vector2(2, 2), Vector2(64, 64))
    var held: Dictionary = _pending_fatal_projectile(actor_id)
    var active: bool = engine.is_combat_capable(actor_id_value) or not held.is_empty()
    if labels_only:
        _draw_actor_labels(actor, cell_origin, dest, held, active)
        return
    var drawn: bool = _draw_monster(actor, dest, active)
    var downed: Texture2D = _texture_for(DOWNED_ATLAS)
    if not drawn and not active and downed != null:
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




func _draw_actor_labels(actor: Dictionary, cell_origin: Vector2, dest: Rect2, held: Dictionary, active: bool) -> void:
    var actor_id: String = str(actor["id"])
    if actor_id == engine.current_id() or (engine.deployment_active and actor_id == selected_deployment_actor):
        draw_rect(Rect2(cell_origin + Vector2(1, 1), Vector2(66, 66)), GOLD, false, 3.0)
    elif active:
        var team_color: Color = PARTY_BLUE if actor["team"] == "party" else ENEMY_RED
        draw_rect(Rect2(cell_origin + Vector2(1, 1), Vector2(66, 66)), team_color, false, 1.3)

    if not engine.burning_snapshot("actor", actor_id).is_empty():
        draw_rect(Rect2(cell_origin + Vector2(2, 47), Vector2(64, 17)), Color("#502512", 0.95))
        draw_string(get_theme_default_font(), cell_origin + Vector2(3, 60),
            "Burning", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fff2b0"))
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


func _draw_tactical() -> void:
    var highlights: Dictionary = get_highlights()
    for y in range(engine.grid_size.y):
        for x in range(engine.grid_size.x):
            var cell := Vector2i(x, y)
            var dest := Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
            if highlights["move"].has(cell) and cell != engine.current_actor()["position"]:
                draw_rect(dest.grow(-2), Color("#399bd5", 0.65), false, 2)
            if highlights["attack"].has(cell):
                draw_rect(dest.grow(-2), Color("#f77869"), false, 2)
            if highlights["spell"].has(cell):
                draw_rect(dest.grow(-2), GOLD, false, 2)
            if engine.deployment_active and not selected_deployment_actor.is_empty() and engine.can_place_character(selected_deployment_actor, cell):
                draw_rect(dest.grow(-3), Color("#65b3df", 0.65), false, 1.5)
            if area_shape.get("nominal_cells", []).has(cell):
                var affected: bool = area_shape.get("affected_cells", []).has(cell)
                var color := Color("#62edbb") if area_preview_valid and affected else Color("#ff706e")
                draw_rect(dest.grow(-6), Color(color, 0.13))
                draw_rect(dest.grow(-6), color, false, 3)
                draw_string(ThemeDB.fallback_font, dest.position + Vector2(6, 38), "WEB" if affected else "BLOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
                if cell == area_preview:
                    draw_circle(dest.get_center(), 7, Color.WHITE, false, 2)
    if inspected_cell.x >= 0 and inspected_cell.y >= 0:
        draw_rect(Rect2(Vector2(inspected_cell * CELL_SIZE) + Vector2(3, 3), Vector2(62, 62)), Color("#faf0c1"), false, 2.5)
    if has_focus():
        draw_rect(Rect2(Vector2(keyboard_cell * CELL_SIZE) + Vector2(2, 2), Vector2(64, 64)), Color("#f0da86"), false, 3)


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
        if selected_spell == "web":
            return indicators
        if selected_spell == "fire_bolt":
            for effect in engine.active_effects.values():
                for cell in effect["cells"]:
                    if engine.fire_bolt_cell_reason(cell).is_empty():
                        indicators["spell"][cell] = true
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
            KEY_ESCAPE:
                cancel_targeting.emit()
                accept_event()
                return
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
