extends Node

enum DayTime { MORNING, NOON, AFTERNOON, EVENING, NIGHT, LATE }
enum Climate { SUNNY, RAINY, SNOWY, STORMY, FOGGY, HEAT }

var current_time: int = DayTime.MORNING
var current_weather: int = Climate.SUNNY
var time_elapsed: float = 0.0
var day_cycle_speed: float = 60.0

signal time_changed(new_time: int)
signal weather_changed(new_weather: int)

func _process(delta):
    time_elapsed += delta * day_cycle_speed
    var hour = fmod(time_elapsed / 60.0, 24.0)
    var nt = current_time
    if hour < 6: nt = DayTime.LATE
    elif hour < 8: nt = DayTime.MORNING
    elif hour < 12: nt = DayTime.NOON
    elif hour < 17: nt = DayTime.AFTERNOON
    elif hour < 21: nt = DayTime.EVENING
    else: nt = DayTime.NIGHT
    if nt != current_time:
        current_time = nt
        time_changed.emit(current_time)
    if randf() < 0.001:
        var wlist = [Climate.SUNNY, Climate.RAINY, Climate.SNOWY, Climate.STORMY, Climate.FOGGY, Climate.HEAT]
        var nw = wlist[randi() % wlist.size()]
        if nw != current_weather:
            current_weather = nw
            weather_changed.emit(current_weather)

func modifier() -> float:
    var m = 1.0
    if current_time == DayTime.LATE: m *= 1.5
    elif current_time == DayTime.MORNING: m *= 1.3
    if current_weather == Climate.RAINY: m *= 1.4
    elif current_weather == Climate.STORMY: m *= 1.6
    return m
