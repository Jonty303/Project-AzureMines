extends RefCounted
## Presentation adapter for the engine's typed, live action-query contract.
static func render(info: Dictionary, details: bool = false) -> String:
    if info.is_empty():
        return ""
    var text := "%s — Cost: %s. Effect: %s. Duration: %s. Consequence: %s." % [
        info["name"], info["cost"], info["effect"], info["duration"], info["consequence"]]
    if not str(info.get("reason", "")).is_empty():
        text += " Disabled: " + str(info["reason"])
    if details:
        text += "\n" + str(info.get("details", ""))
    return text
