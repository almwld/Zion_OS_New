extends Node
class_name AdvancedFluidPhysics

var fluid_particles: GPUParticles3D
var fluid_material: ParticleProcessMaterial

func _init(parent: Node3D):
    _setup(parent)

func _setup(parent: Node3D):
    fluid_particles = GPUParticles3D.new()
    fluid_particles.name = "AdvancedFluidParticles"
    fluid_particles.amount = 500
    fluid_particles.lifetime = 2.0
    fluid_particles.one_shot = true
    fluid_particles.explosiveness = 1.0
    fluid_material = ParticleProcessMaterial.new()
    fluid_material.particle_flag_disable_z = true
    fluid_material.gravity = Vector3(0, -2.0, 0)
    fluid_material.damping = 10.0
    fluid_material.spread = 30.0
    fluid_material.flatness = 0.1
    fluid_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    fluid_material.emission_box_extents = Vector3(0.05, 0.05, 0.05)
    fluid_particles.process_material = fluid_material
    parent.add_child(fluid_particles)
    var collision_shape = CollisionShape3D.new()
    var shape = SphereShape3D.new()
    shape.radius = 0.1
    collision_shape.shape = shape
    fluid_particles.add_child(collision_shape)

func emit_fluid(type: String, amount: float, position: Vector3, direction: Vector3):
    fluid_particles.position = position
    fluid_particles.direction = direction * amount
    fluid_particles.amount = int(amount * 100)
    match type:
        "cum":
            fluid_material.color = Color(0.95, 0.95, 0.98, 0.8)
            fluid_material.scale_min = 0.02 * amount
            fluid_material.scale_max = 0.05 * amount
        "squirt":
            fluid_material.color = Color(0.9, 0.9, 1.0, 0.5)
            fluid_material.scale_min = 0.01 * amount
            fluid_material.scale_max = 0.03 * amount
        "saliva":
            fluid_material.color = Color(1.0, 1.0, 1.0, 0.3)
            fluid_material.scale_min = 0.005
            fluid_material.scale_max = 0.01
        "sweat":
            fluid_material.color = Color(1.0, 1.0, 1.0, 0.1)
            fluid_material.scale_min = 0.001
            fluid_material.scale_max = 0.003
    fluid_particles.emitting = true
    await get_tree().create_timer(0.2).timeout
    fluid_particles.emitting = false
