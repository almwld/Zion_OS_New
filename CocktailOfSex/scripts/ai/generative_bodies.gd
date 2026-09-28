extends Node
class_name GenerativeBodies

var http: HTTPRequest
var cache: Dictionary = {}

func _ready():
    http = HTTPRequest.new(); add_child(http)
    http.request_completed.connect(_on_texture)

func generate(prompt: String, body: CocktailBody):
    var url = "http://localhost:7860/sdapi/v1/txt2img"
    var data = JSON.stringify({
        "prompt": "nude skin texture, " + prompt + ", 8k, realistic, no clothes, anatomical",
        "negative_prompt": "clothes, underwear, censor, blur, deformed",
        "steps": 50,
        "width": 2048,
        "height": 2048
    })
    http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, data)

func _on_texture(result, code, headers, body_data):
    if code == 200:
        var json = JSON.parse_string(body_data.get_string_from_utf8())
        var image_data = Marshalls.base64_to_raw(json["images"][0])
        var image = Image.new()
        image.load_png_from_buffer(image_data)
        var texture = ImageTexture.create_from_image(image)
        cache["last"] = texture
