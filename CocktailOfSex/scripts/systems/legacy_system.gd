extends Node
class_name LegacySystem

var body: CocktailBody
var genetics: GeneticsSystem

var generation: int = 1
var family_name: String = ""
var family_wealth: float = 0.0
var family_reputation: float = 50.0
var family_business: String = ""
var family_motto: String = ""

var ancestors: Array[Dictionary] = []
var descendants: Array[Dictionary] = []
var living_relatives: Array[CocktailBody] = []

var legacy_achievements: Array[String] = []
var family_secrets: Array[String] = []
var heirlooms: Array[Dictionary] = []

signal generation_advanced(new_generation: int)
signal family_wealth_changed(new_wealth: float)
signal legacy_achievement_unlocked(achievement: String)

func _init(_body: CocktailBody, _genetics: GeneticsSystem, _family_name: String = ""):
    body = _body
    genetics = _genetics
    family_name = _family_name if _family_name != "" else body.body_name
    generation = 1

func advance_generation(new_heir: CocktailBody):
    generation += 1
    var heir_genetics = GeneticsSystem.new(new_heir)
    body = new_heir
    genetics = heir_genetics
    generation_advanced.emit(generation)

func add_wealth(amount: float):
    family_wealth += amount
    family_wealth_changed.emit(family_wealth)

func add_heirloom(name: String, value: float, description: String):
    heirlooms.append({"name": name, "value": value, "description": description, "generation_acquired": generation})

func unlock_legacy_achievement(achievement: String):
    if not achievement in legacy_achievements:
        legacy_achievements.append(achievement)
        legacy_achievement_unlocked.emit(achievement)

func get_legacy_report() -> Dictionary:
    return {
        "family_name": family_name,
        "generation": generation,
        "wealth": family_wealth,
        "reputation": family_reputation,
        "achievements": legacy_achievements.size(),
        "heirlooms": heirlooms.size(),
        "living_relatives": living_relatives.size()
    }
