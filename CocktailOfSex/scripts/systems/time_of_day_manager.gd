extends Node
class_name TimeOfDayManager

var time_of_day: float = 8.0
var day_length: float = 1200.0
var time_scale: float = 1.0

var sun_light: DirectionalLight3D
var moon_light: DirectionalLight3D

var sun_color_morning: Color = Color(1.0, 0.6, 0.3)
var sun_color_noon: Color = Color(1.0, 0.95, 0.8)
var sun_color_evening: Color = Color(1.0, 0.4, 0.2)
var moon_color: Color = Color(0.3, 0.4, 0.8)

var current_time_name: String = "Morning"

signal time_changed(hour: float, time_name: String)
signal sunrise()
signal sunset()
signal midnight()

func _ready():
    _find_lights()

func _find_lights():
    var lights = get_tree().get_nodes_in_group("Lights")
    for light in lights:
        if light is DirectionalLight3D:
            if light.name.to_lower().contains("sun"):
                sun_light = light
            elif light.name.to_lower().contains("moon"):
                moon_light = light

func _process(delta):
    time_of_day += delta * time_scale / (day_length / 24.0)
    if time_of_day >= 24.0:
        time_of_day -= 24.0
    _update_lighting()
    _update_time_name()
    time_changed.emit(time_of_day, current_time_name)
    if time_of_day > 5.9 and time_of_day < 6.1: sunrise.emit()
    if time_of_day > 17.9 and time_of_day < 18.1: sunset.emit()
    if time_of_day > 23.9 or time_of_day < 0.1: midnight.emit()

func _update_lighting():
    var sun_angle = (time_of_day - 6.0) / 12.0 * PI
    if sun_light:
        sun_light.global_rotation = Vector3(sun_angle, 0, 0)
        if time_of_day >= 6 and time_of_day <= 18:
            var t = (time_of_day - 6.0) / 6.0
            if t < 1.0:
                sun_light.light_color = sun_color_morning.lerp(sun_color_noon, t)
            else:
                sun_light.light_color = sun_color_noon.lerp(sun_color_evening, t - 1.0)
            sun_light.light_energy = sin(sun_angle) * 1.5
        else:
            sun_light.light_energy = 0.0
    if moon_light:
        if time_of_day < 6 or time_of_day > 18:
            moon_light.light_energy = 0.8
            moon_light.light_color = moon_color
        else:
            moon_light.light_energy = 0.0

func _update_time_name():
    if time_of_day < 5: current_time_name = "Late Night"
    elif time_of_day < 7: current_time_name = "Dawn"
    elif time_of_day < 10: current_time_name = "Morning"
    elif time_of_day < 12: current_time_name = "Late Morning"
    elif time_of_day < 14: current_time_name = "Noon"
    elif time_of_day < 17: current_time_name = "Afternoon"
    elif time_of_day < 19: current_time_name = "Evening"
    elif time_of_day < 21: current_time_name = "Dusk"
    elif time_of_day < 23: current_time_name = "Night"
    else: current_time_name = "Late Night"

func set_time(hour: float):
    time_of_day = hour

func get_hour() -> float:
    return time_of_day

func get_time_name() -> String:
    return current_time_name

func is_daytime() -> bool:
    return time_of_day >= 6 and time_of_day <= 18

func is_nighttime() -> bool:
    return not is_daytime()
