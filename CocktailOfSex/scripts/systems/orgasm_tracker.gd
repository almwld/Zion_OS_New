extends Node
class_name OrgasmTracker

var body: CocktailBody
var total_orgasms: int = 0
var session_orgasms: int = 0
var best_session: int = 0
var orgasm_types: Dictionary = {}
var last_orgasm_time: float = 0.0
var average_time_between: float = 0.0

signal milestone_reached(milestone: String)

func _init(_body: CocktailBody):
    body = _body
    body.orgasm_achieved.connect(_record)

func _record(type: String, intensity: float):
    total_orgasms += 1
    session_orgasms += 1
    if session_orgasms > best_session:
        best_session = session_orgasms
    if not orgasm_types.has(type):
        orgasm_types[type] = 0
    orgasm_types[type] += 1
    var now = Time.get_ticks_msec() / 1000.0
    if last_orgasm_time > 0:
        var diff = now - last_orgasm_time
        if average_time_between == 0:
            average_time_between = diff
        else:
            average_time_between = (average_time_between + diff) / 2.0
    last_orgasm_time = now
    _check_milestones()

func _check_milestones():
    if total_orgasms == 1:
        milestone_reached.emit("first_ever")
    elif total_orgasms == 10:
        milestone_reached.emit("tenth")
    elif total_orgasms == 50:
        milestone_reached.emit("fiftieth")
    elif total_orgasms == 100:
        milestone_reached.emit("century")
    if session_orgasms == 3:
        milestone_reached.emit("hat_trick")
    elif session_orgasms == 5:
        milestone_reached.emit("five_in_session")
    elif session_orgasms == 10:
        milestone_reached.emit("double_digits")

func reset_session():
    session_orgasms = 0

func get_report() -> Dictionary:
    return {
        "total": total_orgasms,
        "session": session_orgasms,
        "best": best_session,
        "types": orgasm_types.duplicate(),
        "average_time": average_time_between
    }
