extends RefCounted
## Validates the minimum manifest contract and resolves a starting location.
## This loader handles data only. Adventures never execute imported scripts.

const RULESETS_ROOT := "res://rulesets/"
const ADVENTURES_ROOT := "res://adventures/"
const SUPPORTED_SCHEMA_VERSION := 1


func load_adventure(adventure_id: String) -> Dictionary:
    if not _valid_id(adventure_id):
        return _failure("Invalid adventure identifier.")

    var adventure: Dictionary = _read_json(
        ADVENTURES_ROOT + adventure_id + "/manifest.json"
    )
    if adventure.is_empty():
        return _failure("Adventure manifest missing or invalid JSON.")
    if adventure.get("id", "") != adventure_id:
        return _failure("Adventure identifier does not match its folder.")
    if adventure.get("schema_version", -1) != SUPPORTED_SCHEMA_VERSION:
        return _failure("Unsupported adventure schema version.")

    var ruleset_id := str(adventure.get("ruleset_id", ""))
    if not _valid_id(ruleset_id):
        return _failure("Invalid ruleset identifier.")
    var ruleset: Dictionary = _read_json(
        RULESETS_ROOT + ruleset_id + "/manifest.json"
    )
    if ruleset.is_empty() or ruleset.get("id", "") != ruleset_id:
        return _failure("Required ruleset manifest missing or invalid.")
    if ruleset.get("schema_version", -1) != SUPPORTED_SCHEMA_VERSION:
        return _failure("Unsupported ruleset schema version.")

    var location_id := str(adventure.get("starting_location", ""))
    if not _valid_id(location_id):
        return _failure("Invalid starting location identifier.")
    var location: Dictionary = _read_json(
        ADVENTURES_ROOT + adventure_id + "/locations/" + location_id + ".json"
    )
    if location.is_empty() or location.get("id", "") != location_id:
        return _failure("Starting location missing or invalid.")

    return {
        "ok": true,
        "adventure": adventure,
        "ruleset": ruleset,
        "location": location
    }


func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        return parsed
    return {}


func _valid_id(value: String) -> bool:
    if value.is_empty():
        return false
    for index in value.length():
        var letter := value.substr(index, 1)
        if not "abcdefghijklmnopqrstuvwxyz0123456789_".contains(letter):
            return false
    return true


func _failure(message: String) -> Dictionary:
    return {"ok": false, "error": message}
