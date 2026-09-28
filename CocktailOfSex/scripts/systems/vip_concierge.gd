extends Node
class_name VIPConcierge

var premium: PremiumMembership
var economy: SexEconomySystem

var concierge_name: String = "Victoria"
var available_services: Array[String] = []
var active_requests: Array[Dictionary] = []
var completed_requests: Array[Dictionary] = []

signal concierge_message(message: String)
signal request_completed(request: Dictionary)
signal special_offer_received(offer: Dictionary)

func _init(_premium: PremiumMembership, _economy: SexEconomySystem):
    premium = _premium
    economy = _economy
    _update_available_services()

func _update_available_services():
    available_services.clear()
    available_services.append("personalized_matchmaking")
    if premium.current_tier >= PremiumMembership.Tier.GOLD:
        available_services.append("custom_scene_request")
        available_services.append("priority_support")
    if premium.current_tier >= PremiumMembership.Tier.PLATINUM:
        available_services.append("private_show")
        available_services.append("exclusive_event_invite")
    if premium.current_tier >= PremiumMembership.Tier.DIAMOND:
        available_services.append("custom_character_creation")
        available_services.append("world_modification")
    if premium.current_tier >= PremiumMembership.Tier.BLACK_CARD:
        available_services.append("developer_access")
        available_services.append("influence_game_direction")
    if premium.current_tier >= PremiumMembership.Tier.INFINITY:
        available_services.append("god_mode")
        available_services.append("universe_creation")

func make_request(service: String, details: String = "") -> bool:
    if not service in available_services: return false
    var request = {
        "id": active_requests.size() + 1,
        "service": service,
        "details": details,
        "status": "pending",
        "timestamp": Time.get_ticks_msec()
    }
    active_requests.append(request)
    concierge_message.emit("Request #" + str(request["id"]) + " for '" + service + "' has been submitted. We will process it shortly.")
    return true

func process_requests():
    for request in active_requests:
        if request["status"] == "pending":
            request["status"] = "completed"
            completed_requests.append(request)
            active_requests.erase(request)
            request_completed.emit(request)
            concierge_message.emit("Request #" + str(request["id"]) + " has been completed!")

func send_special_offer():
    var offers = [
        {"title": "Exclusive Orgy Invitation", "description": "You're invited to a secret VIP orgy. 50 premium members. Tonight at midnight."},
        {"title": "Limited Edition Toy", "description": "A one-of-a-kind toy crafted just for premium members. Only 100 ever made."},
        {"title": "Meet the Developers", "description": "Join our exclusive Q&A session with the game developers."},
        {"title": "Early Access", "description": "Get early access to upcoming features before anyone else."}
    ]
    var offer = offers[randi() % offers.size()]
    special_offer_received.emit(offer)
    concierge_message.emit("Special Offer: " + offer["title"])

func get_concierge_status() -> Dictionary:
    return {
        "name": concierge_name,
        "tier": premium.get_current_tier_name(),
        "available_services": available_services.size(),
        "pending_requests": active_requests.size(),
        "completed_requests": completed_requests.size()
    }
