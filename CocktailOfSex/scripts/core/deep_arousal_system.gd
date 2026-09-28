extends Node
class_name DeepArousalSystem

var body: CocktailBody

var skin_tingle: float = 0.0
var pelvic_heat: float = 0.0
var muscle_tension: float = 0.0
var breath_depth: float = 0.0
var heart_rate: float = 60.0

var feeling_wanted: float = 0.0
var feeling_dirty: float = 0.0
var feeling_loved: float = 0.0
var feeling_used: float = 0.0

var last_orgasm_type: String = ""
var orgasm_count_session: int = 0
var memory_zones: Dictionary = {}

func _init(_body: CocktailBody):
    body = _body
    memory_zones["clitoris"] = 0.0
    memory_zones["penis_head"] = 0.0
    memory_zones["anus_ring"] = 0.0
    memory_zones["nipples"] = 0.0
    memory_zones["neck"] = 0.0
    memory_zones["thighs"] = 0.0

func _process(delta):
    _update_physical(delta)
    _update_emotional(delta)

func _update_physical(delta):
    skin_tingle = lerp(skin_tingle, body.arousal / 100.0, delta * 2.0)
    pelvic_heat = lerp(pelvic_heat, body.arousal / 100.0, delta * 1.5)
    muscle_tension = lerp(muscle_tension, body.arousal / 100.0, delta * 0.8)
    breath_depth = lerp(breath_depth, body.arousal / 100.0, delta * 3.0)
    heart_rate = lerp(heart_rate, 60.0 + (body.arousal * 1.5), delta * 5.0)

func _update_emotional(delta):
    var p = body.personality
    feeling_wanted = lerp(feeling_wanted, body.arousal / 100.0, delta * 1.0)
    feeling_dirty = lerp(feeling_dirty, body.arousal / 100.0 * p["kinkiness"], delta * 2.0)
    feeling_loved = lerp(feeling_loved, body.arousal / 100.0 * (1.0 - p["dominance"]), delta * 1.5)
    feeling_used = lerp(feeling_used, body.arousal / 100.0 * p["dominance"], delta * 2.0)

func apply_stimulation(zone: String, intensity: float):
    if not memory_zones.has(zone):
        memory_zones[zone] = 0.0
    memory_zones[zone] = min(memory_zones[zone] + intensity * 0.1, 1.0)
    var bonus = 1.0 + memory_zones[zone]
    match zone:
        "clitoris":
            body.arousal += intensity * 0.5 * bonus
            skin_tingle += intensity * 2.0
        "penis_head":
            body.arousal += intensity * 0.4 * bonus
            pelvic_heat += intensity * 3.0
        "anus_ring":
            body.arousal += intensity * 0.3 * bonus
            muscle_tension += intensity * 1.5
        "nipples":
            body.arousal += intensity * 0.2 * bonus
            skin_tingle += intensity * 1.0
        "neck":
            body.arousal += intensity * 0.15 * bonus
            feeling_loved += intensity * 0.5
        "thighs":
            body.arousal += intensity * 0.1 * bonus
            feeling_wanted += intensity * 0.3
    body.arousal = min(body.arousal, body.max_arousal)

func get_report() -> Dictionary:
    return {
        "skin_tingle": skin_tingle,
        "pelvic_heat": pelvic_heat,
        "heart_rate": heart_rate,
        "feeling_wanted": feeling_wanted,
        "feeling_loved": feeling_loved,
        "memory_zones": memory_zones.duplicate()
    }
