extends Control
## Discovery-only local cave entrance map. No unvisited interior or lower shafts.
var campaign: RefCounted
var nodes: Dictionary = {}

const PAPER := Color("#d1b98c")
const INK := Color("#4b392c")
const PATH_INK := Color("#6d563e")
const CAVE_LOCATIONS := ["cave_approach", "watchpost_tree", "cave_entrance", "cave_threshold"]
const LINKS := [
    ["cave_approach", "watchpost_tree"],
    ["cave_approach", "cave_entrance"],
    ["cave_entrance", "cave_threshold"]
]


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
    if campaign == null:
        return
    draw_rect(Rect2(Vector2.ZERO, size), PAPER)
    for x in range(0, int(size.x), 24):
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#917d60", 0.23), 1)
    for y in range(0, int(size.y), 24):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color("#917d60", 0.23), 1)
    draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), INK, false, 3)
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(26, 35), "THE CAVE IN THE WOODS", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, INK)
    draw_string(font, Vector2(27, 56), "Field notes - rooms not yet explored remain blank", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    var scale := Vector2(size.x / 816.0, size.y / 680.0)
    var positions := {
        "cave_approach": Vector2(160, 330),
        "watchpost_tree": Vector2(198, 160),
        "cave_entrance": Vector2(404, 325),
        "cave_threshold": Vector2(617, 335)
    }

    # The cave mouth is drawn as a natural limestone edge, not a disclosed room map.
    var a: Vector2 = Vector2(360, 200) * scale
    var b: Vector2 = Vector2(380, 505) * scale
    draw_line(a, b, Color("#8d7d68"), 12.0, true)
    draw_line(a, b, INK, 2.0, true)
    for pair in LINKS:
        if not _known(str(pair[0])) or not _known(str(pair[1])):
            continue
        var begin: Vector2 = positions[str(pair[0])] * scale
        var finish: Vector2 = positions[str(pair[1])] * scale
        draw_line(begin, finish, PATH_INK, 4.0, true)
        draw_dashed_line(begin, finish, Color("#e8d6ad"), 1.0, 8.0)

    for id in CAVE_LOCATIONS:
        if not _known(id):
            continue
        var here: Vector2 = positions[id] * scale
        var visited: bool = bool(campaign.visited.get(id, false))
        draw_circle(here, 13 if visited else 10, INK if visited else Color("#8d674c"))
        draw_circle(here, 9 if visited else 6, PAPER)
        if id == campaign.current_location:
            draw_arc(here, 19, 0, TAU, 32, Color("#9f4433"), 3)
        draw_string(font, here + Vector2(18, -12), _label(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
        draw_string(font, here + Vector2(-5, 5), "X" if visited else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)

    if campaign.flags.get("watchpost_spotted", false):
        draw_string(font, Vector2(27, size.y - 102), "2 goblins - hidden lookout in trees", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    if campaign.flags.get("watchpost_alarm_raised", false):
        draw_string(font, Vector2(27, size.y - 75), "ALARM: watchpost sounded a warning", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#883b2b"))
    elif str(campaign.flags.get("goblin_lair_readiness", "")) == "alerted":
        draw_string(font, Vector2(27, size.y - 75), "CAUTION: cave may have been warned already", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    elif campaign.flags.get("watchpost_bypassed", false):
        draw_string(font, Vector2(27, size.y - 75), "Lookouts bypassed without an alarm", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    if campaign.visited.has("cave_threshold"):
        draw_string(font, Vector2(27, size.y - 45), "Beyond the first corridor: unexplored", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    draw_string(font, Vector2(size.x - 96, 34), "N ^", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)


func _known(id: String) -> bool:
    if id == "watchpost_tree":
        return bool(campaign.flags.get("watchpost_spotted", false))
    return campaign.knows_location(id)


func _label(id: String) -> String:
    match id:
        "cave_approach":
            return "Wooded approach"
        "watchpost_tree":
            return "Tree watchpost"
        "cave_entrance":
            return "Cave mouth"
        "cave_threshold":
            return "First passage"
    return id
