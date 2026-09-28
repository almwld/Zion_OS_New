extends CharacterBody3D
class_name CocktailBody

# ============================================
# COCKTAIL BODY - Ultimate Character System
# ============================================

# --- Identity ---
@export var body_name: String = "Character"
@export var gender: String = "male"
@export var age: int = 25
@export var height: float = 1.75
@export var skin_color: Color = Color(1.0, 0.85, 0.7)
@export var hair_color: Color = Color(0.1, 0.1, 0.1)
@export var eye_color: Color = Color(0.3, 0.5, 0.8)

# --- Sexual Organs ---
@export var penis_length: float = 0.16
@export var penis_girth: float = 0.045
@export var breast_size: float = 0.5
@export var vagina_tightness: float = 0.8
@export var anus_tightness: float = 0.9

# --- Sexual State ---
var arousal: float = 0.0
var max_arousal: float = 100.0
var orgasm_threshold: float = 90.0
var is_climaxing: bool = false
var climax_cooldown: float = 0.0
var multiple_orgasms: int = 0
var max_multiple_orgasms: int = 5

# --- Fluids ---
var precum_amount: float = 0.0
var cum_amount: float = 0.0
var squirt_amount: float = 0.0
var sweat_amount: float = 0.0

# --- Personality ---
var personality: Dictionary = {
    "shyness": 0.5, "dominance": 0.3, "vocalness": 0.7,
    "kinkiness": 0.6, "libido": 0.8, "experience": 0.1,
    "stamina": 0.6, "sensitivity": 0.7
}

# --- Erogenous Zones ---
var zones: Dictionary = {
    "lips": 0.3, "neck": 0.6, "ears": 0.5, "nipples": 0.8,
    "belly": 0.2, "thighs": 0.4, "feet": 0.3, "hands": 0.1,
    "penis_head": 1.0, "penis_shaft": 0.8, "balls": 0.7,
    "clitoris": 1.0, "vagina_wall": 0.9, "g_spot": 1.2,
    "anus_ring": 0.9, "anus_deep": 1.0, "prostate": 1.5,
    "armpits": 0.4, "back": 0.3, "calves": 0.2
}

# --- States ---
var is_in_scene: bool = false
var current_partner: CocktailBody = null
var sex_role: String = "neutral"
var is_pregnant: bool = false
var pregnancy_progress: float = 0.0
var has_sti: bool = false
var sti_type: String = ""

# --- Signals ---
signal orgasm_achieved(type: String, intensity: float)
signal body_touched(part: String, intensity: float)
signal arousal_changed(value: float)
signal fluids_emitted(type: String, amount: float)
signal partner_changed(partner: CocktailBody)

func _ready():
    reset_body()
    add_to_group("Actors")

func _process(delta):
    if climax_cooldown > 0:
        climax_cooldown -= delta
        if climax_cooldown <= 0 and not is_climaxing:
            pass

func _physics_process(delta):
    if not is_climaxing and arousal > 0 and not is_in_scene:
        arousal = max(0, arousal - delta * 0.2)
        arousal_changed.emit(arousal)
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = -0.5
    move_and_slide()

func reset_body():
    arousal = 0.0
    is_climaxing = false
    climax_cooldown = 0.0
    multiple_orgasms = 0
    precum_amount = 0.0
    cum_amount = 0.0
    squirt_amount = 0.0
    sweat_amount = 0.0
    is_in_scene = false
    current_partner = null
    sex_role = "neutral"
    arousal_changed.emit(arousal)

func stimulate(part: String, action: String, intensity: float, duration: float):
    if is_climaxing and climax_cooldown > 0:
        return
    var sensitivity = zones.get(part, 0.1)
    var gain: float = 0.0
    match action:
        "touch": gain = intensity * sensitivity * 0.5
        "lick": gain = intensity * sensitivity * 0.8
        "suck": gain = intensity * sensitivity * 1.0
        "bite": gain = intensity * sensitivity * 0.3
        "rub": gain = intensity * sensitivity * 0.7
        "vibrate": gain = intensity * sensitivity * 1.2
        "penetrate": gain = intensity * sensitivity * 1.5
    arousal = min(arousal + gain * duration, max_arousal)
    body_touched.emit(part, intensity)
    arousal_changed.emit(arousal)
    match part:
        "penis_head", "penis_shaft":
            precum_amount = min(precum_amount + intensity * duration * 2.0, 10.0)
        "clitoris", "vagina_wall", "g_spot":
            squirt_amount = min(squirt_amount + intensity * duration * 3.0, 10.0)
        "anus_ring", "anus_deep", "prostate":
            precum_amount = min(precum_amount + intensity * duration * 1.5, 10.0)
    if arousal >= orgasm_threshold and not is_climaxing and climax_cooldown <= 0 and multiple_orgasms < max_multiple_orgasms:
        _achieve_orgasm()

func _achieve_orgasm():
    is_climaxing = true
    multiple_orgasms += 1
    climax_cooldown = 10.0 / personality["stamina"]
    var intensity = arousal / max_arousal
    cum_amount = 5.0 * intensity
    squirt_amount = 3.0 * intensity
    orgasm_achieved.emit("full", intensity)
    fluids_emitted.emit("cum", cum_amount)
    fluids_emitted.emit("squirt", squirt_amount)
    arousal = 0.0
    arousal_changed.emit(arousal)
    await get_tree().create_timer(climax_cooldown).timeout
    is_climaxing = false

func set_scene_active(active: bool, partner: CocktailBody = null):
    is_in_scene = active
    current_partner = partner
    partner_changed.emit(partner)

func set_role(role: String):
    sex_role = role
