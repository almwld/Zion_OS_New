extends Node
class_name PremiumMembership

var economy: SexEconomySystem

enum Tier {
    FREE,
    SILVER,
    GOLD,
    PLATINUM,
    DIAMOND,
    BLACK_CARD,
    INFINITY
}

var current_tier: Tier = Tier.FREE
var tier_prices: Dictionary = {
    Tier.SILVER: 9.99,
    Tier.GOLD: 19.99,
    Tier.PLATINUM: 49.99,
    Tier.DIAMOND: 99.99,
    Tier.BLACK_CARD: 249.99,
    Tier.INFINITY: 999.99
}

var tier_benefits: Dictionary = {
    Tier.FREE: {
        "max_partners": 2,
        "max_scenes_per_day": 3,
        "toy_discount": 0.0,
        "brothel_cut": 0.3,
        "onlyfans_cut": 0.6,
        "exclusive_positions": [],
        "exclusive_locations": [],
        "priority_support": false,
        "custom_skins": false,
        "modding_access": false
    },
    Tier.SILVER: {
        "max_partners": 4,
        "max_scenes_per_day": 8,
        "toy_discount": 0.05,
        "brothel_cut": 0.4,
        "onlyfans_cut": 0.7,
        "exclusive_positions": ["reverse_cowgirl", "standing"],
        "exclusive_locations": ["office", "car"],
        "priority_support": false,
        "custom_skins": false,
        "modding_access": false
    },
    Tier.GOLD: {
        "max_partners": 8,
        "max_scenes_per_day": 20,
        "toy_discount": 0.1,
        "brothel_cut": 0.5,
        "onlyfans_cut": 0.75,
        "exclusive_positions": ["reverse_cowgirl", "standing", "spoon", "lotus"],
        "exclusive_locations": ["office", "car", "cinema", "rooftop"],
        "priority_support": true,
        "custom_skins": false,
        "modding_access": false
    },
    Tier.PLATINUM: {
        "max_partners": 16,
        "max_scenes_per_day": 50,
        "toy_discount": 0.15,
        "brothel_cut": 0.6,
        "onlyfans_cut": 0.8,
        "exclusive_positions": ["reverse_cowgirl", "standing", "spoon", "lotus", "amazon", "pretzel"],
        "exclusive_locations": ["office", "car", "cinema", "rooftop", "yacht", "private_jet"],
        "priority_support": true,
        "custom_skins": true,
        "modding_access": false
    },
    Tier.DIAMOND: {
        "max_partners": 32,
        "max_scenes_per_day": 100,
        "toy_discount": 0.25,
        "brothel_cut": 0.7,
        "onlyfans_cut": 0.85,
        "exclusive_positions": ["reverse_cowgirl", "standing", "spoon", "lotus", "amazon", "pretzel", "full_nelson", "pile_driver"],
        "exclusive_locations": ["office", "car", "cinema", "rooftop", "yacht", "private_jet", "submarine", "space_station"],
        "priority_support": true,
        "custom_skins": true,
        "modding_access": true
    },
    Tier.BLACK_CARD: {
        "max_partners": 64,
        "max_scenes_per_day": 500,
        "toy_discount": 0.4,
        "brothel_cut": 0.8,
        "onlyfans_cut": 0.9,
        "exclusive_positions": ["all"],
        "exclusive_locations": ["all"],
        "priority_support": true,
        "custom_skins": true,
        "modding_access": true
    },
    Tier.INFINITY: {
        "max_partners": 999,
        "max_scenes_per_day": 9999,
        "toy_discount": 0.6,
        "brothel_cut": 0.95,
        "onlyfans_cut": 1.0,
        "exclusive_positions": ["all"],
        "exclusive_locations": ["all"],
        "priority_support": true,
        "custom_skins": true,
        "modding_access": true
    }
}

var loyalty_points: int = 0
var days_subscribed: int = 0
var total_spent_premium: float = 0.0

signal tier_upgraded(old_tier: Tier, new_tier: Tier)
signal tier_downgraded(old_tier: Tier, new_tier: Tier)
signal loyalty_points_earned(points: int, total: int)
signal benefit_unlocked(benefit: String)

func _init(_economy: SexEconomySystem):
    economy = _economy

func upgrade_tier(new_tier: Tier) -> bool:
    if new_tier <= current_tier: return false
    var price = tier_prices[new_tier]
    if economy.spend_money(price, "premium_upgrade"):
        var old_tier = current_tier
        current_tier = new_tier
        total_spent_premium += price
        loyalty_points += int(price * 10)
        days_subscribed += 30
        tier_upgraded.emit(old_tier, new_tier)
        _check_new_benefits(old_tier, new_tier)
        return true
    return false

func _check_new_benefits(old_tier: Tier, new_tier: Tier):
    var old_benefits = tier_benefits[old_tier]
    var new_benefits = tier_benefits[new_tier]
    if new_benefits["custom_skins"] and not old_benefits["custom_skins"]:
        benefit_unlocked.emit("custom_skins")
    if new_benefits["modding_access"] and not old_benefits["modding_access"]:
        benefit_unlocked.emit("modding_access")
    if new_benefits["priority_support"] and not old_benefits["priority_support"]:
        benefit_unlocked.emit("priority_support")

func downgrade_tier(new_tier: Tier):
    if new_tier >= current_tier: return
    var old_tier = current_tier
    current_tier = new_tier
    tier_downgraded.emit(old_tier, new_tier)

func add_loyalty_points(points: int):
    loyalty_points += points
    loyalty_points_earned.emit(points, loyalty_points)

func get_benefit(benefit_name: String):
    if tier_benefits.has(current_tier):
        return tier_benefits[current_tier].get(benefit_name, null)
    return null

func get_current_tier_name() -> String:
    match current_tier:
        Tier.FREE: return "Free"
        Tier.SILVER: return "Silver"
        Tier.GOLD: return "Gold"
        Tier.PLATINUM: return "Platinum"
        Tier.DIAMOND: return "Diamond"
        Tier.BLACK_CARD: return "Black Card"
        Tier.INFINITY: return "Infinity"
    return "Unknown"

func get_next_tier() -> Tier:
    match current_tier:
        Tier.FREE: return Tier.SILVER
        Tier.SILVER: return Tier.GOLD
        Tier.GOLD: return Tier.PLATINUM
        Tier.PLATINUM: return Tier.DIAMOND
        Tier.DIAMOND: return Tier.BLACK_CARD
        Tier.BLACK_CARD: return Tier.INFINITY
        Tier.INFINITY: return Tier.INFINITY
    return Tier.FREE

func get_premium_status() -> Dictionary:
    return {
        "current_tier": get_current_tier_name(),
        "next_tier": get_current_tier_name() if current_tier == Tier.INFINITY else tier_prices[get_next_tier()],
        "loyalty_points": loyalty_points,
        "days_subscribed": days_subscribed,
        "total_spent": total_spent_premium
    }
