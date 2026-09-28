extends Node
class_name OralMasterySystem

var body: CocktailBody
var partner: CocktailBody

# --- Oral Stats ---
var deep_throat_skill: float = 1.0
var tongue_technique: float = 1.0
var lip_skill: float = 1.0
var gag_reflex_control: float = 1.0
var saliva_production: float = 1.0
var suction_power: float = 1.0
var rhythm_mastery: float = 1.0

# --- Oral Techniques ---
enum OralTechnique {
    GENTLE_KISS,        # 💋 Soft lip caress
    FRENCH_KISS,        # 👅 Deep tongue exploration
    LIP_NIBBLE,         # 🫦 Gentle biting
    LICK_SLOW,          # 👅 Slow sensual licking
    LICK_FAST,          # 👅 Rapid tongue flicking
    SUCK_GENTLE,        # 🤤 Soft suction
    SUCK_HARD,          # 🤤 Powerful vacuum
    DEEP_THROAT_SLOW,   # 🤤 Gradual deep insertion
    DEEP_THROAT_FAST,   # 🤤 Rapid face fucking
    BALL_LICK,          # 👅 Testicle worship
    BALL_SUCK,          # 🤤 Testicle suction
    TAINT_TEASE,        # 👅 Perineum stimulation
    SIXTY_NINE,         # 👅🤤 Mutual oral
    FACE_FUCK,          # 🤤 Aggressive throat penetration
    THROAT_BULGE,       # 🤤 Visible neck distension
    CUM_SWALLOW,        # 🤤 Semen consumption
    SNOWBALL,           # 💋 Fluid exchange
    TONGUE_FUCK,        # 👅 Tongue penetration
    LIP_WORSHIP,        # 🫦 Lip adoration
    JAW_LOCK            # 🤤 Sustained deep throat
}

var current_technique: OralTechnique = OralTechnique.GENTLE_KISS
var technique_history: Array[Dictionary] = []

# --- Physical Feedback ---
var throat_depth: float = 0.0
var throat_stretch: float = 0.0
var jaw_fatigue: float = 0.0
var lip_sensitivity: float = 1.0
var tongue_stamina: float = 100.0
var saliva_amount: float = 0.5
var saliva_viscosity: float = 0.3

# --- Partner Feedback ---
var partner_pleasure: float = 0.0
var partner_arousal_boost: float = 0.0
var partner_orgasm_imminent: bool = false

# --- Visual Effects ---
var lip_swelling: float = 0.0
var lip_color_intensity: Color = Color(1.0, 0.3, 0.3)
var saliva_trail_length: float = 0.0
var throat_bulge_visible: bool = false
var face_mess_level: float = 0.0

signal oral_technique_changed(technique: OralTechnique)
signal deep_throat_achieved(depth: float)
signal partner_climax_from_oral()
signal saliva_dripped()
signal throat_bulged()

func _init(_body: CocktailBody, _partner: CocktailBody = null):
    body = _body
    partner = _partner

func _process(delta):
    _update_saliva(delta)
    _update_fatigue(delta)
    _update_partner_feedback(delta)

func _update_saliva(delta):
    var target_saliva = 0.5 + body.arousal / 100.0 * 0.5
    saliva_amount = lerp(saliva_amount, target_saliva, delta * 2.0)
    if saliva_amount > 0.8 and randf() < delta:
        saliva_dripped.emit()

func _update_fatigue(delta):
    jaw_fatigue = max(0, jaw_fatigue - delta * 0.5)
    tongue_stamina = min(100.0, tongue_stamina + delta * 5.0)

func _update_partner_feedback(delta):
    if partner:
        partner_pleasure = lerp(partner_pleasure, 0.0, delta * 0.3)
        partner_arousal_boost = partner_pleasure * 0.5
        partner.arousal = min(partner.max_arousal, partner.arousal + partner_arousal_boost * delta)

func perform_technique(technique: OralTechnique, intensity: float = 0.5, duration: float = 1.0):
    current_technique = technique
    technique_history.append({"technique": technique, "intensity": intensity, "time": Time.get_ticks_msec()})
    oral_technique_changed.emit(technique)
    match technique:
        OralTechnique.GENTLE_KISS:
            lip_swelling = min(0.3, lip_swelling + 0.01)
            partner_pleasure += intensity * 0.5
            body.arousal += intensity * 2.0
        OralTechnique.FRENCH_KISS:
            tongue_stamina -= intensity * 2.0
            saliva_amount += 0.1
            partner_pleasure += intensity * 0.8
            body.arousal += intensity * 3.0
        OralTechnique.LIP_NIBBLE:
            lip_swelling = min(0.5, lip_swelling + 0.02)
            lip_sensitivity += 0.1
            partner_pleasure += intensity * 0.6
        OralTechnique.LICK_SLOW:
            tongue_stamina -= intensity * 1.0
            saliva_amount += 0.05
            partner_pleasure += intensity * 0.7
        OralTechnique.LICK_FAST:
            tongue_stamina -= intensity * 3.0
            partner_pleasure += intensity * 1.2
        OralTechnique.SUCK_GENTLE:
            suction_power = min(2.0, suction_power + 0.01)
            partner_pleasure += intensity * 0.9
        OralTechnique.SUCK_HARD:
            suction_power = min(3.0, suction_power + 0.03)
            jaw_fatigue += intensity * 5.0
            partner_pleasure += intensity * 1.5
        OralTechnique.DEEP_THROAT_SLOW:
            throat_depth = min(1.0, throat_depth + 0.1)
            throat_stretch += 0.05
            gag_reflex_control = max(1.0, gag_reflex_control + 0.02)
            partner_pleasure += intensity * 2.0
            if throat_depth > 0.8:
                throat_bulge_visible = true
                throat_bulged.emit()
        OralTechnique.DEEP_THROAT_FAST:
            throat_depth = min(1.0, throat_depth + 0.2)
            throat_stretch += 0.1
            jaw_fatigue += intensity * 8.0
            partner_pleasure += intensity * 3.0
            face_mess_level += 0.1
        OralTechnique.BALL_LICK:
            saliva_amount += 0.03
            partner_pleasure += intensity * 0.6
        OralTechnique.BALL_SUCK:
            suction_power = min(2.0, suction_power + 0.01)
            partner_pleasure += intensity * 1.0
        OralTechnique.CUM_SWALLOW:
            face_mess_level = max(0, face_mess_level - 0.3)
            partner_pleasure += intensity * 2.0
        OralTechnique.FACE_FUCK:
            throat_depth = min(1.0, throat_depth + 0.3)
            jaw_fatigue += intensity * 10.0
            partner_pleasure += intensity * 4.0
            face_mess_level += 0.2
    if partner_pleasure > 8.0:
        partner_orgasm_imminent = true
        if randf() < 0.1:
            partner_climax_from_oral.emit()
            if partner:
                partner._achieve_orgasm()

func get_oral_report() -> Dictionary:
    return {
        "deep_throat_skill": deep_throat_skill,
        "tongue_technique": tongue_technique,
        "lip_skill": lip_skill,
        "gag_reflex": gag_reflex_control,
        "saliva": saliva_amount,
        "suction": suction_power,
        "throat_depth": throat_depth,
        "jaw_fatigue": jaw_fatigue,
        "face_mess": face_mess_level
    }
