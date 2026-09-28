extends Node
class_name MenstrualCycle

var body: CocktailBody
var cycle_day: int = 1
var cycle_length: int = 28
var is_fertile: bool = false
var is_menstruating: bool = false

signal fertility_changed(fertile: bool)
signal menstruation_started()
signal menstruation_ended()

func _init(_body: CocktailBody):
    body = _body
    cycle_day = randi() % cycle_length + 1

func _process(delta):
    pass

func advance_day():
    cycle_day += 1
    if cycle_day > cycle_length:
        cycle_day = 1
    is_fertile = (cycle_day >= 10 and cycle_day <= 17)
    is_menstruating = (cycle_day <= 5)
    fertility_changed.emit(is_fertile)
    if cycle_day == 1:
        menstruation_started.emit()
    if cycle_day == 6:
        menstruation_ended.emit()

func get_fertility() -> float:
    if is_fertile:
        return 1.0
    elif cycle_day >= 6 and cycle_day <= 9:
        return 0.3
    elif cycle_day >= 18 and cycle_day <= 21:
        return 0.2
    else:
        return 0.05
