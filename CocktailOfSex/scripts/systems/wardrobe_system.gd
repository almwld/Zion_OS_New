extends Node
class_name WardrobeSystem

var body: CocktailBody
var owned_outfits: Array[Dictionary] = []
var current_outfit: Dictionary = {}

var outfit_catalog: Array[Dictionary] = [
    {"name": "Casual", "category": "everyday", "pieces": ["t-shirt", "jeans"], "attraction_bonus": 0.0, "accessibility": 1.0},
    {"name": "Business", "category": "formal", "pieces": ["blazer", "pencil skirt"], "attraction_bonus": 0.1, "accessibility": 0.3},
    {"name": "Sportswear", "category": "active", "pieces": ["tank top", "shorts"], "attraction_bonus": 0.05, "accessibility": 0.7},
    {"name": "Sleepwear", "category": "intimate", "pieces": ["silk robe"], "attraction_bonus": 0.2, "accessibility": 1.0},
    {"name": "Swimwear", "category": "beach", "pieces": ["bikini"], "attraction_bonus": 0.3, "accessibility": 0.9},
    {"name": "Lingerie Basic", "category": "intimate", "pieces": ["bra", "panties"], "attraction_bonus": 0.4, "accessibility": 1.0},
    {"name": "Lingerie Lace", "category": "intimate", "pieces": ["lace bra", "lace panties"], "attraction_bonus": 0.5, "accessibility": 0.9},
    {"name": "Lingerie Leather", "category": "fetish", "pieces": ["leather corset", "leather panties"], "attraction_bonus": 0.6, "accessibility": 0.5},
    {"name": "School Uniform", "category": "roleplay", "pieces": ["pleated skirt", "blouse"], "attraction_bonus": 0.3, "accessibility": 0.8},
    {"name": "Nurse Uniform", "category": "roleplay", "pieces": ["white dress", "cap"], "attraction_bonus": 0.4, "accessibility": 0.6},
    {"name": "Maid Uniform", "category": "roleplay", "pieces": ["frilly dress", "apron"], "attraction_bonus": 0.35, "accessibility": 0.7},
    {"name": "Bunny Suit", "category": "fetish", "pieces": ["leotard", "ears"], "attraction_bonus": 0.7, "accessibility": 0.4},
    {"name": "Latex Catsuit", "category": "fetish", "pieces": ["full body latex"], "attraction_bonus": 0.8, "accessibility": 0.2},
    {"name": "Nothing", "category": "nude", "pieces": [], "attraction_bonus": 0.0, "accessibility": 1.0}
]

signal outfit_changed(outfit_name: String)

func _init(_body: CocktailBody):
    body = _body
    for outfit in outfit_catalog:
        outfit["owned"] = false

func purchase_outfit(outfit_name: String) -> bool:
    for outfit in outfit_catalog:
        if outfit["name"] == outfit_name and not outfit["owned"]:
            outfit["owned"] = true
            owned_outfits.append(outfit.duplicate())
            return true
    return false

func wear_outfit(outfit_name: String) -> bool:
    for outfit in outfit_catalog:
        if outfit["name"] == outfit_name and outfit["owned"]:
            current_outfit = outfit
            outfit_changed.emit(outfit_name)
            return true
    return false

func remove_outfit():
    current_outfit = outfit_catalog[outfit_catalog.size() - 1]
    outfit_changed.emit("Nothing")

func get_current_outfit() -> Dictionary:
    return current_outfit

func get_attraction_bonus() -> float:
    return current_outfit.get("attraction_bonus", 0.0)

func get_accessibility() -> float:
    return current_outfit.get("accessibility", 1.0)

func get_owned_outfits() -> Array:
    return owned_outfits

func get_all_catalog() -> Array:
    var catalog = []
    for outfit in outfit_catalog:
        var info = outfit.duplicate()
        info["owned"] = is_owned(outfit["name"])
        catalog.append(info)
    return catalog

func is_owned(outfit_name: String) -> bool:
    for outfit in owned_outfits:
        if outfit["name"] == outfit_name: return true
    return false
