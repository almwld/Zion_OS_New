extends Control
class_name CharacterCreatorUI

@onready var name_input: LineEdit = $Panel/VBoxContainer/NameInput
@onready var gender_option: OptionButton = $Panel/VBoxContainer/GenderOption
@onready var height_slider: HSlider = $Panel/VBoxContainer/HeightSlider
@onready var breast_slider: HSlider = $Panel/VBoxContainer/BreastSlider
@onready var penis_slider: HSlider = $Panel/VBoxContainer/PenisSlider
@onready var skin_color_picker: ColorPickerButton = $Panel/VBoxContainer/SkinColor
@onready var hair_color_picker: ColorPickerButton = $Panel/VBoxContainer/HairColor
@onready var shyness_slider: HSlider = $Panel/VBoxContainer/ShynessSlider
@onready var dominance_slider: HSlider = $Panel/VBoxContainer/DominanceSlider
@onready var kinkiness_slider: HSlider = $Panel/VBoxContainer/KinkinessSlider
@onready var create_button: Button = $Panel/VBoxContainer/CreateButton

var created_character: CocktailBody = null

func _ready():
    gender_option.add_item("Male")
    gender_option.add_item("Female")
    gender_option.add_item("Futa")
    create_button.pressed.connect(_on_create)

func _on_create():
    var body = CocktailBody.new()
    body.body_name = name_input.text if name_input.text != "" else "Custom Character"
    var g = gender_option.selected
    body.gender = "male" if g == 0 else ("female" if g == 1 else "futa")
    body.height = height_slider.value
    body.breast_size = breast_slider.value
    body.penis_length = penis_slider.value
    body.skin_color = skin_color_picker.color
    body.hair_color = hair_color_picker.color
    body.personality["shyness"] = shyness_slider.value
    body.personality["dominance"] = dominance_slider.value
    body.personality["kinkiness"] = kinkiness_slider.value
    created_character = body
    queue_free()
