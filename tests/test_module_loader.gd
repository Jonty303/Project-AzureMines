extends SceneTree

const ModuleLoader = preload("res://core/module_loader.gd")
const Dice = preload("res://core/dice_roller.gd")


func _initialize() -> void:
    var loader := ModuleLoader.new()
    var loaded: Dictionary = loader.load_adventure("test_adventure")
    if not loaded.get("ok", false):
        _fail("Sample adventure did not load: " + str(loaded.get("error", "")))
        return
    var location: Dictionary = loaded["location"]
    if location.get("id", "") != "training_ground":
        _fail("Wrong starting location.")
        return

    if loader.load_adventure("../unsafe").get("ok", true):
        _fail("Unsafe adventure identifier was accepted.")
        return
    if loader.load_adventure("nonexistent").get("ok", true):
        _fail("Missing adventure was accepted.")
        return

    if Dice.ability_modifier(8) != -1 or Dice.ability_modifier(15) != 2:
        _fail("Ability score modifiers are incorrect.")
        return
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    for i in 100:
        var die := Dice.roll_d20(rng)
        if die < 1 or die > 20:
            _fail("d20 value out of bounds.")
            return

    print("PASS: module loader, safe identifiers, basic dice utilities")
    quit(0)


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)
