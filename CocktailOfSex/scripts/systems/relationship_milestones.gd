extends Node
class_name RelationshipMilestones

var body: CocktailBody
var partner: CocktailBody

var milestones: Dictionary = {
    "first_kiss": {"achieved": false, "date": 0, "description": "First kiss shared"},
    "first_touch": {"achieved": false, "date": 0, "description": "First intimate touch"},
    "first_oral": {"achieved": false, "date": 0, "description": "First oral sex"},
    "first_vaginal": {"achieved": false, "date": 0, "description": "First vaginal sex"},
    "first_anal": {"achieved": false, "date": 0, "description": "First anal sex"},
    "first_orgasm_together": {"achieved": false, "date": 0, "description": "First simultaneous orgasm"},
    "first_public": {"achieved": false, "date": 0, "description": "First public sex"},
    "first_threesome": {"achieved": false, "date": 0, "description": "First threesome together"},
    "first_sleepover": {"achieved": false, "date": 0, "description": "First night spent together"},
    "first_i_love_you": {"achieved": false, "date": 0, "description": "First 'I love you'"},
    "moved_in_together": {"achieved": false, "date": 0, "description": "Moved in together"},
    "engaged": {"achieved": false, "date": 0, "description": "Got engaged"},
    "married": {"achieved": false, "date": 0, "description": "Got married"},
    "first_child": {"achieved": false, "date": 0, "description": "Had first child together"}
}

var relationship_level: String = "strangers"
var total_intimacy_points: float = 0.0

signal milestone_achieved(milestone: String, description: String)
signal relationship_leveled_up(new_level: String)

func _init(_body: CocktailBody, _partner: CocktailBody):
    body = _body
    partner = _partner

func record_event(event: String):
    if milestones.has(event) and not milestones[event]["achieved"]:
        milestones[event]["achieved"] = true
        milestones[event]["date"] = Time.get_ticks_msec()
        total_intimacy_points += 10.0
        milestone_achieved.emit(event, milestones[event]["description"])
        _update_relationship_level()

func _update_relationship_level():
    var old_level = relationship_level
    if total_intimacy_points < 20: relationship_level = "strangers"
    elif total_intimacy_points < 50: relationship_level = "acquaintances"
    elif total_intimacy_points < 100: relationship_level = "friends"
    elif total_intimacy_points < 200: relationship_level = "close_friends"
    elif total_intimacy_points < 350: relationship_level = "dating"
    elif total_intimacy_points < 500: relationship_level = "lovers"
    elif total_intimacy_points < 750: relationship_level = "partners"
    elif total_intimacy_points < 1000: relationship_level = "soulmates"
    else: relationship_level = "eternal_bond"
    if old_level != relationship_level:
        relationship_leveled_up.emit(relationship_level)

func get_milestone_progress() -> Dictionary:
    return {
        "achieved": _count_achieved(),
        "total": milestones.size(),
        "level": relationship_level,
        "points": total_intimacy_points
    }

func _count_achieved() -> int:
    var count = 0
    for key in milestones:
        if milestones[key]["achieved"]: count += 1
    return count
