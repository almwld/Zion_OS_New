extends Node
class_name SensoryOverload

var body: CocktailBody

# --- Multi-Sensory Stimulation ---
var visual_stimulation: float = 0.0
var auditory_stimulation: float = 0.0
var olfactory_stimulation: float = 0.0
var gustatory_stimulation: float = 0.0
var tactile_stimulation: float = 0.0
var proprioceptive_stimulation: float = 0.0

# --- Sensory Thresholds ---
var pleasure_threshold: float = 50.0
var overload_threshold: float = 90.0
var is_in_overload: bool = false
var overload_duration: float = 0.0

# --- Visual Triggers ---
var visual_nudity: bool = false
var visual_genitals: bool = false
var visual_penetration: bool = false
var visual_fluids: bool = false
var visual_expressions: bool = false

# --- Auditory Triggers ---
var auditory_moans: bool = false
var auditory_wet_sounds: bool = false
var auditory_dirty_talk: bool = false
var auditory_bed_sounds: bool = false
var auditory_breathing: bool = false

# --- Olfactory Triggers ---
var scent_arousal: float = 0.0
var scent_pheromones: float = 0.0
var scent_sweat: float = 0.0
var scent_perfume: float = 0.0

# --- Gustatory Triggers ---
var taste_salt: float = 0.0
var taste_sweet: float = 0.0
var taste_musk: float = 0.0
var taste_cum: float = 0.0

# --- Tactile Triggers ---
var touch_pressure: float = 0.0
var touch_temperature: float = 36.5
var touch_texture: float = 0.0
var touch_vibration: float = 0.0

signal sensory_overload_started()
signal sensory_overload_ended()
signal sense_triggered(sense: String, intensity: float)
signal orgasm_from_overload()

func _init(_body: CocktailBody):
    body = _body

func _process(delta):
    _calculate_total_stimulation()
    _check_overload(delta)
    _update_body_response(delta)

func _calculate_total_stimulation():
    visual_stimulation = _calc_visual()
    auditory_stimulation = _calc_auditory()
    olfactory_stimulation = _calc_olfactory()
    gustatory_stimulation = _calc_gustatory()
    tactile_stimulation = _calc_tactile()
    proprioceptive_stimulation = body.arousal / 100.0 * 0.5

func _calc_visual() -> float:
    var total = 0.0
    if visual_nudity: total += 15.0
    if visual_genitals: total += 25.0
    if visual_penetration: total += 35.0
    if visual_fluids: total += 20.0
    if visual_expressions: total += 10.0
    return min(100.0, total)

func _calc_auditory() -> float:
    var total = 0.0
    if auditory_moans: total += 20.0
    if auditory_wet_sounds: total += 25.0
    if auditory_dirty_talk: total += 15.0
    if auditory_bed_sounds: total += 10.0
    if auditory_breathing: total += 10.0
    return min(100.0, total)

func _calc_olfactory() -> float:
    return min(100.0, scent_arousal + scent_pheromones + scent_sweat + scent_perfume)

func _calc_gustatory() -> float:
    return min(100.0, taste_salt + taste_sweet + taste_musk + taste_cum)

func _calc_tactile() -> float:
    return min(100.0, touch_pressure * 30 + abs(touch_temperature - 36.5) * 5 + touch_texture * 20 + touch_vibration * 25)

func _check_overload(delta):
    var total = _get_total_stimulation()
    if total > overload_threshold and not is_in_overload:
        is_in_overload = true
        overload_duration = 0.0
        sensory_overload_started.emit()
    elif total < overload_threshold * 0.7 and is_in_overload:
        is_in_overload = false
        sensory_overload_ended.emit()
    if is_in_overload:
        overload_duration += delta
        body.arousal = min(body.max_arousal, body.arousal + delta * 20.0)
        if randf() < delta * 0.3:
            orgasm_from_overload.emit()
            body._achieve_orgasm()

func _get_total_stimulation() -> float:
    return (visual_stimulation + auditory_stimulation + olfactory_stimulation + gustatory_stimulation + tactile_stimulation + proprioceptive_stimulation) / 6.0

func _update_body_response(delta):
    var total = _get_total_stimulation()
    body.arousal = min(body.max_arousal, body.arousal + total * delta * 0.5)

func trigger_visual(element: String, active: bool):
    match element:
        "nudity": visual_nudity = active
        "genitals": visual_genitals = active
        "penetration": visual_penetration = active
        "fluids": visual_fluids = active
        "expressions": visual_expressions = active
    sense_triggered.emit("visual_" + element, 1.0 if active else 0.0)

func trigger_auditory(element: String, active: bool):
    match element:
        "moans": auditory_moans = active
        "wet": auditory_wet_sounds = active
        "talk": auditory_dirty_talk = active
        "bed": auditory_bed_sounds = active
        "breath": auditory_breathing = active
    sense_triggered.emit("auditory_" + element, 1.0 if active else 0.0)

func trigger_tactile(pressure: float = 0.0, temperature: float = 36.5, texture: float = 0.0, vibration: float = 0.0):
    touch_pressure = pressure
    touch_temperature = temperature
    touch_texture = texture
    touch_vibration = vibration
    sense_triggered.emit("tactile", (pressure + texture + vibration) / 3.0)

func get_sensory_report() -> Dictionary:
    return {
        "total_stimulation": _get_total_stimulation(),
        "is_overloaded": is_in_overload,
        "visual": visual_stimulation,
        "auditory": auditory_stimulation,
        "olfactory": olfactory_stimulation,
        "gustatory": gustatory_stimulation,
        "tactile": tactile_stimulation,
        "proprioceptive": proprioceptive_stimulation
    }
