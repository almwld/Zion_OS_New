extends Node
class_name SpaceExploration

var body: CocktailBody

var current_planet: String = "Earth"
var visited_planets: Array[String] = ["Earth"]
var discovered_species: Array[Dictionary] = []

var planets: Dictionary = {
    "Earth": {"gravity": 1.0, "atmosphere": "breathable", "natives": "Human", "temperature": 22.0},
    "Venus_Prime": {"gravity": 0.9, "atmosphere": "aphrodisiac", "natives": "Venusian", "temperature": 35.0},
    "Mars_Red": {"gravity": 0.38, "atmosphere": "thin", "natives": "Martian", "temperature": -10.0},
    "Jupiter_Palace": {"gravity": 2.5, "atmosphere": "dense_gas", "natives": "Jovian", "temperature": 15.0},
    "Neptunes_Depth": {"gravity": 1.1, "atmosphere": "liquid_pleasure", "natives": "Neptunian", "temperature": 28.0},
    "Pleasure_Station_9": {"gravity": 0.0, "atmosphere": "artificial", "natives": "Mixed", "temperature": 21.0},
    "Andromeda_Prime": {"gravity": 1.3, "atmosphere": "energizing", "natives": "Andromedan", "temperature": 25.0},
    "Black_Hole_Bordello": {"gravity": 10.0, "atmosphere": "time_dilated", "natives": "Singularity", "temperature": 100.0}
}

var alien_species: Array[Dictionary] = [
    {"name": "Venusian", "traits": "hermaphrodite, tentacles, aphrodisiac_sweat", "compatibility": 0.8},
    {"name": "Martian", "traits": "telepathic, red_skin, dual_organs", "compatibility": 0.6},
    {"name": "Jovian", "traits": "shapeshifter, gas_form, size_adaptable", "compatibility": 0.7},
    {"name": "Neptunian", "traits": "aquatic, bioluminescent, hydro_pleasure", "compatibility": 0.9},
    {"name": "Andromedan", "traits": "energy_being, pure_pleasure_waves, formless", "compatibility": 0.5},
    {"name": "Xenomorph_Queen", "traits": "exoskeleton, multiple_orifices, ovipositor", "compatibility": 0.3}
]

var space_ship_name: String = "The Lusty Comet"
var space_ship_level: int = 1
var fuel: float = 100.0
var credits: float = 1000.0

signal planet_discovered(planet: String)
signal alien_encountered(species: String)
signal space_sex_performed(partner: String, location: String)

func _init(_body: CocktailBody):
    body = _body

func travel_to_planet(planet_name: String) -> bool:
    if not planets.has(planet_name): return false
    if planet_name == current_planet: return false
    var fuel_cost = _calculate_fuel_cost(planet_name)
    if fuel < fuel_cost: return false
    fuel -= fuel_cost
    current_planet = planet_name
    if not planet_name in visited_planets:
        visited_planets.append(planet_name)
        planet_discovered.emit(planet_name)
    _apply_planet_effects(planet_name)
    return true

func _calculate_fuel_cost(planet_name: String) -> float:
    var distances = {"Earth": 0, "Venus_Prime": 10, "Mars_Red": 15, "Jupiter_Palace": 30, "Neptunes_Depth": 50, "Pleasure_Station_9": 25, "Andromeda_Prime": 100, "Black_Hole_Bordello": 75}
    return distances.get(planet_name, 20)

func _apply_planet_effects(planet_name: String):
    var planet = planets[planet_name]
    match planet_name:
        "Venus_Prime":
            body.arousal += 20.0
        "Mars_Red":
            body.personality["stamina"] *= 1.3
        "Jupiter_Palace":
            body.arousal += 10.0
        "Neptunes_Depth":
            body.vagina_wetness += 30.0
        "Pleasure_Station_9":
            body.max_multiple_orgasms += 2
        "Andromeda_Prime":
            body.max_arousal *= 1.5
        "Black_Hole_Bordello":
            body.orgasm_threshold *= 0.5

func encounter_alien(species_name: String) -> Dictionary:
    for species in alien_species:
        if species["name"] == species_name:
            alien_encountered.emit(species_name)
            discovered_species.append(species)
            return species
    return {}

func perform_space_sex(partner_species: String):
    space_sex_performed.emit(partner_species, current_planet)
    var arousal_boost = 20.0
    for species in alien_species:
        if species["name"] == partner_species:
            arousal_boost *= species["compatibility"]
    body.arousal = min(body.max_arousal, body.arousal + arousal_boost)

func upgrade_ship():
    space_ship_level += 1
    fuel = 100.0 * space_ship_level

func get_space_report() -> Dictionary:
    return {
        "current_planet": current_planet,
        "visited_planets": visited_planets.size(),
        "species_discovered": discovered_species.size(),
        "ship_level": space_ship_level,
        "fuel": fuel
    }
