extends Node
class_name UltimateGodTools

var assembly: FinalAssembly

# --- Developer Shortcuts ---
var debug_visible: bool = false
var fps_display: bool = true
var wireframe_mode: bool = false
var slow_motion: bool = false
var freeze_time: bool = false
var infinite_money: bool = false

# --- Spawn Controls ---
var spawn_body_count: int = 1
var spawn_gender: String = "female"
var spawn_age: int = 25

# --- Scene Controls ---
var auto_climax: bool = false
var auto_climax_interval: float = 30.0
var auto_climax_timer: float = 0.0
var force_climax_all: bool = false

# --- Recording ---
var is_recording_video: bool = false
var video_frame_count: int = 0
var video_frames: Array[Image] = []

signal debug_toggled(visible: bool)
signal body_spawned(body: CocktailBody)
signal video_frame_captured(frame: int)

func _init(_assembly: FinalAssembly):
    assembly = _assembly

func _process(delta):
    if auto_climax:
        auto_climax_timer += delta
        if auto_climax_timer >= auto_climax_interval:
            auto_climax_timer = 0.0
            _force_all_to_climax()
    if is_recording_video:
        _capture_video_frame(delta)

func toggle_debug():
    debug_visible = !debug_visible
    debug_toggled.emit(debug_visible)

func toggle_wireframe():
    wireframe_mode = !wireframe_mode
    var viewport = assembly.get_viewport()
    viewport.debug_draw = 1 if wireframe_mode else 0

func toggle_slow_motion():
    slow_motion = !slow_motion
    Engine.time_scale = 0.25 if slow_motion else 1.0

func toggle_freeze_time():
    freeze_time = !freeze_time
    Engine.time_scale = 0.0 if freeze_time else 1.0

func toggle_infinite_money():
    infinite_money = !infinite_money
    for economy in assembly.economy_systems:
        if infinite_money:
            economy.add_money(999999.0, "developer_cheat")
        else:
            economy.money = 500.0

func spawn_random_body() -> CocktailBody:
    var gender = spawn_gender if spawn_gender != "random" else ["male", "female"][randi() % 2]
    var name_pool = ["Aria", "Luna", "Nova", "Sage", "River", "Kai", "Jade", "Ash", "Ember", "Storm"]
    var name = name_pool[randi() % name_pool.size()]
    var body = assembly.create_full_body(name, gender, spawn_age)
    body.global_position = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
    body_spawned.emit(body)
    return body

func spawn_orgy(count: int = 10):
    for i in range(count):
        spawn_random_body()
    print("[GodTools] Spawned " + str(count) + " bodies for orgy")

func _force_all_to_climax():
    for body in assembly.all_bodies:
        body.arousal = body.max_arousal
        body._achieve_orgasm()
    print("[GodTools] Forced all bodies to climax!")

func start_video_recording():
    is_recording_video = true
    video_frame_count = 0
    video_frames.clear()
    print("[GodTools] Video recording started")

func stop_video_recording() -> String:
    is_recording_video = false
    var path = "user://recordings/scene_" + str(Time.get_unix_time_from_system()) + ".avi"
    print("[GodTools] Video recording saved to: " + path + " (" + str(video_frame_count) + " frames)")
    return path

func _capture_video_frame(delta):
    video_frame_count += 1
    var viewport = assembly.get_viewport()
    var image = viewport.get_texture().get_image()
    video_frames.append(image)
    video_frame_captured.emit(video_frame_count)

func get_developer_console_output() -> String:
    var output = "=== DEVELOPER CONSOLE ===\n"
    output += "Bodies: " + str(assembly.all_bodies.size()) + "\n"
    output += "Scene Active: " + str(assembly.is_scene_active) + "\n"
    output += "God Mode: " + str(assembly.god_mode_active) + "\n"
    output += "Wireframe: " + str(wireframe_mode) + "\n"
    output += "Slow Motion: " + str(slow_motion) + "\n"
    output += "Freeze Time: " + str(freeze_time) + "\n"
    output += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
    return output
