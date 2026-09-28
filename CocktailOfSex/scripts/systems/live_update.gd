extends Node
class_name LiveUpdate

var update_server: String = "https://updates.cocktailofsex.com"
var current_version: String = "2.0.0"
var update_available: bool = false

signal update_found(version: String, notes: String)
signal update_downloaded()

func check_for_updates():
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_check_complete)
    http.request(update_server + "/check?version=" + current_version)

func _on_check_complete(result, code, headers, body):
    if code == 200:
        update_available = true
        update_found.emit("2.1.0", "New features!")
