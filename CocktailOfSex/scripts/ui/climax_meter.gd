extends Control
class_name ClimaxMeter

@export var body: CocktailBody
@onready var bar: ProgressBar = $ClimaxBar
@onready var edge_label: Label = $EdgeLabel

var is_edging: bool = false
var edge_count: int = 0
var edge_start_time: float = 0.0

func _ready():
    if body:
        body.arousal_changed.connect(_on_arousal)
        body.orgasm_achieved.connect(_on_orgasm)

func _on_arousal(value: float):
    if bar:
        bar.value = value
        if value > 95:
            bar.modulate = Color.PURPLE
            if not is_edging:
                is_edging = true
                edge_count += 1
                edge_start_time = Time.get_ticks_msec() / 1000.0
                if edge_label:
                    edge_label.text = "EDGING! (" + str(edge_count) + ")"
                    edge_label.visible = true
        elif value < 90 and is_edging:
            is_edging = false
            if edge_label:
                edge_label.visible = false

func _on_orgasm(type: String, intensity: float):
    is_edging = false
    if edge_label:
        edge_label.visible = false
