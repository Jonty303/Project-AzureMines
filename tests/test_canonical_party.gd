extends SceneTree

const Dice = preload("res://core/dice_roller.gd")
const FIXTURE_PATH := "res://tests/fixtures/party/level_01_v1.json"

func _initialize() -> void:
    if not FileAccess.file_exists(FIXTURE_PATH):
        _fail("Missing canonical party fixture")
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
    if not parsed is Dictionary:
        _fail("Fixture is not valid JSON object")
        return
    var fixture: Dictionary = parsed
    if fixture.get("snapshot_id", "") != "level_01_v1":
        _fail("Wrong snapshot identifier")
        return
    var characters: Array = fixture.get("characters", [])
    if characters.size() != 4:
        _fail("Expected exactly four canonical characters")
        return

    var expected: Dictionary = {
        "alden": {"hp": 12, "ac": 19, "attack": 5},
        "elyra": {"hp": 7, "ac": 12, "attack": 4},
        "brunna": {"hp": 11, "ac": 15, "attack": 4},
        "pip": {"hp": 10, "ac": 14, "attack": 5}
    }
    var seen: Dictionary = {}
    for character_variant in characters:
        var character: Dictionary = character_variant
        var id: String = str(character.get("id", ""))
        if not expected.has(id) or seen.has(id):
            _fail("Unknown or duplicate character: " + id)
            return
        seen[id] = true
        if int(character.get("level", 0)) != 1:
            _fail(id + ": expected level 1")
            return
        if int(character.get("proficiency_bonus", 0)) != 2:
            _fail(id + ": expected proficiency +2")
            return
        var scores: Dictionary = character.get("ability_scores", {})
        var constitution_mod: int = Dice.ability_modifier(int(scores.get("constitution", 10)))
        var base_hit_die: int = {"champion": 10, "priest": 8, "evoker": 6, "thief": 8}[str(character["class_id"])]
        var racial_hp_bonus: int = 1 if id == "brunna" else 0
        var calculated_hp: int = base_hit_die + constitution_mod + racial_hp_bonus
        var e: Dictionary = expected[id]
        if int(character["max_hp"]) != calculated_hp or calculated_hp != e["hp"]:
            _fail(id + ": HP mismatch")
            return
        if int(character["armor_class"]) != e["ac"]:
            _fail(id + ": AC mismatch")
            return
        var attacks: Array = character.get("attacks", [])
        if attacks.is_empty() or int(attacks[0].get("to_hit", -100)) != e["attack"]:
            _fail(id + ": primary attack modifier mismatch")
            return

    print("PASS: four immutable level-1 party fixtures and expected combat statistics")
    quit(0)

func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
