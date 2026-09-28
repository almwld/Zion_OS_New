extends Node
class_name PhysicsBodySync

var body: CocktailBody
var soft_bodies: Array[SoftBody3D] = []

var breast_left: SoftBody3D = null
var breast_right: SoftBody3D = null
var penis: SoftBody3D = null
var butt_left: SoftBody3D = null
var butt_right: SoftBody3D = null

var breast_stiffness: float = 0.3
var breast_damping: float = 0.5
var penis_stiffness: float = 0.8
var penis_damping: float = 0.2
var butt_stiffness: float = 0.4
var butt_damping: float = 0.6

func _init(_body: CocktailBody):
    body = _body

func setup_soft_bodies():
    if body.gender == "female" or body.gender == "futa":
        breast_left = SoftBody3D.new()
        breast_left.mesh = _create_sphere_mesh(body.breast_size * 0.3)
        breast_left.stiffness = breast_stiffness
        breast_left.damping = breast_damping
        body.add_child(breast_left)
        soft_bodies.append(breast_left)

        breast_right = SoftBody3D.new()
        breast_right.mesh = _create_sphere_mesh(body.breast_size * 0.3)
        breast_right.stiffness = breast_stiffness
        breast_right.damping = breast_damping
        body.add_child(breast_right)
        soft_bodies.append(breast_right)

    if body.gender == "male" or body.gender == "futa":
        penis = SoftBody3D.new()
        penis.mesh = _create_cylinder_mesh(body.penis_length, body.penis_girth)
        penis.stiffness = penis_stiffness
        penis.damping = penis_damping
        body.add_child(penis)
        soft_bodies.append(penis)

    butt_left = SoftBody3D.new()
    butt_left.mesh = _create_sphere_mesh(0.2)
    butt_left.stiffness = butt_stiffness
    butt_left.damping = butt_damping
    body.add_child(butt_left)
    soft_bodies.append(butt_left)

    butt_right = SoftBody3D.new()
    butt_right.mesh = _create_sphere_mesh(0.2)
    butt_right.stiffness = butt_stiffness
    butt_right.damping = butt_damping
    body.add_child(butt_right)
    soft_bodies.append(butt_right)

func _create_sphere_mesh(radius: float) -> SphereMesh:
    var mesh = SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    return mesh

func _create_cylinder_mesh(length: float, radius: float) -> CylinderMesh:
    var mesh = CylinderMesh.new()
    mesh.height = length
    mesh.top_radius = radius * 0.8
    mesh.bottom_radius = radius
    return mesh

func apply_breast_bounce(delta: float):
    if breast_left:
        breast_left.apply_central_force(Vector3(0, -9.8 * body.breast_size, 0))
    if breast_right:
        breast_right.apply_central_force(Vector3(0, -9.8 * body.breast_size, 0))

func apply_penis_force(direction: Vector3, force: float):
    if penis:
        penis.apply_central_impulse(direction * force)

func apply_butt_bounce(delta: float):
    if butt_left:
        butt_left.apply_central_force(Vector3(0, -9.8 * 0.3, 0))
    if butt_right:
        butt_right.apply_central_force(Vector3(0, -9.8 * 0.3, 0))

func _process(delta):
    apply_breast_bounce(delta)
    apply_butt_bounce(delta)
