extends Camera3D
class_name CinematicCameraSystem

# ============================================
# CINEMATIC CAMERA SYSTEM - GTA6 QUALITY
# Dynamic Angles, Depth of Field, Motion Blur
# ============================================

var target_body: CocktailBody
var partner_body: CocktailBody

enum CameraMode {
    FREE_ROAM,
    OVER_SHOULDER,
    FIRST_PERSON,
    CINEMATIC_AUTO,
    CLOSE_UP_GENITAL,
    CLOSE_UP_FACE,
    CLOSE_UP_BODY,
    WIDE_SHOT,
    DUTCH_ANGLE,
    POV_PENETRATOR,
    POV_RECEIVER,
    ORBIT_SLOW,
    TRACKING_SHOT,
    CRANE_SHOT,
    HANDHELD_SHAKE
}

var current_mode: CameraMode = CameraMode.CINEMATIC_AUTO
var target_position: Vector3 = Vector3.ZERO
var target_lookat: Vector3 = Vector3.ZERO
var current_velocity: Vector3 = Vector3.ZERO

var orbit_angle: float = 0.0
var orbit_height: float = 2.0
var orbit_radius: float = 3.0

var handheld_shake_intensity: float = 0.0
var handheld_shake_frequency: float = 10.0

var depth_of_field_enabled: bool = true
var depth_of_field_distance: float = 2.0
var depth_of_field_range: float = 0.5

var motion_blur_enabled: bool = true
var motion_blur_intensity: float = 0.3

var auto_exposure_enabled: bool = true
var exposure_compensation: float = 0.0

var color_grading_enabled: bool = true
var color_temperature: float = 6500.0
var color_tint: float = 0.0
var saturation: float = 1.0
var contrast: float = 1.0

var lens_flare_enabled: bool = true
var vignette_enabled: bool = true
var vignette_intensity: float = 0.3

var cinematic_sequence: Array[Dictionary] = []
var current_sequence_index: int = 0
var sequence_timer: float = 0.0
var sequence_duration: float = 3.0

signal camera_mode_changed(new_mode: CameraMode)
signal cinematic_shot_triggered(shot_description: String)

func _init(_target: CocktailBody, _partner: CocktailBody = null):
    target_body = _target
    partner_body = _partner

func _process(delta):
    _update_cinematic_sequence(delta)
    _apply_handheld_shake(delta)
    _update_post_processing()
    _smooth_move(delta)

func set_mode(mode: CameraMode):
    current_mode = mode
    camera_mode_changed.emit(mode)
    _generate_target_for_mode()

func _generate_target_for_mode():
    if not target_body: return
    match current_mode:
        CameraMode.OVER_SHOULDER:
            target_position = target_body.global_position + Vector3(0, 1.6, -2.0)
            target_lookat = target_body.global_position + Vector3(0, 1.0, 2.0)
        CameraMode.CLOSE_UP_GENITAL:
            target_position = target_body.global_position + Vector3(0, 0.7, 1.0)
            target_lookat = target_body.global_position + Vector3(0, 0.7, 0.0)
        CameraMode.CLOSE_UP_FACE:
            target_position = target_body.global_position + Vector3(0.3, 1.6, 0.5)
            target_lookat = target_body.global_position + Vector3(0, 1.5, 0.0)
        CameraMode.WIDE_SHOT:
            target_position = target_body.global_position + Vector3(0, 3.0, -5.0)
            target_lookat = target_body.global_position
        CameraMode.ORBIT_SLOW:
            target_position = target_body.global_position + Vector3(cos(orbit_angle) * orbit_radius, orbit_height, sin(orbit_angle) * orbit_radius)
            target_lookat = target_body.global_position
            orbit_angle += 0.01
        CameraMode.HANDHELD_SHAKE:
            handheld_shake_intensity = 0.3

func _update_cinematic_sequence(delta):
    if current_mode != CameraMode.CINEMATIC_AUTO: return
    sequence_timer += delta
    if sequence_timer >= sequence_duration:
        sequence_timer = 0.0
        _next_cinematic_shot()

func _next_cinematic_shot():
    var shots = [
        {"mode": CameraMode.CLOSE_UP_FACE, "duration": 3.0, "description": "Close-up on face showing pleasure"},
        {"mode": CameraMode.CLOSE_UP_GENITAL, "duration": 2.0, "description": "Close-up on penetration"},
        {"mode": CameraMode.WIDE_SHOT, "duration": 4.0, "description": "Wide shot showing full bodies"},
        {"mode": CameraMode.OVER_SHOULDER, "duration": 3.0, "description": "Over shoulder view of partner"},
        {"mode": CameraMode.ORBIT_SLOW, "duration": 5.0, "description": "Slow orbit around the couple"},
        {"mode": CameraMode.DUTCH_ANGLE, "duration": 2.0, "description": "Dutch angle for intensity"},
        {"mode": CameraMode.CLOSE_UP_BODY, "duration": 2.5, "description": "Body pan showing sweat and muscles"},
        {"mode": CameraMode.POV_PENETRATOR, "duration": 3.0, "description": "Point of view from penetrator"},
        {"mode": CameraMode.POV_RECEIVER, "duration": 3.0, "description": "Point of view from receiver"}
    ]
    var shot = shots[randi() % shots.size()]
    set_mode(shot["mode"])
    sequence_duration = shot["duration"]
    cinematic_shot_triggered.emit(shot["description"])

func _apply_handheld_shake(delta):
    if handheld_shake_intensity > 0:
        var shake_x = sin(Time.get_ticks_msec() * 0.001 * handheld_shake_frequency) * handheld_shake_intensity * 0.05
        var shake_y = cos(Time.get_ticks_msec() * 0.001 * handheld_shake_frequency * 1.3) * handheld_shake_intensity * 0.05
        target_position += Vector3(shake_x, shake_y, 0)
        handheld_shake_intensity = max(0, handheld_shake_intensity - delta * 0.2)

func _update_post_processing():
    if depth_of_field_enabled:
        var distance_to_target = global_position.distance_to(target_lookat)
        depth_of_field_distance = distance_to_target
    if motion_blur_enabled:
        motion_blur_intensity = current_velocity.length() * 0.1

func _smooth_move(delta):
    global_position = global_position.lerp(target_position, 5.0 * delta)
    var look_target = target_lookat
    look_at(look_target, Vector3.UP)

func trigger_cinematic_climax():
    set_mode(CameraMode.CLOSE_UP_FACE)
    sequence_duration = 5.0
    depth_of_field_range = 0.1
    motion_blur_intensity = 0.5
    handheld_shake_intensity = 0.5
    cinematic_shot_triggered.emit("CLIMAX SHOT - Extreme close-up with intense shake")

func trigger_cinematic_afterglow():
    set_mode(CameraMode.WIDE_SHOT)
    sequence_duration = 8.0
    depth_of_field_range = 1.0
    motion_blur_intensity = 0.05
    handheld_shake_intensity = 0.0
    color_temperature = 5500.0
    vignette_intensity = 0.5
    cinematic_shot_triggered.emit("AFTERGLOW SHOT - Wide, warm, peaceful")
