extends Control
class_name GalleryViewer

@onready var texture_rect: TextureRect = $TextureRect
@onready var prev_button: Button = $PrevButton
@onready var next_button: Button = $NextButton
@onready var delete_button: Button = $DeleteButton
@onready var label: Label = $Label

var images: Array[String] = []
var current_index: int = 0

func _ready():
    prev_button.pressed.connect(_prev)
    next_button.pressed.connect(_next)
    delete_button.pressed.connect(_delete)
    _load_images()

func _load_images():
    var dir = DirAccess.open("user://gallery")
    if dir:
        dir.list_dir_begin()
        var file = dir.get_next()
        while file != "":
            if file.ends_with(".png") or file.ends_with(".jpg"):
                images.append("user://gallery/" + file)
            file = dir.get_next()
    if images.size() > 0:
        _show_image(0)

func _show_image(index: int):
    if images.size() == 0: return
    current_index = index
    var image = Image.load_from_file(images[current_index])
    if image:
        texture_rect.texture = ImageTexture.create_from_image(image)
        label.text = str(current_index + 1) + " / " + str(images.size())

func _prev():
    if current_index > 0:
        _show_image(current_index - 1)

func _next():
    if current_index < images.size() - 1:
        _show_image(current_index + 1)

func _delete():
    if images.size() > 0:
        DirAccess.remove_absolute(images[current_index])
        images.remove_at(current_index)
        if current_index >= images.size():
            current_index = max(0, images.size() - 1)
        if images.size() > 0:
            _show_image(current_index)
        else:
            texture_rect.texture = null
            label.text = "0 / 0"
