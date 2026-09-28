extends Node
class_name AIDialogue

var http: HTTPRequest
var history: Array[Dictionary] = []

func _ready():
    http = HTTPRequest.new(); add_child(http)
    http.request_completed.connect(_on_response)

func generate(body: CocktailBody, context: String, arousal: float):
    var prompt = "You are " + body.body_name + ". Personality: " + str(body.personality) + ". Arousal: " + str(arousal) + ". Context: " + context + ". Generate a short erotic dialogue response."
    var url = "http://localhost:11434/api/generate"
    var data = JSON.stringify({"model": "mistral", "prompt": prompt, "stream": false})
    http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, data)

func _on_response(result, code, headers, body_data):
    if code == 200:
        var json = JSON.parse_string(body_data.get_string_from_utf8())
        print(json["response"])
