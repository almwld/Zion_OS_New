extends Node
class_name NeuralAnimationController

var body: CocktailBody
var animation_player: AnimationPlayer
var skeleton: Skeleton3D

var current_pose: Dictionary = {}
var target_pose: Dictionary = {}
var pose_velocity: Dictionary = {}

var animation_blend_time: float = 0.3
var animation_strength: float = 1.0

var sex_position: String = "missionary"
var thrust_cycle: float = 0.0
var thrust_speed: float = 1.0
var thrust_depth: float = 0.5

var breathing_rate: float = 1.0
var breathing_depth: float = 0.3

var muscle_tension: float = 0.0
var body_sway: float = 0.0

var spine_curvature: float = 0.0
var hip_tilt: float = 0.0
var shoulder_rotation: float = 0.0

var facial_expression: String = "neutral"
var facial_blend: float = 0.0

var eye_gaze_target: Vector3 = Vector3.ZERO
var eye_gaze_weight: float = 0.0

var hand_pose_left: String = "relaxed"
var hand_pose_right: String = "relaxed"

var ik_targets: Dictionary = {
    "left_hand": Vector3.ZERO,
    "right_hand": Vector3.ZERO,
    "left_foot": Vector3.ZERO,
    "right_foot": Vector3.ZERO,
    "pelvis": Vector3.ZERO,
    "spine": Vector3.ZERO,
    "head": Vector3.ZERO
}

signal pose_updated(pose_name: String)
signal animation_cycle_completed()
signal thrust_event(depth: float, speed: float)

func _init(_body: CocktailBody):
    body = _body

func _ready():
    _find_skeleton()
    _initialize_poses()

func _find_skeleton():
    animation_player = body.get_node_or_null("AnimationPlayer")
    skeleton = body.get_node_or_null("Skeleton3D")
    if not skeleton:
        for child in body.get_children():
            if child is Skeleton3D:
                skeleton = child
                break

func _initialize_poses():
    var bones = ["spine", "spine_01", "spine_02", "neck", "head",
                 "clavicle_l", "upperarm_l", "lowerarm_l", "hand_l",
                 "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
                 "thigh_l", "calf_l", "foot_l", "thigh_r", "calf_r", "foot_r",
                 "pelvis"]
    for bone in bones:
        current_pose[bone] = Transform3D.IDENTITY
        target_pose[bone] = Transform3D.IDENTITY
        pose_velocity[bone] = Vector3.ZERO

func _process(delta):
    _update_thrust_cycle(delta)
    _update_breathing(delta)
    _update_muscle_tension(delta)
    _update_facial_expression(delta)
    _update_body_sway(delta)
    _interpolate_poses(delta)
    _apply_poses()
    _solve_ik(delta)

func _update_thrust_cycle(delta):
    thrust_cycle += delta * thrust_speed * 2.0 * PI
    if thrust_cycle > 2.0 * PI:
        thrust_cycle -= 2.0 * PI
        animation_cycle_completed.emit()
    var thrust_offset = sin(thrust_cycle) * thrust_depth * 0.15
    target_pose["pelvis"] = Transform3D.IDENTITY.translated(Vector3(0, 0, thrust_offset))
    target_pose["spine"] = Transform3D.IDENTITY.rotated(Vector3(1, 0, 0), sin(thrust_cycle) * thrust_depth * 0.1)
    var depth = abs(sin(thrust_cycle)) * thrust_depth
    thrust_event.emit(depth, thrust_speed)

func _update_breathing(delta):
    var breath_cycle = sin(Time.get_ticks_msec() * 0.001 * breathing_rate)
    breathing_depth = lerp(breathing_depth, body.arousal / 100.0 * 0.5 + 0.1, delta * 2.0)
    var chest_expansion = breath_cycle * breathing_depth * 0.05
    target_pose["spine_01"] = Transform3D.IDENTITY.scaled(Vector3(1 + chest_expansion, 1, 1 + chest_expansion))
    target_pose["spine_02"] = Transform3D.IDENTITY.scaled(Vector3(1 + chest_expansion, 1, 1 + chest_expansion))

