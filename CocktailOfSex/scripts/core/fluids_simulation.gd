extends Node

var systems: Dictionary = {}

func _ready():
    _create("cum", Color(0.95, 0.95, 1.0, 0.8), 0.02, 0.05)
    _create("squirt", Color(0.85, 0.85, 1.0, 0.4), 0.01, 0.03)
    _create("saliva", Color(1.0, 1.0, 1.0, 0.2), 0.005, 0.01)

func _create(name: String, color: Color, min_s: float, max_s: float):
    var ps = GPUParticles3D.new()
    ps.name = name
    ps.amount = 500
    ps.lifetime = 2.0
    ps.one_shot = true
    ps.explosiveness = 1.0
    var mat = ParticleProcessMaterial.new()
    mat.particle_flag_disable_z = true
    mat.gravity = Vector3(0, -2.0, 0)
    mat.damping = 10.0
    mat.spread = 30.0
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(0.05, 0.05, 0.05)
    mat.color = color
    mat.scale_min = min_s
    mat.scale_max = max_s
    ps.process_material = mat
    add_child(ps)
    systems[name] = ps

func emit_fluid(type: String, position: Vector3, direction: Vector3, amount: float):
    if systems.has(type):
        var ps = systems[type]
        ps.position = position
        ps.emitting = true
        await get_tree().create_timer(0.3).timeout
        ps.emitting = false
