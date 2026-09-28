extends Node
class_name BlackMarket

var economy: SexEconomySystem

var illegal_items: Array[Dictionary] = [
    {"name": "Unregistered Aphrodisiac", "effect": "double_arousal", "duration": 3600.0, "price": 200.0, "risk": 0.3},
    {"name": "Illegal Viagra", "effect": "permanent_erection", "duration": 7200.0, "price": 350.0, "risk": 0.4},
    {"name": "Mind Control Pheromones", "effect": "increase_consent", "duration": 1800.0, "price": 500.0, "risk": 0.6},
    {"name": "Fertility Booster", "effect": "guarantee_pregnancy", "duration": 86400.0, "price": 400.0, "risk": 0.2},
    {"name": "Sterilization Serum", "effect": "prevent_pregnancy", "duration": 2592000.0, "price": 300.0, "risk": 0.1},
    {"name": "Gender Swap Potion", "effect": "temporary_gender_change", "duration": 86400.0, "price": 1000.0, "risk": 0.5},
    {"name": "Pleasure Amplifier", "effect": "double_orgasm_intensity", "duration": 7200.0, "price": 250.0, "risk": 0.25},
    {"name": "Stamina Drain", "effect": "partner_exhaustion", "duration": 3600.0, "price": 150.0, "risk": 0.35}
]

var heat_level: float = 0.0
var max_heat: float = 100.0
var is_being_watched: bool = false

signal illegal_purchase(item_name: String, success: bool)
signal police_raid()
signal heat_increased(level: float)

func _init(_economy: SexEconomySystem):
    economy = _economy

func buy_illegal_item(item_name: String) -> bool:
    for item in illegal_items:
        if item["name"] == item_name:
            if economy.spend_money(item["price"], "black_market"):
                heat_level += item["risk"] * 15.0
                heat_increased.emit(heat_level)
                if randf() < item["risk"]:
                    _fail_purchase(item)
                    return false
                illegal_purchase.emit(item_name, true)
                if heat_level > 80.0 and randf() < 0.3:
                    _police_raid()
                return true
    return false

func _fail_purchase(item: Dictionary):
    illegal_purchase.emit(item["name"], false)
    heat_level += 10.0

func _police_raid():
    police_raid.emit()
    economy.spend_money(economy.money * 0.3, "police_fine")
    heat_level = max(0, heat_level - 40.0)

func get_illegal_items() -> Array:
    return illegal_items

func _process(delta):
    heat_level = max(0, heat_level - delta * 0.5)
