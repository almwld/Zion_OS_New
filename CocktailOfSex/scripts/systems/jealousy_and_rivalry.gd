extends Node
class_name JealousyAndRivalry

var body: CocktailBody
var rivals: Array[CocktailBody] = []
var crushes: Array[CocktailBody] = []
var jealousy_level: float = 0.0

signal jealousy_triggered(target: CocktailBody, intensity: float)
signal rivalry_formed(rival: CocktailBody, reason: String)
signal confrontation_started(body1: CocktailBody, body2: CocktailBody)

func _init(_body: CocktailBody):
    body = _body

func witness_partner_with_other(partner: CocktailBody, other: CocktailBody):
    jealousy_level += 20.0
    if not other in rivals:
        rivals.append(other)
        rivalry_formed.emit(other, "Saw them with " + partner.body_name)
    jealousy_triggered.emit(partner, jealousy_level)
    if jealousy_level > 70.0:
        _confront(partner)

func _confront(partner: CocktailBody):
    confrontation_started.emit(body, partner)
    jealousy_level -= 30.0

func develop_crush(target: CocktailBody):
    if not target in crushes:
        crushes.append(target)

func lose_crush(target: CocktailBody):
    crushes.erase(target)

func get_jealousy_level() -> float:
    return jealousy_level

func get_rivals() -> Array:
    return rivals

func _process(delta):
    jealousy_level = max(0, jealousy_level - delta * 1.0)
