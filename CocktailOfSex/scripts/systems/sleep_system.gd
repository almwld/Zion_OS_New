extends Node
class_name SleepSystem

var body: CocktailBody
var is_sleeping: bool = false
var sleep_quality: float = 0.5
var sleep_duration: float = 0.0
var sleep_debt: float = 0.0

var can_have_wet_dream: bool = true
var wet_dream_chance: float = 0.1

signal fell_asleep()
signal woke_up(duration: float, quality: float)
signal wet_dream_occurred()

func _init(_body: CocktailBody):
    body = _body

func start_sleep():
    is_sleeping = true
    sleep_duration = 0.0
    fell_asleep.emit()

func _process(delta):
    if not is_sleeping: return
    sleep_duration += delta
    if sleep_debt > 0:
        sleep_debt = max(0, sleep_debt - delta * 0.5)
    if sleep_duration > 3600.0 and can_have_wet_dream and body.arousal > 50.0:
        if randf() < wet_dream_chance:
            _trigger_wet_dream()

func end_sleep():
    if not is_sleeping: return
    is_sleeping = false
    sleep_quality = _calculate_sleep_quality()
    woke_up.emit(sleep_duration, sleep_quality)

func _calculate_sleep_quality() -> float:
    var quality = 0.5
    if sleep_duration >= 28800.0:
        quality = 1.0
    elif sleep_duration >= 21600.0:
        quality = 0.8
    elif sleep_duration >= 14400.0:
        quality = 0.6
    else:
        quality = 0.3
    quality -= sleep_debt * 0.1
    return clamp(quality, 0.0, 1.0)

func _trigger_wet_dream():
    wet_dream_occurred.emit()
    body.arousal = 80.0
    body._achieve_orgasm()
    can_have_wet_dream = false
    await get_tree().create_timer(86400.0).timeout
    can_have_wet_dream = true

func add_sleep_debt(amount: float):
    sleep_debt = min(100.0, sleep_debt + amount)

func get_sleep_report() -> Dictionary:
    return {
        "sleeping": is_sleeping,
        "duration": sleep_duration,
        "quality": sleep_quality,
        "debt": sleep_debt
    }
