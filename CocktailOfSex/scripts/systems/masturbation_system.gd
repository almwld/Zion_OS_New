extends Node
class_name MasturbationSystem

var body: CocktailBody
var is_masturbating: bool = false
var masturbation_speed: float = 0.5
var masturbation_intensity: float = 0.5
var masturbation_duration: float = 0.0
var total_masturbation_sessions: int = 0
var total_masturbation_time: float = 0.0

var techniques: Dictionary = {
    "hand": {"speed": 0.7, "intensity": 0.6, "description": "Using hand to stroke"},
    "pillow_humping": {"speed": 0.5, "intensity": 0.4, "description": "Grinding against a pillow"},
    "shower_head": {"speed": 0.6, "intensity": 0.7, "description": "Using water pressure"},
    "vibrator": {"speed": 0.9, "intensity": 0.9, "description": "Using a vibrating toy"},
    "dildo": {"speed": 0.6, "intensity": 0.8, "description": "Using a penetrative toy"},
    "fleshlight": {"speed": 0.7, "intensity": 0.8, "description": "Using a sleeve toy"},
    "fingers": {"speed": 0.5, "intensity": 0.5, "description": "Using fingers to stimulate"}
}

var current_technique: String = "hand"

signal masturbation_started()
signal masturbation_ended(duration: float, orgasm_achieved: bool)
signal technique_changed(technique: String)

func _init(_body: CocktailBody):
    body = _body

func start_masturbation(technique: String = "hand"):
    if is_masturbating: return
    is_masturbating = true
    current_technique = technique
    masturbation_duration = 0.0
    if techniques.has(technique):
        masturbation_speed = techniques[technique]["speed"]
        masturbation_intensity = techniques[technique]["intensity"]
    total_masturbation_sessions += 1
    masturbation_started.emit()

func _process(delta):
    if not is_masturbating: return
    masturbation_duration += delta
    total_masturbation_time += delta
    var effective_intensity = masturbation_intensity * masturbation_speed
    if body.gender == "male" or body.gender == "futa":
        body.stimulate("penis_head", "rub", effective_intensity, delta)
        body.stimulate("penis_shaft", "rub", effective_intensity * 0.8, delta)
    if body.gender == "female" or body.gender == "futa":
        body.stimulate("clitoris", "rub", effective_intensity, delta)
        if current_technique in ["dildo", "fingers"]:
            body.stimulate("vagina_wall", "penetrate", effective_intensity * 0.7, delta)
    if body.arousal > body.orgasm_threshold:
        end_masturbation(true)

func end_masturbation(orgasm: bool = false):
    is_masturbating = false
    masturbation_ended.emit(masturbation_duration, orgasm)

func switch_technique(technique: String):
    if techniques.has(technique):
        current_technique = technique
        masturbation_speed = techniques[technique]["speed"]
        masturbation_intensity = techniques[technique]["intensity"]
        technique_changed.emit(technique)

func get_masturbation_report() -> Dictionary:
    return {
        "total_sessions": total_masturbation_sessions,
        "total_time": total_masturbation_time,
        "average_duration": total_masturbation_time / max(1, total_masturbation_sessions)
    }
