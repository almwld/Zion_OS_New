extends Node

var body = null
var partner = null
var narrative_history: Array = []
var current_scene_description: String = ""

signal narrative_generated(text: String)

func _init(_body = null, _partner = null):
    body = _body
    partner = _partner

func generate_moment(action: String) -> String:
    var narrative = "A moment of " + action + " passes between them."
    narrative_history.append(narrative)
    narrative_generated.emit(narrative)
    return narrative

func generate_climax_narrative() -> String:
    var options = [
        "They reach the peak together, their cries filling the air.",
        "They shatter into pure pleasure, holding each other through the storm.",
        "They find release in each other's arms, waves of orgasm washing over them."
    ]
    var narrative = options[randi() % options.size()]
    narrative_history.append(narrative)
    narrative_generated.emit(narrative)
    return narrative

func generate_afterglow_narrative() -> String:
    var options = [
        "In the aftermath, they lie tangled together, breathing slowly.",
        "A profound peace settles over them. They drift in satisfaction.",
        "They hold each other close, basking in the warmth of shared intimacy."
    ]
    var narrative = options[randi() % options.size()]
    narrative_history.append(narrative)
    narrative_generated.emit(narrative)
    return narrative
