extends RefCounted
## One deterministic renderer for resolved facts. Never evaluates rules or RNG.
static func format_event(event: Dictionary, actors: Dictionary) -> String:
    var actor: String = str(actors.get(event.get("actor_id", ""), {}).get("name", event.get("actor_id", "")))
    var target: String = str(actors.get(event.get("target_id", ""), {}).get("name", event.get("target_id", "")))
    var fields: PackedStringArray = []
    var roll_keys: Array = []
    if event.has("dice"):
        var modifiers: PackedStringArray = []
        for name in event.get("modifiers", {}):
            modifiers.append("%s %+d" % [name, int(event["modifiers"][name])])
        fields.append("%s %s%s = %d%s — %s" % [event.get("die", "dice"), str(event["dice"]),
            " + (" + ", ".join(modifiers) + ")" if not modifiers.is_empty() else "",
            int(event.get("total", 0)), " vs DC %d" % int(event["dc"]) if event.has("dc") else (" vs AC %d" % int(event["ac"]) if event.has("ac") else ""),
            event.get("outcome", "RESOLVED")])
        roll_keys = ["dice", "die", "modifiers", "total", "dc", "ac", "outcome"]
    for key in event:
        if key not in ["schema_version", "event_id", "round", "turn", "kind", "actor_id", "target_id", "text", "sound", "rule"] and key not in roll_keys:
            fields.append("%s=%s" % [str(key), str(event[key])])
    return "[R%d T%d %s] %s%s — %s: %s" % [event["round"], event["turn"], event["event_id"],
        actor, " → " + target if not target.is_empty() else "", event.get("rule", event["kind"]), "; ".join(fields)]
