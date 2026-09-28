extends Node
class_name FullVRIntegration

var xr_interface: XRInterface
var vr_active: bool = false

var head_camera: XRCamera3D
var left_controller: XRController3D
var right_controller: XRController3D

var left_hand_skeleton: Skeleton3D
var right_hand_skeleton: Skeleton3D

var hand_gestures: Dictionary = {
    "grab": false,
    "point": false,
    "open_palm": false,
    "fist": false,
    "peace": false,
    "thumbs_up": false
}

var vr_body: CocktailBody
var vr_scene_active: bool = false

signal vr_initialized()
signal gesture_detected(gesture: String, hand: String)
signal vr_body_touched(part: String, intensity: float)

func _ready():
    _init_vr()

func _init_vr():
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.initialize():
        vr_active = true
        get_viewport().use_xr = true
        head_camera = XRCamera3D.new()
        add_child(head_camera)
        left_controller = XRController3D.new()
        left_controller.controller_id = 0
        add_child(left_controller)
        right_controller = XRController3D.new()
        right_controller.controller_id = 1
        add_child(right_controller)
        vr_initialized.emit()

func _process(delta):
    if not vr_active: return
    _track_controllers()
    _detect_gestures()

func _track_controllers():
    if left_controller:
        var pos = left_controller.global_position
        if vr_body and vr_scene_active:
            var dist = pos.distance_to(vr_body.global_position)
            if dist < 0.2:
                vr_body.stimulate("skin", "touch", 0.5, 0.1)

func _detect_gestures():
    pass

func start_vr_scene(body: CocktailBody):
    vr_body = body
    vr_scene_active = true

func stop_vr_scene():
    vr_scene_active = false
    vr_body = null
