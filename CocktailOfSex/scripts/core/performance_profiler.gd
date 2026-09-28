extends Node

var fps_history: Array = []
var current_fps: float = 0.0
var draw_debug: bool = false

func _process(delta):
    current_fps = Engine.get_frames_per_second()
    fps_history.append(current_fps)
    if fps_history.size() > 60: fps_history.pop_front()

func get_report() -> String:
    return "FPS: " + str(round(current_fps))
