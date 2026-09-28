extends Control
class_name PositionWheel

var sex_manager: UltimateSexManager
var buttons: Array[Button] = []
var position_names: Array[String] = [
    "Missionary", "Doggy", "Cowgirl", "Reverse Cowgirl",
    "Anal Missionary", "Anal Doggy", "Blowjob", "Cunnilingus",
    "Sixty Nine", "Double Penetration", "Scissoring", "Tribadism"
]

func _ready():
    _create_wheel()

func _create_wheel():
    var radius = 120
    var center = Vector2(150, 150)
    for i in range(position_names.size()):
        var angle = (2 * PI * i) / position_names.size() - PI / 2
        var pos = center + Vector2(cos(angle), sin(angle)) * radius
        var btn = Button.new()
        btn.text = position_names[i]
        btn.position = pos - btn.size / 2
        btn.pressed.connect(func(): _on_position_selected(i))
        add_child(btn)
        buttons.append(btn)

func _on_position_selected(index: int):
    if sex_manager:
        match index:
            0: sex_manager.current_act = UltimateSexManager.SexAct.VAGINAL_SEX
            1: sex_manager.current_act = UltimateSexManager.SexAct.VAGINAL_SEX
            2: sex_manager.current_act = UltimateSexManager.SexAct.VAGINAL_SEX
            3: sex_manager.current_act = UltimateSexManager.SexAct.VAGINAL_SEX
            4: sex_manager.current_act = UltimateSexManager.SexAct.ANAL_SEX
            5: sex_manager.current_act = UltimateSexManager.SexAct.ANAL_SEX
            6: sex_manager.current_act = UltimateSexManager.SexAct.ORAL_PENIS
            7: sex_manager.current_act = UltimateSexManager.SexAct.ORAL_VAGINA
            8: sex_manager.current_act = UltimateSexManager.SexAct.ORAL_PENIS
            9: sex_manager.current_act = UltimateSexManager.SexAct.VAGINAL_SEX
            10: sex_manager.current_act = UltimateSexManager.SexAct.SCISSORING
            11: sex_manager.current_act = UltimateSexManager.SexAct.TRIBADISM
