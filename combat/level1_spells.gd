extends RefCounted
## Small explicitly supported level-1 spell subset. Definitions are NOT the whole SRD.
## The engine enforces costs, targets and effects; this module only declares capabilities.

const DEFINITIONS := {
    "fire_bolt": {"level": 0, "time": "action", "target": "enemy", "range_feet": 120,
        "effect": "attack_damage", "damage": "1d10", "damage_type": "fire"},
    "ray_of_frost": {"level": 0, "time": "action", "target": "enemy", "range_feet": 60,
        "effect": "attack_damage", "damage": "1d8", "damage_type": "cold"},
    "sacred_flame": {"level": 0, "time": "action", "target": "enemy", "range_feet": 60,
        "effect": "dex_save_damage", "damage": "1d8", "damage_type": "radiant"},
    "magic_missile": {"level": 1, "time": "action", "target": "enemy", "range_feet": 120,
        "effect": "automatic_damage", "damage": "3d4+3", "damage_type": "force"},
    "cure_wounds": {"level": 1, "time": "action", "target": "ally", "range_feet": 5,
        "effect": "heal", "healing": "2d8"},
    "healing_word": {"level": 1, "time": "bonus", "target": "ally", "range_feet": 60,
        "effect": "heal", "healing": "2d4"},
    "mage_armor": {"level": 1, "time": "action", "target": "self", "range_feet": 0,
        "effect": "mage_armor"},
    "shield": {"level": 1, "time": "reaction", "target": "self", "range_feet": 0,
        "effect": "shield"},
    "bless": {"level": 1, "time": "action", "target": "ally", "range_feet": 30,
        "effect": "bless", "concentration": true, "duration_rounds": 10}
}

static func get_definition(spell_id: String) -> Dictionary:
    return DEFINITIONS.get(spell_id, {})


static func known_spells(actor: Dictionary) -> Array[String]:
    var result: Array[String] = []
    var info: Variant = actor.get("spellcasting")
    if not info is Dictionary:
        return result
    var casting: Dictionary = info
    for key in ["wizard_cantrips", "cantrips", "prepared_spells"]:
        for spell_id_variant in casting.get(key, []):
            var spell_id: String = str(spell_id_variant)
            if DEFINITIONS.has(spell_id) and not result.has(spell_id):
                result.append(spell_id)
    return result
