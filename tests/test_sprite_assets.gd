extends SceneTree
## Verify every runtime sprite resolves as a valid 64x64 PNG.

const IDS := ["alden", "elyra", "brunna", "pip", "goblin"]

func _initialize() -> void:
    for id in IDS:
        var path := "res://assets/characters/sprites/%s_front_64.png" % id
        var image := Image.new()
        var result: Error = image.load(path)
        if result != OK:
            _fail("Cannot decode image: " + path)
            return
        if image.get_width() != 64 or image.get_height() != 64:
            _fail("Expected 64x64 PNG: " + path)
            return
    print("PASS: five front-facing 64x64 combat sprites decoded")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
