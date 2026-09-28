extends Node
class_name HapticFeedbackAdvanced

# ============================================
# ADVANCED HAPTIC FEEDBACK SYSTEM
# Supports VR controllers, haptic suits, toys
# ============================================

var body: CocktailBody

enum HapticDevice {
    VR_CONTROLLER_LEFT,
    VR_CONTROLLER_RIGHT,
    HAPTIC_SUIT_CHEST,
    HAPTIC_SUIT_BACK,
    HAPTIC_SUIT_THIGHS,
    HAPTIC_SUIT_ARMS,
    HAPTIC_SUIT_GENITALS,
    BLUETOOTH_TOY_VIBRATOR,
    BLUETOOTH_TOY_PLUG,
    BLUETOOTH_TOY_SLEEVE,
    BLUETOOTH_TOY_STROKER
}

var connected_devices: Array[Dictionary] = []

var haptic_patterns: Dictionary = {
    "gentle_touch": {"intensity": 0.2, "frequency": 1.0, "duration": 0.5, "ramp_up": 0.1, "ramp_down": 0.1},
    "firm_touch": {"intensity": 0.5, "frequency": 2.0, "duration": 0.3, "ramp_up": 0.05, "ramp_down": 0.05},
    "thrust": {"intensity": 0.7, "frequency": 3.0, "duration": 0.2, "ramp_up": 0.0, "ramp_down": 0.1},
    "deep_thrust": {"intensity": 1.0, "frequency": 1.5, "duration": 0.4, "ramp_up": 0.0, "ramp_down": 0.2},
    "lick": {"intensity": 0.3, "frequency": 4.0, "duration": 0.8, "ramp_up": 0.2, "ramp_down": 0.2},
    "suck": {"intensity": 0.6, "frequency": 2.5, "duration": 1.0, "ramp_up": 0.3, "ramp_down": 0.3},
    "orgasm_buildup": {"intensity": 0.8, "frequency": 5.0, "duration": 3.0, "ramp_up": 2.0, "ramp_down": 0.5},
    "orgasm_peak": {"intensity": 1.0, "frequency": 10.0, "duration": 1.0, "ramp_up": 0.0, "ramp_down": 1.0},
    "orgasm_release": {"intensity": 0.4, "frequency": 1.0, "duration": 2.0, "ramp_up": 0.0, "ramp_down": 2.0},
    "afterglow": {"intensity": 0.1, "frequency": 0.5, "duration": 5.0, "ramp_up": 1.0, "ramp_down": 4.0},
    "spank": {"intensity": 0.9, "frequency": 1.0, "duration": 0.1, "ramp_up": 0.0, "ramp_down": 0.1},
    "bite": {"intensity": 0.7, "frequency": 3.0, "duration": 0.3, "ramp_up": 0.0, "ramp_down": 0.1}
}

var active_patterns: Array[Dictionary] = []

signal haptic_triggered(pattern: String, intensity: float)
signal device_connected(device_type: int)
signal device_disconnected(device_type: int)

func _init(_body: CocktailBody):
    body = _body

func _ready():
    _scan_for_devices()

func _scan_for_devices():
    connected_devices.append({"type": HapticDevice.VR_CONTROLLER_LEFT, "id": "vr_left", "battery": 1.0})
    connected_devices.append({"type": HapticDevice.VR_CONTROLLER_RIGHT, "id": "vr_right", "battery": 1.0})

func trigger_haptic(zone: String, action: String, intensity: float = 0.5):
    if not haptic_patterns.has(action): return
    var pattern = haptic_patterns[action].duplicate()
    pattern["intensity"] *= intensity
    var target_devices = _get_devices_for_zone(zone)
    for device in target_devices:
        _send_haptic_command(device, pattern)
    haptic_triggered.emit(action, intensity)

func _get_devices_for_zone(zone: String) -> Array:
    match zone:
        "penis_head", "penis_shaft":
            return [HapticDevice.BLUETOOTH_TOY_SLEEVE, HapticDevice.BLUETOOTH_TOY_STROKER]
        "clitoris", "vagina_wall":
            return [HapticDevice.BLUETOOTH_TOY_VIBRATOR, HapticDevice.HAPTIC_SUIT_GENITALS]
        "anus_ring", "anus_deep":
            return [HapticDevice.BLUETOOTH_TOY_PLUG, HapticDevice.HAPTIC_SUIT_GENITALS]
        "nipples", "chest":
            return [HapticDevice.HAPTIC_SUIT_CHEST]
        "butt":
            return [HapticDevice.HAPTIC_SUIT_BACK, HapticDevice.BLUETOOTH_TOY_PLUG]
        "thighs":
            return [HapticDevice.HAPTIC_SUIT_THIGHS]
        _:
            return [HapticDevice.VR_CONTROLLER_LEFT, HapticDevice.VR_CONTROLLER_RIGHT]

func _send_haptic_command(device_type: int, pattern: Dictionary):
    for device in connected_devices:
        if device["type"] == device_type:
            _execute_pattern(device, pattern)

func _execute_pattern(device: Dictionary, pattern: Dictionary):
    var tween = create_tween()
    tween.tween_method(func(v): _set_device_intensity(device, v), 0.0, pattern["intensity"], pattern["ramp_up"])
    tween.tween_interval(pattern["duration"])
    tween.tween_method(func(v): _set_device_intensity(device, v), pattern["intensity"], 0.0, pattern["ramp_down"])

func _set_device_intensity(device: Dictionary, intensity: float):
    pass

func trigger_orgasm_sequence():
    trigger_haptic("genitals", "orgasm_buildup", 1.0)
    await get_tree().create_timer(3.0).timeout
    trigger_haptic("genitals", "orgasm_peak", 1.0)
    await get_tree().create_timer(1.0).timeout
    trigger_haptic("genitals", "orgasm_release", 1.0)
    await get_tree().create_timer(2.0).timeout
    trigger_haptic("genitals", "afterglow", 1.0)

func sync_haptic_to_thrust(depth: float, speed: float):
    var intensity = depth * speed
    trigger_haptic("genitals", "thrust", intensity)
