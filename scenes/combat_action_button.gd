extends Button
## Draw a clear diagonal strike-through over exhausted combat actions.
## Disabled-but-not-exhausted buttons stay grey without the strike.

var crossed_out := false:
    set(value):
        crossed_out = value
        queue_redraw()


func _draw() -> void:
    if not crossed_out:
        return
    var ink := Color("#e76c64", 0.92)
    draw_line(Vector2(7, 5), Vector2(size.x - 7, size.y - 5), ink, 3.0, true)
    draw_line(Vector2(7, size.y - 5), Vector2(size.x - 7, 5), ink, 2.0, true)
