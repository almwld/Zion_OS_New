extends Control
class_name UIManager

@onready var bar: ProgressBar = $ArousalBar
@onready var pos_label: Label = $PositionLabel
@onready var text_label: Label = $DialogueLabel
@onready var count_label: Label = $OrgasmCounter

func _ready():
    if bar: bar.max_value = 100; bar.value = 0

func update_arousal(v: float):
    if bar:
        bar.value = v
        bar.modulate = Color.RED if v > 80 else (Color.ORANGE if v > 50 else Color.GREEN)

func update_position(t: String):
    if pos_label: pos_label.text = t

func update_text(t: String):
    if text_label:
        text_label.text = t
        text_label.visible = true
        await get_tree().create_timer(3.0).timeout
        text_label.visible = false

func update_count(c: int):
    if count_label: count_label.text = "Orgasms: " + str(c)
