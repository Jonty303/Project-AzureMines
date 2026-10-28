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
    var region: Dictionary = setting.get("region", {})
    var economy: Dictionary = region.get("economy", {})
    if region.get("map_constraints", {}).get("seabrook", "") != "west_of_the_dales":
        _fail("Seabrook must be west of the Dales on every map")
        return
    if not economy.get("primary_exports", []).has("gems") or not economy.get("primary_producers", []).has("dwarven_mines"):
        _fail("Substantial dwarven mining and gemstone exports missing")
        return
    if not region.get("terrain", []).has("limestone_karst") or not region.get("terrain", []).has("waterfalls"):
        _fail("Limestone caves and waterfalls must be represented in the region")
        return
    if not str(economy.get("material_tension", "")).contains("woodland elves"):
        _fail("Elven woodland protection and land-use conflict missing")
        return
    var routes: Array = setting.get("routes", [])
    if routes.size() != 1 or routes[0].get("id", "") != "old_trade_road":
        _fail("The Old Trade Road must be the named west-to-inland route")
        return
    var route: Dictionary = routes[0]
    if route.get("origin", "") != "seabrook" or route.get("destination", "") != "harrowford":
        _fail("The trade road does not link Seabrook with Harrowford")
        return
    if not route.get("escorts", {}).get("typical", []).has("minor_mage") or not route.get("escorts", {}).get("prosperous", []).has("priest_when_affordable"):
        _fail("Escorted mineral caravan baseline missing")
        return
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
    if intro.get("title", "") != "The Old Trade Road" or intro.get("commission", {}).get("route_id", "") != "old_trade_road":
        _fail("Opening contract must name the Old Trade Road")
        return
    var story: Dictionary = intro["screens"]["approach"]
    if not str(story["paragraphs"][1]).contains("entire caravans") or not str(story["paragraphs"][1]).contains("no survivors"):
        _fail("Whole escorted caravans vanishing without survivors is the mystery")
        return
    if not str(story["paragraphs"][0]).contains("Tavian Marr"):
        _fail("Opening did not describe the commissioning merchant")
        return
    var public_trends: Array = economy.get("public_trends", [])
    if public_trends.size() != 3:
        _fail("Public ore shortfall, dwarven denial and uncertain cause must stay distinct")
        return
    var trend_ids: Array[String] = []
    for trend in public_trends:
        trend_ids.append(str(trend.get("id", "")))
    if not trend_ids.has("ore_deliveries_irregular") or not trend_ids.has("dwarven_reassurances"):
        _fail("Mine shipment irregularity and public reassurances missing")
        return
    var story_text: String = " ".join(story["paragraphs"]).to_lower()
    if not story_text.contains("irregular loads") or not story_text.contains("workings are sound"):
        _fail("The opening needs a subtle public mine-supply clue")
        return
    for forbidden in ["containment", "secret society", "uncovered something", "threatens to break free"]:
        if story_text.contains(forbidden):
            _fail("Author-only campaign secret leaked into opening: " + forbidden)
            return
    var artwork: String = str(story.get("art", ""))
    if not ResourceLoader.exists(artwork) or load(artwork) == null:
        _fail("Static campfire illustration failed to import")
        return
    print("PASS: city/keep lore, all town sites, coastal merchant commission and story illustration")
    quit(0)
