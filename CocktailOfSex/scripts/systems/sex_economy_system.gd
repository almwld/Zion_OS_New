extends Node
class_name SexEconomySystem

var body: CocktailBody
var money: float = 500.0
var income_sources: Dictionary = {}
var expenses: Array[Dictionary] = []
var total_earned: float = 0.0
var total_spent: float = 0.0

var sex_work_multiplier: float = 1.0
var fame_level: int = 0
var subscriber_count: int = 0
var tip_jar_total: float = 0.0

signal money_changed(current: float, change: float)
signal new_income_source(source: String)
signal fame_increased(new_level: int)

func _init(_body: CocktailBody):
    body = _body

func add_money(amount: float, source: String = "unknown"):
    money += amount
    total_earned += amount
    if not income_sources.has(source):
        income_sources[source] = 0.0
        new_income_source.emit(source)
    income_sources[source] += amount
    money_changed.emit(money, amount)

func spend_money(amount: float, purpose: String = "unknown") -> bool:
    if money >= amount:
        money -= amount
        total_spent += amount
        expenses.append({"purpose": purpose, "amount": amount, "time": Time.get_ticks_msec()})
        money_changed.emit(money, -amount)
        return true
    return false

func earn_from_sex_work(service: String, client_rating: float) -> float:
    var base_pay: Dictionary = {
        "quick_handjob": 20.0,
        "blowjob": 40.0,
        "cunnilingus": 35.0,
        "vaginal_sex": 60.0,
        "anal_sex": 80.0,
        "full_service": 100.0,
        "overnight": 200.0,
        "weekend": 500.0,
        "fetish_session": 75.0,
        "domination": 90.0,
        "submission": 70.0,
        "cam_show": 30.0,
        "custom_video": 50.0,
        "phone_sex": 15.0,
        "sexting": 10.0
    }
    if base_pay.has(service):
        var earned = base_pay[service] * sex_work_multiplier * client_rating
        add_money(earned, "sex_work_" + service)
        return earned
    return 0.0

func earn_from_subscriptions():
    var monthly_income = subscriber_count * 5.0
    add_money(monthly_income, "subscriptions")

func earn_from_tips(amount: float, tipper_name: String):
    tip_jar_total += amount
    add_money(amount, "tip_from_" + tipper_name)

func increase_fame(amount: int = 1):
    fame_level += amount
    if fame_level % 5 == 0:
        sex_work_multiplier += 0.1
    fame_increased.emit(fame_level)

func get_financial_report() -> Dictionary:
    return {
        "current_balance": money,
        "total_earned": total_earned,
        "total_spent": total_spent,
        "income_sources": income_sources.duplicate(),
        "fame_level": fame_level,
        "subscribers": subscriber_count,
        "tips": tip_jar_total
    }
