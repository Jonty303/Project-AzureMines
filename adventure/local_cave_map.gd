extends Control
## Discovered cave locations only. Map knowledge is owned by CampaignState.
var campaign: RefCounted
var nodes: Dictionary = {}
const PAPER := Color("#d1b98c")
const INK := Color("#4b392c")
const PATH_INK := Color("#6d563e")
const POSITION := {
    "cave_approach": Vector2(110, 350),
    "watchpost_tree": Vector2(144, 160),
    "cave_entrance": Vector2(248, 352),
    "cave_threshold": Vector2(348, 352),
    "cave_corridor": Vector2(473, 350),
    "cave_rubbish": Vector2(462, 165),
    "cave_guardroom": Vector2(641, 177),
    "cave_common": Vector2(675, 294),
    "cave_waterfall": Vector2(685, 478),
    "cave_bugbear_outer": Vector2(488, 521)
}
const LINKS := [
    ["cave_approach", "watchpost_tree"],
    ["cave_approach", "cave_entrance"],
    ["cave_entrance", "cave_threshold"],
    ["cave_threshold", "cave_corridor"],
    ["cave_corridor", "cave_rubbish"],
    ["cave_corridor", "cave_guardroom"],
    ["cave_corridor", "cave_common"],
    ["cave_corridor", "cave_waterfall"],
    ["cave_corridor", "cave_bugbear_outer"]
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
    draw_string(font, Vector2(26, 35), "THE GOBLIN CAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
    draw_string(font, Vector2(26, 57), "An explorer's rough sketch - unvisited chambers are blank", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    var scale := Vector2(size.x / 816.0, size.y / 680.0)
    draw_line(Vector2(218, 218) * scale, Vector2(228, 474) * scale, Color("#8d7d68"), 12.0, true)
    for pair in LINKS:
        if not _known(str(pair[0])) or not _known(str(pair[1])):
            continue
        var begin: Vector2 = POSITION[str(pair[0])] * scale
        var finish: Vector2 = POSITION[str(pair[1])] * scale
        draw_line(begin, finish, PATH_INK, 4.0, true)
        draw_dashed_line(begin, finish, Color("#e8d6ad"), 1.0, 8.0)
    for id in POSITION.keys():
        if not _known(str(id)):
            continue
        var here: Vector2 = POSITION[str(id)] * scale
        var visited: bool = campaign.visited.has(id)
        draw_circle(here, 13 if visited else 9, INK if visited else Color("#8d674c"))
        draw_circle(here, 8 if visited else 5, PAPER)
        if id == campaign.current_location:
            draw_arc(here, 19, 0, TAU, 32, Color("#9f4433"), 3)
        draw_string(font, here + Vector2(17, -11), _label(str(id)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
        draw_string(font, here + Vector2(-5, 5), "X" if visited else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    var notes: PackedStringArray = []
    if campaign.flags.get("watchpost_spotted", false):
        notes.append("Lookout: two goblin sentries")
    if campaign.flags.get("watchpost_admitted_under_guard", false):
        notes.append("Watchpost: cautious entry granted; not allies")
    elif campaign.flags.get("watchpost_parley_failed", false):
        notes.append("Watchpost: negotiation failed")
    if campaign.flags.get("watchpost_alarm_raised", false):
        notes.append("ALARM: tree watchpost raised a warning")
    elif str(campaign.flags.get("goblin_lair_readiness", "")) == "alerted":
        notes.append("Earlier warning: cave may be prepared")
    if campaign.flags.get("rubbish_shaft_noticed", false):
        notes.append("Refuse shaft: depth and destination unknown")
    if campaign.flags.get("waterfall_tunnel_noted", false):
        notes.append("Waterfall: guarded tunnel towards commander")
    for n in range(mini(notes.size(), 4)):
        draw_string(font, Vector2(26, size.y - 95 + n * 20), notes[n], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
    draw_string(font, Vector2(size.x - 92, 34), "N ^", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)


func _known(id: String) -> bool:
    if id == "watchpost_tree":
        return bool(campaign.flags.get("watchpost_spotted", false))
    return campaign.knows_location(id)


func _label(id: String) -> String:
    match id:
        "cave_approach":
            return "Woods"
        "watchpost_tree":
            return "Watchpost"
        "cave_entrance":
            return "Entrance"
        "cave_threshold":
            return "First passage"
        "cave_corridor":
            return "Main corridor"
        "cave_rubbish":
            return "Refuse"
        "cave_guardroom":
            return "Guardroom"
        "cave_common":
            return "Common cave"
        "cave_waterfall":
            return "Waterfall"
        "cave_bugbear_outer":
            return "Chief's passage"
    return id
