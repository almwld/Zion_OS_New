extends Node
class_name WorldPersistence

var world_name: String = "Primal World"
var world_age: float = 0.0
var total_population: int = 0
var total_births: int = 0
var total_deaths: int = 0
var total_orgasms_world: int = 0
var total_money_circulated: float = 0.0

var locations: Array[Dictionary] = []
var active_events: Array[Dictionary] = []
var world_news: Array[String] = []
var economic_state: String = "stable"

var persisted_bodies: Array[Dictionary] = []

signal world_event_occurred(event: String)
signal population_changed(new_count: int)
signal world_age_advanced(years: float)

func _ready():
    _initialize_world()

func _initialize_world():
    locations.append({"name": "The Velvet Room", "type": "brothel", "owner": "Madame X", "reputation": 75.0})
    locations.append({"name": "The Dungeon", "type": "bdsm_club", "owner": "Master Z", "reputation": 85.0})
    locations.append({"name": "The Garden", "type": "public_park", "owner": "City", "reputation": 40.0})
    locations.append({"name": "The Observatory", "type": "voyeur_spot", "owner": "Professor L", "reputation": 60.0})
    locations.append({"name": "The Spa", "type": "relaxation", "owner": "Madame Rose", "reputation": 90.0})

func _process(delta):
    world_age += delta * 0.0001

func record_birth():
    total_births += 1
    total_population += 1
    population_changed.emit(total_population)

func record_death():
    total_deaths += 1
    total_population = max(0, total_population - 1)
    population_changed.emit(total_population)

func record_orgasm():
    total_orgasms_world += 1

func record_money(amount: float):
    total_money_circulated += amount

func add_news(news: String):
    world_news.append(news)
    if world_news.size() > 50:
        world_news.pop_front()

func get_world_report() -> Dictionary:
    return {
        "world_name": world_name,
        "age": world_age,
        "population": total_population,
        "births": total_births,
        "deaths": total_deaths,
        "total_orgasms": total_orgasms_world,
        "money_circulated": total_money_circulated,
        "economy": economic_state,
        "locations": locations.size()
    }
