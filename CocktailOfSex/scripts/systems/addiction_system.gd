extends Node
class_name AddictionSystem

var body: CocktailBody
var sex_addiction: float = 0.0
var porn_addiction: float = 0.0
var masturbation_addiction: float = 0.0
var withdrawal_timer: float = 0.0

signal addiction_level_changed(addiction: String, level: float)

func _init(_body: CocktailBody):
    body = _body

func _process(delta):
    if sex_addiction > 50 and withdrawal_timer <= 0:
        body.arousal += delta * 5.0
    withdrawal_timer -= delta
    sex_addiction = max(0, sex_addiction - delta * 0.01)
    porn_addiction = max(0, porn_addiction - delta * 0.005)
    masturbation_addiction = max(0, masturbation_addiction - delta * 0.02)

func record_sex():
    sex_addiction = min(100, sex_addiction + 2.0)
    withdrawal_timer = 3600.0
    addiction_level_changed.emit("sex", sex_addiction)

func record_porn():
    porn_addiction = min(100, porn_addiction + 1.0)
    addiction_level_changed.emit("porn", porn_addiction)

func record_masturbation():
    masturbation_addiction = min(100, masturbation_addiction + 0.5)
    addiction_level_changed.emit("masturbation", masturbation_addiction)
