extends SceneTree
const Builder = preload("res://combat_lab/setup_builder.gd")
const CombatEngine = preload("res://combat/combat_engine.gd")
const Level1Spells = preload("res://combat/level1_spells.gd")

func _initialize() -> void:
    var bad: Dictionary = Builder.build_setup(0, "thief", "wolf", 1, "stone", 10)
    if not bad.is_empty() or not Builder.build_setup(1, "thief", "wolf", 9, "stone", 10).is_empty():
        _fail("Invalid level or count was accepted")
        return
    var baseline: Dictionary = Builder.build_setup(1, "thief", "goblin_melee", 4, "camp", 42024)
    if baseline.is_empty() or baseline["encounter"]["enemies"].size() != 4:
        _fail("Could not build level-one combat setup")
        return
    var level_five: Dictionary = Builder.build_setup(5, "hunter", "wolf", 6, "stone", 500)
    if level_five.is_empty():
        _fail("Could not build level-five Hunter setup")
        return
    var party: Array = level_five["party"]["characters"]
    for hero in party:
        if int(hero["level"]) != 5 or int(hero["max_hp"]) <= 7:
            _fail("Level fixture did not change character state")
            return
    if party[3]["class_id"] != "hunter" or party[3]["id"] != "pip":
        _fail("Hunter test variant did not use the reserved fourth slot")
        return
    if not Level1Spells.known_spells(party[1]).has("fire_bolt") or not Level1Spells.known_spells(party[2]).has("bless"):
        _fail("Implemented class spells were not unlocked in the lab")
        return
    if not Level1Spells.known_spells(party[3]).has("cure_wounds"):
        _fail("Hunter test spell unavailable")
        return
    var seen: Dictionary = {}
    for enemy in level_five["encounter"]["enemies"]:
        var cell: Array = enemy["position"]
        var key := "%d,%d" % [int(cell[0]), int(cell[1])]
        if seen.has(key):
            _fail("Two enemies share a cell")
            return
        seen[key] = true
        if str(enemy.get("npc_id", "")) != "":
            _fail("Sandbox enemy retained a persistent narrative NPC identity")
            return
    var game := CombatEngine.new()
    if not game.start_from_setup(level_five, true):
        _fail("CombatEngine rejected valid custom setup")
        return
    if game.actors.size() != 10 or not game.deployment_active or game.actors["pip"]["class_id"] != "hunter":
        _fail("CombatEngine did not initialise configured parties and enemies")
        return
    if not game.begin_battle() or game.turn_order.size() != 10:
        _fail("Custom fixture could not start battle")
        return
    if game.start_from_setup({"schema_version": 0}):
        _fail("Invalid combat setup was accepted")
        return
    print("PASS: level 1-5 fixtures, class spell availability, Hunter test variant, enemy counts, validated combat setup")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
