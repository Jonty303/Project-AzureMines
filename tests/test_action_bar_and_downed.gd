extends SceneTree
## Regression coverage for combat UI v0.3: downed actors and action bar.

const CombatEngine = preload("res://combat/combat_engine.gd")
const CombatScene = preload("res://scenes/combat.tscn")


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var battle = CombatEngine.new()
    if not battle.start(733):
        _fail("Unable to start fixed tutorial encounter")
        return

    battle.turn_index = battle.turn_order.find("alden")
    battle._begin_turn()
    var previous_reach: int = battle.get_reachable("alden").size()
    if not battle.use_dash():
        _fail("Alden could not Dash")
        return
    if not battle.action_used or battle.dash_extra_squares != 6:
        _fail("Dash did not use Action and grant six extra squares")
        return
    if battle.get_reachable("alden").size() <= previous_reach:
        _fail("Dash did not expand legal movement")
        return
    if battle.use_dodge():
        _fail("Dodge was possible after Dash used Action")
        return

    battle._begin_turn()
    if not battle.use_dodge() or not battle.actors["alden"]["dodging"]:
        _fail("Dodge action did not set its defence state")
        return
    battle._begin_turn()
    if battle.actors["alden"]["dodging"]:
        _fail("Dodge was not removed at start of the next turn")
        return

    # Downed party characters stay on the map and remain valid healing targets.
    var alden: Dictionary = battle.actors["alden"]
    alden["hp"] = 0
    alden["combat_state"] = "unconscious"
    battle.actors["alden"] = alden
    if battle.target_at(alden["position"]) != "alden":
        _fail("Unconscious Alden is not selectable for healing")
        return

    battle.turn_index = battle.turn_order.find("brunna")
    battle._begin_turn()
    if not battle.can_cast_spell("healing_word", "alden"):
        _fail("Brunna cannot target downed Alden with Healing Word")
        return
    if not battle.cast_spell("healing_word", "alden"):
        _fail("Healing Word failed")
        return
    if int(battle.actors["alden"]["hp"]) <= 0 or battle.actors["alden"]["combat_state"] != "active":
        _fail("Healing did not restore Alden to the active state")
        return

    var goblin: Dictionary = battle.actors["goblin_blade"]
    goblin["hp"] = 0
    goblin["combat_state"] = "dead"
    battle.actors["goblin_blade"] = goblin
    if battle.target_at(goblin["position"]) == "goblin_blade":
        _fail("Dead goblins should not intercept tactical targeting")
        return

    var downed_atlas := Image.new()
    if downed_atlas.load("res://assets/characters/sprites/downed_party_atlas_64.png") != OK:
        _fail("Downed atlas cannot be decoded")
        return
    if downed_atlas.get_width() != 320 or downed_atlas.get_height() != 64:
        _fail("Downed atlas must be five 64px frames")
        return

    var prop_atlas := Image.new()
    if prop_atlas.load("res://assets/environment/dungeon_props_64.png") != OK:
        _fail("Prop atlas cannot be decoded")
        return
    if prop_atlas.get_width() != 192 or prop_atlas.get_height() != 64:
        _fail("Expected three 64px props")
        return

    if not ResourceLoader.exists("res://assets/environment/dungeon_tiles_64.svg"):
        _fail("Stone tile atlas is missing")
        return

    var scene_root: Node = CombatScene.instantiate()
    root.add_child(scene_root)
    await process_frame
    await process_frame
    for name in ["board", "attack_button", "move_button", "spells_button",
            "second_wind_button", "dash_button", "dodge_button", "end_turn_button"]:
        if scene_root.get(name) == null:
            _fail("Action-bar UI is missing %s" % name)
            return
    var board: Control = scene_root.get("board")
    board.queue_redraw()
    await process_frame

    print("PASS: downed assets, healing, dead targeting, Dash/Dodge and action-bar scene")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
