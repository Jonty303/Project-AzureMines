extends RefCounted
## Opening story controller; all persistent data lives in one shared CampaignState.
const CampaignState = preload("res://adventure/campaign_state.gd")
const NarrativeEngine = preload("res://adventure/narrative_engine.gd")
const OPENING_PATH := "res://adventures/test_adventure/opening_sequence.json"
const HERO_IDS := ["alden", "elyra", "brunna", "pip"]

var campaign: RefCounted = CampaignState.new()
var exploration: RefCounted
var story: Dictionary = {}
var stage := ""
var last_reward: Dictionary = {}
var dungeon_encounter_id := ""
const DUNGEON_ENCOUNTERS := {
    "cave_watchpost": {"path": "res://adventures/test_adventure/encounters/watchpost_two_goblins.json", "xp": 100, "gold": 0},
    "cave_guardroom": {"path": "res://adventures/test_adventure/encounters/guardroom_goblin_wolf.json", "xp": 100, "gold": 0},
    "cave_midden_grub": {"path": "res://adventures/test_adventure/encounters/rubbish_midden_grub.json", "xp": 20, "gold": 0}
}

var gold_gp: int:
    get:
        return int(campaign.gold_gp)
var xp_by_character: Dictionary:
    get:
        return campaign.xp_by_character
var completed_encounters: Dictionary:
    get:
        return campaign.completed_encounters
var npc_outcomes: Dictionary:
    get:
        return campaign.flags.get("npc_outcomes", {})


func start_journey() -> bool:
    # Replay resets presentation, never the global reward ledger.
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OPENING_PATH))
    if not parsed is Dictionary or parsed.get("schema_version", 0) != 1:
        return false
    story = parsed
    if not story.has("screens"):
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


func enter_exploration() -> bool:
    if stage != "aftermath":
        return false
    exploration = NarrativeEngine.new(campaign)
    if not exploration.begin():
        return false
    stage = "exploration"
    return true


func exploration_screen() -> Dictionary:
    if stage != "exploration" or exploration == null:
        return {}
    return exploration.current_scene()


func exploration_choices() -> Array[Dictionary]:
    if stage != "exploration" or exploration == null:
        return []
    return exploration.available_choices()


func choose_exploration(choice_id: String, party: Dictionary, combat: RefCounted = null) -> Dictionary:
    if stage != "exploration" or exploration == null:
        return {"ok": false, "text": "Exploration has not begun."}
    return exploration.choose(choice_id, party, combat)


func begin_dungeon_battle(encounter_id: String) -> bool:
    if stage != "exploration" or not DUNGEON_ENCOUNTERS.has(encounter_id):
        return false
    if campaign.completed_encounters.has(encounter_id):
        return false
    var place: String = campaign.current_location
    if encounter_id == "cave_watchpost" and place != "cave_approach":
        return false
    if encounter_id == "cave_guardroom" and place != "cave_guardroom":
        return false
    if encounter_id == "cave_midden_grub" and place != "cave_rubbish":
        return false
    dungeon_encounter_id = encounter_id
    stage = "dungeon_battle"
    return true


func dungeon_fixture_path() -> String:
    if stage != "dungeon_battle" or not DUNGEON_ENCOUNTERS.has(dungeon_encounter_id):
        return ""
    return str(DUNGEON_ENCOUNTERS[dungeon_encounter_id]["path"])


func conclude_dungeon_battle(victor: String, actors: Dictionary) -> Dictionary:
    if stage != "dungeon_battle" or not DUNGEON_ENCOUNTERS.has(dungeon_encounter_id):
        return {"ok": false}
    campaign.capture_party(actors)
    if victor != "party":
        campaign.record_event("defeat_" + dungeon_encounter_id,
            "The party was defeated in %s." % dungeon_encounter_id)
        stage = "defeat"
        return {"ok": true, "victory": false, "text": "The adventurers were defeated."}
    var id: String = dungeon_encounter_id
    var config: Dictionary = DUNGEON_ENCOUNTERS[id]
    var reward: Dictionary = campaign.award_once(id, int(config["xp"]), int(config["gold"]))
    match id:
        "cave_watchpost":
            campaign.flags["watchpost_resolved"] = true
            campaign.flags["watchpost_crossed"] = true
            campaign.flags["watchpost_spotted"] = true
            campaign.reveal_route("watchpost_tree")
        "cave_guardroom":
            campaign.flags["guardroom_resolved"] = true
        "cave_midden_grub":
            campaign.flags["midden_grub_resolved"] = true
    campaign.record_event("encounter_cleared_" + id,
        "The party defeated the defenders of %s." % id)
    stage = "exploration"
    dungeon_encounter_id = ""
    return {"ok": true, "victory": true, "xp": int(reward.get("xp_total", 0)),
        "text": "The fight is over. The party receives %d XP total. The cave remembers this encounter." % int(reward.get("xp_total", 0))}


func save_game(actors: Dictionary, path: String = CampaignState.DEFAULT_SAVE) -> bool:
    if stage not in ["victory", "aftermath", "exploration"]:
        return false
    campaign.capture_party(actors)
    if stage == "victory":
        campaign.capture_npc_from_combat(actors)
    return campaign.save_to_file(stage, path)


func load_game(path: String = CampaignState.DEFAULT_SAVE) -> bool:
    if story.is_empty() and not start_journey():
        return false
    var loaded_stage: String = campaign.load_from_file(path)
    if loaded_stage.is_empty():
        return false
    stage = loaded_stage
    last_reward = {"already_claimed": true, "xp_total": 0, "xp_each": 0,
        "gold_gp": 0, "consumables": [], "named_items": []}
    exploration = NarrativeEngine.new(campaign)
    return true


func record_named_npc_outcome(npc_id: String, outcome: String, healed: bool = false) -> bool:
    var outcomes: Dictionary = campaign.flags.get("npc_outcomes", {})
    if stage != "victory" or npc_id.is_empty() or outcomes.has(npc_id):
        return false
    if outcome not in ["released", "captive", "dead"]:
        return false
    var state: Dictionary = {
        "fate": outcome, "treated_by_party": healed,
        "warning_possible": outcome == "released",
        "lair_readiness": "unalerted", "lair_attitude": "wary"
    }
    if outcome == "released":
        state["lair_readiness"] = "alerted"
        state["lair_attitude"] = "receptive" if healed else "wary"
    elif outcome == "dead":
        state["lair_attitude"] = "hostile"
    outcomes[npc_id] = state
    campaign.flags["npc_outcomes"] = outcomes
    if campaign.npc_registry.has(npc_id):
        campaign.set_npc(npc_id, {"state": outcome, "alive": outcome != "dead",
            "attitude": "receptive" if healed and outcome == "released" else "wary"})
    return true


func _award_once() -> Dictionary:
    var encounter_id: String = str(story.get("encounter_id", ""))
    var config: Dictionary = story.get("rewards", {})
    if not config.get("consumables", []).is_empty() or not config.get("named_items", []).is_empty():
        push_error("Opening battle cannot award unimplemented inventory items.")
        return {"error": true, "xp_total": 0, "xp_each": 0, "gold_gp": 0,
            "consumables": [], "named_items": []}
    return campaign.award_once(encounter_id, int(config.get("xp_total", 0)),
        int(config.get("gold_gp", 0)))
