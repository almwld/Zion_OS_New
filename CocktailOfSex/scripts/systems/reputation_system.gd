extends Node
class_name ReputationSystem

var body: CocktailBody
var reputation: float = 50.0
var is_known_as_easy: bool = false
var is_known_as_prude: bool = false
var partner_count: int = 0
var public_sex_count: int = 0

signal reputation_changed(new_value: float)

func _init(_body: CocktailBody):
    body = _body

func add_partner():
    partner_count += 1
    if partner_count > 10:
        is_known_as_easy = true
        is_known_as_prude = false

func add_public_sex():
    public_sex_count += 1
    reputation -= 2.0
    reputation_changed.emit(reputation)

func refuse_sex():
    reputation += 1.0
    if reputation > 80:
        is_known_as_prude = true
    reputation_changed.emit(reputation)

func get_reputation_label() -> String:
    if is_known_as_easy:
        return "Easy"
    elif is_known_as_prude:
        return "Prude"
    elif reputation > 70:
        return "Respectable"
    elif reputation > 40:
        return "Normal"
    else:
        return "Loose"
