extends RefCounted
## Wagon-clearing NPC interaction. Narrative choices, combat-rule treatment,
## and persistent campaign disposition remain separate from victory rewards.
const HESK := "hesk_roadwatch"
const ACTOR := "goblin_blade"

var state: RefCounted


func _init(campaign: RefCounted) -> void:
    state = campaign


func description() -> String:
    var npc: Dictionary = state.npc_registry.get(HESK, {})
    var condition: String = str(npc.get("state", "unmet"))
    var fate: String = str(npc.get("fate", "unresolved"))
    if condition == "unmet":
        return ""
    if fate == "released":
        return "Hesk has left the clearing alive. The choices you made about his family may shape what happens at the goblin cave."
    if fate == "captive":
        return "Hesk is bound beside the wagon, a living prisoner. His custody is recorded; moving him elsewhere has not yet been resolved."
    if fate == "left":
        return "You chose to leave Hesk at the wagon. You have no confirmed news of what happened to him afterwards."
    if condition == "dead" or not bool(npc.get("alive", true)):
        return "Hesk, the shield-bearing goblin, is dead. There is no one left here to question."
    if condition == "unconscious":
        return "Hesk lies badly hurt beside the broken wagon, unconscious and dying. A Medicine check might stabilise him; healing magic could wake him."
    if condition == "stable":
        return "Hesk breathes faintly beside the wagon. He is stable, but unconscious at zero hit points."
    if condition == "knocked_out":
        return "The shield-bearing goblin Hesk is alive but unconscious after being subdued. He is not making death saves."
    if condition == "active" and bool(state.flags.get("hesk_dialogue_open", false)):
        return "Hesk keeps his eyes on your weapons. 'I have a family in there,' he mutters. 'I do what I'm told. What do you want to know?'"
    if condition == "active":
        return "Hesk has regained consciousness. He watches you warily, clearly uncertain whether he will leave the clearing alive."
    return ""


func available_choices() -> Array[Dictionary]:
    var npc: Dictionary = state.npc_registry.get(HESK, {})
    if str(npc.get("state", "unmet")) == "unmet" or str(state.current_location) != "wagon_clearing":
        return []
    var result: Array[Dictionary] = []
    var condition: String = str(npc.get("state", "unmet"))
    var fate: String = str(npc.get("fate", "unresolved"))
    if fate != "unresolved" or condition == "dead" or not bool(npc.get("alive", true)):
        return result
    if condition in ["unconscious", "knocked_out"] and not bool(npc.get("first_aid_attempted", false)):
        result.append({"id": "hesk_first_aid", "label": "Check Hesk's wounds (Medicine DC 10)"})
    if condition in ["unconscious", "stable", "knocked_out"]:
        result.append({"id": "hesk_heal", "label": "Have Brunna cast Cure Wounds on Hesk (1 spell slot)"})
    if condition == "active":
        if not bool(state.flags.get("hesk_dialogue_open", false)):
            result.append({"id": "hesk_talk", "label": "Talk to Hesk"})
        else:
            if not bool(state.flags.get("hesk_asked_lord", false)):
                result.append({"id": "hesk_ask_lord", "label": "Ask who commands the goblin raiders"})
            if not bool(state.flags.get("hesk_promised_family", false)):
                result.append({"id": "hesk_promise_family", "label": "Promise to spare goblin families"})
            result.append({"id": "hesk_close_talk", "label": "End the conversation"})
        result.append({"id": "hesk_release", "label": "Release Hesk and let him go"})
    result.append({"id": "hesk_capture", "label": "Restrain Hesk as a prisoner"})
    result.append({"id": "hesk_leave", "label": "Leave Hesk at the clearing"})
    result.append({"id": "hesk_kill", "label": "Kill Hesk"})
    return result


