extends RefCounted
## Combat Lab fixtures. This builder has no campaign, NPC registry or reward access.
const Level1Spells = preload("res://combat/level1_spells.gd")
const PARTY_SOURCE := "res://combat_lab/fixtures/party/level_01_v1.json"
const ARENAS := {
    "camp": "res://combat_lab/fixtures/encounters/training_battle.json",
    "stone": "res://combat_lab/fixtures/encounters/stone_chamber.json",
    "woodland": "res://combat_lab/fixtures/encounters/woodland_watch.json",
    "refuse": "res://combat_lab/fixtures/encounters/refuse_room.json",
    "wide": "res://combat_lab/fixtures/encounters/wide_training_camp.json"
}
const ENEMIES := {
    "goblin_melee": {"arena": "camp", "index": 1},
    "goblin_archer": {"arena": "camp", "index": 2},
    "goblin_vanguard": {"arena": "camp", "index": 0},
    "wolf": {"arena": "stone", "index": 1},
    "midden_grub": {"arena": "refuse", "index": 0},
    "skeleton": {"path": "res://combat_lab/fixtures/enemies/v04_archetypes.json", "index": 0},
    "spider": {"path": "res://combat_lab/fixtures/enemies/v04_archetypes.json", "index": 1},
    "kobold": {"path": "res://combat_lab/fixtures/enemies/v04_archetypes.json", "index": 2},
    "bandit": {"path": "res://combat_lab/fixtures/enemies/v04_archetypes.json", "index": 3},
    "mixed": {"kind": "preset"}
}
const MIXED_ROSTER := ["skeleton", "goblin_archer", "spider", "kobold", "bandit"]

const CLASS_SPELLS := {
    "evoker": ["fire_bolt", "ray_of_frost", "magic_missile", "mage_armor", "shield"],
    "priest": ["sacred_flame", "cure_wounds", "healing_word", "bless"],
    "hunter": ["cure_wounds"]
}
const HIT_POINT_INCREASE := {"champion": 6, "evoker": 4, "priest": 5, "thief": 5, "hunter": 6}

static func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return parsed if parsed is Dictionary else {}


static func _hunter_for_lab(original: Dictionary) -> Dictionary:
    # Test-only variant in slot 'pip' until the Hunter's canonical character fixture is authored.
    var hero: Dictionary = original.duplicate(true)
    hero["name"] = "Rowan (Hunter test)"
    hero["race_id"] = "human"
    hero["class_id"] = "hunter"
    hero["ability_scores"]["wisdom"] = 14
    hero["max_hp"] = 12
    hero["starting_hp"] = 12
    hero["armor_class"] = 15
    hero["abilities_available"] = ["weapon_mastery", "spellcasting"]
    hero["conditional_attack_bonus"] = {}
    hero["fighting_style"] = "archery"
    hero["spellcasting"] = {"ability": "wisdom", "save_dc": 12, "spell_attack_bonus": 4,
        "spell_slots": {"1": 2}, "cantrips": [], "prepared_spells": ["cure_wounds"]}
    hero["art"] = original.get("art", {}).duplicate(true)
    # Borrow the existing sprite as placeholder; this is not a canonical Hunter character.
    return hero


static func _set_test_spells(hero: Dictionary, level: int) -> void:
    var class_id: String = str(hero.get("class_id", ""))
    var casting_value: Variant = hero.get("spellcasting")
    if not casting_value is Dictionary:
        return
    var casting: Dictionary = casting_value
    var cantrips: Array[String] = []
    var prepared: Array[String] = []
    for id_variant in CLASS_SPELLS.get(class_id, []):
        var spell_id: String = str(id_variant)
        var definition: Dictionary = Level1Spells.get_definition(spell_id)
        if definition.is_empty():
            continue
        if int(definition.get("level", 0)) == 0:
            cantrips.append(spell_id)
        else:
            prepared.append(spell_id)
    if str(hero.get("id", "")) == "elyra" and class_id == "evoker" and level >= 3:
        prepared.append("web")
    casting["cantrips"] = cantrips
    casting["wizard_cantrips"] = cantrips
    casting["prepared_spells"] = prepared
    # Lab resource tiers are explicit; spell availability is separately bounded.
    var first_level_slots := 2
    if class_id in ["priest", "evoker"]:
        first_level_slots = 2 if level == 1 else (3 if level == 2 else 4)
    elif class_id == "hunter":
        first_level_slots = 2 if level <= 2 else (3 if level <= 4 else 4)
    # Resource tiers mirror full-caster progression; higher-level spell effects
    # are introduced separately and are NOT made available by these slots alone.
    var slot_totals: Dictionary = {"1": first_level_slots}
    if class_id in ["priest", "evoker"]:
        if level >= 3:
            slot_totals["2"] = 2 if level == 3 else 3
        if level >= 5:
            slot_totals["3"] = 2
    casting["spell_slots"] = slot_totals
    hero["spellcasting"] = casting


