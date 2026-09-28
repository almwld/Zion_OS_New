extends Node
class_name TimeTravelSex

var body: CocktailBody

var current_era: String = "Present"
var visited_eras: Array[String] = ["Present"]
var temporal_paradoxes: int = 0

var eras: Dictionary = {
    "Prehistoric": {"period": "10000 BC", "partners": "Caveman/Cavewoman", "arousal_mod": 1.5, "risk": 0.3},
    "Ancient_Egypt": {"period": "2500 BC", "partners": "Pharaoh/Cleopatra", "arousal_mod": 1.4, "risk": 0.2},
    "Roman_Empire": {"period": "100 AD", "partners": "Gladiator/Empress", "arousal_mod": 1.6, "risk": 0.25},
    "Medieval": {"period": "1200 AD", "partners": "Knight/Princess", "arousal_mod": 1.3, "risk": 0.15},
    "Victorian": {"period": "1850 AD", "partners": "Gentleman/Lady", "arousal_mod": 1.2, "risk": 0.1},
    "Roaring_20s": {"period": "1920 AD", "partners": "Flapper/Gangster", "arousal_mod": 1.4, "risk": 0.2},
    "Future_2100": {"period": "2100 AD", "partners": "Cyborg/Hologram", "arousal_mod": 1.8, "risk": 0.4},
    "Future_3000": {"period": "3000 AD", "partners": "Pure_Energy", "arousal_mod": 2.0, "risk": 0.5},
    "End_of_Time": {"period": "Heat Death", "partners": "Cosmic_Entity", "arousal_mod": 3.0, "risk": 0.9}
}

var time_machine_name: String = "The Chrono-Orgasmer"
var temporal_energy: float = 100.0
var max_temporal_energy: float = 100.0

signal era_travelled(era: String)
signal paradox_created(description: String)
signal temporal_orgasm_achieved(era: String, intensity: float)

func _init(_body: CocktailBody):
    body = _body

func _process(delta):
    temporal_energy = min(max_temporal_energy, temporal_energy + delta * 2.0)

func travel_to_era(era_name: String) -> bool:
    if not eras.has(era_name): return false
    if temporal_energy < 20.0: return false
    temporal_energy -= 20.0
    current_era = era_name
    if not era_name in visited_eras:
        visited_eras.append(era_name)
        era_travelled.emit(era_name)
    if randf() < eras[era_name]["risk"]:
        _create_paradox()
    _apply_era_effects(era_name)
    return true

func _apply_era_effects(era_name: String):
    var era = eras[era_name]
    body.arousal = min(body.max_arousal, body.arousal * era["arousal_mod"])

func _create_paradox():
    temporal_paradoxes += 1
    var descriptions = [
        "You accidentally became your own grandfather!",
        "A duplicate of yourself appears from another timeline and joins in!",
        "The timeline splits! Now there are two of you, both equally horny!",
        "You created a loop where you keep losing your virginity for the first time, forever!",
        "Your orgasm echoes through time, causing spontaneous pleasure across all eras!"
    ]
    var desc = descriptions[randi() % descriptions.size()]
    paradox_created.emit(desc)

func have_temporal_sex(partner_name: String):
    var era = eras[current_era]
    var pleasure_multiplier = era["arousal_mod"]
    body.arousal = min(body.max_arousal, body.arousal + 30.0 * pleasure_multiplier)
    temporal_orgasm_achieved.emit(current_era, body.arousal / body.max_arousal)

func get_time_report() -> Dictionary:
    return {
        "current_era": current_era,
        "visited_eras": visited_eras.size(),
        "paradoxes": temporal_paradoxes,
        "temporal_energy": temporal_energy
    }
