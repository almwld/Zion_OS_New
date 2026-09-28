extends Control
class_name ArousalDisplay

@export var target_body: CocktailBody
@onready var bar: ProgressBar = $ArousalBar
@onready var label: Label = $NameLabel
@onready var orgasm_label: Label = $OrgasmLabel
@onready var fluid_label: Label = $FluidLabel

var tracker: OrgasmTracker

func _ready():
    if target_body:
        label.text = target_body.body_name
        target_body.arousal_changed.connect(_on_arousal)
        target_body.orgasm_achieved.connect(_on_orgasm)
        tracker = OrgasmTracker.new(target_body)

func _on_arousal(value: float):
    if bar:
        bar.value = value
        if value > 80: bar.modulate = Color.RED
        elif value > 50: bar.modulate = Color.ORANGE
        else: bar.modulate = Color.GREEN

func _on_orgasm(type: String, intensity: float):
    if orgasm_label:
        orgasm_label.text = "Orgasms: " + str(tracker.total_orgasms)

func _process(delta):
    if fluid_label and target_body:
        fluid_label.text = "Pre: " + str(round(target_body.precum_amount * 10) / 10.0) + " | Cum: " + str(round(target_body.cum_amount * 10) / 10.0)
