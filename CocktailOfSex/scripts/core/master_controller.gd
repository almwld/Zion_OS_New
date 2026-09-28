extends Node
class_name MasterController

# ============================================
# MASTER CONTROLLER - ULTIMATE INTEGRATION
# Every system connected to this controller
# ============================================

# --- Core Systems ---
var game_manager: GameManager
var sound_engine: SoundEngine
var save_load: SaveLoadSystem
var relationship_manager: RelationshipManager
var world_simulation: WorldSimulation
var pregnancy_system: PregnancySystem
var fluid_simulation: FluidSimulation

# --- Body Systems ---
var all_bodies: Array[CocktailBody] = []
var hyper_realistic_bodies: Array[HyperRealisticBody] = []
var physics_bodies: Array[PhysicsBodySync] = []

# --- Sex Systems ---
var ultimate_sex_manager: UltimateSexManager
var deep_arousal_systems: Array[DeepArousalSystem] = []
var kink_engine: KinkEngine
var sexual_dialogue: SexualDialogueSystem
var position_manager: AdvancedSexScene

# --- AI Systems ---
var ai_personality_engines: Array[AIPersonalityEngine] = []
var ai_memory_systems: Array[AIMemorySystem] = []
var ai_learning_engines: Array[AILearningEngine] = []
var ai_emotion_engines: Array[AIEmotionEngine] = []
var ai_relationship_ais: Array[AIRelationshipAI] = []
var ai_desire_engines: Array[AIDesireEngine] = []

# --- Enhancement Systems ---
var masturbation_systems: Array[MasturbationSystem] = []
var toy_inventory: ToyInventory
var fantasy_generator: FantasyGenerator
var body_modification: BodyModificationSystem
var performance_enhancers: Array[PerformanceEnhancer] = []

# --- Tracking Systems ---
var orgasm_trackers: Array[OrgasmTracker] = []
var achievement_system: AchievementSystem
var skill_tree_system: SkillTreeSystem
var addiction_systems: Array[AddictionSystem] = []
var reputation_systems: Array[ReputationSystem] = []
var fetish_evolution_systems: Array[FetishEvolution] = []

# --- Visual Systems ---
var cinematic_camera: CinematicCameraSystem
var real_time_fluids: RealTimeFluidSimulator
var adaptive_music: AdaptiveMusicSystem
var haptic_feedback: HapticFeedbackAdvanced

# --- UI Systems ---
var ui_manager: UIManager
var character_creator: CharacterCreatorUI
var arousal_display: ArousalDisplay
var position_wheel: PositionWheel
var climax_meter: ClimaxMeter
var gallery_viewer: GalleryViewer
var settings_menu: SettingsMenu
var multiplayer_lobby: MultiplayerLobby

# --- State ---
var is_initialized: bool = false
var is_sex_scene_active: bool = false
var current_focus_body: CocktailBody = null

signal systems_initialized()
signal sex_scene_started(participants: Array)
signal sex_scene_ended()
signal body_added(body: CocktailBody)
signal body_removed(body: CocktailBody)

func _ready():
    _initialize_all_systems()
    is_initialized = true
    systems_initialized.emit()
    print("[MasterController] All systems initialized successfully!")

func _initialize_all_systems():
    game_manager = GameManager.new(); add_child(game_manager)
    sound_engine = SoundEngine.new(); add_child(sound_engine)
    save_load = SaveLoadSystem.new(); add_child(save_load)
    relationship_manager = RelationshipManager.new(); add_child(relationship_manager)
    world_simulation = WorldSimulation.new(); add_child(world_simulation)
    pregnancy_system = PregnancySystem.new(); add_child(pregnancy_system)
    fluid_simulation = FluidSimulation.new(); add_child(fluid_simulation)
    toy_inventory = ToyInventory.new(); add_child(toy_inventory)
    fantasy_generator = FantasyGenerator.new(); add_child(fantasy_generator)
    kink_engine = KinkEngine.new(); add_child(kink_engine)
    sexual_dialogue = SexualDialogueSystem.new(); add_child(sexual_dialogue)
    real_time_fluids = RealTimeFluidSimulator.new(); add_child(real_time_fluids)

