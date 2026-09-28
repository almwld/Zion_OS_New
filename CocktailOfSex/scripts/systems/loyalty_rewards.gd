extends Node
class_name LoyaltyRewards

var premium: PremiumMembership
var economy: SexEconomySystem

var login_streak: int = 0
var total_logins: int = 0
var total_playtime: float = 0.0
var achievements_completed: int = 0

var daily_rewards: Array[Dictionary] = [
    {"day": 1, "reward": "100 coins", "claimed": false},
    {"day": 2, "reward": "Free Toy", "claimed": false},
    {"day": 3, "reward": "200 coins", "claimed": false},
    {"day": 4, "reward": "Exclusive Outfit", "claimed": false},
    {"day": 5, "reward": "500 coins", "claimed": false},
    {"day": 6, "reward": "Premium Trial (1 day)", "claimed": false},
    {"day": 7, "reward": "1000 coins + Rare Toy", "claimed": false}
]

signal daily_reward_claimed(day: int, reward: String)
signal login_streak_milestone(days: int)
signal loyalty_milestone_reached(milestone: String)

func _init(_premium: PremiumMembership, _economy: SexEconomySystem):
    premium = _premium
    economy = _economy

func daily_login():
    login_streak += 1
    total_logins += 1
    if login_streak > 7:
        login_streak = 1
    _reset_daily_rewards_if_new_cycle()
    if login_streak in [7, 30, 100, 365]:
        login_streak_milestone.emit(login_streak)
    if total_logins == 1:
        loyalty_milestone_reached.emit("First Login")
    elif total_logins == 10:
        loyalty_milestone_reached.emit("10 Logins")
    elif total_logins == 50:
        loyalty_milestone_reached.emit("50 Logins")
    elif total_logins == 100:
        loyalty_milestone_reached.emit("100 Logins - Veteran Status")

func claim_daily_reward() -> bool:
    var today = login_streak - 1
    if today < 0: today = 0
    if today < daily_rewards.size():
        if not daily_rewards[today]["claimed"]:
            daily_rewards[today]["claimed"] = true
            var reward = daily_rewards[today]["reward"]
            daily_reward_claimed.emit(today + 1, reward)
            _process_reward(reward)
            return true
    return false

func _process_reward(reward: String):
    if "coins" in reward.to_lower():
        var amount = int(reward.split(" ")[0])
        economy.add_money(amount, "daily_reward")
    elif "Toy" in reward:
        economy.add_money(50, "daily_reward")
    elif "Outfit" in reward:
        economy.add_money(100, "daily_reward")
    elif "Trial" in reward:
        pass

func _reset_daily_rewards_if_new_cycle():
    if login_streak == 1:
        for reward in daily_rewards:
            reward["claimed"] = false

func add_playtime(delta: float):
    total_playtime += delta
    if total_playtime > 3600 and total_playtime - delta <= 3600:
        loyalty_milestone_reached.emit("1 Hour Played")
    elif total_playtime > 36000 and total_playtime - delta <= 36000:
        loyalty_milestone_reached.emit("10 Hours Played")
    elif total_playtime > 86400 and total_playtime - delta <= 86400:
        loyalty_milestone_reached.emit("24 Hours Played - Dedicated Player")

func get_loyalty_status() -> Dictionary:
    return {
        "login_streak": login_streak,
        "total_logins": total_logins,
        "total_playtime": total_playtime,
        "daily_claimed": daily_rewards[min(login_streak - 1, 6)]["claimed"]
    }
