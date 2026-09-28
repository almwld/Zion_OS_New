extends Node
class_name MatchmakingSystem

var body: CocktailBody
var available_partners: Array[CocktailBody] = []

var preferences: Dictionary = {
    "preferred_gender": "any",
    "preferred_age_min": 18,
    "preferred_age_max": 60,
    "preferred_dominance": 0.5,
    "preferred_kinkiness": 0.5,
    "preferred_body_type": "any",
    "max_distance": 50.0,
    "looking_for": "casual"
}

var compatibility_cache: Dictionary = {}

signal match_found(partner: CocktailBody, compatibility: float)
signal match_list_updated(matches: Array)

func _init(_body: CocktailBody):
    body = _body

func update_available_partners(all_bodies: Array[CocktailBody]):
    available_partners.clear()
    for b in all_bodies:
        if b != body and not b.is_in_scene:
            available_partners.append(b)

func find_best_match() -> CocktailBody:
    var best_match: CocktailBody = null
    var best_score: float = 0.0
    for partner in available_partners:
        var score = calculate_compatibility(partner)
        if score > best_score:
            best_score = score
            best_match = partner
    if best_match:
        match_found.emit(best_match, best_score)
    return best_match

func calculate_compatibility(partner: CocktailBody) -> float:
    var cache_key = body.body_name + "_" + partner.body_name
    if compatibility_cache.has(cache_key):
        return compatibility_cache[cache_key]
    var score = 0.0
    if preferences["preferred_gender"] != "any":
        if partner.gender == preferences["preferred_gender"]:
            score += 25.0
    else:
        score += 15.0
    if partner.age >= preferences["preferred_age_min"] and partner.age <= preferences["preferred_age_max"]:
        score += 20.0
    var dom_diff = abs(partner.personality["dominance"] - preferences["preferred_dominance"])
    score += (1.0 - dom_diff) * 20.0
    var kink_diff = abs(partner.personality["kinkiness"] - preferences["preferred_kinkiness"])
    score += (1.0 - kink_diff) * 15.0
    if body.current_partner == null:
        score += 10.0
    score += partner.personality["libido"] * 10.0
    compatibility_cache[cache_key] = score
    return score

func get_top_matches(count: int = 5) -> Array:
    var scored = []
    for partner in available_partners:
        var score = calculate_compatibility(partner)
        scored.append({"partner": partner, "compatibility": score})
    scored.sort_custom(func(a, b): return a["compatibility"] > b["compatibility"])
    var top = []
    for i in range(min(count, scored.size())):
        top.append(scored[i])
    match_list_updated.emit(top)
    return top

func set_preference(key: String, value):
    if preferences.has(key):
        preferences[key] = value
        compatibility_cache.clear()
