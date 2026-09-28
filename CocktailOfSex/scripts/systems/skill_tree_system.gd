extends Node
class_name SkillTreeSystem

var body: CocktailBody
var skill_points: int = 0
var total_skill_points_earned: int = 0

var skills: Dictionary = {
    "stamina": {
        "name": "Stamina",
        "description": "Increases sexual endurance",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.05,
        "category": "physical"
    },
    "flexibility": {
        "name": "Flexibility",
        "description": "Allows more advanced positions",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.03,
        "category": "physical"
    },
    "sensitivity": {
        "name": "Sensitivity",
        "description": "Increases pleasure from touch",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.04,
        "category": "physical"
    },
    "orgasm_control": {
        "name": "Orgasm Control",
        "description": "Better control over climax timing",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 3,
        "bonus_per_level": 0.06,
        "category": "mental"
    },
    "multi_orgasm": {
        "name": "Multi Orgasm",
        "description": "Increases maximum orgasms per session",
        "level": 0,
        "max_level": 5,
        "cost_per_level": 5,
        "bonus_per_level": 1.0,
        "category": "mental"
    },
    "dirty_talk": {
        "name": "Dirty Talk",
        "description": "Improves partner arousal through words",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.05,
        "category": "social"
    },
    "seduction": {
        "name": "Seduction",
        "description": "Easier to attract partners",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.04,
        "category": "social"
    },
    "oral_technique": {
        "name": "Oral Technique",
        "description": "Improved oral sex skills",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.05,
        "category": "technique"
    },
    "anal_technique": {
        "name": "Anal Technique",
        "description": "Improved anal sex skills",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.05,
        "category": "technique"
    },
    "vaginal_technique": {
        "name": "Vaginal Technique",
        "description": "Improved vaginal sex skills",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.05,
        "category": "technique"
    },
    "kink_awareness": {
        "name": "Kink Awareness",
        "description": "Better at exploring kinks safely",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.03,
        "category": "mental"
    },
    "recovery": {
        "name": "Recovery",
        "description": "Faster recovery between sessions",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.05,
        "category": "physical"
    },
    "size_matters": {
        "name": "Size Matters",
        "description": "Slightly increases penis or breast size",
        "level": 0,
        "max_level": 5,
        "cost_per_level": 5,
        "bonus_per_level": 0.02,
        "category": "physical"
    },
    "empathy": {
        "name": "Empathy",
        "description": "Better at reading partner's desires",
        "level": 0,
        "max_level": 10,
        "cost_per_level": 2,
        "bonus_per_level": 0.04,
        "category": "social"
    }
}

signal skill_upgraded(skill_id: String, new_level: int)
signal skill_point_earned(total: int)

func _init(_body: CocktailBody):
    body = _body

func earn_skill_points(amount: int = 1):
    skill_points += amount
    total_skill_points_earned += amount
    skill_point_earned.emit(skill_points)

func upgrade_skill(skill_id: String) -> bool:
    if not skills.has(skill_id): return false
    var skill = skills[skill_id]
    if skill["level"] >= skill["max_level"]: return false
    if skill_points < skill["cost_per_level"]: return false
    skill_points -= skill["cost_per_level"]
    skill["level"] += 1
    _apply_skill_bonus(skill_id, skill["bonus_per_level"])
    skill_upgraded.emit(skill_id, skill["level"])
    return true

func _apply_skill_bonus(skill_id: String, bonus: float):
    match skill_id:
        "stamina":
            body.personality["stamina"] = min(1.0, body.personality["stamina"] + bonus)
        "flexibility":
            pass
        "sensitivity":
            for zone in body.zones:
                body.zones[zone] = min(2.0, body.zones[zone] + bonus * 0.5)
        "orgasm_control":
            body.orgasm_threshold += bonus * 50.0
        "multi_orgasm":
            body.max_multiple_orgasms += int(bonus * 5.0)
        "dirty_talk":
            body.personality["vocalness"] = min(1.0, body.personality["vocalness"] + bonus)
        "seduction":
            pass
        "oral_technique":
            body.zones["penis_head"] = min(2.0, body.zones.get("penis_head", 1.0) + bonus)
            body.zones["clitoris"] = min(2.0, body.zones.get("clitoris", 1.0) + bonus)
        "anal_technique":
            body.zones["anus_ring"] = min(2.0, body.zones.get("anus_ring", 1.0) + bonus)
        "vaginal_technique":
            body.zones["vagina_wall"] = min(2.0, body.zones.get("vagina_wall", 1.0) + bonus)
        "recovery":
            body.climax_cooldown = max(1.0, body.climax_cooldown - bonus * 5.0)
        "size_matters":
            body.penis_length += bonus * 0.5
            body.breast_size += bonus * 0.3
        "empathy":
            pass

func get_skill_level(skill_id: String) -> int:
    if skills.has(skill_id): return skills[skill_id]["level"]
    return 0

func get_all_skills() -> Dictionary:
    return skills.duplicate()

func get_available_skill_points() -> int:
    return skill_points

func get_total_earned() -> int:
    return total_skill_points_earned
