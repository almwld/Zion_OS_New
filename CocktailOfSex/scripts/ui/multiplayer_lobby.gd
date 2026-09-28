extends Control
class_name MultiplayerLobby

@onready var player_list: ItemList = $PlayerList
@onready var chat_input: LineEdit = $ChatInput
@onready var chat_log: RichTextLabel = $ChatLog
@onready var host_button: Button = $HostButton
@onready var join_button: Button = $JoinButton
@onready var ip_input: LineEdit = $IPInput

func _ready():
    host_button.pressed.connect(_host)
    join_button.pressed.connect(_join)

func _host():
    var peer = WebSocketMultiplayerPeer.new()
    peer.create_server(8080)
    multiplayer.multiplayer_peer = peer
    multiplayer.peer_connected.connect(_on_player_connected)
    multiplayer.peer_disconnected.connect(_on_player_disconnected)
    chat_log.append_text("[System] Hosting server on port 8080\n")

func _join():
    var peer = WebSocketMultiplayerPeer.new()
    peer.create_client(ip_input.text, 8080)
    multiplayer.multiplayer_peer = peer
    chat_log.append_text("[System] Connecting to " + ip_input.text + "\n")

func _on_player_connected(id: int):
    player_list.add_item("Player " + str(id))
    chat_log.append_text("[System] Player " + str(id) + " joined\n")

func _on_player_disconnected(id: int):
    for i in range(player_list.item_count):
        if player_list.get_item_text(i) == "Player " + str(id):
            player_list.remove_item(i)
            break
    chat_log.append_text("[System] Player " + str(id) + " left\n")

func _on_chat_submitted(text: String):
    chat_log.append_text("[You]: " + text + "\n")
    rpc("_receive_chat", text)
    chat_input.clear()

@rpc("any_peer", "unreliable")
func _receive_chat(text: String):
    chat_log.append_text("[Them]: " + text + "\n")
