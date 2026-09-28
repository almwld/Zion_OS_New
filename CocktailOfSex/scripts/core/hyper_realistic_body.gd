extends Node3D
class_name HyperRealisticBody

# ============================================
# HYPER-REALISTIC BODY SYSTEM - GTA6 QUALITY
# Subsurface Scattering, Pore-Level Detail
# ============================================

var body: CocktailBody

# --- High-Resolution Skin Textures ---
var skin_albedo: ImageTexture
var skin_normal: ImageTexture
var skin_roughness: ImageTexture
var skin_subsurface: ImageTexture
var skin_micro_normal: ImageTexture

# --- Skin Parameters ---
var skin_base_color: Color = Color(1.0, 0.85, 0.7)
var skin_subsurface_color: Color = Color(1.0, 0.3, 0.2)
var skin_subsurface_intensity: float = 0.3
var skin_roughness_value: float = 0.4
var skin_specular: float = 0.35
var skin_micro_detail: float = 1.0

# --- Sweat System (Real-time) ---
var sweat_amount: float = 0.0
var sweat_droplets: Array[Vector3] = []
var sweat_specular: float = 0.1
var sweat_normal_strength: float = 0.0

# --- Blush/Flush System ---
var blush_amount: float = 0.0
var blush_color: Color = Color(1.0, 0.2, 0.2)
var blush_locations: Array[String] = ["cheeks", "chest", "ears", "neck"]

# --- Vein Visibility ---
var vein_visibility: float = 0.2
var vein_color: Color = Color(0.3, 0.4, 0.6, 0.3)

# --- Goosebumps ---
var goosebumps_amount: float = 0.0
var goosebumps_scale: float = 0.001

# --- High-Resolution Mesh Details ---
var mesh_lod0: MeshInstance3D
var mesh_lod1: MeshInstance3D
var mesh_lod2: MeshInstance3D

# --- Eye System ---
var eye_moisture: float = 0.8
var eye_reflection: float = 0.9
var pupil_dilation: float = 0.5
var iris_detail: float = 1.0

# --- Hair System ---
var hair_root_color: Color = Color(0.1, 0.1, 0.1)
var hair_tip_color: Color = Color(0.2, 0.2, 0.2)
var hair_shine: float = 0.6
var hair_frizz: float = 0.1
var hair_movement: float = 0.0

# --- Lip System ---
var lip_moisture: float = 0.7
var lip_color: Color = Color(0.8, 0.2, 0.3)
var lip_plumpness: float = 0.5

# --- Nipple System ---
var nipple_color: Color = Color(0.7, 0.3, 0.3)
var nipple_erectness: float = 0.0

# --- Genital System ---
var penis_head_color: Color = Color(0.8, 0.4, 0.5)
var penis_shaft_color: Color = Color(0.9, 0.7, 0.6)
var penis_vein_detail: float = 0.5
var vulva_color: Color = Color(0.8, 0.4, 0.5)
var vulva_moisture: float = 0.3
var clitoris_visibility: float = 0.0
var anus_color: Color = Color(0.7, 0.35, 0.4)

# --- Physics-Based Animation ---
var breast_physics: Array[Dictionary] = []
var butt_physics: Array[Dictionary] = []
var belly_physics: Dictionary = {}
var penis_physics: Dictionary = {}
var hair_physics: Array[Dictionary] = []

# --- Collision Detection ---
var collision_spheres: Array[Dictionary] = []

# --- Material Instances ---
var skin_material: ShaderMaterial
var eye_material: ShaderMaterial
var hair_material: ShaderMaterial
var lip_material: ShaderMaterial
var genital_material: ShaderMaterial

signal body_updated()
signal sweat_formed(droplet_position: Vector3)

func _init(_body: CocktailBody):
    body = _body
    _create_materials()
    _setup_meshes()
    _setup_physics()

