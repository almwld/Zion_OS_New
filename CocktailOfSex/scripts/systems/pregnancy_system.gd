extends Node

var characters: Array = []

func _ready():
    pass

func check_pregnancy(penetrator, receiver, creampie: bool):
    if not creampie or receiver.gender != "female" or receiver.has_meta("pregnant"): return
    if randf() < 0.15:
        receiver.set_meta("pregnant", true)
        receiver.set_meta("progress", 0.0)

func update_pregnancy(delta: float):
    for body in characters:
        if body.has_meta("pregnant") and body.get_meta("pregnant"):
            var progress = body.get_meta("progress") + delta * 0.001
            body.set_meta("progress", progress)
            if progress >= 1.0:
                body.set_meta("pregnant", false)
                body.set_meta("progress", 0.0)
