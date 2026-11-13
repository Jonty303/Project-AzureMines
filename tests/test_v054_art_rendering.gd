extends SceneTree
const Art = preload("res://combat/combat_art.gd")
const Scene = preload("res://scenes/combat.tscn")
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/combat_v054/manifest.json"))
    var checked_frames := 0
    for name in manifest["assets"]:
        var meta: Dictionary = manifest["assets"][name]
        var imported: Texture2D = load("res://assets/combat_v054/" + str(meta["file"]))
        check(imported != null, "Decode " + name)
        var image: Image = imported.get_image()
        check(image.get_size() == Vector2i(int(meta["size"][0]), int(meta["size"][1])), "Dimensions " + name)
        var frame_size: Array = meta.get("frame_size", meta["size"])
        var fw: int = int(frame_size[0])
        var fh: int = int(frame_size[1])
        for fy in range(0, image.get_height(), fh):
            for fx in range(0, image.get_width(), fw):
                check(not image.get_region(Rect2i(fx, fy, fw, fh)).is_invisible(), "Nonempty frame " + name)
                checked_frames += 1
        if meta.has("animations"):
            var pivot: Array = meta["pivot"]
            check(int(pivot[0]) < fw and int(pivot[1]) < fh, "Pivot inside box " + name)
            for fy in range(0, image.get_height(), fh):
                for fx in range(0, image.get_width(), fw):
                    for i in range(fw):
                        check(image.get_pixel(fx + i, fy).a == 0 and image.get_pixel(fx + i, fy + fh - 1).a == 0, "No vertical clip " + name)
                    for i in range(fh):
                        check(image.get_pixel(fx, fy + i).a == 0 and image.get_pixel(fx + fw - 1, fy + i).a == 0, "No horizontal clip " + name)
    check(checked_frames == 249, "Every production frame validated")
    var terrain_texture: Texture2D = load("res://assets/combat_v054/terrain.png")
    var terrain: Image = terrain_texture.get_image()
    for a in range(8):
        for b in range(8):
            for i in range(32):
                check(terrain.get_pixel(a * 32, i) == terrain.get_pixel(b * 32 + 31, i), "Horizontal floor seam")
                check(terrain.get_pixel(a * 32 + i, 0) == terrain.get_pixel(b * 32 + i, 31), "Vertical floor seam")
    var lab: Node = Scene.instantiate()
    root.add_child(lab)
    await process_frame
    lab.call("_start_battle")
    var board = lab.get("board")
    var engine = lab.get("engine")
    check(Art.PASSES.find("ground") < Art.PASSES.find("ground_y"), "Web must remain under feet")
    check(Art.PASSES.find("environment") < Art.PASSES.find("projectiles"), "Projectiles above smoke/props")
    check(Art.PASSES.find("projectiles") < Art.PASSES.find("impacts"), "Impact compositing")
    check(Art.PASSES.find("impacts") < Art.PASSES.find("tactical"), "Tactical outlines above effects")
    check(Art.PASSES.find("tactical") < Art.PASSES.find("labels"), "Labels on top")
    var wagon := {"id": "wagon", "kind": "wagon", "position": Vector2i(5, 3), "size": Vector2i(3, 2)}
    var stone := {"id": "east_stone", "kind": "boulder", "position": Vector2i(13, 4), "size": Vector2i(1, 2)}
    var chest := {"id": "chest", "kind": "chest", "position": Vector2i(4, 5), "size": Vector2i(1, 1)}
    check(Art.prop_anchor(wagon).is_equal_approx(Vector2(6.5, 4.9)), "Wagon ground contact uses full footprint")
    check(Art.prop_anchor(stone).is_equal_approx(Vector2(13.5, 5.9)), "1x2 stone uses lower contact")
    check(Art.prop_rect(chest, 68).size.y < 100, "Chest remains low half cover")
    var prop_entry := {"kind": "prop", "id": "wagon", "anchor": Art.prop_anchor(wagon)}
    check(Art.depth_before({"kind": "actor", "id": "behind", "anchor": Vector2(6.5, 3.9)}, prop_entry), "Actor behind wagon")
    check(Art.depth_before(prop_entry, {"kind": "actor", "id": "front", "anchor": Vector2(6.5, 5.9)}), "Actor in front of wagon")
    check(Art.depth_before({"kind": "actor", "id": "a", "anchor": Vector2.ONE}, {"kind": "actor", "id": "b", "anchor": Vector2.ONE}), "Stable ID tie breaker")
    for scale in [0.65, 1.0, 1.6]:
        board.camera_zoom = scale
        board.camera_offset = Vector2(-25, -12)
        var point: Vector2 = (Vector2(5, 4) + Vector2(0.5, 0.5)) * board.display_cell_size * scale + board.camera_offset
        check(board._cell_from_position(point) == Vector2i(5, 4), "Shared transform at zoom " + str(scale))
    # Real board planner uses rendered movement positions; never texture top Y.
    engine.obstacles.clear()
    engine.obstacles.append_array([wagon, stone, chest])
    engine.actors["alden"]["position"] = Vector2i(6, 3)
    var entries: Array = board.render_entries()
    var actor_index := -1
    var wagon_index := -1
    for i in range(entries.size()):
        if entries[i]["id"] == "alden": actor_index = i
        if entries[i]["id"] == "wagon": wagon_index = i
    check(actor_index >= 0 and actor_index < wagon_index, "Real board sorts behind wagon")
    check(board._occludes_actor(Art.prop_rect(wagon, 68), Art.prop_anchor(wagon).y), "Occluded actor forces prop fade")
    engine.actors["alden"]["position"] = Vector2i(6, 5)
    entries = board.render_entries()
    for i in range(entries.size()):
        if entries[i]["id"] == "alden": actor_index = i
        if entries[i]["id"] == "wagon": wagon_index = i
    check(actor_index > wagon_index, "Real board sorts in front of wagon")
    check(Art.monster({"id": "alden", "team": "party", "name": "Goblin disguise"}).is_empty(), "Party never animates")
    for species in ["goblin", "kobold", "bugbear", "spider", "skeleton"]:
        var frames: SpriteFrames = load("res://assets/combat_v054/" + species + ".tres")
        check(frames != null, "Native SpriteFrames " + species)
        for facing in ["left", "right"]:
            for state in ["idle", "walk", "melee", "hit", "defeated"]:
                check(frames.has_animation("melee_" + facing + "_" + state), species + " state " + facing + " " + state)
        var texture: Texture2D = load("res://assets/combat_v054/" + species + ".png")
        check(texture.get_width() % 48 == 0 and texture.get_height() % 48 == 0, "Fixed frame boxes")
    check(Art.monster_region("walk", 210, -1, false).position.x == 192, "Third walk frame reachable")
    check(Art.monster_region("melee", 200, 1, false).position.x == 288, "Second melee frame")
    check(Art.wall_mask(Vector2i(1, 1), [Vector2i(1, 0), Vector2i(2, 1)]) == 3, "Wall corner mask")
    check(Art.wall_mask(Vector2i(1, 1), []) == 0, "Isolated wall end mask")
    # Audio lifetime is covered by the existing impact test; avoid starting audio during this visual contract.
    board.projectile_impact.disconnect(lab._on_projectile_impact)
    var victim := "lab_skeleton_01"
    engine.actors[victim]["hp"] = 0
    engine.actors[victim]["combat_state"] = "dead"
    board.enqueue_combat_event({"kind": "hit", "actor_id": "elyra", "target_id": victim, "action_id": "fire_bolt", "source_kind": "spell", "damage_type": "fire", "source_cell": [1, 5], "target_cell": [9, 3], "hp_before": 7, "state_after": "dead"})
    check(not board._pending_fatal_projectile(victim).is_empty(), "Defeated sprite waits for impact")
    check(str(board._projectiles[0].get("action_id", "")) == "fire_bolt", "Projectile retains effect identity")
    board._projectiles[0]["start_ms"] = Time.get_ticks_msec() - 500
    board._process(0.5)
    check(board._pending_fatal_projectile(victim).is_empty(), "Impact releases defeated sprite")
    check(board._effects[0].get("action_id", "") == "fire_bolt", "Impact retains spell identity")
    board.reset_presentation()
    check(board._actor_actions.is_empty() and board._actor_facing.is_empty(), "Retry clears animation state")
    for player in lab.get("sfx_players").values():
        player.stop()
    await process_frame
    lab.queue_free()
    await process_frame
    if failures.is_empty():
        print("PASS: v054 assets, native animations, contact-Y, wagon front/back, boulder, chest, wall corners, zoom, occlusion and impact/death contract")
        quit(0)
    else:
        for message in failures: printerr("FAIL: " + message)
        quit(1)
