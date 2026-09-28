extends Node
class_name GrandUnifiedSystem

# ============================================
# GRAND UNIFIED SYSTEM - EVERYTHING CONNECTED
# This is the final master controller
# ============================================

# --- All System References ---
var final_assembly: FinalAssembly
var genetics_systems: Array[GeneticsSystem] = []
var legacy_systems: Array[LegacySystem] = []
var world_persistence: WorldPersistence
var quantum_systems: Array[QuantumPleasure] = []
var multiverse: MultiverseConnector
var nft_integration: NFTIntegration
var space_exploration: SpaceExploration
var time_travel: TimeTravelSex
var cosmic_ascension: CosmicAscension
var apocalypse: ApocalypseScenarios
var oral_systems: Array[OralMasterySystem] = []
var anal_systems: Array[AnalParadiseSystem] = []
var sensory_systems: Array[SensoryOverload] = []
var premium_systems: Array[PremiumMembership] = []
var economy_systems: Array[SexEconomySystem] = []
var deep_emotional_ais: Array[DeepEmotionalAI] = []
var vr_system: FullVRIntegration
var modding: ModdingSystem
var live_update: LiveUpdate
var performance: AdvancedPerformance
var achievement_systems: Array[AchievementSystem] = []
var skill_trees: Array[SkillTreeSystem] = []
var matchmaking: MatchmakingSystem

# --- Universe State ---
var universe_name: String = "Primal Universe"
var universe_age: float = 0.0
var total_bodies_ever_created: int = 0
var total_orgasms_universal: int = 0
var total_pleasure_energy: float = 0.0

# --- God Mode ---
var is_creator_mode: bool = false
var console_commands: Array[String] = []

signal universe_initialized()
signal universal_orgasm_detected(source: String)
signal creator_mode_activated()
signal final_ascension_achieved()

func _ready():
    _initialize_universe()
    universe_initialized.emit()
    print("[GrandUnifiedSystem] The universe has been created!")

func _initialize_universe():
    final_assembly = FinalAssembly.new()
    add_child(final_assembly)
    world_persistence = WorldPersistence.new()
    add_child(world_persistence)
    multiverse = MultiverseConnector.new()
    add_child(multiverse)
    nft_integration = NFTIntegration.new()
    add_child(nft_integration)
    vr_system = FullVRIntegration.new()
    add_child(vr_system)
    modding = ModdingSystem.new()
    add_child(modding)
    live_update = LiveUpdate.new()
    add_child(live_update)
    performance = AdvancedPerformance.new()
    add_child(performance)
    print("[GrandUnifiedSystem] All core systems initialized")

func create_ultimate_body(name: String, gender: String, age: int = 25) -> CocktailBody:
    var body = final_assembly.create_full_body(name, gender, age)
    total_bodies_ever_created += 1
    _attach_advanced_systems(body)
    return body

func _attach_advanced_systems(body: CocktailBody):
    var genetics = GeneticsSystem.new(body)
    genetics_systems.append(genetics)
    body.add_child(genetics)
    var legacy = LegacySystem.new(body, genetics, body.body_name)
    legacy_systems.append(legacy)
    body.add_child(legacy)
    var quantum = QuantumPleasure.new(body)
    quantum_systems.append(quantum)
    body.add_child(quantum)
    var space = SpaceExploration.new(body)
    space_exploration = space
    body.add_child(space)
    var time = TimeTravelSex.new(body)
    time_travel = time
    body.add_child(time)
    var cosmic = CosmicAscension.new(body)
    cosmic_ascension = cosmic
    body.add_child(cosmic)
    var emotional = DeepEmotionalAI.new(body)
    deep_emotional_ais.append(emotional)
    body.add_child(emotional)
    var achievement = AchievementSystem.new(body)
    achievement_systems.append(achievement)
    body.add_child(achievement)
    var skill = SkillTreeSystem.new(body)
    skill_trees.append(skill)
    body.add_child(skill)
    body.orgasm_achieved.connect(_on_universal_orgasm.bind(body))

func _on_universal_orgasm(type: String, intensity: float, source: CocktailBody):
    total_orgasms_universal += 1
    total_pleasure_energy += intensity
    universal_orgasm_detected.emit(source.body_name)
    if cosmic_ascension:
        cosmic_ascension.add_orgasm_to_ascension()
    if world_persistence:
        world_persistence.record_orgasm()

func activate_creator_mode():
    is_creator_mode = true
    creator_mode_activated.emit()
    print("[GrandUnifiedSystem] CREATOR MODE ACTIVATED - You are now a God!")

func execute_console_command(command: String):
    console_commands.append(command)
    var parts = command.split(" ")
    match parts[0]:
        "spawn":
            if parts.size() >= 3:
                var count = int(parts[1])
                var gender = parts[2]
                for i in range(count):
                    create_ultimate_body("Spawn_" + str(i), gender, randf_range(18, 50))
        "orgasm_all":
            for body in final_assembly.all_bodies:
                body._achieve_orgasm()
        "god_mode":
            final_assembly.activate_god_mode()
        "nuke":
            print("[Console] Reality has been reset!")
        _:
            print("[Console] Unknown command: " + command)

func get_universal_report() -> String:
    var report = "╔══════════════════════════════════════════╗\n"
    report += "║     GRAND UNIFIED SYSTEM - FINAL REPORT  ║\n"
    report += "╠══════════════════════════════════════════╣\n"
    report += "║ Universe: " + universe_name + "\n"
    report += "║ Age: " + str(universe_age) + "\n"
    report += "║ Total Bodies Created: " + str(total_bodies_ever_created) + "\n"
    report += "║ Total Universal Orgasms: " + str(total_orgasms_universal) + "\n"
    report += "║ Total Pleasure Energy: " + str(total_pleasure_energy) + "\n"
    report += "║ Genetic Systems: " + str(genetics_systems.size()) + "\n"
    report += "║ Legacy Systems: " + str(legacy_systems.size()) + "\n"
    report += "║ Quantum Entanglements: " + str(quantum_systems.size()) + "\n"
    report += "║ Emotional AIs: " + str(deep_emotional_ais.size()) + "\n"
    report += "║ Achievement Systems: " + str(achievement_systems.size()) + "\n"
    report += "║ Skill Trees: " + str(skill_trees.size()) + "\n"
    report += "║ Creator Mode: " + ("ACTIVE" if is_creator_mode else "OFF") + "\n"
    report += "╚══════════════════════════════════════════╝\n"
    return report

func _process(delta):
    universe_age += delta * 0.000001
    if is_creator_mode:
        if Input.is_key_pressed(KEY_F1): activate_creator_mode()
        if Input.is_key_pressed(KEY_F2): final_assembly.activate_god_mode()
        if Input.is_key_pressed(KEY_F3):
            for i in range(10):
                create_ultimate_body("CreatorBody_" + str(i), "female", randf_range(18, 30))
