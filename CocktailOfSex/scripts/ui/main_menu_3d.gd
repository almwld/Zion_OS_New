extends Control
class_name MainMenu3D

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var gallery_button: Button = $VBoxContainer/GalleryButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var version_label: Label = $VersionLabel
@onready var title_label: Label = $TitleLabel
@onready var background_video: VideoStreamPlayer = $BackgroundVideo

func _ready():
    start_button.pressed.connect(_on_start)
    continue_button.pressed.connect(_on_continue)
    gallery_button.pressed.connect(_on_gallery)
    settings_button.pressed.connect(_on_settings)
    quit_button.pressed.connect(_on_quit)
    version_label.text = "Cocktail of Sex v1.0.0 - Ultimate Edition"
    title_label.text = "🍸 COCKTAIL OF SEX 🍸"
    if background_video:
        background_video.play()

func _on_start():
    var master = get_node("/root/MasterController")
    if master:
        var body1 = master.create_new_body("Player", "male", 25)
        var body2 = master.create_new_body("Partner", "female", 23)
        master.start_sex_scene([body1, body2])
    queue_free()

func _on_continue():
    var master = get_node("/root/MasterController")
    if master:
        master.load_saved_state(1)
    queue_free()

func _on_gallery():
    var gallery = load("res://scripts/ui/gallery_viewer.gd").new()
    add_child(gallery)

func _on_settings():
    var settings = load("res://scripts/ui/settings_menu.gd").new()
    add_child(settings)

func _on_quit():
    get_tree().quit()
