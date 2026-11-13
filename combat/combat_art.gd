extends RefCounted
## Original v054 art and pure depth/animation contracts. No combat authority.
const ROOT := "assets/combat_v054/"
const VFX_ROWS := ["flame", "smoke", "ember", "web", "burning_web", "fire_bolt", "magic_missile", "frost", "bless", "healing", "shield", "radiant", "impact", "arcane", "slash", "arrow", "sling"]
const PASSES := ["terrain", "ground", "shadows", "ground_y", "foreground", "environment", "projectiles", "impacts", "tactical", "labels", "ui"]
const ANIMATIONS := {"idle": [0, 1], "walk": [2, 3, 4], "melee": [5, 6], "hit": [7], "defeated": [8], "ranged": [9, 10]}
const FRAME_MS := {"idle": 420, "walk": 100, "melee": 140, "hit": 200, "defeated": 1000, "ranged": 170}

static func monster(actor: Dictionary) -> String:
    if actor.get("team", "") == "party":
        return ""
    var identity: String = (str(actor.get("id", "")) + " " + str(actor.get("name", "")) + " " + str(actor.get("art", {}))).to_lower()
    for species in ["goblin", "kobold", "bugbear", "spider", "skeleton"]:
        if identity.contains(species):
            return species
    return ""

static func prop_kind(prop: Dictionary) -> String:
    var kind: String = str(prop.get("kind", ""))
    return kind if kind in ["wagon", "boulder", "chest", "crate", "barrel", "table"] else ""

static func prop_rect(prop: Dictionary, pitch: float) -> Rect2:
    var size: Vector2 = Vector2(prop["size"]) * pitch
    var height: float = pitch * (0.25 if prop_kind(prop) in ["table", "chest", "crate", "barrel"] else 0.5)
    var box_size := size + Vector2(0, height)
    # The source pivot is four pixels above the bottom transparent margin.
    var source_height := 80.0 if prop_kind(prop) in ["wagon", "boulder"] else (72.0 if prop_kind(prop) == "table" else 40.0)
    var pivot_fraction := Vector2(0.5, (source_height - 4.0) / source_height)
    return Rect2(prop_anchor(prop) * pitch - box_size * pivot_fraction, box_size)

static func prop_anchor(prop: Dictionary) -> Vector2:
    return Vector2(prop["position"]) + Vector2(float(prop["size"].x) * 0.5, float(prop["size"].y) - 0.10)

static func depth_before(a: Dictionary, b: Dictionary) -> bool:
    if not is_equal_approx(a["anchor"].y, b["anchor"].y):
        return a["anchor"].y < b["anchor"].y
    if not is_equal_approx(a["anchor"].x, b["anchor"].x):
        return a["anchor"].x < b["anchor"].x
    return str(a["kind"]) + ":" + str(a["id"]) < str(b["kind"]) + ":" + str(b["id"])

static func monster_region(state: String, elapsed_ms: int, facing: int, ranged: bool) -> Rect2:
    var sequence: Array = ANIMATIONS.get(state, ANIMATIONS["idle"])
    var tick: int = maxi(0, elapsed_ms) / int(FRAME_MS.get(state, 420))
    var frame: int = int(sequence[tick % sequence.size()] if state in ["walk", "idle"] else sequence[mini(tick, sequence.size() - 1)])
    var row: int = (1 if facing >= 0 else 0) + (2 if ranged else 0)
    return Rect2(frame * 48, row * 48, 48, 48)

static func wall_mask(cell: Vector2i, walls: Array) -> int:
    var mask := 0
    var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
    for i in range(4):
        if cell + directions[i] in walls:
            mask |= 1 << i
    return mask
