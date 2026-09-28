extends Node
class_name AchievementSystem

var body: CocktailBody
var unlocked_achievements: Array[String] = []
var achievement_progress: Dictionary = {}

var all_achievements: Array[Dictionary] = [
    {"id": "first_kiss", "name": "First Kiss", "description": "Experience your first kiss", "icon": "💋"},
    {"id": "first_orgasm", "name": "First Release", "description": "Achieve your first orgasm", "icon": "💦"},
    {"id": "orgasm_10", "name": "Double Digits", "description": "Achieve 10 orgasms", "icon": "🔟"},
    {"id": "orgasm_50", "name": "Half Century", "description": "Achieve 50 orgasms", "icon": "🎯"},
    {"id": "orgasm_100", "name": "Century", "description": "Achieve 100 orgasms", "icon": "💯"},
    {"id": "first_anal", "name": "Backdoor Explorer", "description": "Experience anal sex for the first time", "icon": "🚪"},
    {"id": "first_oral", "name": "Taste Test", "description": "Experience oral sex for the first time", "icon": "👅"},
    {"id": "first_threesome", "name": "Third Wheel", "description": "Participate in a threesome", "icon": "👥"},
    {"id": "first_orgy", "name": "Party Animal", "description": "Participate in an orgy (5+ people)", "icon": "🎉"},
    {"id": "virginity_lost", "name": "Debut", "description": "Lose your virginity", "icon": "🌸"},
    {"id": "public_sex", "name": "Exhibitionist", "description": "Have sex in public", "icon": "👀"},
    {"id": "multiple_orgasm", "name": "Overachiever", "description": "Achieve 3+ orgasms in one session", "icon": "✨"},
    {"id": "edge_master", "name": "Edge Lord", "description": "Edge 5 times in one session", "icon": "⏸️"},
    {"id": "all_positions", "name": "Position Master", "description": "Try all available positions", "icon": "🔄"},
    {"id": "first_pregnancy", "name": "Bun in the Oven", "description": "Get pregnant", "icon": "🤰"},
    {"id": "toy_collector", "name": "Toy Collector", "description": "Own 10 different toys", "icon": "🧸"},
    {"id": "marathon", "name": "Marathon", "description": "Have sex for over 2 hours straight", "icon": "⏱️"},
    {"id": "speed_demon", "name": "Speed Demon", "description": "Achieve orgasm in under 2 minutes", "icon": "⚡"},
    {"id": "size_queen", "name": "Size Queen", "description": "Take a penis over 20cm", "icon": "📏"},
    {"id": "virgin_maker", "name": "Virgin Maker", "description": "Take someone's virginity", "icon": "🎀"}
]

signal achievement_unlocked(achievement: Dictionary)

func _init(_body: CocktailBody):
    body = _body

func check_achievement(id: String, progress: float = 1.0):
    if id in unlocked_achievements: return
    if not achievement_progress.has(id):
        achievement_progress[id] = 0.0
    achievement_progress[id] += progress
    var achievement = _get_achievement(id)
    if achievement and achievement_progress[id] >= 1.0:
        unlocked_achievements.append(id)
        achievement_unlocked.emit(achievement)

func _get_achievement(id: String) -> Dictionary:
    for a in all_achievements:
        if a["id"] == id: return a
    return {}

func get_unlocked_count() -> int:
    return unlocked_achievements.size()

func get_total_count() -> int:
    return all_achievements.size()

func get_completion_percentage() -> float:
    return float(unlocked_achievements.size()) / float(all_achievements.size()) * 100.0

func get_recent_achievements(count: int = 5) -> Array:
    var recent = []
    var start = max(0, unlocked_achievements.size() - count)
    for i in range(start, unlocked_achievements.size()):
        var a = _get_achievement(unlocked_achievements[i])
        if a: recent.append(a)
    return recent
