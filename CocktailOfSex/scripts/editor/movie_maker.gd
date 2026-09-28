extends Node
class_name MovieMaker

var recording: bool = false
var frames: Array[Dictionary] = []

func start():
    recording = true; frames.clear()

func _process(delta):
    if recording:
        var fd = {}
        for b in get_tree().get_nodes_in_group("Actors"):
            if b is CocktailBody:
                fd[b.body_name] = {
                    "pos": b.global_position,
                    "rot": b.global_rotation,
                    "arousal": b.arousal,
                    "climax": b.is_climaxing
                }
        frames.append(fd)

func stop() -> String:
    recording = false
    var path = "user://movies/scene_" + str(Time.get_unix_time_from_system()) + ".json"
    var f = FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(frames))
    f.close()
    return path

func play(path: String):
    var f = FileAccess.open(path, FileAccess.READ)
    var data = JSON.parse_string(f.get_as_text())
    var tween = create_tween()
    for frame in data:
        tween.tween_callback(func():
            for name in frame:
                var b = _find(name)
                if b:
                    b.global_position = frame[name]["pos"]
                    b.global_rotation = frame[name]["rot"]
                    b.arousal = frame[name]["arousal"]
                    b.is_climaxing = frame[name]["climax"]
        )
        tween.tween_interval(0.033)

func _find(name: String) -> CocktailBody:
    for b in get_tree().get_nodes_in_group("Actors"):
        if b is CocktailBody and b.body_name == name: return b
    return null
