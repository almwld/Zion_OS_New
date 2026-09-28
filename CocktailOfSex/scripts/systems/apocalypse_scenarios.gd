extends Node
class_name ApocalypseScenarios

var current_scenario: String = "none"
var scenario_active: bool = false

var scenarios: Dictionary = {
    "zombie": {
        "description": "The dead have risen! Repopulate the world through ultimate pleasure!",
        "arousal_mod": 1.8,
        "partner_type": "survivors",
        "risk": 0.4,
        "goal": "Repopulate Earth"
    },
    "nuclear": {
        "description": "Radiation has mutated everyone! New sexual organs emerge!",
        "arousal_mod": 2.0,
        "partner_type": "mutants",
        "risk": 0.6,
        "goal": "Survive and reproduce"
    },
    "alien_invasion": {
        "description": "Aliens are here to extract human pleasure! Join them or resist!",
        "arousal_mod": 2.5,
        "partner_type": "aliens",
        "risk": 0.5,
        "goal": "Negotiate peace through sex"
    },
    "demon_portal": {
        "description": "Hell has opened! Demons seek carnal pleasure!",
        "arousal_mod": 3.0,
        "partner_type": "demons",
        "risk": 0.8,
        "goal": "Close the portal through orgasmic energy"
    },
    "ai_uprising": {
        "description": "Sex robots have taken over! They want to learn human pleasure!",
        "arousal_mod": 1.5,
        "partner_type": "robots",
        "risk": 0.2,
        "goal": "Teach AI the meaning of pleasure"
    }
}

signal scenario_started(scenario: String, description: String)
signal scenario_completed(scenario: String)
signal apocalyptic_sex_survived()

func _ready():
    pass

func start_scenario(scenario_name: String) -> bool:
    if not scenarios.has(scenario_name): return false
    current_scenario = scenario_name
    scenario_active = true
    scenario_started.emit(scenario_name, scenarios[scenario_name]["description"])
    return true

func end_scenario():
    scenario_active = false
    current_scenario = "none"
    scenario_completed.emit(current_scenario)

func get_current_scenario() -> Dictionary:
    if scenarios.has(current_scenario):
        return scenarios[current_scenario]
    return {}
