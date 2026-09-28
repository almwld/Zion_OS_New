extends Node
class_name AIRelationshipAI

var body: CocktailBody
var relationship_system: RelationshipSystem
var ideal_partner_traits: Dictionary = {}
var current_crush: CocktailBody = null
var is_in_love: bool = false

func _init(_body: CocktailBody):
    body = _body
    relationship_system = RelationshipSystem.new()
    _generate_ideal_traits()

func _generate_ideal_traits():
    ideal_partner_traits["dominance"] = randf_range(0.0, 1.0)
    ideal_partner_traits["shyness"] = randf_range(0.0, 1.0)
    ideal_partner_traits["kinkiness"] = randf_range(0.0, 1.0)
    ideal_partner_traits["age"] = randf_range(0.5, 1.5) * body.age

func evaluate_partner(partner: CocktailBody) -> float:
    var score = 0.0
    score += (1.0 - abs(partner.personality["dominance"] - ideal_partner_traits["dominance"])) * 30.0
    score += (1.0 - abs(partner.personality["shyness"] - ideal_partner_traits["shyness"])) * 20.0
    score += (1.0 - abs(partner.personality["kinkiness"] - ideal_partner_traits["kinkiness"])) * 20.0
    score += (1.0 - abs(partner.age - ideal_partner_traits["age"]) / max(ideal_partner_traits["age"], 1.0)) * 30.0
    return score

func develop_feelings(partner: CocktailBody):
    var score = evaluate_partner(partner)
    if score > 70.0 and not is_in_love:
        current_crush = partner
        is_in_love = true
        print(body.body_name + " has fallen in love with " + partner.body_name)
    elif score < 30.0 and is_in_love and current_crush == partner:
        current_crush = null
        is_in_love = false
        print(body.body_name + " has fallen out of love with " + partner.body_name)
