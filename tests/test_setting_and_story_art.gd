extends SceneTree
## Establish the commissioned journey and settlement worldbuilding as stable authored data.
func _initialize() -> void:
    call_deferred("_run")


func _fail(message: String) -> void:
    printerr("FAIL: " + message)
    quit(1)


func _run() -> void:
    var setting_path := "res://adventures/test_adventure/setting_anchors.json"
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(setting_path))
    if not parsed is Dictionary:
        _fail("Setting anchors are not valid JSON")
        return
    var setting: Dictionary = parsed
    var settlements: Array = setting.get("settlements", [])
    if settlements.size() != 2:
        _fail("Expected coastal city and northern Dales market town")
        return
    var seaport: Dictionary = settlements[0]
    var market: Dictionary = settlements[1]
    if seaport.get("id", "") != "seabrook" or seaport.get("kind", "") != "small_coastal_city":
        _fail("Missing multicultural coastal city")
        return
    var keep: Dictionary = {}
    for site_variant in seaport.get("important_sites", []):
        var site: Dictionary = site_variant
        if site.get("id", "") == "old_rookhold":
            keep = site
            break
    if keep.get("condition", "") != "derelict" or keep.get("monsters", "") != "rumoured_not_confirmed":
        _fail("Old coastal keep should be ruined; occupants not yet established")
        return
    if market.get("id", "") != "harrowford" or market.get("important_sites", []).size() != 10:
        _fail("Harrowford's ten requested landmarks are missing")
        return
    var found := {}
    for landmark_variant in market["important_sites"]:
        var landmark: Dictionary = landmark_variant
        found[landmark["id"]] = landmark
    if found["ore_weighhouse"].get("market_days_per_week", 0) != 2:
        _fail("Twice-weekly ore market missing")
        return
    if found["lethiel_shrine"].get("deity", "") != "Lethiel":
        _fail("Life shrine missing its working deity name")
        return
    if found["vale_manor"].get("role", "") != "local_lords_residence":
        _fail("Town lord's manor must remain distinct from derelict coastal keep")
        return

    var opening_path := "res://adventures/test_adventure/opening_sequence.json"
    var intro: Variant = JSON.parse_string(FileAccess.get_file_as_string(opening_path))
    if not intro is Dictionary:
        _fail("Original adventure introduction could not load")
        return
    var contract: Dictionary = intro.get("commission", {})
    if contract.get("origin_id", "") != "seabrook" or contract.get("destination_id", "") != "harrowford":
        _fail("Merchant's commission should travel from city to town")
        return
    if contract.get("required_report", "") != "harrowford_adventurers_guild":
        _fail("Guild reporting obligation missing")
        return
    var story: Dictionary = intro["screens"]["approach"]
    if not str(story["paragraphs"][0]).contains("Tavian Marr"):
        _fail("Opening did not describe the commissioning merchant")
        return
    var artwork: String = str(story.get("art", ""))
    if not ResourceLoader.exists(artwork) or load(artwork) == null:
        _fail("Static campfire illustration failed to import")
        return
    print("PASS: city/keep lore, all town sites, coastal merchant commission and story illustration")
    quit(0)