func choose(choice_id: String, actors: Dictionary, combat: RefCounted) -> Dictionary:
    var valid := false
    for choice in available_choices():
        if str(choice["id"]) == choice_id:
            valid = true
            break
    if not valid:
        return {"ok": false, "text": "Hesk is not available for that action."}
    if not actors.has(ACTOR):
        return {"ok": false, "text": "Hesk's combat condition is missing."}
    var npc: Dictionary = state.npc_registry[HESK]
    var actor: Dictionary = actors[ACTOR]
    var condition: String = str(npc.get("state", "unmet"))
    if choice_id == "hesk_first_aid":
        if combat == null:
            return {"ok": false, "text": "The post-battle Medicine rules are unavailable."}
        var check: Dictionary = combat.stabilize_creature(ACTOR, "brunna")
        if not bool(check.get("allowed", false)):
            return {"ok": false, "text": "Brunna cannot attempt first aid right now."}
        state.capture_npc_from_combat(actors)
        state.flags["hesk_first_aid_done"] = true
        state.checks["hesk_first_aid"] = {
            "character_id": "brunna", "die": int(check.get("roll", 0)),
            "total": int(check.get("total", 0)), "dc": 10,
            "success": bool(check.get("success", false))
        }
        state.record_event("hesk_medicine", "Brunna attempted first aid on Hesk (Medicine DC 10).")
        if bool(check.get("success", false)):
            return {"ok": true, "text": "Brunna's Medicine check succeeds (%d vs DC 10). %s" % [
                int(check.get("total", 0)),
                "Hesk is now stable, but unconscious." if condition == "unconscious" else "Hesk can be roused and speak."
            ]}
        return {"ok": true, "text": "Brunna's Medicine check fails (%d vs DC 10). Hesk's condition is unchanged. This attempt cannot be repeated for free." % int(check.get("total", 0))}
    if choice_id == "hesk_heal":
        if combat == null or not combat.heal_survivor("brunna", ACTOR):
            return {"ok": false, "text": "Brunna cannot cast Cure Wounds: check her condition and remaining spell slots."}
        state.capture_npc_from_combat(actors)
        state.capture_party(actors)
        state.record_event("hesk_healed", "Brunna spent a Cure Wounds spell slot to heal Hesk.")
        return {"ok": true, "text": "Brunna spends a spell slot and touches Hesk's wounds. He opens his eyes and stares at the party."}
    if choice_id == "hesk_talk":
        state.flags["hesk_dialogue_open"] = true
        state.record_event("hesk_spoken_to", "The party began questioning Hesk at the wagon.")
        return {"ok": true, "text": "The goblin flinches, then speaks. 'There's folk back in the caves who never wanted this. Leave the little ones out of it.'"}
    if choice_id == "hesk_ask_lord":
        state.flags["hesk_asked_lord"] = true
        state.discover_clue("hesk_fearful_raiders", "Hesk says the goblins fear the commander now ruling their cave.", "confirmed")
        return {"ok": true, "text": "'He isn't one of ours,' Hesk says of the commander. 'The old chief doesn't make the decisions any more. I don't know who sent him.'"}
    if choice_id == "hesk_promise_family":
        state.flags["hesk_promised_family"] = true
        var promises: Array = npc.get("promises", []).duplicate()
        if not promises.has("protect_goblin_families"):
            promises.append("protect_goblin_families")
        state.set_npc(HESK, {"promises": promises, "trust": int(npc.get("trust", 0)) + 2, "attitude": "hopeful"})
        state.discover_clue("hesk_ravine_directions", "Hesk described an overgrown ravine track that leads towards the goblin caves.")
        state.reveal_route("overgrown_track")
        state.record_event("hesk_family_promise", "The party promised Hesk to spare goblin families.")
        return {"ok": true, "text": "Hesk studies you before giving directions to a narrow ravine trail. 'If you mean it, don't kill the families. They're not the ones giving orders.'"}
    if choice_id == "hesk_close_talk":
        state.flags["hesk_dialogue_open"] = false
        return {"ok": true, "text": "Hesk waits uneasily while the party decides his fate."}
    if choice_id in ["hesk_release", "hesk_capture", "hesk_leave", "hesk_kill"]:
        var fate := ""
        var whereabouts := "wagon_clearing"
        var attitude := str(npc.get("attitude", "wary"))
        var text_result := ""
        match choice_id:
            "hesk_release":
                fate = "released"
                whereabouts = "towards_goblin_hideout"
                attitude = "receptive" if bool(state.flags.get("hesk_promised_family", false)) else "wary"
                state.flags["goblin_lair_readiness"] = "alerted"
                text_result = "You release Hesk. He slips into the trees, possibly carrying a warning to the cave. His trust in you depends on the promises you made."
            "hesk_capture":
                fate = "captive"
                whereabouts = "wagon_clearing_captive"
                attitude = "resentful"
                text_result = "The party binds Hesk beside the wagon. Taking him safely to a settlement will require a later decision; he is not silently added to the travelling party."
            "hesk_leave":
                fate = "left"
                text_result = "You leave Hesk in the clearing. His later survival is not yet known; he has not been automatically killed or released."
            "hesk_kill":
                fate = "dead"
                attitude = "none"
                actor["hp"] = 0
                actor["combat_state"] = "dead"
                actors[ACTOR] = actor
                text_result = "You kill Hesk. Whatever answers he might have offered are lost."
        state.flags["hesk_dialogue_open"] = false
        state.flags["hesk_fate"] = fate
        state.set_npc(HESK, {
            "fate": fate, "alive": fate != "dead", "attitude": attitude,
            "whereabouts": whereabouts, "state": "dead" if fate == "dead" else condition,
            "hp": 0 if fate == "dead" else int(actor.get("hp", 0))
        })
        state.record_event("hesk_fate_" + fate, "At the wagon clearing, the party chose to leave Hesk %s." % fate)
        return {"ok": true, "text": text_result}
    return {"ok": false, "text": "Unknown Hesk interaction."}
