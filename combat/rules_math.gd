extends RefCounted
## Pure, deterministic combat calculations. The RNG is supplied by the caller.


static func attack_hits(natural_roll: int, attack_bonus: int, armor_class: int, critical_from: int = 20) -> Dictionary:
    if natural_roll == 1:
        return {"hit": false, "critical": false, "total": natural_roll + attack_bonus}
    if natural_roll == 20:
        return {"hit": true, "critical": true, "total": natural_roll + attack_bonus}
    return {
        "hit": natural_roll + attack_bonus >= armor_class,
        "critical": natural_roll >= critical_from,
        "total": natural_roll + attack_bonus
    }


static func roll_damage(formula: String, rng: RandomNumberGenerator, critical: bool = false) -> int:
    return int(damage_roll(formula, rng, critical)["total"])


static func damage_roll(formula: String, rng: RandomNumberGenerator, critical: bool = false) -> Dictionary:
    var halves := formula.split("d")
    if halves.size() != 2:
        return {"formula": formula, "dice": [], "total": 0, "reason": "unsupported formula"}
    var tail := halves[1].split("+")
    var count := int(halves[0])
    var sides := int(tail[0])
    var bonus := int(tail[1]) if tail.size() > 1 else 0
    var total := bonus
    var rolls: Array[int] = []
    for i in range(count * (2 if critical else 1)):
        var value := rng.randi_range(1, sides)
        rolls.append(value)
        total += value
    return {"formula": formula, "dice": rolls, "die": "d%d" % sides, "modifiers": {"formula bonus": bonus}, "critical": critical, "total": total}
