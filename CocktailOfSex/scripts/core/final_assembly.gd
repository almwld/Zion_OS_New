extends Node
class_name FinalAssembly

# ============================================
# FINAL ASSEMBLY - ULTIMATE INTEGRATION LAYER
# Every system connected, every signal routed
# ============================================

# --- References to ALL systems ---
var master: MasterController
var all_bodies: Array[CocktailBody] = []
var oral_systems: Array[OralMasterySystem] = []
var anal_systems: Array[AnalParadiseSystem] = []
var sensory_systems: Array[SensoryOverload] = []
var premium_systems: Array[PremiumMembership] = []
var exclusive_content: ExclusiveContentManager
var vip_concierge: VIPConcierge
var loyalty_rewards: LoyaltyRewards
var economy_systems: Array[SexEconomySystem] = []
var onlyfans_systems: Array[OnlyFansSimulator] = []
var brothel_managers: Array[BrothelManager] = []
var storytellers: Array[AIStoryteller] = []
var neural_animations: Array[NeuralAnimationController] = []
var weather_effects: DynamicWeatherEffects
var time_manager: TimeOfDayManager
var cinematic_cameras: Array[CinematicCameraSystem] = []
var fluid_simulators: Array[RealTimeFluidSimulator] = []
var haptic_feedbacks: Array[HapticFeedbackAdvanced] = []
var adaptive_musics: Array[AdaptiveMusicSystem] = []

# --- Global State ---
var is_scene_active: bool = false
var current_scene_participants: Array[CocktailBody] = []
var scene_duration: float = 0.0
var total_orgasms_in_scene: int = 0
var scene_position: String = "missionary"
var scene_intensity: float = 0.5
var scene_speed: float = 0.5

# --- God Mode ---
var god_mode_active: bool = false
var god_mode_time_scale: float = 1.0
var god_mode_infinite_stamina: bool = false
var god_mode_no_refractory: bool = false
var god_mode_max_arousal_boost: float = 1.0
var god_mode_instant_orgasm: bool = false

signal scene_fully_initialized()
signal all_systems_connected()
signal god_mode_activated()
signal god_mode_deactivated()
signal scene_climax_moment()
signal scene_afterglow_moment()

func _ready():
    _initialize_everything()
    all_systems_connected.emit()
    print("[FinalAssembly] All systems connected and ready!")

func _initialize_everything():
    master = MasterController.new()
    add_child(master)
    weather_effects = DynamicWeatherEffects.new()
    add_child(weather_effects)
    time_manager = TimeOfDayManager.new()
    add_child(time_manager)
    print("[FinalAssembly] Core systems initialized")

func create_full_body(body_name: String, gender: String, age: int = 25) -> CocktailBody:
    var body = master.create_new_body(body_name, gender, age)
    all_bodies.append(body)
    _attach_all_systems_to_body(body)
    return body

func _attach_all_systems_to_body(body: CocktailBody):
    var economy = SexEconomySystem.new(body)
    economy_systems.append(economy)
    body.add_child(economy)
    var premium = PremiumMembership.new(economy)
    premium_systems.append(premium)
    body.add_child(premium)
    var oral = OralMasterySystem.new(body)
    oral_systems.append(oral)
    body.add_child(oral)
    var anal = AnalParadiseSystem.new(body)
    anal_systems.append(anal)
    body.add_child(anal)
    var sensory = SensoryOverload.new(body)
    sensory_systems.append(sensory)
    body.add_child(sensory)
    var storyteller = AIStoryteller.new(body)
    storytellers.append(storyteller)
    body.add_child(storyteller)
    var neural = NeuralAnimationController.new(body)
    neural_animations.append(neural)
    body.add_child(neural)
    body.add_to_group("FullyEquipped")

func start_ultimate_scene(participants: Array[CocktailBody]):
    if is_scene_active: return
    is_scene_active = true
    current_scene_participants = participants
    scene_duration = 0.0
    total_orgasms_in_scene = 0
    master.start_sex_scene(participants)
    _setup_cinematic_camera(participants)
    _setup_adaptive_music(participants[0])
    _setup_haptic_feedback(participants[0])
    _setup_oral_systems(participants)
    _setup_anal_systems(participants)
    _setup_sensory_systems(participants)
    for body in participants:
        body.orgasm_achieved.connect(_on_scene_orgasm)
    scene_fully_initialized.emit()
    print("[FinalAssembly] Ultimate scene started with " + str(participants.size()) + " participants")

func _setup_cinematic_camera(participants: Array):
    var cam = CinematicCameraSystem.new(participants[0], participants[1] if participants.size() > 1 else null)
    cinematic_cameras.append(cam)
    add_child(cam)
    cam.current = true

func _setup_adaptive_music(body: CocktailBody):
    var music = AdaptiveMusicSystem.new(body)
    adaptive_musics.append(music)
    add_child(music)

