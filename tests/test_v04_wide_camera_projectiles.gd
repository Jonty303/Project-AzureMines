extends SceneTree
## v0.4: wide encounter, mixed illustrated enemies, direct selection and resolved projectiles.
const Builder = preload("res://combat_lab/setup_builder.gd")
const CombatEngine = preload("res://combat/combat_engine.gd")
const SCENE = preload("res://scenes/combat.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var setup: Dictionary = Builder.build_setup(2, "thief", "mixed", 8, "wide", 2026)
    if setup.is_empty() or setup["encounter"]["grid_size"][0] != 17:
        _fail("17-column mixed-encounter setup failed")
        return
    var seen: Dictionary = {}
    for enemy in setup["encounter"]["enemies"]:
        var art: String = str(enemy.get("art", {}).get("combat_sprite", ""))
        var species: String = str(enemy.get("id", "")).split("_")[1]
        seen[species] = true
        if art.is_empty() and species != "goblin":
            _fail("An illustrated new monster lacks its sprite: " + species)
            return
        if not art.is_empty() and not ResourceLoader.exists("res://" + art):
            _fail("A monster sprite cannot be loaded: " + art)
            return
    if seen.size() < 5:
        _fail("Mixed squad does not include five distinct combat roles")
        return
    var battle := CombatEngine.new()
    if not battle.start_from_setup(setup, false) or battle.grid_size != Vector2i(17, 10):
        _fail("Wide setup could not start the authoritative engine")
        return
    if battle.actors.size() != 12:
        _fail("Expected a four-person party and eight opponents")
        return

    var scene: Node = SCENE.instantiate()
    root.add_child(scene)
    await process_frame
    scene.call("_start_battle")
    var board = scene.get("board")
    if scene.get("engine").grid_size.x != 17:
        _fail("The default Combat Lab arena must be wide")
        return
    if scene.get("end_turn_button").icon == null:
        _fail("Large End Turn command lacks an icon")
        return
    if scene.get("end_turn_button").custom_minimum_size.y < 90:
        _fail("End Turn is not prominently sized")
        return
    scene.call("_begin_battle")
    var engine = scene.get("engine")
    engine.turn_index = engine.turn_order.find("elyra")
    engine._begin_turn()
    scene.set("picker_actor", "")
    scene.call("_refresh")
    var spell_strip = scene.get("spell_strip")
    if spell_strip.get_child_count() < 3:
        _fail("Caster spells were not presented as separate cards")
        return
    if scene.get("spell_scroll") == null or scene.get("weapon_strip") == null:
        _fail("Swipeable spell strip or weapon cards missing")
        return
    scene.call("_select_spell_card", "fire_bolt")
    if scene.call("_selected_spell") != "fire_bolt" or scene.get("action_mode") != "spell":
        _fail("Touch spell card did not select the correct implemented spell")
        return

    board.reset_presentation()
    board.engine = battle
    var first_enemy: String = str(setup["encounter"]["enemies"][0]["id"])
    battle._event("hit", "pip", first_enemy, {
        "action_id": "shortbow", "source_kind": "weapon",
        "attack_kind": "ranged_weapon", "damage_type": "piercing", "amount": 5
    })
    var arrow_event: Dictionary = battle.events.back()
    if not arrow_event.has("source_cell") or not arrow_event.has("target_cell"):
        _fail("Ranged resolved event lacks source or target cell snapshots")
        return
    board.enqueue_combat_event(arrow_event)
    if board.get("_projectiles").size() != 1 or not board.get("_effects").is_empty():
        _fail("Arrow projectile should fly before its impact effect")
        return
    var projectile: Dictionary = board.get("_projectiles")[0]
    projectile["start_ms"] = Time.get_ticks_msec() - 600
    board.call("_process", 0.6)
    if not board.get("_projectiles").is_empty() or board.get("_effects").size() != 1:
        _fail("Arrow projectile did not resolve into an impact effect")
        return

    board.reset_presentation()
    battle._event("miss", "elyra", first_enemy, {
        "action_id": "fire_bolt", "source_kind": "spell", "damage_type": "fire"
    })
    board.enqueue_combat_event(battle.events.back())
    if board.get("_projectiles").size() != 1:
        _fail("Missed Fire Bolt did not launch a travelling projectile")
        return
    board.reset_presentation()
    if not board.get("_projectiles").is_empty():
        _fail("Battle restart did not cancel projectiles")
        return

    print("PASS: 17-column arena, mixed illustrated monsters, direct spell cards, iconic End Turn and ranged/spell projectile travel")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
