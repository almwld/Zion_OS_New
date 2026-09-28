extends Node3D
class_name RealTimeFluidSimulator

# ============================================
# SMOOTHED PARTICLE HYDRODYNAMICS (SPH)
# Real-time cum, squirt, saliva simulation
# ============================================

var fluid_particles: Array[Dictionary] = []
var max_particles: int = 5000

var fluid_density: float = 1000.0
var fluid_viscosity: float = 0.5
var fluid_surface_tension: float = 0.3
var fluid_gravity: Vector3 = Vector3(0, -9.8, 0)

var particle_mass: float = 0.01
var particle_radius: float = 0.02
var smoothing_radius: float = 0.08

var collision_bodies: Array[Node3D] = []
var collision_planes: Array[Dictionary] = []

var active_emitters: Array[Dictionary] = []

var fluid_color: Color = Color(0.95, 0.95, 1.0, 0.8)
var fluid_type: String = "cum"

# --- Mesh Generation ---
var fluid_mesh: ArrayMesh
var fluid_mesh_instance: MeshInstance3D
var fluid_material: ShaderMaterial

func _ready():
    _setup_mesh()
    _setup_material()

func _setup_mesh():
    fluid_mesh = ArrayMesh.new()
    fluid_mesh_instance = MeshInstance3D.new()
    fluid_mesh_instance.mesh = fluid_mesh
    add_child(fluid_mesh_instance)

func _setup_material():
    fluid_material = ShaderMaterial.new()
    fluid_material.shader = load("res://shaders/fluid_sph_shader.gdshader")
    fluid_material.set_shader_parameter("color", fluid_color)
    fluid_material.set_shader_parameter("refraction", 1.33)
    fluid_material.set_shader_parameter("specular", 0.5)
    fluid_material.set_shader_parameter("roughness", 0.1)
    fluid_mesh_instance.material_override = fluid_material

func _process(delta):
    _update_particles(delta)
    _update_emitters(delta)
    _generate_mesh()

func _update_particles(delta):
    for i in range(fluid_particles.size()):
        var p = fluid_particles[i]
        p["velocity"] += fluid_gravity * delta
        _apply_viscosity(p, delta)
        _apply_surface_tension(p, delta)
        _apply_collisions(p, delta)
        p["position"] += p["velocity"] * delta
        p["lifetime"] -= delta

func _apply_viscosity(particle: Dictionary, delta: float):
    for other in fluid_particles:
        if other == particle: continue
        var dist = particle["position"].distance_to(other["position"])
        if dist < smoothing_radius and dist > 0:
            var kernel = (smoothing_radius - dist) / smoothing_radius
            var velocity_diff = other["velocity"] - particle["velocity"]
            particle["velocity"] += velocity_diff * kernel * fluid_viscosity * delta

func _apply_surface_tension(particle: Dictionary, delta: float):
    var center = Vector3.ZERO
    var count = 0
    for other in fluid_particles:
        if other == particle: continue
        var dist = particle["position"].distance_to(other["position"])
        if dist < smoothing_radius:
            center += other["position"]
            count += 1
    if count > 0:
        center /= count
        var direction = (center - particle["position"]).normalized()
        particle["velocity"] += direction * fluid_surface_tension * delta

func _apply_collisions(particle: Dictionary, delta: float):
    for body in collision_bodies:
        if body is CollisionShape3D:
            var shape = body.shape
            if shape is SphereShape3D:
                var center = body.global_position
                var radius = shape.radius
                var dist = particle["position"].distance_to(center)
                if dist < radius + particle_radius:
                    var normal = (particle["position"] - center).normalized()
                    particle["position"] = center + normal * (radius + particle_radius)
                    particle["velocity"] = particle["velocity"].reflect(normal) * 0.5

func _update_emitters(delta):
    for emitter in active_emitters:
        emitter["timer"] += delta
        if emitter["timer"] >= emitter["interval"]:
            emitter["timer"] = 0.0
            _emit_particles(emitter["position"], emitter["direction"], emitter["amount"], emitter["velocity"])

func _emit_particles(position: Vector3, direction: Vector3, amount: int, speed: float):
    for i in range(amount):
        if fluid_particles.size() >= max_particles: break
        var offset = Vector3(randf_range(-0.01, 0.01), randf_range(-0.01, 0.01), randf_range(-0.01, 0.01))
        var vel = direction * speed * randf_range(0.5, 1.5) + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
        fluid_particles.append({
            "position": position + offset,
            "velocity": vel,
            "lifetime": 3.0,
            "color": fluid_color
        })

func _generate_mesh():
    var vertices = PackedVector3Array()
    for p in fluid_particles:
        vertices.append(p["position"])
    if vertices.size() > 0:
        var arrays = []
        arrays.resize(Mesh.ARRAY_MAX)
        arrays[Mesh.ARRAY_VERTEX] = vertices
        fluid_mesh.clear_surfaces()
        fluid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, arrays)

func start_emission(type: String, position: Vector3, direction: Vector3, amount: int, speed: float, duration: float):
    match type:
        "cum": fluid_color = Color(0.95, 0.95, 1.0, 0.8)
        "squirt": fluid_color = Color(0.85, 0.85, 1.0, 0.4)
        "saliva": fluid_color = Color(1.0, 1.0, 1.0, 0.2)
    fluid_type = type
    fluid_material.set_shader_parameter("color", fluid_color)
    active_emitters.append({
        "position": position,
        "direction": direction,
        "amount": amount,
        "velocity": speed,
        "interval": 0.05,
        "timer": 0.0,
        "duration": duration
    })
    await get_tree().create_timer(duration).timeout
    active_emitters.pop_front()

func add_collision_body(body: Node3D):
    if not body in collision_bodies:
        collision_bodies.append(body)

func get_particle_count() -> int:
    return fluid_particles.size()
