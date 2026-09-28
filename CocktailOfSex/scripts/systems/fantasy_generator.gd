extends Node
class_name FantasyGenerator

var body: CocktailBody

var location_pool: Array[String] = [
    "beach", "forest", "office", "classroom", "church", "hospital",
    "spaceship", "dungeon", "castle", "garden", "library", "nightclub",
    "airplane", "elevator", "rooftop", "swimming pool", "locker room",
    "movie theater", "park bench", "alleyway"
]

var scenario_pool: Array[String] = [
    "stranger encounter", "reunion with ex", "first date", "wedding night",
    "cheating", "makeup sex", "hate sex", "pity sex", "celebration sex",
    "goodbye sex", "long distance reunion", "breakup sex", "birthday treat",
    "anniversary", "honeymoon", "one night stand", "friends with benefits",
    "teacher and student", "boss and secretary", "doctor and patient"
]

var kink_pool: Array[String] = [
    "light bondage", "blindfold", "spanking", "roleplay", "public risk",
    "threesome", "orgy", "cuckolding", "hotwife", "swinging",
    "age play", "pet play", "master slave", "sensory deprivation",
    "temperature play", "wax play", "electro stimulation"
]

func generate_fantasy() -> Dictionary:
    var location = location_pool[randi() % location_pool.size()]
    var scenario = scenario_pool[randi() % scenario_pool.size()]
    var kink = kink_pool[randi() % kink_pool.size()]
    var partner_count = 1
    if kink in ["threesome", "cuckolding", "hotwife"]:
        partner_count = randi_range(2, 3)
    elif kink == "orgy":
        partner_count = randi_range(4, 10)
    var intensity = randf_range(0.5, 1.0)
    var narrative = "You find yourself in a " + location + ". It's a " + scenario + " scenario. "
    narrative += "The air is thick with tension. "
    if kink != "vanilla":
        narrative += "There's an underlying theme of " + kink + ". "
    narrative += "You feel your heart racing as the moment approaches."
    return {
        "location": location,
        "scenario": scenario,
        "kink": kink,
        "partner_count": partner_count,
        "intensity": intensity,
        "narrative": narrative
    }

func generate_quick_fantasy(arousal: float) -> String:
    var fantasy = generate_fantasy()
    var text = ""
    text += "Location: " + fantasy["location"] + "\n"
    text += "Scenario: " + fantasy["scenario"] + "\n"
    if fantasy["kink"] != "vanilla":
        text += "Kink: " + fantasy["kink"] + "\n"
    text += "Partners: " + str(fantasy["partner_count"]) + "\n"
    return text