func _setup_haptic_feedback(body: CocktailBody):
    var haptic = HapticFeedbackAdvanced.new(body)
    haptic_feedbacks.append(haptic)
    add_child(haptic)

func _setup_oral_systems(participants: Array):
    for i in range(participants.size()):
        for j in range(participants.size()):
            if i != j:
                var oral = OralMasterySystem.new(participants[i], participants[j])
                oral_systems.append(oral)
                participants[i].add_child(oral)

func _setup_anal_systems(participants: Array):
    for i in range(participants.size()):
        for j in range(participants.size()):
            if i != j:
                var anal = AnalParadiseSystem.new(participants[i], participants[j])
                anal_systems.append(anal)
                participants[i].add_child(anal)

func _setup_sensory_systems(participants: Array):
    for body in participants:
        var sensory = SensoryOverload.new(body)
        sensory_systems.append(sensory)
        body.add_child(sensory)

func _on_scene_orgasm(type: String, intensity: float):
    total_orgasms_in_scene += 1
    if total_orgasms_in_scene % 3 == 0:
        scene_climax_moment.emit()

func end_ultimate_scene():
    if not is_scene_active: return
    is_scene_active = false
    scene_afterglow_moment.emit()
    master.end_sex_scene()
    current_scene_participants.clear()
    print("[FinalAssembly] Ultimate scene ended. Total orgasms: " + str(total_orgasms_in_scene))

func activate_god_mode():
    god_mode_active = true
    god_mode_time_scale = 0.5
    god_mode_infinite_stamina = true
    god_mode_no_refractory = true
    god_mode_max_arousal_boost = 2.0
    god_mode_instant_orgasm = true
    Engine.time_scale = god_mode_time_scale
    for body in all_bodies:
        body.max_arousal *= god_mode_max_arousal_boost
        body.personality["stamina"] = 999.0
    god_mode_activated.emit()
    print("[FinalAssembly] GOD MODE ACTIVATED")

func deactivate_god_mode():
    god_mode_active = false
    Engine.time_scale = 1.0
    for body in all_bodies:
        body.max_arousal /= god_mode_max_arousal_boost
        body.personality["stamina"] = 0.6
    god_mode_deactivated.emit()
    print("[FinalAssembly] God Mode deactivated")

func _process(delta):
    if is_scene_active:
        scene_duration += delta
        if god_mode_active and god_mode_instant_orgasm:
            for body in current_scene_participants:
                if body.arousal > 80 and randf() < delta * 2.0:
                    body._achieve_orgasm()

func get_scene_report() -> Dictionary:
    return {
        "active": is_scene_active,
        "duration": scene_duration,
        "participants": current_scene_participants.size(),
        "total_orgasms": total_orgasms_in_scene,
        "position": scene_position,
        "god_mode": god_mode_active,
        "bodies_total": all_bodies.size(),
        "oral_systems": oral_systems.size(),
        "anal_systems": anal_systems.size(),
        "sensory_systems": sensory_systems.size()
    }

func get_complete_system_diagnostics() -> String:
    var diag = "=== COMPLETE SYSTEM DIAGNOSTICS ===\n\n"
    diag += "Core Systems:\n"
    diag += "  Master Controller: " + ("ACTIVE" if master else "OFFLINE") + "\n"
    diag += "  Weather Effects: " + ("ACTIVE" if weather_effects else "OFFLINE") + "\n"
    diag += "  Time Manager: " + ("ACTIVE" if time_manager else "OFFLINE") + "\n"
    diag += "\nBody Systems:\n"
    diag += "  Total Bodies: " + str(all_bodies.size()) + "\n"
    diag += "  Oral Systems: " + str(oral_systems.size()) + "\n"
    diag += "  Anal Systems: " + str(anal_systems.size()) + "\n"
    diag += "  Sensory Systems: " + str(sensory_systems.size()) + "\n"
    diag += "  Premium Systems: " + str(premium_systems.size()) + "\n"
    diag += "  Economy Systems: " + str(economy_systems.size()) + "\n"
    diag += "\nVisual/Audio Systems:\n"
    diag += "  Cinematic Cameras: " + str(cinematic_cameras.size()) + "\n"
    diag += "  Adaptive Music: " + str(adaptive_musics.size()) + "\n"
    diag += "  Haptic Feedbacks: " + str(haptic_feedbacks.size()) + "\n"
    diag += "\nAI Systems:\n"
    diag += "  Storytellers: " + str(storytellers.size()) + "\n"
    diag += "  Neural Animations: " + str(neural_animations.size()) + "\n"
    diag += "\nScene Status:\n"
    diag += "  Active Scene: " + ("YES" if is_scene_active else "NO") + "\n"
    diag += "  God Mode: " + ("ACTIVE" if god_mode_active else "OFF") + "\n"
    diag += "\n=== END DIAGNOSTICS ==="
    return diag
