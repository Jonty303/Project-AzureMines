extends RefCounted
## Small deterministic-test-friendly dice utility.
## The caller owns the RandomNumberGenerator seed and lifetime.


static func roll(sides: int, rng: RandomNumberGenerator) -> int:
    assert(sides > 0, "A die must have at least one side.")
    return rng.randi_range(1, sides)


static func roll_d20(rng: RandomNumberGenerator) -> int:
    return roll(20, rng)


static func ability_modifier(score: int) -> int:
    return floori((score - 10) / 2.0)
