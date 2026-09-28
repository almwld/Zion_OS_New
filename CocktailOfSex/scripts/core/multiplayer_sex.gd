extends Node
class_name MultiplayerSex

var peer: WebSocketMultiplayerPeer
var players: Dictionary = {}
var local_player: CocktailBody

func _ready():
    _start_server()

func _start_server():
    peer = WebSocketMultiplayerPeer.new()
    peer.create_server(8080)
    multiplayer.multiplayer_peer = peer
    peer.peer_connected.connect(_on_connect)
    peer.peer_disconnected.connect(_on_disconnect)

func _on_connect(id: int):
    var body = CocktailBody.new()
    body.body_name = "Player_" + str(id)
    players[id] = body
    add_child(body)

func _on_disconnect(id: int):
    if players.has(id):
        players[id].queue_free()
        players.erase(id)

func _process(delta):
    if multiplayer.is_server():
        _sync()

func _sync():
    for id in players:
        var body = players[id]
        rpc("_update_remote", id, {
            "position": body.global_position,
            "arousal": body.arousal,
            "is_climaxing": body.is_climaxing
        })

@rpc("any_peer", "unreliable")
func _update_remote(id: int, data: Dictionary):
    if players.has(id):
        var body = players[id]
        body.global_position = data["position"]
        body.arousal = data["arousal"]
        body.is_climaxing = data["is_climaxing"]