func create_new_body(body_name: String, gender: String, age: int) -> CocktailBody:
    var body = CocktailBody.new()
    body.body_name = body_name
    body.gender = gender
    body.age = age
    all_bodies.append(body)
    add_child(body)
    _attach_systems_to_body(body)
    body_added.emit(body)
    return body

func _attach_systems_to_body(body: CocktailBody):
    var deep_arousal = DeepArousalSystem.new(body)
    deep_arousal_systems.append(deep_arousal)
    body.add_child(deep_arousal)
    var physics = PhysicsBodySync.new(body)
    physics.setup_soft_bodies()
    physics_bodies.append(physics)
    body.add_child(physics)
    var hyper_body = HyperRealisticBody.new(body)
    hyper_realistic_bodies.append(hyper_body)
    body.add_child(hyper_body)
    var ai_personality = AIPersonalityEngine.new(body)
    ai_personality_engines.append(ai_personality)
    body.add_child(ai_personality)
    var ai_memory = AIMemorySystem.new(body)
    ai_memory_systems.append(ai_memory)
    body.add_child(ai_memory)
    var ai_learning = AILearningEngine.new(body)
    ai_learning_engines.append(ai_learning)
    body.add_child(ai_learning)
    var ai_emotion = AIEmotionEngine.new(body)
    ai_emotion_engines.append(ai_emotion)
    body.add_child(ai_emotion)
    var ai_relationship = AIRelationshipAI.new(body)
    ai_relationship_ais.append(ai_relationship)
    body.add_child(ai_relationship)
    var ai_desire = AIDesireEngine.new(body)
    ai_desire_engines.append(ai_desire)
    body.add_child(ai_desire)
    var masturbation = MasturbationSystem.new(body)
    masturbation_systems.append(masturbation)
    body.add_child(masturbation)
    var orgasm_tracker = OrgasmTracker.new(body)
    orgasm_trackers.append(orgasm_tracker)
    body.add_child(orgasm_tracker)
    var addiction = AddictionSystem.new(body)
    addiction_systems.append(addiction)
    body.add_child(addiction)
    var reputation = ReputationSystem.new(body)
    reputation_systems.append(reputation)
    body.add_child(reputation)
    var fetish = FetishEvolution.new(body)
    fetish_evolution_systems.append(fetish)
    body.add_child(fetish)
    var performance = PerformanceEnhancer.new(body)
    performance_enhancers.append(performance)
    body.add_child(performance)
    var body_mod = BodyModificationSystem.new(body)
    body_modification = body_mod
    body.add_child(body_mod)
    var skill_tree = SkillTreeSystem.new(body)
    skill_tree_system = skill_tree
    body.add_child(skill_tree)
    var achievement = AchievementSystem.new(body)
    achievement_system = achievement
    body.add_child(achievement)
    body.add_to_group("Actors")

func start_sex_scene(participants: Array[CocktailBody]):
    if is_sex_scene_active: return
    is_sex_scene_active = true
    ultimate_sex_manager = UltimateSexManager.new()
    add_child(ultimate_sex_manager)
    ultimate_sex_manager.actors = participants
    for body in participants:
        body.set_scene_active(true, participants[0] if body != participants[0] else participants[1])
    cinematic_camera = CinematicCameraSystem.new(participants[0], participants[1] if participants.size() > 1 else null)
    add_child(cinematic_camera)
    cinematic_camera.current = true
    adaptive_music = AdaptiveMusicSystem.new(participants[0])
    add_child(adaptive_music)
    haptic_feedback = HapticFeedbackAdvanced.new(participants[0])
    add_child(haptic_feedback)
    sex_scene_started.emit(participants)
    print("[MasterController] Sex scene started with " + str(participants.size()) + " participants")

