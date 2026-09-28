extends Node
class_name BrothelManager

var body: CocktailBody
var economy: SexEconomySystem

var brothel_name: String = "The Velvet Room"
var brothel_level: int = 1
var brothel_reputation: float = 50.0
var brothel_location: String = "downtown"

var workers: Array[Dictionary] = []
var rooms: Array[Dictionary] = []
var clients: Array[Dictionary] = []
var active_sessions: Array[Dictionary] = []

var daily_revenue: float = 0.0
var daily_expenses: float = 0.0
var weekly_revenue: float = 0.0
var monthly_revenue: float = 0.0

var services_offered: Array[String] = [
    "basic_service",
    "full_service",
    "fetish_session",
    "couples_session",
    "group_session",
    "overnight",
    "weekend_package",
    "vip_experience"
]

var service_prices: Dictionary = {
    "basic_service": 50.0,
    "full_service": 100.0,
    "fetish_session": 150.0,
    "couples_session": 200.0,
    "group_session": 300.0,
    "overnight": 500.0,
    "weekend_package": 1000.0,
    "vip_experience": 2000.0
}

signal brothel_upgraded(new_level: int)
signal worker_hired(worker_name: String)
signal worker_fired(worker_name: String)
signal client_served(client_name: String, service: String, satisfaction: float)
signal revenue_generated(amount: float)

func _init(_body: CocktailBody, _economy: SexEconomySystem):
    body = _body
    economy = _economy
    _initialize_rooms()

func _initialize_rooms():
    for i in range(3):
        rooms.append({
            "id": i + 1,
            "name": "Room " + str(i + 1),
            "quality": 1,
            "occupied": false,
            "clean": true
        })

func hire_worker(worker_name: String, skills: Array, cut_percentage: float = 0.5):
    var worker = {
        "name": worker_name,
        "skills": skills,
        "cut": cut_percentage,
        "sessions_completed": 0,
        "total_earned": 0.0,
        "satisfaction_rating": 3.0,
        "is_available": true,
        "energy": 100.0,
        "health": 100.0
    }
    workers.append(worker)
    worker_hired.emit(worker_name)

func fire_worker(worker_name: String):
    for i in range(workers.size()):
        if workers[i]["name"] == worker_name:
            workers.remove_at(i)
            worker_fired.emit(worker_name)
            return

func serve_client(client_name: String, service: String, worker_name: String) -> bool:
    var worker = _find_worker(worker_name)
    var room = _find_available_room()
    if not worker or not room: return false
    if not service in services_offered: return false
    var price = service_prices[service]
    var satisfaction = worker["satisfaction_rating"] * randf_range(0.8, 1.2)
    var revenue = price * satisfaction
    var worker_cut = revenue * worker["cut"]
    var brothel_cut = revenue - worker_cut
    economy.add_money(brothel_cut, "brothel_" + service)
    worker["total_earned"] += worker_cut
    worker["sessions_completed"] += 1
    worker["energy"] = max(0, worker["energy"] - 20.0)
    daily_revenue += brothel_cut
    room["occupied"] = true
    room["clean"] = false
    active_sessions.append({
        "client": client_name,
        "worker": worker_name,
        "service": service,
        "room": room["id"],
        "start_time": Time.get_ticks_msec()
    })
    client_served.emit(client_name, service, satisfaction)
    revenue_generated.emit(revenue)
    return true

func _find_worker(name: String) -> Dictionary:
    for w in workers:
        if w["name"] == name and w["is_available"]: return w
    return {}

func _find_available_room() -> Dictionary:
    for room in rooms:
        if not room["occupied"] and room["clean"]: return room
    return {}

func upgrade_brothel():
    brothel_level += 1
    for i in range(2):
        rooms.append({
            "id": rooms.size() + 1,
            "name": "VIP Room " + str(rooms.size() + 1),
            "quality": brothel_level,
            "occupied": false,
            "clean": true
        })
    for service in service_prices:
        service_prices[service] *= 1.25
    brothel_upgraded.emit(brothel_level)

func get_brothel_stats() -> Dictionary:
    return {
        "name": brothel_name,
        "level": brothel_level,
        "reputation": brothel_reputation,
        "workers": workers.size(),
        "rooms": rooms.size(),
        "daily_revenue": daily_revenue,
        "active_sessions": active_sessions.size()
    }

func _process(delta):
    for session in active_sessions:
        var elapsed = (Time.get_ticks_msec() - session["start_time"]) / 1000.0
        if elapsed > 1800.0:
            active_sessions.erase(session)
            for room in rooms:
                if room["id"] == session["room"]:
                    room["occupied"] = false
                    room["clean"] = false
    for worker in workers:
        worker["energy"] = min(100.0, worker["energy"] + delta * 2.0)
