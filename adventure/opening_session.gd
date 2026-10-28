extends RefCounted
## One opening-adventure session: story state, once-only victory awards, party purse.
## No on-disk saves yet. No loot from routine goblin equipment.

const OPENING_PATH := "res://adventures/test_adventure/opening_sequence.json"
const HERO_IDS := ["alden", "elyra", "brunna", "pip"]

var story: Dictionary = {}
var stage := ""
var gold_gp := 0
var xp_by_character := {"alden": 0, "elyra": 0, "brunna": 0, "pip": 0}
var completed_encounters: Dictionary = {}
var last_reward: Dictionary = {}


func start_journey() -> bool:
    # Restarting an encounter resets the story screen, NOT awarded session rewards.
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OPENING_PATH))
    if not parsed is Dictionary:
        return false
    story = parsed
    if story.get("schema_version", 0) != 1 or not story.has("screens"):
        return false
    stage = "approach"
    last_reward.clear()
    return true


func screen() -> Dictionary:
    var screens: Dictionary = story.get("screens", {})
    return screens.get(stage, {})


func begin_deployment() -> bool:
    if stage != "approach":
        return false
    stage = "deployment"
    return true


func begin_combat() -> bool:
    if stage != "deployment":
        return false
    stage = "battle"
    return true


func conclude_battle(victor: String) -> bool:
    if stage != "battle" or victor not in ["party", "enemy"]:
        return false
    if victor == "enemy":
        stage = "defeat"
        last_reward.clear()
        return true
    stage = "victory"
    last_reward = _award_once()
    return true


func continue_after_victory() -> bool:
    if stage != "victory":
        return false
    stage = "aftermath"
    return true


func _award_once() -> Dictionary:
    var encounter_id: String = str(story.get("encounter_id", ""))
    if encounter_id.is_empty() or completed_encounters.has(encounter_id):
        return {"already_claimed": true, "xp_total": 0, "gold_gp": 0, "xp_each": 0,
            "consumables": [], "named_items": []}

    var config: Dictionary = story.get("rewards", {})
    var total_xp: int = maxi(0, int(config.get("xp_total", 0)))
    var coin: int = maxi(0, int(config.get("gold_gp", 0)))
    var xp_each: int = total_xp / HERO_IDS.size()
    # All four heroes receive XP, including allies who ended the encounter downed.
    # Require divisible-by-four encounters until party size/remainder rules exist.
    if xp_each * HERO_IDS.size() != total_xp:
        push_error("Adventure XP reward must be divisible among the four heroes.")
        return {"already_claimed": false, "error": true, "xp_total": 0, "gold_gp": 0,
            "xp_each": 0, "consumables": [], "named_items": []}

    var consumables: Array = config.get("consumables", [])
    var named_items: Array = config.get("named_items", [])
    # This encounter deliberately has no equipment drops; future authored rewards
    # will be screened by a typed item system before actual inventory integration.
    if not consumables.is_empty() or not named_items.is_empty():
        push_error("Opening encounter cannot award unimplemented inventory items.")
        return {"error": true, "already_claimed": false, "xp_total": 0, "gold_gp": 0,
            "xp_each": 0, "consumables": [], "named_items": []}

    for id in HERO_IDS:
        xp_by_character[id] = int(xp_by_character[id]) + xp_each
    gold_gp += coin
    completed_encounters[encounter_id] = true

    return {"already_claimed": false, "xp_total": total_xp, "xp_each": xp_each,
        "gold_gp": coin, "consumables": [], "named_items": []}