static func _build_party(level: int, fourth_class: String) -> Dictionary:
    var party: Dictionary = _read(PARTY_SOURCE)
    if party.is_empty() or not party.has("characters"):
        return {}
    var characters: Array = party["characters"]
    if characters.size() != 4:
        return {}
    for index in range(characters.size()):
        var hero: Dictionary = characters[index].duplicate(true)
        if str(hero.get("id", "")) == "pip" and fourth_class == "hunter":
            hero = _hunter_for_lab(hero)
        hero["level"] = level
        var class_id: String = str(hero.get("class_id", ""))
        var hp_gain: int = int(HIT_POINT_INCREASE.get(class_id, 5))
        var constitution: int = int(hero.get("ability_scores", {}).get("constitution", 10))
        var con_mod: int = int(floori(float(constitution - 10) / 2.0))
        var dwarf_bonus := 1 if str(hero.get("race_id", "")) == "dwarf" else 0
        var extra: int = maxi(1, hp_gain + con_mod + dwarf_bonus) * (level - 1)
        hero["max_hp"] = int(hero.get("max_hp", 1)) + extra
        hero["starting_hp"] = hero["max_hp"]
        _set_test_spells(hero, level)
        characters[index] = hero
    party["characters"] = characters
    party["target_level"] = level
    party["immutable_baseline"] = false
    party["snapshot_id"] = "combat_lab_level_%02d" % level
    return party


static func build_setup(level: int, fourth_class: String, enemy_kind: String, enemy_count: int,
        arena_id: String, seed: int) -> Dictionary:
    if level < 1 or level > 5 or fourth_class not in ["thief", "hunter"]:
        return {}
    if not ARENAS.has(arena_id) or not ENEMIES.has(enemy_kind) or enemy_count < 1 or enemy_count > 8:
        return {}
    var party: Dictionary = _build_party(level, fourth_class)
    var arena: Dictionary = _read(str(ARENAS[arena_id]))
    if party.is_empty() or arena.is_empty():
        return {}
    # Every species uses an authored creature stat block. "mixed" cycles through
    # a documented roster without modifying the combat engine or its AI rules.
    var enemy_templates: Dictionary = {}
    for kind_variant in ENEMIES.keys():
        var kind: String = str(kind_variant)
        if kind == "mixed":
            continue
        var spec: Dictionary = ENEMIES[kind]
        var fixture_path: String = str(spec.get("path", ARENAS.get(str(spec.get("arena", "")), "")))
        var source: Dictionary = _read(fixture_path)
        var definitions: Array = source.get("enemies", [])
        var slot: int = int(spec.get("index", -1))
        if slot < 0 or slot >= definitions.size():
            return {}
        enemy_templates[kind] = definitions[slot]
    var enemies: Array = []
    var blocked: Dictionary = {}
    for cell in arena.get("walls", []):
        blocked[Vector2i(int(cell[0]), int(cell[1]))] = true
    for object_variant in arena.get("obstacles", []):
        var object_data: Dictionary = object_variant
        if not bool(object_data.get("blocks_movement", false)):
            continue
        var corner: Array = object_data.get("position", [0, 0])
        var extent: Array = object_data.get("size", [1, 1])
        for oy in range(int(extent[1])):
            for ox in range(int(extent[0])):
                blocked[Vector2i(int(corner[0]) + ox, int(corner[1]) + oy)] = true
    for hazard in arena.get("hazards", []):
        var pos: Array = hazard.get("position", [0, 0])
        blocked[Vector2i(int(pos[0]), int(pos[1]))] = true
    var party_positions: Dictionary = arena.get("party_positions", {})
    for pos in party_positions.values():
        blocked[Vector2i(int(pos[0]), int(pos[1]))] = true
    var size: Array = arena.get("grid_size", [12, 10])
    var candidates: Array[Vector2i] = []
    # Populate right-hand rows first; never overlap walls, props, hazards or heroes.
    for x in range(int(size[0]) - 2, maxi(4, int(size[0]) - 7), -1):
        for y in [2, 5, 7, 3, 6, 1, 4, 8]:
            var cell := Vector2i(x, y)
            if y < int(size[1]) - 1 and not blocked.has(cell):
                candidates.append(cell)
    if candidates.size() < enemy_count:
        return {}
    for n in range(enemy_count):
        var archetype: String = str(MIXED_ROSTER[n % MIXED_ROSTER.size()]) if enemy_kind == "mixed" else enemy_kind
        var template: Dictionary = enemy_templates[archetype]
        var enemy: Dictionary = template.duplicate(true)
        enemy["id"] = "lab_%s_%02d" % [archetype, n + 1]
        enemy["name"] = "%s %d" % [str(template.get("name", archetype)), n + 1]
        enemy["position"] = [candidates[n].x, candidates[n].y]
        enemy.erase("npc_id")
        enemy.erase("special_npc")
        enemy.erase("death_saves")
        enemies.append(enemy)
    arena["enemies"] = enemies
    arena["id"] = "lab_%s_%s_%d" % [arena_id, enemy_kind, enemy_count]
    arena["name"] = "Combat Lab — %s, %s x%d" % [arena_id.capitalize(), enemy_kind.replace("_", " ").capitalize(), enemy_count]
    arena["intro"] = "Repeatable test encounter with no campaign rewards."
    arena.erase("rewards")
    return {"schema_version": 1, "seed": seed, "party": party, "encounter": arena,
        "lab": {"level": level, "fourth_class": fourth_class, "enemy_type": enemy_kind,
        "enemy_count": enemy_count, "arena": arena_id, "seed": seed,
        "supported_mechanics": "Level-one abilities and Elyra L3+ Web; tiered slots; remaining progression is HP scaffolding"}}
