extends Node
class_name AdvancedPerformance

var target_fps: int = 60
var current_fps: float = 0.0
var adaptive_quality: bool = true

var quality_levels: Dictionary = {
    "ultra": {"shadows": 4096, "aa": 4, "lod_distance": 100.0, "particles": 10000},
    "high": {"shadows": 2048, "aa": 2, "lod_distance": 70.0, "particles": 5000},
    "medium": {"shadows": 1024, "aa": 1, "lod_distance": 50.0, "particles": 2000},
    "low": {"shadows": 512, "aa": 0, "lod_distance": 30.0, "particles": 1000}
}
var current_quality: String = "high"

signal quality_changed(level: String)

func _process(delta):
    current_fps = Engine.get_frames_per_second()
    if adaptive_quality:
        if current_fps < 30 and current_quality != "low":
            set_quality("low")
        elif current_fps < 45 and current_quality == "low":
            set_quality("medium")
        elif current_fps < 55 and current_quality == "medium":
            set_quality("high")

func set_quality(level: String):
    if quality_levels.has(level):
        current_quality = level
        quality_changed.emit(level)