func end_sex_scene():
    if not is_sex_scene_active: return
    is_sex_scene_active = false
    if ultimate_sex_manager: ultimate_sex_manager.queue_free()
    if cinematic_camera: cinematic_camera.queue_free()
    if adaptive_music: adaptive_music.queue_free()
    if haptic_feedback: haptic_feedback.queue_free()
    for body in all_bodies:
        body.set_scene_active(false)
    sex_scene_ended.emit()
    print("[MasterController] Sex scene ended")

func _process(delta):
    if not is_initialized: return
    if world_simulation: world_simulation._process(delta)
    if pregnancy_system: pregnancy_system.update(delta)
    for body in all_bodies:
        if body.has_meta("pregnant") and body.get_meta("pregnant"):
            body.update_pregnancy(delta)
    for perf in performance_enhancers:
        perf._process(delta)

func get_all_bodies() -> Array[CocktailBody]:
    return all_bodies

func get_body_by_name(name: String) -> CocktailBody:
    for body in all_bodies:
        if body.body_name == name: return body
    return null

func get_available_bodies() -> Array[CocktailBody]:
    var available: Array[CocktailBody] = []
    for body in all_bodies:
        if not body.is_in_scene: available.append(body)
    return available

func save_current_state(slot: int):
    var data = {
        "bodies": [],
        "relationships": relationship_manager.rel if relationship_manager else {},
        "world_time": world_simulation.elapsed if world_simulation else 0.0,
        "weather": world_simulation.weather if world_simulation else 0
    }
    for body in all_bodies:
        data["bodies"].append({
            "name": body.body_name,
            "gender": body.gender,
            "age": body.age,
            "arousal": body.arousal,
            "pregnant": body.has_meta("pregnant"),
            "progress": body.get_meta("progress") if body.has_meta("progress") else 0.0
        })
    save_load.save(slot, data)
    print("[MasterController] Game saved to slot " + str(slot))

func load_saved_state(slot: int):
    var data = save_load.load(slot)
    if data.is_empty(): return
    for body_data in data["bodies"]:
        var body = create_new_body(body_data["name"], body_data["gender"], body_data["age"])
        body.arousal = body_data["arousal"]
        if body_data["pregnant"]:
            body.set_meta("pregnant", true)
            body.set_meta("progress", body_data["progress"])
    if world_simulation:
        world_simulation.elapsed = data.get("world_time", 0.0)
        world_simulation.weather = data.get("weather", 0)
    print("[MasterController] Game loaded from slot " + str(slot))

func get_system_report() -> String:
    var report = "=== COCKTAIL OF SEX - SYSTEM REPORT ===\n\n"
    report += "Bodies: " + str(all_bodies.size()) + "\n"
    report += "Active Sex Scene: " + ("Yes" if is_sex_scene_active else "No") + "\n"
    report += "AI Engines: " + str(ai_personality_engines.size()) + "\n"
    report += "Orgasm Trackers: " + str(orgasm_trackers.size()) + "\n"
    report += "Fluid Particles: " + str(real_time_fluids.get_particle_count() if real_time_fluids else 0) + "\n"
    report += "Connected Haptic Devices: " + str(haptic_feedback.connected_devices.size() if haptic_feedback else 0) + "\n"
    report += "Music BPM: " + str(adaptive_music.current_bpm if adaptive_music else 0) + "\n"
    report += "World Time: " + str(world_simulation.elapsed if world_simulation else 0) + "\n"
    report += "Weather: " + str(world_simulation.weather if world_simulation else 0) + "\n"
    report += "Pregnancies: " + str(_count_pregnancies()) + "\n"
    report += "Total Orgasms: " + str(_count_total_orgasms()) + "\n"
    report += "\n=== END REPORT ==="
    return report

func _count_pregnancies() -> int:
    var count = 0
    for body in all_bodies:
        if body.has_meta("pregnant") and body.get_meta("pregnant"): count += 1
    return count

func _count_total_orgasms() -> int:
    var total = 0
    for tracker in orgasm_trackers:
        total += tracker.total_orgasms
    return total