func _create_materials():
    skin_material = ShaderMaterial.new()
    skin_material.shader = load("res://shaders/skin_uber_shader.gdshader")
    skin_material.set_shader_parameter("base_color", skin_base_color)
    skin_material.set_shader_parameter("subsurface_color", skin_subsurface_color)
    skin_material.set_shader_parameter("subsurface_intensity", skin_subsurface_intensity)
    skin_material.set_shader_parameter("roughness", skin_roughness_value)
    skin_material.set_shader_parameter("specular", skin_specular)
    skin_material.set_shader_parameter("sweat_amount", sweat_amount)
    skin_material.set_shader_parameter("blush_amount", blush_amount)
    skin_material.set_shader_parameter("blush_color", blush_color)
    skin_material.set_shader_parameter("vein_visibility", vein_visibility)
    skin_material.set_shader_parameter("goosebumps_amount", goosebumps_amount)

    eye_material = ShaderMaterial.new()
    eye_material.shader = load("res://shaders/eye_uber_shader.gdshader")
    eye_material.set_shader_parameter("moisture", eye_moisture)
    eye_material.set_shader_parameter("reflection", eye_reflection)
    eye_material.set_shader_parameter("pupil_dilation", pupil_dilation)
    eye_material.set_shader_parameter("iris_detail", iris_detail)

    hair_material = ShaderMaterial.new()
    hair_material.shader = load("res://shaders/hair_uber_shader.gdshader")
    hair_material.set_shader_parameter("root_color", hair_root_color)
    hair_material.set_shader_parameter("tip_color", hair_tip_color)
    hair_material.set_shader_parameter("shine", hair_shine)
    hair_material.set_shader_parameter("frizz", hair_frizz)

    lip_material = ShaderMaterial.new()
    lip_material.shader = load("res://shaders/lip_uber_shader.gdshader")
    lip_material.set_shader_parameter("lip_color", lip_color)
    lip_material.set_shader_parameter("moisture", lip_moisture)
    lip_material.set_shader_parameter("plumpness", lip_plumpness)

    genital_material = ShaderMaterial.new()
    genital_material.shader = load("res://shaders/genital_uber_shader.gdshader")
    genital_material.set_shader_parameter("penis_head_color", penis_head_color)
    genital_material.set_shader_parameter("vulva_color", vulva_color)
    genital_material.set_shader_parameter("moisture", vulva_moisture)

func _setup_meshes():
    mesh_lod0 = MeshInstance3D.new()
    mesh_lod0.mesh = load("res://assets/meshes/body_lod0.res")
    mesh_lod0.material_override = skin_material
    add_child(mesh_lod0)

func _setup_physics():
    if body.gender == "female" or body.gender == "futa":
        for i in range(2):
            breast_physics.append({
                "position": Vector3(0.2 if i == 0 else -0.2, 1.3, 0.0),
                "velocity": Vector3.ZERO,
                "mass": body.breast_size * 2.0,
                "stiffness": 0.3,
                "damping": 0.5
            })
    butt_physics.append({"position": Vector3(0.15, 0.8, -0.3), "velocity": Vector3.ZERO, "mass": 1.5, "stiffness": 0.4, "damping": 0.6})
    butt_physics.append({"position": Vector3(-0.15, 0.8, -0.3), "velocity": Vector3.ZERO, "mass": 1.5, "stiffness": 0.4, "damping": 0.6})
    belly_physics = {"position": Vector3(0, 1.0, 0.1), "velocity": Vector3.ZERO, "mass": 0.8, "stiffness": 0.5, "damping": 0.4}
    penis_physics = {"position": Vector3(0, 0.7, 0.1), "velocity": Vector3.ZERO, "mass": 0.3, "stiffness": 0.8, "damping": 0.2}

func _process(delta):
    _update_sweat(delta)
    _update_blush(delta)
    _update_goosebumps(delta)
    _update_nipple_erectness(delta)
    _update_genital_state(delta)
    _update_physics(delta)
    _update_materials()
    body_updated.emit()

