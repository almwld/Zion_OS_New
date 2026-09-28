extends Node
class_name AIMemorySystem

var body: CocktailBody
var sexual_memories: Array[Dictionary] = []
var partner_memories: Dictionary = {}
var favorite_positions: Dictionary = {}
var favorite_zones: Dictionary = {}
var disliked_actions: Array[String] = []
var liked_actions: Array[String] = []

func _init(_body: CocktailBody):
    body = _body

func record_experience(partner: CocktailBody, action: String, position: String, pleasure: float, zone: String = ""):
    var memory = {
        "partner": partner.body_name,
        "action": action,
        "position": position,
        "pleasure": pleasure,
        "zone": zone,
        "arousal": body.arousal,
        "time": Time.get_ticks_msec()
    }
    sexual_memories.append(memory)
    if not partner_memories.has(partner.body_name):
        partner_memories[partner.body_name] = {"count": 0, "total_pleasure": 0.0, "best_action": "", "best_pleasure": 0.0}
    partner_memories[partner.body_name]["count"] += 1
    partner_memories[partner.body_name]["total_pleasure"] += pleasure
    if pleasure > partner_memories[partner.body_name]["best_pleasure"]:
        partner_memories[partner.body_name]["best_pleasure"] = pleasure
        partner_memories[partner.body_name]["best_action"] = action
    if not favorite_positions.has(position):
        favorite_positions[position] = {"count": 0, "total_pleasure": 0.0}
    favorite_positions[position]["count"] += 1
    favorite_positions[position]["total_pleasure"] += pleasure
    if zone != "":
        if not favorite_zones.has(zone):
            favorite_zones[zone] = {"count": 0, "total_pleasure": 0.0}
        favorite_zones[zone]["count"] += 1
        favorite_zones[zone]["total_pleasure"] += pleasure
    if pleasure > 7.0 and not action in liked_actions:
        liked_actions.append(action)
    if pleasure < 3.0 and not action in disliked_actions:
        disliked_actions.append(action)
    if sexual_memories.size() > 100:
        sexual_memories.pop_front()

func get_favorite_position() -> String:
    var best = ""
    var best_avg = 0.0
    for pos in favorite_positions:
        var avg = favorite_positions[pos]["total_pleasure"] / favorite_positions[pos]["count"]
        if avg > best_avg:
            best_avg = avg
            best = pos
    return best

func get_best_partner() -> String:
    var best = ""
    var best_avg = 0.0
    for p in partner_memories:
        var avg = partner_memories[p]["total_pleasure"] / partner_memories[p]["count"]
        if avg > best_avg and partner_memories[p]["count"] >= 3:
            best_avg = avg
            best = p
    return best

func should_do_action(action: String) -> bool:
    if action in liked_actions: return true
    if action in disliked_actions: return false
    return true
