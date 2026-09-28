extends Node
class_name Soundscape

var moan_pool: Array[AudioStreamPlayer] = []
var squirt_player: AudioStreamPlayer
var spank_player: AudioStreamPlayer
var bg_music: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

func _ready():
    _init_pool()
    _init_players()

func _init_pool():
    for i in range(10):
        var p = AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        moan_pool.append(p)

func _init_players():
    squirt_player = AudioStreamPlayer.new(); squirt_player.bus = "SFX"; add_child(squirt_player)
    spank_player = AudioStreamPlayer.new(); spank_player.bus = "SFX"; add_child(spank_player)
    bg_music = AudioStreamPlayer.new(); bg_music.bus = "Music"; add_child(bg_music)
    ambient_player = AudioStreamPlayer.new(); ambient_player.bus = "Music"; add_child(ambient_player)

func play_moan(intensity: float):
    var p = moan_pool[randi() % moan_pool.size()]
    if not p.playing:
        p.pitch_scale = 0.8 + intensity * 0.4
        p.volume_db = -20.0 + intensity * 10.0
        p.play()

func play_squirt():
    squirt_player.stream = load("res://assets/audio/fx/squirt.ogg")
    squirt_player.play()

func play_spank():
    spank_player.stream = load("res://assets/audio/fx/spank_hard.ogg")
    spank_player.play()

func start_bg_music():
    bg_music.stream = load("res://assets/audio/music/romantic_sex.ogg")
    bg_music.play()

func stop_bg_music():
    bg_music.stop()

func set_ambient(stream: AudioStream):
    ambient_player.stream = stream
    ambient_player.play()

func stop_ambient():
    ambient_player.stop()
