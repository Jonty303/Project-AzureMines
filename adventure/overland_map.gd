extends Control
## Parchment-style map of justified discoveries only; never reveals hidden locations.
var campaign: RefCounted
var nodes: Dictionary = {}
var routes := [
    ["wagon_clearing", "town_road"],
    ["town_road", "harrowford_guild"],
    ["town_road", "harrowford_market"],
    ["harrowford_guild", "harrowford_market"],
    ["wagon_clearing", "overgrown_track"],
    ["overgrown_track", "town_road"],
    ["overgrown_track", "cave_approach"]
]
const PAPER := Color("#c7ae83")
const INK := Color("#4c3d32")


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
    var bounds := Rect2(Vector2.ZERO, size)
    draw_rect(bounds, PAPER)
    for x in range(0, int(size.x), 22):
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color("#9c906e", 0.24), 1.0)
    for y in range(0, int(size.y), 22):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color("#9c906e", 0.24), 1.0)
    draw_rect(bounds.grow(-8), INK, false, 3.0)
    var font: Font = ThemeDB.fallback_font
    draw_string(font, Vector2(28, 38), "THE OLD TRADE ROAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
    draw_string(font, Vector2(28, 64), "A traveller's notes", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
    if campaign == null:
        return
    var scale_xy := Vector2(size.x / 816.0, size.y / 680.0)
    for pair in routes:
        if not campaign.knows_location(pair[0]) or not campaign.knows_location(pair[1]):
            continue
        if not nodes.has(pair[0]) or not nodes.has(pair[1]):
            continue
        var a: Vector2 = Vector2(nodes[pair[0]]["map_pos"][0], nodes[pair[0]]["map_pos"][1]) * scale_xy
        var b: Vector2 = Vector2(nodes[pair[1]]["map_pos"][0], nodes[pair[1]]["map_pos"][1]) * scale_xy
        draw_line(a, b, INK, 3.0, true)
        draw_dashed_line(a, b, Color("#e1d0ad"), 1.0, 9.0)
    for id_variant in nodes.keys():
        var id: String = str(id_variant)
        # Interior chambers belong only on the local dungeon chart.
        if (id.begins_with("cave_") and id != "cave_approach") or id == "watchpost_tree":
            continue
        if not campaign.knows_location(id):
            continue
        var node: Dictionary = nodes[id]
        var pos: Vector2 = Vector2(node["map_pos"][0], node["map_pos"][1]) * scale_xy
        var visited: bool = campaign.visited.has(id)
        draw_circle(pos, 12 if visited else 9, INK if visited else Color("#817155"))
        draw_circle(pos, 8 if visited else 5, Color("#e5d2a4"))
        if id == campaign.current_location:
            draw_arc(pos, 17, 0, TAU, 32, Color("#8d442e"), 3.0)
        draw_string(font, pos + Vector2(-5, 5), "X" if visited else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
        var title: String = str(node.get("title", id))
        draw_string(font, pos + Vector2(17, -10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
    if campaign.knows_location("overgrown_track"):
        draw_string(font, Vector2(32, size.y - 46), "ink note: tracks lead towards the ravine", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
    draw_string(font, Vector2(size.x - 103, 36), "N ^", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