func _update_muscle_tension(delta):
    muscle_tension = lerp(muscle_tension, body.arousal / 100.0, delta * 3.0)
    spine_curvature = muscle_tension * 0.1
    target_pose["spine"] = target_pose["spine"].rotated(Vector3(1, 0, 0), spine_curvature)
    target_pose["spine_01"] = target_pose["spine_01"].rotated(Vector3(1, 0, 0), -spine_curvature * 0.5)

func _update_facial_expression(delta):
    var arousal = body.arousal
    if arousal < 20:
        facial_expression = "neutral"
    elif arousal < 50:
        facial_expression = "pleasure_mild"
    elif arousal < 80:
        facial_expression = "pleasure_strong"
    elif arousal < 95:
        facial_expression = "ecstasy"
    else:
        facial_expression = "climax"
    facial_blend = lerp(facial_blend, 1.0, delta * 5.0)

func _update_body_sway(delta):
    body_sway = sin(Time.get_ticks_msec() * 0.001 * 0.5) * 0.02
    target_pose["spine"] = target_pose["spine"].rotated(Vector3(0, 0, 1), body_sway)

func _interpolate_poses(delta):
    var speed = 10.0 * animation_strength
    for bone in current_pose:
        current_pose[bone] = current_pose[bone].interpolate_with(target_pose[bone], min(speed * delta, 1.0))

func _apply_poses():
    if not skeleton: return
    for bone in current_pose:
        var bone_idx = skeleton.find_bone(bone)
        if bone_idx >= 0:
            skeleton.set_bone_pose(bone_idx, current_pose[bone])

func _solve_ik(delta):
    if not skeleton: return
    _solve_two_bone_ik("upperarm_l", "lowerarm_l", "hand_l", ik_targets["left_hand"])
    _solve_two_bone_ik("upperarm_r", "lowerarm_r", "hand_r", ik_targets["right_hand"])
    _solve_two_bone_ik("thigh_l", "calf_l", "foot_l", ik_targets["left_foot"])
    _solve_two_bone_ik("thigh_r", "calf_r", "foot_r", ik_targets["right_foot"])

func _solve_two_bone_ik(upper: String, lower: String, end: String, target: Vector3):
    var upper_idx = skeleton.find_bone(upper)
    var lower_idx = skeleton.find_bone(lower)
    var end_idx = skeleton.find_bone(end)
    if upper_idx < 0 or lower_idx < 0 or end_idx < 0: return

func set_position(position_name: String):
    sex_position = position_name
    match position_name:
        "missionary":
            ik_targets["pelvis"] = Vector3(0, 0.8, 0.2)
            ik_targets["left_hand"] = Vector3(0.3, 1.0, 0.5)
            ik_targets["right_hand"] = Vector3(-0.3, 1.0, 0.5)
            ik_targets["left_foot"] = Vector3(0.3, 0.3, 0.5)
            ik_targets["right_foot"] = Vector3(-0.3, 0.3, 0.5)
        "doggy":
            ik_targets["pelvis"] = Vector3(0, 0.6, 0.4)
            ik_targets["left_hand"] = Vector3(0.4, 0.5, 0.5)
            ik_targets["right_hand"] = Vector3(-0.4, 0.5, 0.5)
            ik_targets["left_foot"] = Vector3(0.4, 0.1, 0.5)
            ik_targets["right_foot"] = Vector3(-0.4, 0.1, 0.5)
        "cowgirl":
            ik_targets["pelvis"] = Vector3(0, 1.0, 0.0)
            ik_targets["left_hand"] = Vector3(0.3, 1.2, 0.3)
            ik_targets["right_hand"] = Vector3(-0.3, 1.2, 0.3)
            ik_targets["left_foot"] = Vector3(0.3, 0.5, 0.3)
            ik_targets["right_foot"] = Vector3(-0.3, 0.5, 0.3)
    pose_updated.emit(position_name)

func trigger_orgasm_animation():
    animation_strength = 2.0
    body_sway = 0.1
    breathing_rate = 3.0
    breathing_depth = 1.0
    muscle_tension = 1.0
    facial_expression = "climax"
    await get_tree().create_timer(3.0).timeout
    animation_strength = 0.3
    breathing_rate = 0.8
    breathing_depth = 0.2
    muscle_tension = 0.1
    facial_expression = "afterglow"
