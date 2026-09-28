extends Node

var body = null
var partner = null
var anal_gap_visible: bool = false
var anal_gap_duration: float = 0.0
var anal_stretch: float = 0.0
var anal_pleasure: float = 0.0

func _init(_body = null, _partner = null):
    body = _body
    partner = _partner

func _process(delta):
    if anal_gap_visible:
        anal_gap_duration += delta
        if anal_gap_duration > 5.0:
            anal_gap_visible = false
            anal_gap_duration = 0.0

func perform_technique(technique: int, intensity: float = 0.5):
    anal_pleasure += intensity