func _update_sweat(delta):
    var target_sweat = body.arousal / 100.0 * 0.8
    sweat_amount = lerp(sweat_amount, target_sweat, delta * 2.0)
    sweat_specular = sweat_amount * 0.5
    sweat_normal_strength = sweat_amount * 0.3
    if sweat_amount > 0.3 and randf() < delta * sweat_amount:
        var drop_pos = Vector3(randf_range(-0.1, 0.1), randf_range(1.5, 1.7), randf_range(-0.1, 0.1))
        sweat_droplets.append(drop_pos)
        sweat_formed.emit(drop_pos)

func _update_blush(delta):
    var target_blush = body.arousal / 100.0 * 0.6
    blush_amount = lerp(blush_amount, target_blush, delta * 3.0)
    if body.arousal > 80:
        blush_color = Color(1.0, 0.1, 0.1)
    elif body.arousal > 50:
        blush_color = Color(1.0, 0.3, 0.2)
    else:
        blush_color = Color(1.0, 0.5, 0.4)

func _update_goosebumps(delta):
    var target_goosebumps = 0.0
    if body.arousal > 70:
        target_goosebumps = 0.8
    goosebumps_amount = lerp(goosebumps_amount, target_goosebumps, delta * 10.0)

func _update_nipple_erectness(delta):
    var target_erectness = body.arousal / 100.0
    nipple_erectness = lerp(nipple_erectness, target_erectness, delta * 5.0)

func _update_genital_state(delta):
    if body.gender == "male" or body.gender == "futa":
        penis_vein_detail = body.arousal / 100.0
    if body.gender == "female" or body.gender == "futa":
        vulva_moisture = lerp(vulva_moisture, body.arousal / 100.0, delta * 3.0)
        clitoris_visibility = lerp(clitoris_visibility, body.arousal / 100.0, delta * 2.0)
    anus_color = Color(0.7 + body.arousal / 300.0, 0.35, 0.4)

func _update_physics(delta):
    for breast in breast_physics:
        breast["velocity"].y -= 9.8 * delta
        breast["velocity"] *= (1.0 - breast["damping"] * delta)
        breast["position"] += breast["velocity"] * delta
    for butt in butt_physics:
        butt["velocity"].y -= 9.8 * delta
        butt["velocity"] *= (1.0 - butt["damping"] * delta)
        butt["position"] += butt["velocity"] * delta

func _update_materials():
    skin_material.set_shader_parameter("sweat_amount", sweat_amount)
    skin_material.set_shader_parameter("blush_amount", blush_amount)
    skin_material.set_shader_parameter("blush_color", blush_color)
    skin_material.set_shader_parameter("goosebumps_amount", goosebumps_amount)
    skin_material.set_shader_parameter("nipple_erectness", nipple_erectness)
    genital_material.set_shader_parameter("penis_vein_detail", penis_vein_detail)
    genital_material.set_shader_parameter("vulva_moisture", vulva_moisture)
    genital_material.set_shader_parameter("clitoris_visibility", clitoris_visibility)
    eye_material.set_shader_parameter("pupil_dilation", pupil_dilation)

func apply_force_to_breast(index: int, force: Vector3):
    if index < breast_physics.size():
        breast_physics[index]["velocity"] += force / breast_physics[index]["mass"]

func apply_force_to_butt(index: int, force: Vector3):
    if index < butt_physics.size():
        butt_physics[index]["velocity"] += force / butt_physics[index]["mass"]

func apply_force_to_belly(force: Vector3):
    belly_physics["velocity"] += force / belly_physics["mass"]

func apply_force_to_penis(force: Vector3):
    penis_physics["velocity"] += force / penis_physics["mass"]

func get_sweat_level() -> float:
    return sweat_amount

func get_skin_temperature() -> float:
    return 36.5 + body.arousal / 100.0 * 2.0

func get_heart_rate() -> float:
    return 60.0 + body.arousal * 1.2
