extends Node
class_name DreamSex

var body: CocktailBody
var is_dreaming: bool = false
var current_dream: Dictionary = {}
var dream_history: Array[Dictionary] = []

var dream_scenarios: Array[String] = [
    "flying_sex", "underwater_orgy", "haunted_bedroom",
    "giant_partner", "tiny_partner", "mirror_world",
    "shadow_lover", "animal_spirits", "celestial_bodies",
    "plant_tentacles", "machine_pleasure", "elemental_fusion"
]

signal dream_started(dream_type: String)
signal dream_ended(dream_type: String)
signal wet_dream_orgasm()

func _init(_body: CocktailBody):
    body = _body

func enter_dream():
    is_dreaming = true
    var dream_type = dream_scenarios[randi() % dream_scenarios.size()]
    current_dream = {"type": dream_type, "start_time": Time.get_ticks_msec()}
    dream_started.emit(dream_type)

func _process(delta):
    if is_dreaming:
        body.arousal += delta * 5.0
        if body.arousal > 90 and randf() < delta * 0.5:
            wet_dream_orgasm.emit()
            body._achieve_orgasm()

func exit_dream():
    is_dreaming = false
    current_dream["end_time"] = Time.get_ticks_msec()
    dream_history.append(current_dream)
    dream_ended.emit(current_dream["type"])
