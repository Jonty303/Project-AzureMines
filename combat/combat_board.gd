extends Control
## Static top-down battle board. The logic resides in CombatEngine.

signal cell_clicked(cell: Vector2i)

const CELL_SIZE := 44
const PARTY_BLUE := Color("#244b78")
const ENEMY_RED := Color("#9c4745")

var engine: RefCounted
var _sprite_cache: Dictionary = {}


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter = Control.MOUSE_FILTER_STOP
    custom_minimum_size = Vector2(12 * CELL_SIZE, 10 * CELL_SIZE)


func _draw() -> void:
    if engine == null:
        return
    var current := engine.current_id()
    var reachable: Dictionary = {}
    if engine.current_is_party():
        reachable = engine.get_reachable(current)
    for y in range(engine.grid_size.y):
        for x in range(engine.grid_size.x):
            var cell := Vector2i(x, y)
            var rect := Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
            var terrain_color := Color("#26313c")
            if cell in engine.walls:
                terrain_color = Color("#77808a")
            elif cell in engine.difficult_terrain:
                terrain_color = Color("#574b37")
            elif reachable.has(cell) and cell != engine.current_actor()["position"]:
                terrain_color = Color("#264c57")
            if (x + y) % 2 == 1 and not cell in engine.walls:
                terrain_color = terrain_color.lightened(0.07)
            draw_rect(rect, terrain_color)
            draw_rect(rect, Color("#536270"), false, 1.0)

    for id_variant in engine.actors.keys():
        var actor: Dictionary = engine.actors[id_variant]
        var cell: Vector2i = actor["position"]
        if int(actor["hp"]) <= 0:
            continue
        var rect := Rect2(Vector2(cell * CELL_SIZE) + Vector2(4, 4), Vector2(36, 36))
        if str(actor["id"]) == current:
            draw_rect(Rect2(Vector2(cell * CELL_SIZE) + Vector2(1, 1), Vector2(42, 42)), Color("#e3bf58"), false, 3.0)
        var art: Dictionary = actor.get("art", {})
        var path := str(art.get("combat_sprite", ""))
        var texture: Texture2D = _texture_for(path)
        if texture != null:
            draw_texture_rect(texture, rect, false)
        else:
            var is_party := actor["team"] == "party"
            draw_circle(rect.get_center(), 17.0, PARTY_BLUE if is_party else ENEMY_RED)
            var first_letter := str(actor["name"]).substr(0, 1)
            draw_string(get_theme_default_font(), rect.position + Vector2(6, 26), first_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
        # HP bar, red lost HP section and green remaining HP section.
        var bar := Rect2(Vector2(cell * CELL_SIZE) + Vector2(5, 39), Vector2(34, 3))
        draw_rect(bar, Color("#8d2f31"))
        var ratio := float(actor["hp"]) / float(maxi(1, int(actor["max_hp"])))
        draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, 3)), Color("#7bc36a"))


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
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var cell := Vector2i(
            floori(event.position.x / float(CELL_SIZE)),
            floori(event.position.y / float(CELL_SIZE))
        )
        if engine != null and cell.x >= 0 and cell.y >= 0:
            if cell.x < engine.grid_size.x and cell.y < engine.grid_size.y:
                cell_clicked.emit(cell)
