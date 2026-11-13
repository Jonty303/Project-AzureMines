extends SceneTree
const F = preload("res://tests/web_fixture.gd")
func _initialize() -> void:
    var b := F.battle()
    assert(b.ignite_actor("alden", "torch"))
    var snapshot := b.burning_snapshot("actor", "alden")
    assert(snapshot.target_kind == "actor" and snapshot.ticks_remaining == 3)
    snapshot.ticks_remaining = 100
    assert(not b.ignite_actor("alden", "other"))
    assert(b.burning_snapshot("actor", "alden").ticks_remaining == 3)
    b.cast_area_spell("web", Vector2i(5, 5))
    b._stop_concentration("elyra", "test")
    assert(not b.burning_snapshot("actor", "alden").is_empty())
    for tick in range(3):
        b.turn_index = b.turn_order.find("alden")
        var hp: int = b.actors.alden.hp
        b._begin_turn()
        var damage: int = hp - b.actors.alden.hp
        assert(damage >= 1 and damage <= 4)
        b._actor_burning_start_turn("alden")
        assert(b.actors.alden.hp == hp - damage)
    assert(b.burning_snapshot("actor", "alden").is_empty())
    assert(F.facts(b, "hit").size() == 3)
    assert(b.ignite_actor("alden", "torch") and b.can_extinguish())
    b.pending_reaction = {"test": true}
    assert(not b.extinguish())
    b.pending_reaction.clear()
    assert(b.extinguish() and b.action_used and not b.extinguish())
    assert(b.ignite_actor("alden", "torch"))
    assert(b.douse_burning("actor", "alden", "water") and not b.douse_burning("actor", "alden", "water"))
    for state in ["unconscious", "stable"]:
        b = F.battle()
        b.actors.alden.hp = 0
        b.actors.alden.combat_state = state
        b.ignite_actor("alden", "torch")
        b.turn_index = b.turn_order.find("alden")
        b._begin_turn()
        assert(b.actors.alden.death_failures >= 1 or b.actors.alden.hp == 1)
        assert(not b.can_extinguish() or b.actors.alden.hp == 1)
    b = F.battle()
    b.cast_area_spell("web", Vector2i(5, 5))
    b.ignite_web_cell(Vector2i(4, 4), "fire")
    b.actors.alden.position = Vector2i(4, 4)
    b.effect_hook("alden", "start_turn")
    assert(b.burning_snapshot("actor", "alden").is_empty())
    b._apply_spell_damage(b.actors.elyra, "alden", "Fire Bolt", 1, "fire")
    assert(b.burning_snapshot("actor", "alden").is_empty())
    assert(b.douse_web_cell(Vector2i(4, 4), "water") and not b.is_web_burning(Vector2i(4, 4)))
    b = F.battle()
    var authored: Dictionary = b._read_json("res://combat_lab/fixtures/encounters/stone_chamber.json").obstacles[0]
    authored.position = Vector2i(5, 4)
    authored.size = Vector2i(2, 2)
    b.obstacles.append(authored)
    var before := b.obstacles.duplicate(true)
    assert(b.ignite_prop("wooden_table", "torch") and not b.ignite_prop("wooden_table", "torch"))
    assert(not b.ignite_prop("stone", "torch"))
    assert(b.burning_snapshot("prop", "wooden_table").fuel_policy == "authored_prop_rounds")
    b.round_number += 3
    b._expire_effects()
    assert(b.burning_snapshot("prop", "wooden_table").is_empty() and before == b.obstacles)
    b.ignite_actor("alden", "torch")
    assert(b.start(53022) and b.burning_snapshots().is_empty())
    print("PASS: v0531 explicit actor/prop Burning, immutable typed state, 1d4/3 ticks, extinguish/douse, downed and reset")
    quit()
