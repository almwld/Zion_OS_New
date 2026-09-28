extends Node
class_name QuantumPleasure

var body: CocktailBody

var quantum_state: String = "superposition"
var pleasure_wave_function: float = 0.0
var quantum_entanglement_partner: CocktailBody = null
var is_entangled: bool = false

var parallel_orgasms: int = 0
var probability_cloud: Array[float] = []

signal quantum_entanglement_formed(partner: CocktailBody)
signal wave_function_collapsed(pleasure: float)
signal parallel_orgasm_achieved()

func _init(_body: CocktailBody):
    body = _body

func entangle_with(partner: CocktailBody):
    quantum_entanglement_partner = partner
    is_entangled = true
    quantum_entanglement_formed.emit(partner)

func _process(delta):
    if is_entangled and quantum_entanglement_partner:
        if body.arousal > 80 and quantum_entanglement_partner.arousal > 80:
            if randf() < 0.1:
                parallel_orgasms += 1
                body._achieve_orgasm()
                quantum_entanglement_partner._achieve_orgasm()
                parallel_orgasm_achieved.emit()

func collapse_wave_function():
    pleasure_wave_function = body.arousal * randf()
    wave_function_collapsed.emit(pleasure_wave_function)
    body.arousal = pleasure_wave_function
