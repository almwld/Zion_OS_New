extends Node
class_name PerformanceEnhancer

var body: CocktailBody
var active_effects: Dictionary = {}

func _init(_body: CocktailBody):
    body = _body

func apply_viagra():
    active_effects["viagra"] = {
        "duration": 3600.0,
        "penis_bonus": 0.02,
        "stamina_bonus": 0.3,
        "climax_delay": 20.0
    }
    body.penis_length += active_effects["viagra"]["penis_bonus"]
    body.personality["stamina"] += active_effects["viagra"]["stamina_bonus"]
    body.orgasm_threshold += active_effects["viagra"]["climax_delay"]

func apply_lubricant():
    active_effects["lubricant"] = {
        "duration": 1800.0,
        "wetness_bonus": 0.5
    }
    body.vagina_tightness -= active_effects["lubricant"]["wetness_bonus"]

func apply_aphrodisiac():
    active_effects["aphrodisiac"] = {
        "duration": 2400.0,
        "arousal_rate": 2.0,
        "sensitivity": 0.3
    }
    for zone in body.zones:
        body.zones[zone] += active_effects["aphrodisiac"]["sensitivity"]

func _process(delta):
    var to_remove = []
    for effect in active_effects:
        active_effects[effect]["duration"] -= delta
        if active_effects[effect]["duration"] <= 0:
            to_remove.append(effect)
    for effect in to_remove:
        _remove_effect(effect)

func _remove_effect(effect: String):
    match effect:
        "viagra":
            body.penis_length -= active_effects["viagra"]["penis_bonus"]
            body.personality["stamina"] -= active_effects["viagra"]["stamina_bonus"]
            body.orgasm_threshold -= active_effects["viagra"]["climax_delay"]
        "lubricant":
            body.vagina_tightness += active_effects["lubricant"]["wetness_bonus"]
        "aphrodisiac":
            for zone in body.zones:
                body.zones[zone] -= active_effects["aphrodisiac"]["sensitivity"]
    active_effects.erase(effect)
