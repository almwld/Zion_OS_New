extends Node
class_name OnlineOrgyManager

var peer: WebSocketMultiplayerPeer
var is_host: bool = false
var max_players: int = 32
var connected_players: Dictionary = {}
var local_player_id: int = 0

var orgy_room: String = "lobby"
var orgy_positions: Dictionary = {}
var orgy_actions: Dictionary = {}

var chat_messages: Array[Dictionary] = []

enum OrgyType {
    FREE_FOR_ALL,
    COUPLE_SWAP,
    GANG_BANG,
    BUKKAKE,
    TRAIN,
    CIRCLE_JERK,
    DAISY_CHAIN,
    GLORY_HOLE,
    EXHIBITION,
    VOYEUR
}

var current_orgy_type: OrgyType = OrgyType.FREE_FOR_ALL

signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)
signal chat_message_received(sender: String, message: String)
signal orgy_action_triggered(action: String, participants: Array)

func _ready():
    _initialize_network()

func _initialize_network():
    peer = WebSocketMultiplayerPeer.new()
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func host_orgy(port: int = 8080, max_players: int = 32):
    is_host = true
    self.max_players = max_players
    peer.create_server(port, max_players)
    multiplayer.multiplayer_peer = peer
    local_player_id = multiplayer.get_unique_id()
    connected_players[local_player_id] = {"name": "Host", "position": Vector3.ZERO, "arousal": 0.0}
    print("[OrgyManager] Hosting orgy on port " + str(port) + " with max " + str(max_players) + " players")

func join_orgy(address: String, port: int = 8080):
    is_host = false
    peer.create_client(address, port)
    multiplayer.multiplayer_peer = peer
    local_player_id = multiplayer.get_unique_id()
    print("[OrgyManager] Joining orgy at " + address + ":" + str(port))

func _on_peer_connected(peer_id: int):
    var player_name = "Player_" + str(peer_id)
    connected_players[peer_id] = {"name": player_name, "position": Vector3.ZERO, "arousal": 0.0}
    player_joined.emit(peer_id, player_name)
    rpc("_sync_new_player", peer_id, player_name)

func _on_peer_disconnected(peer_id: int):
    if connected_players.has(peer_id):
        connected_players.erase(peer_id)
        player_left.emit(peer_id)

@rpc("any_peer", "reliable")
func _sync_new_player(peer_id: int, player_name: String):
    if not connected_players.has(peer_id):
        connected_players[peer_id] = {"name": player_name, "position": Vector3.ZERO, "arousal": 0.0}
        player_joined.emit(peer_id, player_name)

func send_chat_message(message: String):
    var sender = connected_players.get(local_player_id, {}).get("name", "Unknown")
    chat_messages.append({"sender": sender, "message": message, "time": Time.get_ticks_msec()})
    chat_message_received.emit(sender, message)
    rpc("_receive_chat", sender, message)

@rpc("any_peer", "reliable")
func _receive_chat(sender: String, message: String):
    chat_messages.append({"sender": sender, "message": message, "time": Time.get_ticks_msec()})
    chat_message_received.emit(sender, message)

func set_orgy_type(type: OrgyType):
    current_orgy_type = type
    rpc("_sync_orgy_type", type)

@rpc("any_peer", "reliable")
func _sync_orgy_type(type: OrgyType):
    current_orgy_type = type

func trigger_orgy_action(action: String, participants: Array):
    orgy_action_triggered.emit(action, participants)
    rpc("_sync_orgy_action", action, participants)

@rpc("any_peer", "reliable")
func _sync_orgy_action(action: String, participants: Array):
    orgy_action_triggered.emit(action, participants)

func get_player_count() -> int:
    return connected_players.size()

func get_all_players() -> Array:
    var players = []
    for id in connected_players:
        players.append({"id": id, "name": connected_players[id]["name"]})
    return players

func kick_player(peer_id: int):
    if is_host and peer_id != local_player_id:
        multiplayer.multiplayer_peer.disconnect_peer(peer_id)

func ban_player(peer_id: int):
    if is_host:
        kick_player(peer_id)

func end_orgy():
    if is_host:
        multiplayer.multiplayer_peer.close()
    connected_players.clear()
    print("[OrgyManager] Orgy ended")
