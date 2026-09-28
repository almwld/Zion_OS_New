extends Node
class_name ToyInventory

var owned_toys: Array[Dictionary] = []
var active_toy: Dictionary = {}
var toy_catalog: Array[Dictionary] = [
    {"name": "Basic Vibrator", "type": "vibrator", "intensity": 0.6, "noise": 0.3, "battery_life": 120.0, "cost": 25.0},
    {"name": "Rabbit Vibrator", "type": "vibrator", "intensity": 0.8, "noise": 0.4, "battery_life": 180.0, "cost": 45.0},
    {"name": "Magic Wand", "type": "vibrator", "intensity": 1.0, "noise": 0.7, "battery_life": 240.0, "cost": 75.0},
    {"name": "Small Dildo", "type": "dildo", "length": 0.12, "girth": 0.03, "material": "silicone", "cost": 20.0},
    {"name": "Medium Dildo", "type": "dildo", "length": 0.18, "girth": 0.04, "material": "glass", "cost": 35.0},
    {"name": "Large Dildo", "type": "dildo", "length": 0.25, "girth": 0.06, "material": "rubber", "cost": 55.0},
    {"name": "Butt Plug Small", "type": "plug", "size": 0.08, "material": "silicone", "cost": 15.0},
    {"name": "Butt Plug Medium", "type": "plug", "size": 0.12, "material": "metal", "cost": 25.0},
    {"name": "Butt Plug Large", "type": "plug", "size": 0.16, "material": "glass", "cost": 40.0},
    {"name": "Fleshlight", "type": "sleeve", "texture": "ribbed", "cost": 30.0},
    {"name": "Cock Ring", "type": "ring", "vibration": true, "cost": 20.0},
    {"name": "Nipple Clamps", "type": "clamp", "adjustable": true, "cost": 15.0},
    {"name": "Blindfold", "type": "accessory", "cost": 10.0},
    {"name": "Handcuffs", "type": "restraint", "cost": 20.0},
    {"name": "Rope", "type": "restraint", "length": 5.0, "cost": 15.0},
    {"name": "Ball Gag", "type": "gag", "cost": 18.0},
    {"name": "Paddle", "type": "impact", "cost": 22.0},
    {"name": "Whip", "type": "impact", "cost": 30.0},
    {"name": "Strap-on Harness", "type": "harness", "cost": 40.0},
    {"name": "Lubricant", "type": "consumable", "volume": 100.0, "cost": 8.0}
]

func _ready():
    for toy in toy_catalog:
        toy["purchased"] = false

func purchase_toy(toy_name: String) -> bool:
    for toy in toy_catalog:
        if toy["name"] == toy_name and not toy["purchased"]:
            toy["purchased"] = true
            owned_toys.append(toy.duplicate())
            return true
    return false

func get_owned_toys() -> Array:
    return owned_toys

func use_toy(toy_name: String, body: CocktailBody):
    for toy in owned_toys:
        if toy["name"] == toy_name:
            active_toy = toy
            match toy["type"]:
                "vibrator":
                    body.stimulate("clitoris", "vibrate", toy["intensity"], 1.0)
                "dildo":
                    body.stimulate("vagina_wall", "penetrate", 0.8, 1.0)
                    if toy["length"] > 0.18:
                        body.stimulate("g_spot", "penetrate", 0.9, 1.0)
                "plug":
                    body.stimulate("anus_ring", "penetrate", 0.6, 1.0)
                    body.anus_tightness = max(0.2, body.anus_tightness - toy["size"] * 0.5)
                "sleeve":
                    body.stimulate("penis_shaft", "rub", 0.7, 1.0)
                "clamp":
                    body.stimulate("nipples", "bite", 0.5, 1.0)
            return true
    return false

func get_available_catalog() -> Array:
    var available = []
    for toy in toy_catalog:
        var info = toy.duplicate()
        info["owned"] = is_owned(toy["name"])
        available.append(info)
    return available

func is_owned(toy_name: String) -> bool:
    for toy in owned_toys:
        if toy["name"] == toy_name: return true
    return false
