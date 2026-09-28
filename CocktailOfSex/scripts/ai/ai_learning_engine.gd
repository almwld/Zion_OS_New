extends Node
class_name AILearningEngine

var body: CocktailBody
var skill_levels: Dictionary = {
    "oral": 1.0,
    "vaginal": 1.0,
    "anal": 1.0,
    "handjob": 1.0,
    "fingering": 1.0,
    "kissing": 1.0,
    "dirty_talk": 1.0,
    "rhythm": 1.0,
    "stamina": 1.0
}
var total_experiences: int = 0

func _init(_body: CocktailBody):
    body = _body

func record_skill_use(skill: String, success: float):
    if skill_levels.has(skill):
        skill_levels[skill] += success * 0.01
        total_experiences += 1

func get_skill_level(skill: String) -> float:
    return skill_levels.get(skill, 1.0)

func get_skill_bonus(skill: String) -> float:
    return (get_skill_level(skill) - 1.0) * 0.5

func get_overall_level() -> String:
    var avg = 0.0
    for s in skill_levels:
        avg += skill_levels[s]
    avg /= skill_levels.size()
    if avg > 3.0: return "Expert"
    elif avg > 2.0: return "Experienced"
    elif avg > 1.5: return "Intermediate"
    elif avg > 1.1: return "Beginner"
    else: return "Virgin"
