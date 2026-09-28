extends Node
class_name ExclusiveContentManager

var premium: PremiumMembership

var exclusive_scenes: Array[Dictionary] = [
    {"name": "Royal Harem", "required_tier": PremiumMembership.Tier.GOLD, "max_partners": 10, "description": "Be the king/queen of your own harem"},
    {"name": "Celebrity Encounter", "required_tier": PremiumMembership.Tier.PLATINUM, "max_partners": 2, "description": "Meet and seduce famous personalities"},
    {"name": "Alien Abduction", "required_tier": PremiumMembership.Tier.DIAMOND, "max_partners": 4, "description": "Zero-gravity sex with extraterrestrial beings"},
    {"name": "Time Travel Orgy", "required_tier": PremiumMembership.Tier.BLACK_CARD, "max_partners": 20, "description": "Travel through time for the ultimate orgy"},
    {"name": "Divine Ascension", "required_tier": PremiumMembership.Tier.INFINITY, "max_partners": 999, "description": "Become a sex god and create your own universe"}
]

var exclusive_outfits: Array[Dictionary] = [
    {"name": "Royal Robes", "required_tier": PremiumMembership.Tier.GOLD, "attraction_bonus": 0.3},
    {"name": "Diamond Lingerie", "required_tier": PremiumMembership.Tier.PLATINUM, "attraction_bonus": 0.4},
    {"name": "Starlight Gown", "required_tier": PremiumMembership.Tier.DIAMOND, "attraction_bonus": 0.5},
    {"name": "Shadow Mist", "required_tier": PremiumMembership.Tier.BLACK_CARD, "attraction_bonus": 0.6},
    {"name": "Divine Aura", "required_tier": PremiumMembership.Tier.INFINITY, "attraction_bonus": 1.0}
]

var exclusive_locations: Array[Dictionary] = [
    {"name": "Presidential Suite", "required_tier": PremiumMembership.Tier.GOLD, "arousal_modifier": 1.3},
    {"name": "Private Island", "required_tier": PremiumMembership.Tier.PLATINUM, "arousal_modifier": 1.5},
    {"name": "Underwater Palace", "required_tier": PremiumMembership.Tier.DIAMOND, "arousal_modifier": 1.7},
    {"name": "Sky Castle", "required_tier": PremiumMembership.Tier.BLACK_CARD, "arousal_modifier": 1.9},
    {"name": "Nexus of Reality", "required_tier": PremiumMembership.Tier.INFINITY, "arousal_modifier": 2.5}
]

var exclusive_toys: Array[Dictionary] = [
    {"name": "Golden Dildo", "required_tier": PremiumMembership.Tier.GOLD, "intensity_bonus": 0.2},
    {"name": "Platinum Vibrator", "required_tier": PremiumMembership.Tier.PLATINUM, "intensity_bonus": 0.3},
    {"name": "Diamond Plug", "required_tier": PremiumMembership.Tier.DIAMOND, "intensity_bonus": 0.4},
    {"name": "Obsidian Whip", "required_tier": PremiumMembership.Tier.BLACK_CARD, "intensity_bonus": 0.5},
    {"name": "Celestial Orb", "required_tier": PremiumMembership.Tier.INFINITY, "intensity_bonus": 0.8}
]

signal exclusive_content_unlocked(content_type: String, content_name: String)
signal exclusive_scene_played(scene_name: String)

func _init(_premium: PremiumMembership):
    premium = _premium

func is_content_unlocked(content: Dictionary) -> bool:
    return premium.current_tier >= content["required_tier"]

func get_available_scenes() -> Array:
    var available = []
    for scene in exclusive_scenes:
        if is_content_unlocked(scene):
            available.append(scene)
    return available

func get_available_outfits() -> Array:
    var available = []
    for outfit in exclusive_outfits:
        if is_content_unlocked(outfit):
            available.append(outfit)
    return available

func get_available_locations() -> Array:
    var available = []
    for loc in exclusive_locations:
        if is_content_unlocked(loc):
            available.append(loc)
    return available

func get_available_toys() -> Array:
    var available = []
    for toy in exclusive_toys:
        if is_content_unlocked(toy):
            available.append(toy)
    return available

func play_exclusive_scene(scene_name: String) -> bool:
    for scene in exclusive_scenes:
        if scene["name"] == scene_name and is_content_unlocked(scene):
            exclusive_scene_played.emit(scene_name)
            return true
    return false

func get_locked_content_summary() -> Dictionary:
    var summary = {
        "scenes": {"locked": 0, "unlocked": 0},
        "outfits": {"locked": 0, "unlocked": 0},
        "locations": {"locked": 0, "unlocked": 0},
        "toys": {"locked": 0, "unlocked": 0}
    }
    for scene in exclusive_scenes:
        if is_content_unlocked(scene): summary["scenes"]["unlocked"] += 1
        else: summary["scenes"]["locked"] += 1
    for outfit in exclusive_outfits:
        if is_content_unlocked(outfit): summary["outfits"]["unlocked"] += 1
        else: summary["outfits"]["locked"] += 1
    for loc in exclusive_locations:
        if is_content_unlocked(loc): summary["locations"]["unlocked"] += 1
        else: summary["locations"]["locked"] += 1
    for toy in exclusive_toys:
        if is_content_unlocked(toy): summary["toys"]["unlocked"] += 1
        else: summary["toys"]["locked"] += 1
    return summary
