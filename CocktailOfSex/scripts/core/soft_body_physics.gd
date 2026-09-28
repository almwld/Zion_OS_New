extends Node
class_name SoftBodyPhysics

var soft_bodies: Array[SoftBody3D] = []
var penis_soft: SoftBody3D = null
var breast_soft: Array[SoftBody3D] = []

func _ready():
    _setup()

func _setup():
    var mesh = get_parent()
    if mesh is MeshInstance3D:
        var sb = SoftBody3D.new()
        sb.mesh = mesh.mesh
        sb.stiffness = 0.3
        sb.damping = 0.5
        mesh.replace_by(sb)
        soft_bodies.append(sb)

func apply_force(force: Vector3):
    for sb in soft_bodies:
        sb.apply_central_impulse(force)
