extends Node
class_name AIDesireEngine

var body: CocktailBody
var current_desires: Array[Dictionary] = []
var long_term_desires: Array[Dictionary] = []

func _init(_body: CocktailBody):
    body = _body

func _process(delta):
    _update_desires(delta)

func _update_desires(delta):
    current_desires.clear()
    if body.arousal > 70:
        current_desires.append({"action": "orgasm", "priority": body.arousal})
    if body.arousal > 40:
        if body.gender == "male" or body.gender == "futa":
            if randf() < 0.3:
                current_desires.append({"action": "penetrate", "priority": body.arousal * 0.8})
            else:
                current_desires.append({"action": "receive_oral", "priority": body.arousal * 0.7})
        if body.gender == "female" or body.gender == "futa":
            if randf() < 0.3:
                current_desires.append({"action": "be_penetrated", "priority": body.arousal * 0.9})
            else:
                current_desires.append({"action": "receive_oral", "priority": body.arousal * 0.8})
    if body.precum_amount > 5.0:
        current_desires.append({"action": "release", "priority": body.precum_amount * 10})

func get_top_desire() -> Dictionary:
    if current_desires.size() == 0:
        return {"action": "idle", "priority": 0.0}
    var best = current_desires[0]
    for d in current_desires:
        if d["priority"] > best["priority"]:
            best = d
    return best

func add_long_term_desire(desire: String, priority: float):
    long_term_desires.append({"action": desire, "priority": priority})
