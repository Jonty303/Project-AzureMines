extends Control

const ModuleLoader = preload("res://core/module_loader.gd")
const Dice = preload("res://core/dice_roller.gd")

@onready var status_label: Label = $Margin/Content/Status
@onready var details_label: Label = $Margin/Content/Details
@onready var dice_label: Label = $Margin/Content/DiceResult
@onready var reload_button: Button = $Margin/Content/ReloadButton
@onready var roll_button: Button = $Margin/Content/RollButton

var _random := RandomNumberGenerator.new()


func _ready() -> void:
    _random.randomize()
    reload_button.pressed.connect(_load_example)
    roll_button.pressed.connect(_roll_demo)
    _load_example()


func _load_example() -> void:
    var result: Dictionary = ModuleLoader.new().load_adventure("test_adventure")
    if not result.get("ok", false):
        status_label.text = "Adventure failed to load."
        details_label.text = str(result.get("error", "Unknown error"))
        return

    var adventure: Dictionary = result["adventure"]
    var ruleset: Dictionary = result["ruleset"]
    var location: Dictionary = result["location"]
    status_label.text = "Loaded: %s | Ruleset: %s" % [adventure.get("title", ""), ruleset.get("name", "")]
    details_label.text = "%s\n\n%s" % [location.get("name", ""), location.get("description", "")]


func _roll_demo() -> void:
    dice_label.text = "Demo d20: %d" % Dice.roll_d20(_random)
