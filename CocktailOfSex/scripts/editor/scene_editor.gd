extends Node
class_name SceneEditor

var bodies: Array[CocktailBody] = []

func _ready():
    for b in get_tree().get_nodes_in_group("Actors"):
        if b is CocktailBody: bodies.append(b)

func create_custom_scene():
    var window = AcceptDialog.new()
    window.title = "Scene Editor"
    var body_select = OptionButton.new()
    for b in bodies:
        body_select.add_item(b.body_name)
    var part_select = OptionButton.new()
    part_select.add_item("penis_head"); part_select.add_item("clitoris")
    part_select.add_item("vagina_wall"); part_select.add_item("anus_ring")
    part_select.add_item("nipples"); part_select.add_item("mouth")
    var action_select = OptionButton.new()
    action_select.add_item("touch"); action_select.add_item("penetrate")
    action_select.add_item("suck"); action_select.add_item("vibrate"); action_select.add_item("spank")
    var intensity_slider = HSlider.new(); intensity_slider.min_value = 0.0; intensity_slider.max_value = 1.0; intensity_slider.value = 0.5
    window.add_child(body_select); window.add_child(part_select)
    window.add_child(action_select); window.add_child(intensity_slider)
    var apply = Button.new(); apply.text = "Apply"
    apply.pressed.connect(func():
        var b = bodies[body_select.selected]
        var p = part_select.get_item_text(part_select.selected)
        var a = action_select.get_item_text(action_select.selected)
        var i = intensity_slider.value
        b.stimulate(p, a, i, 2.0)
        window.queue_free()
    )
    window.add_child(apply)
    window.popup_centered()
