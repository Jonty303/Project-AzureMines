extends SceneTree
## Named special NPCs use player-style 0HP rules; ordinary monsters do not.
const CombatEngine = preload("res://combat/combat_engine.gd")

func _initialize() -> void:
    _run()


func _fail(msg: String) -> void:
    printerr("FAIL: " + msg)
    quit(1)


func _run() -> void:
    var b = CombatEngine.new()
    if not b.start(8124):
        _fail("Could not load encounter")
        return
    var hesk: Dictionary = b.actors["goblin_blade"]
    if hesk.get("npc_id", "") != "hesk_roadwatch" or not hesk.get("death_saves", false):
        _fail("Named goblin lacks stable identity / death-saving-throw rule")
        return
    if hesk["attacks"][0]["id"] != "shortsword" or not hesk.get("equipment", []).has("shield"):
        _fail("Hesk must wield a shortsword and shield")
        return
    if int(hesk["armor_class"]) != 16:
        _fail("Hesk's shield AC was not applied")
        return
    var routine: Dictionary = b.actors["goblin_blade_two"]
    if routine.get("death_saves", false):
        _fail("Ordinary goblins should use default instant death at zero")
        return

    # Same damage, different authored death rule.
    hesk["hp"] = 3
    b.actors["goblin_blade"] = hesk
    routine["hp"] = 3
    b.actors["goblin_blade_two"] = routine
    b._deal_damage("goblin_blade", 4)
    b._deal_damage("goblin_blade_two", 4)
    if b.actors["goblin_blade"]["combat_state"] != "unconscious":
        _fail("Hesk should be unconscious and dying, not instantly dead")
        return
    if b.actors["goblin_blade_two"]["combat_state"] != "dead":
        _fail("Ordinary knife goblin should die at 0 HP")
        return
    if b.actor_at(b.actors["goblin_blade"]["position"]) == "goblin_blade":
        _fail("Unconscious goblins must not intercept normal tactical targeting")
        return
    if b.survivors().size() != 1 or b.survivors()[0]["npc_id"] != "hesk_roadwatch":
        _fail("Survivor registry must expose the stable named NPC identifier")
        return
    b._deal_damage("goblin_blade", 1)
    if b.actors["goblin_blade"]["death_failures"] != 1:
        _fail("Damage at 0 HP should give one death-save failure")
        return
    b._deal_damage("goblin_blade", 1, true)
    if b.actors["goblin_blade"]["combat_state"] != "dead":
        _fail("Critical damage at 0 HP should give two further failures and death")
        return
    if not b.survivors().is_empty():
        _fail("The named goblin remained survivable after death")
        return

    var lethal = CombatEngine.new()
    lethal.start(8124)
    lethal._deal_damage("goblin_blade", 30)
    if lethal.actors["goblin_blade"]["combat_state"] != "dead":
        _fail("Massive excess damage must kill a special NPC instantly")
        return

    var spared = CombatEngine.new()
    spared.start(8124)
    var attack: Dictionary = spared.actors["alden"]["attacks"][0]
    if attack.get("kind", "") != "melee_weapon":
        _fail("Alden needs a melee weapon for a nonlethal knockout")
        return
    var target: Dictionary = spared.actors["goblin_blade"]
    target["hp"] = 1
    spared.actors["goblin_blade"] = target
    if not spared._resolve_hit("alden", "goblin_blade", attack,
            {"critical": false, "total": 19}, false, true):
        _fail("Nonlethal hit resolution failed")
        return
    if spared.actors["goblin_blade"]["combat_state"] != "knocked_out" or spared.actors["goblin_blade"]["hp"] != 1:
        _fail("2024 nonlethal melee must leave victim at 1 HP and unconscious")
        return
    if not spared.actors["goblin_blade"]["short_rest_started"]:
        _fail("Nonlethal knockout should start victim's Short Rest")
        return

    var only_hesk = CombatEngine.new()
    only_hesk.start(8124)
    for id in ["goblin_blade_two", "goblin_bow", "goblin_bow_two"]:
        var enemy: Dictionary = only_hesk.actors[id]
        enemy["hp"] = 0
        enemy["combat_state"] = "dead"
        only_hesk.actors[id] = enemy
    only_hesk._deal_damage("goblin_blade", 9)
    only_hesk._check_victory()
    if not only_hesk.finished or only_hesk.victor != "party":
        _fail("Battle must end when the only remaining foe is unconscious, not dead")
        return
    if only_hesk.survivors().size() != 1:
        _fail("Incapacitation victory erased the surviving named goblin")
        return
    if only_hesk.heal_survivor("elyra", "goblin_blade"):
        _fail("An unprepared healer cannot cast Cure Wounds")
        return
    var slots: int = int(only_hesk.actors["brunna"]["spell_slots_remaining"])
    if not only_hesk.heal_survivor("brunna", "goblin_blade"):
        _fail("Brunna should be able to heal the survivor with a real spell slot")
        return
    if only_hesk.actors["brunna"]["spell_slots_remaining"] != slots - 1:
        _fail("Reviving Hesk didn't spend the spell slot")
        return
    if not only_hesk.is_combat_capable("goblin_blade"):
        _fail("Healing should make Hesk conscious again")
        return
    if only_hesk.victor != "party" or not only_hesk.finished:
        _fail("Post-battle healing must not restart the ended combat")
        return

    print("PASS: special NPC vs ordinary deaths, instant death, critical failures, nonlethal, victory and healing")
    quit(0)
