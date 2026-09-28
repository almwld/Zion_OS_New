extends Node
class_name FetishEvolution

var body: CocktailBody
var fetishes: Dictionary = {}
var experience: Dictionary = {}

func _init(_body: CocktailBody):
    body = _body
    var all_fetishes = [
        "vanilla", "bdsm", "anal", "oral", "group",
        "public", "age_play", "pet_play", "feet",
        "sensory_deprivation", "roleplay", "bondage",
        "spanking", "domination", "submission"
    ]
    for f in all_fetishes:
        fetishes[f] = 0.0
        experience[f] = 0

func record_experience(fetish: String, pleasure: float):
    if fetishes.has(fetish):
        fetishes[fetish] = min(100, fetishes[fetish] + pleasure * 0.1)
        experience[fetish] += 1

func get_top_fetishes(count: int) -> Array:
    var sorted = []
    for f in fetishes:
        sorted.append({"name": f, "level": fetishes[f]})
    sorted.sort_custom(func(a, b): return a["level"] > b["level"])
    var result = []
    for i in range(min(count, sorted.size())):
        result.append(sorted[i])
    return result

func get_fetish_level(fetish: String) -> float:
    return fetishes.get(fetish, 0.0)
