extends Node

var active_sessions: Dictionary = {}
var character_roles: Dictionary = {}

func set_role(body, role: String):
    character_roles[body] = role

func get_role(body) -> String:
    return character_roles.get(body, "neutral")

func start_session(kink_type: int, participants: Array) -> String:
    var id = str(Time.get_unix_time_from_system())
    active_sessions[id] = {"type": kink_type, "participants": participants}
    return id

func apply_action(actor, target, action: String, intensity: float):
    target.arousal = min(target.max_arousal, target.arousal + intensity * 15.0)
