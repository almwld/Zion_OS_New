extends Node
class_name UltimateSexManager

# ============================================
# ULTIMATE SEX MANAGER - Master Sex Scene Controller
# ============================================

var actors: Array[CocktailBody] = []
var main_actor: CocktailBody = null
var partner: CocktailBody = null

enum SexAct {
    IDLE, KISSING, TOUCHING, GRINDING,
    ORAL_PENIS, ORAL_VAGINA, ORAL_ANUS,
    VAGINAL_SEX, ANAL_SEX,
    SCISSORING, TRIBADISM,
    ORGASM, AFTERGLOW
}
var current_act: SexAct = SexAct.IDLE
var previous_act: SexAct = SexAct.IDLE
var act_timer: float = 0.0

var intensity: float = 0.5
var speed: float = 0.5
var depth: float = 0.5

var plot_phase: String = "shy_start"
var dialogue_pool: Dictionary = {}
var orgasm_count: int = 0
var scene_duration: float = 0.0

var moan_player: AudioStreamPlayer
var squish_player: AudioStreamPlayer
var kiss_player: AudioStreamPlayer

func _ready():
    _initialize_plot()
    _initialize_sound()
    var bodies = get_tree().get_nodes_in_group("Actors")
    for body in bodies:
        if body is CocktailBody:
            actors.append(body)
    if actors.size() >= 2:
        main_actor = actors[0]
        partner = actors[1]
        main_actor.set_scene_active(true, partner)
        partner.set_scene_active(true, main_actor)
        main_actor.orgasm_achieved.connect(_on_orgasm)
        partner.orgasm_achieved.connect(_on_orgasm)

func _initialize_plot():
    dialogue_pool = {
        "shy_start": ["هل أنت متأكد؟", "أنا خجلة...", "هذه أول مرة لي...", "كن لطيفاً..."],
        "eager_middle": ["أكثر!", "لا تتوقف!", "هناك!", "أعمق!", "أسرع!"],
        "desperate_climax": ["سأبلغ!", "أنا أبلغ!", "في الداخل!", "يا إلهي!", "اقذف معي!"],
        "afterglow": ["رائع...", "شكراً...", "أحبك...", "ابقَ معي..."]
    }

func _initialize_sound():
    moan_player = AudioStreamPlayer.new(); moan_player.bus = "SFX"; add_child(moan_player)
    squish_player = AudioStreamPlayer.new(); squish_player.bus = "SFX"; add_child(squish_player)
    kiss_player = AudioStreamPlayer.new(); kiss_player.bus = "SFX"; add_child(kiss_player)

func _process(delta):
    if current_act in [SexAct.IDLE, SexAct.ORGASM, SexAct.AFTERGLOW]:
        return
    scene_duration += delta
    act_timer += delta
    _update_plot_phase()
    if act_timer > 0.5:
        act_timer = 0.0
        _play_sound()

func _physics_process(delta):
    if current_act in [SexAct.IDLE, SexAct.ORGASM, SexAct.AFTERGLOW]:
        return
    _perform_act(delta)
    if randf() < 0.02:
        _generate_dialogue()

func _update_plot_phase():
    if not main_actor or not partner:
        return
    var avg = (main_actor.arousal + partner.arousal) / 2.0
    if avg < 30: plot_phase = "shy_start"
    elif avg < 70: plot_phase = "eager_middle"
    else: plot_phase = "desperate_climax"

func _generate_dialogue():
    if dialogue_pool.has(plot_phase):
        var phrases = dialogue_pool[plot_phase]
        var text = phrases[randi() % phrases.size()]
        print(text)

func _play_sound():
    match current_act:
        SexAct.KISSING: kiss_player.stream = load("res://assets/audio/fx/kiss_soft.wav"); kiss_player.play()
        SexAct.ORAL_PENIS, SexAct.ORAL_VAGINA, SexAct.ORAL_ANUS: squish_player.stream = load("res://assets/audio/fx/squish_wet.wav"); squish_player.play()
        SexAct.VAGINAL_SEX, SexAct.ANAL_SEX: squish_player.stream = load("res://assets/audio/fx/squish_hard.wav"); squish_player.play(); if randf() < 0.3: moan_player.stream = load("res://assets/audio/moans/moan_low.wav"); moan_player.play()

func _perform_act(delta):
    var s = speed; var i = intensity
    if not main_actor or not partner: return
    match current_act:
        SexAct.KISSING:
            main_actor.stimulate("lips", "touch", 0.3*s, delta)
            partner.stimulate("lips", "touch", 0.3*s, delta)
        SexAct.TOUCHING:
            main_actor.stimulate("skin", "touch", 0.5*s, delta)
            partner.stimulate("nipples", "rub", 0.4*s, delta)
        SexAct.GRINDING:
            main_actor.stimulate("penis_head", "rub", 0.6*s, delta)
            partner.stimulate("clitoris", "rub", 0.7*s, delta)
        SexAct.ORAL_PENIS:
            main_actor.stimulate("penis_head", "suck", 0.8*s, delta)
        SexAct.ORAL_VAGINA:
            partner.stimulate("clitoris", "lick", 0.9*s, delta)
        SexAct.ORAL_ANUS:
            partner.stimulate("anus_ring", "lick", 0.8*s, delta)
        SexAct.VAGINAL_SEX:
            partner.stimulate("vagina_wall", "penetrate", 1.0*s*i, delta)
            main_actor.stimulate("penis_shaft", "penetrate", 0.9*s, delta)
        SexAct.ANAL_SEX:
            partner.stimulate("anus_deep", "penetrate", 1.0*s*i, delta)
            main_actor.stimulate("penis_shaft", "penetrate", 0.9*s, delta)
        SexAct.SCISSORING:
            main_actor.stimulate("clitoris", "rub", 0.7*s, delta)
            partner.stimulate("clitoris", "rub", 0.7*s, delta)
        SexAct.TRIBADISM:
            main_actor.stimulate("vagina_wall", "rub", 0.6*s, delta)
            partner.stimulate("vagina_wall", "rub", 0.6*s, delta)

func _on_orgasm(type: String, intensity: float):
    orgasm_count += 1
    previous_act = current_act
    current_act = SexAct.ORGASM
    plot_phase = "afterglow"
    await get_tree().create_timer(5.0).timeout
    current_act = SexAct.AFTERGLOW
    await get_tree().create_timer(10.0).timeout
    current_act = previous_act if previous_act != SexAct.ORGASM else SexAct.IDLE

func handle_input(event: InputEvent):
    if event.is_action_pressed("kiss"): current_act = SexAct.KISSING
    elif event.is_action_pressed("position_missionary"): current_act = SexAct.VAGINAL_SEX
    elif event.is_action_pressed("position_doggy"): current_act = SexAct.VAGINAL_SEX
    elif event.is_action_pressed("position_anal"): current_act = SexAct.ANAL_SEX
    elif event.is_action_pressed("position_69"): current_act = SexAct.ORAL_PENIS
    if event.is_action_pressed("thrust_deeper"): intensity = min(intensity + 0.1, 1.0)
    if event.is_action_pressed("thrust_shallower"): intensity = max(intensity - 0.1, 0.1)
    if event.is_action_pressed("thrust_faster"): speed = min(speed + 0.1, 1.0)
    if event.is_action_pressed("thrust_slower"): speed = max(speed - 0.1, 0.1)
