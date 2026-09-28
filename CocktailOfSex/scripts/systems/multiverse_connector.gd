extends Node
class_name MultiverseConnector

var current_universe_id: String = ""
var connected_universes: Array[String] = []
var multiverse_bodies: Dictionary = {}

signal universe_connected(universe_id: String)
signal body_imported(body_data: Dictionary)

func _ready():
    current_universe_id = _generate_universe_id()

func _generate_universe_id() -> String:
    return "UNIVERSE_" + str(randi() % 999999).pad_zeros(6)

func connect_to_universe(universe_id: String):
    if not universe_id in connected_universes:
        connected_universes.append(universe_id)
        universe_connected.emit(universe_id)

func import_body_from_universe(universe_id: String, body_name: String) -> Dictionary:
    var body_data = {
        "name": body_name,
        "universe": universe_id,
        "import_time": Time.get_ticks_msec()
    }
    multiverse_bodies[body_name + "_" + universe_id] = body_data
    body_imported.emit(body_data)
    return body_data

func get_multiverse_report() -> Dictionary:
    return {
        "current_universe": current_universe_id,
        "connected_universes": connected_universes.size(),
        "imported_bodies": multiverse_bodies.size()
    }
