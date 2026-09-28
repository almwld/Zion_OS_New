extends Node
class_name GenerativeAI

var male_names = ["آدم", "يوسف", "نوح", "إلياس", "سامر", "ريان", "كايل", "دانتي", "أليكس", "ماركو"]
var female_names = ["حواء", "مريم", "ليلى", "نور", "سلمى", "زينب", "إيفا", "لونا", "كلوي", "صوفيا"]
var hair_styles = ["short", "long", "curly", "straight", "wavy", "bald", "ponytail", "bob"]
var body_types = ["slim", "athletic", "curvy", "petite", "tall", "muscular", "chubby", "average"]
var kinks = ["vanilla", "bdsm", "roleplay", "exhibitionist", "submissive", "dominant", "feet", "anal_lover", "oral_fixation"]

func generate_character(gender_override: String = "") -> CocktailBody:
    var g = gender_override if gender_override != "" else ["male", "female"][randi() % 2]
    var n = male_names[randi() % male_names.size()] if g == "male" else female_names[randi() % female_names.size()]
    var b = CocktailBody.new()
    b.body_name = n
    b.gender = g
    b.height = randf_range(1.5, 2.0)
    b.skin_color = Color(randf_range(0.6, 1.0), randf_range(0.4, 0.8), randf_range(0.3, 0.7))
    b.hair_color = Color(randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0))
    b.eye_color = Color(randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0))
    b.penis_length = randf_range(0.08, 0.25) if g == "male" else 0.0
    b.breast_size = randf_range(0.2, 1.0) if g == "female" else 0.0
    b.vagina_tightness = randf_range(0.5, 1.0) if g == "female" else 0.0
    b.personality["shyness"] = randf_range(0.0, 1.0)
    b.personality["dominance"] = randf_range(0.0, 1.0)
    b.personality["kinkiness"] = randf_range(0.0, 1.0)
    return b
